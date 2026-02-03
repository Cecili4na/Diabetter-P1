-- =====================================================
-- CRON JOB FOR MONTHLY COUNTER RESET
-- =====================================================
-- 
-- This creates a scheduled job using pg_cron extension
-- to reset freemium counters on the 1st of each month.
--
-- IMPORTANT: Before running this, make sure pg_cron is enabled:
-- 1. Go to Supabase Dashboard > Database > Extensions
-- 2. Enable "pg_cron" extension
-- 3. Then run this SQL
--
-- =====================================================

-- Enable pg_cron extension (if not already enabled via dashboard)
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Grant usage on cron schema to postgres
GRANT USAGE ON SCHEMA cron TO postgres;

-- Schedule the monthly reset job
-- Runs at 00:05 UTC on the 1st of every month
-- (5 minutes after midnight to avoid edge cases)
SELECT cron.schedule(
  'reset-monthly-freemium-counters', -- job name
  '5 0 1 * *',                       -- cron expression: minute 5, hour 0, day 1, every month
  $$
    SELECT public.reset_monthly_counters();
  $$
);

-- Verify the job was created (optional check)
-- SELECT * FROM cron.job;

-- =====================================================
-- ALTERNATIVE: If you prefer Edge Functions
-- =====================================================
--
-- You can also create a Supabase Edge Function and trigger it
-- via an external cron service (like cron-job.org, GitHub Actions, etc.)
--
-- Edge Function example (create in supabase/functions/reset-counters/index.ts):
--
-- import { createClient } from '@supabase/supabase-js'
-- 
-- Deno.serve(async (req) => {
--   // Verify secret to prevent unauthorized calls
--   const authHeader = req.headers.get('Authorization')
--   if (authHeader !== `Bearer ${Deno.env.get('CRON_SECRET')}`) {
--     return new Response('Unauthorized', { status: 401 })
--   }
--
--   const supabase = createClient(
--     Deno.env.get('SUPABASE_URL')!,
--     Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
--   )
--
--   const { error } = await supabase.rpc('reset_monthly_counters')
--   
--   if (error) {
--     return new Response(JSON.stringify({ error: error.message }), { status: 500 })
--   }
--   
--   return new Response(JSON.stringify({ success: true }), { status: 200 })
-- })
--
-- =====================================================

-- To remove the job if needed:
-- SELECT cron.unschedule('reset-monthly-freemium-counters');
