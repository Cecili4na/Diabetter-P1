-- ============================================================
-- Notification System Hardening (MVP)
-- ============================================================

-- 1. Add notification times column to profiles (separate from measurement labels)
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS horarios_notificacao jsonb DEFAULT '[]'::jsonb;

-- 2. GIN index on profiles.horarios_notificacao for fast @> (contains) queries
CREATE INDEX IF NOT EXISTS idx_profiles_horarios_notificacao
  ON public.profiles USING GIN (horarios_notificacao);

-- 3. GIN index on profiles.horarios_medicao (keep for reference)
CREATE INDEX IF NOT EXISTS idx_profiles_horarios_medicao
  ON public.profiles USING GIN (horarios_medicao);

-- 2. Idempotency table: one email per user per slot per day
CREATE TABLE IF NOT EXISTS public.email_reminder_sends (
  id         uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id    uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  slot       text NOT NULL,                  -- e.g. "08:20"
  send_date  date NOT NULL DEFAULT CURRENT_DATE,
  status     text NOT NULL DEFAULT 'sent',   -- 'sent' | 'failed'
  created_at timestamptz DEFAULT now(),

  -- Prevents duplicate sends for the same user + slot + day
  CONSTRAINT uq_reminder_user_slot_day UNIQUE (user_id, slot, send_date)
);

-- 3. Index for quick lookups on the idempotency table
CREATE INDEX IF NOT EXISTS idx_reminder_sends_lookup
  ON public.email_reminder_sends (user_id, slot, send_date);

-- 4. RLS: only service_role should access this table (Edge Function uses service_role key)
ALTER TABLE public.email_reminder_sends ENABLE ROW LEVEL SECURITY;
-- No policies = no access via anon/authenticated, only service_role bypasses RLS.
