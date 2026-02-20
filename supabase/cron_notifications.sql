-- CRON JOB FOR EMAIL NOTIFICATIONS
-- This script creates a scheduled job using the pg_cron extension to trigger the edge function hourly

-- 1. Enable pg_cron and pg_net extensions if not already enabled via dashboard
CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS pg_net;

-- 2. Grant usage on cron schema to postgres
GRANT USAGE ON SCHEMA cron TO postgres;

-- 3. Schedule the edge function to run every hour on the minute 0 (e.g. 08:00, 09:00)
-- IMPORTANT: Replace [PROJECT_REF] with your Supabase project ID (e.g. abcdefghijklm)
-- IMPORTANT: Replace [CRON_SECRET] with the secret configured in the Edge Function

SELECT cron.schedule(
  'send-measurement-reminders',      -- Name of the cron job
  '*/10 * * * *',                    -- cron expression: every 10 minutes
  $$
  SELECT net.http_post(
    url := 'https://[PROJECT_REF].supabase.co/functions/v1/send_email_notifications',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer [CRON_SECRET]'
    )
  );
  $$
);

/*
USEFUL COMMANDS FOR MANAGEMENT:

-- View all scheduled jobs
-- SELECT * FROM cron.job;

-- Remove the job
-- SELECT cron.unschedule('send-measurement-reminders');
*/
