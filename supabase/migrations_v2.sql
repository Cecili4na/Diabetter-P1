-- =====================================================
-- SCHEMA MIGRATIONS FOR DIABETTER MVP
-- Run this in Supabase SQL Editor
-- =====================================================

-- 1. Enhance profiles table (RF-03)
ALTER TABLE public.profiles 
  ADD COLUMN IF NOT EXISTS horarios_medicao jsonb DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS metas jsonb DEFAULT '{"min": 70, "max": 180, "alvo": 100}'::jsonb,
  ADD COLUMN IF NOT EXISTS unidade_glicemia text DEFAULT 'mg/dL';

-- 2. Enhance glicemia table (RF-04) - add notes field
ALTER TABLE public.glicemia 
  ADD COLUMN IF NOT EXISTS notas text;

-- 3. Enhance eventos table (RF-06) - add event type
ALTER TABLE public.eventos 
  ADD COLUMN IF NOT EXISTS tipo_evento text DEFAULT 'outro',
  ADD COLUMN IF NOT EXISTS carboidratos numeric,
  ADD COLUMN IF NOT EXISTS calorias numeric;

-- Add check constraint for event types
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'eventos_tipo_check'
  ) THEN
    ALTER TABLE public.eventos 
      ADD CONSTRAINT eventos_tipo_check 
      CHECK (tipo_evento IN ('refeicao', 'exercicio', 'estresse', 'medicamento', 'outro'));
  END IF;
END $$;

-- =====================================================
-- FREEMIUM TABLES (RF-11)
-- =====================================================

-- Planos (subscription plans)
CREATE TABLE IF NOT EXISTS public.planos (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  nome text NOT NULL UNIQUE,
  descricao text,
  limite_registros_mes integer,      -- NULL = unlimited
  limite_exportacoes_mes integer,     -- NULL = unlimited
  preco_mensal numeric DEFAULT 0,
  ativo boolean DEFAULT true,
  created_at timestamptz DEFAULT now()
);

-- User subscription status
CREATE TABLE IF NOT EXISTS public.user_planos (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  plano_id uuid NOT NULL REFERENCES public.planos(id),
  data_inicio date DEFAULT CURRENT_DATE,
  data_fim date,                      -- NULL = active indefinitely
  registros_usados_mes integer DEFAULT 0,
  exportacoes_usadas_mes integer DEFAULT 0,
  mes_referencia date DEFAULT date_trunc('month', CURRENT_DATE)::date,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  CONSTRAINT user_planos_user_unique UNIQUE(user_id)
);

-- Insert default plans (idempotent)
INSERT INTO public.planos (nome, descricao, limite_registros_mes, limite_exportacoes_mes, preco_mensal)
VALUES
  ('free', 'Plano gratuito com limites', 30, 2, 0),
  ('premium', 'Plano premium sem limites', NULL, NULL, 19.90)
ON CONFLICT (nome) DO NOTHING;

-- =====================================================
-- RLS POLICIES FOR NEW TABLES
-- =====================================================

ALTER TABLE public.planos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_planos ENABLE ROW LEVEL SECURITY;

-- Planos: Anyone can view (public catalog)
DROP POLICY IF EXISTS "Anyone can view plans" ON public.planos;
CREATE POLICY "Anyone can view plans" 
  ON public.planos FOR SELECT 
  USING (true);

-- User Planos: Users CRUD their own subscription
DROP POLICY IF EXISTS "Users view own subscription" ON public.user_planos;
CREATE POLICY "Users view own subscription" 
  ON public.user_planos FOR SELECT 
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users insert own subscription" ON public.user_planos;
CREATE POLICY "Users insert own subscription" 
  ON public.user_planos FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users update own subscription" ON public.user_planos;
CREATE POLICY "Users update own subscription" 
  ON public.user_planos FOR UPDATE 
  USING (auth.uid() = user_id);

-- =====================================================
-- TRIGGER: Auto-assign free plan to new users
-- =====================================================

CREATE OR REPLACE FUNCTION public.assign_free_plan()
RETURNS TRIGGER AS $$
DECLARE
  free_plan_id uuid;
BEGIN
  SELECT id INTO free_plan_id FROM public.planos WHERE nome = 'free' LIMIT 1;
  
  IF free_plan_id IS NOT NULL THEN
    INSERT INTO public.user_planos (user_id, plano_id)
    VALUES (NEW.id, free_plan_id)
    ON CONFLICT (user_id) DO NOTHING;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_profile_created_assign_plan ON public.profiles;
CREATE TRIGGER on_profile_created_assign_plan
  AFTER INSERT ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.assign_free_plan();

-- =====================================================
-- HELPER FUNCTION: Reset monthly counters
-- Run this monthly via Supabase cron or Edge Function
-- =====================================================

CREATE OR REPLACE FUNCTION public.reset_monthly_counters()
RETURNS void AS $$
BEGIN
  UPDATE public.user_planos
  SET 
    registros_usados_mes = 0,
    exportacoes_usadas_mes = 0,
    mes_referencia = date_trunc('month', CURRENT_DATE)::date,
    updated_at = now()
  WHERE mes_referencia < date_trunc('month', CURRENT_DATE)::date;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- RPC FUNCTIONS: Increment counters (used by Flutter)
-- =====================================================

CREATE OR REPLACE FUNCTION public.increment_record_count(p_user_id uuid)
RETURNS void AS $$
BEGIN
  -- First reset if month changed
  UPDATE public.user_planos
  SET 
    registros_usados_mes = 0,
    exportacoes_usadas_mes = 0,
    mes_referencia = date_trunc('month', CURRENT_DATE)::date
  WHERE user_id = p_user_id 
    AND mes_referencia < date_trunc('month', CURRENT_DATE)::date;

  -- Then increment
  UPDATE public.user_planos
  SET 
    registros_usados_mes = registros_usados_mes + 1,
    updated_at = now()
  WHERE user_id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.increment_export_count(p_user_id uuid)
RETURNS void AS $$
BEGIN
  -- First reset if month changed
  UPDATE public.user_planos
  SET 
    registros_usados_mes = 0,
    exportacoes_usadas_mes = 0,
    mes_referencia = date_trunc('month', CURRENT_DATE)::date
  WHERE user_id = p_user_id 
    AND mes_referencia < date_trunc('month', CURRENT_DATE)::date;

  -- Then increment
  UPDATE public.user_planos
  SET 
    exportacoes_usadas_mes = exportacoes_usadas_mes + 1,
    updated_at = now()
  WHERE user_id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute to authenticated users
GRANT EXECUTE ON FUNCTION public.reset_monthly_counters() TO authenticated;
GRANT EXECUTE ON FUNCTION public.increment_record_count(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.increment_export_count(uuid) TO authenticated;
