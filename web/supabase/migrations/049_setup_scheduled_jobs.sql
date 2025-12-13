-- =====================================================
-- Migration 049: Setup Scheduled Jobs
-- Version: 1.0
-- Date: 2025-12-02
-- Purpose: Configure pg_cron for automated cleanup and metrics
-- =====================================================

-- NOTE: pg_cron must be enabled in your Supabase project settings
-- Dashboard → Database → Extensions → pg_cron → Enable

-- =====================================================
-- STEP 1: Create job tracking table
-- =====================================================

CREATE TABLE IF NOT EXISTS scheduled_job_logs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    job_name TEXT NOT NULL,
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    status TEXT DEFAULT 'running',
    details JSONB,
    error_message TEXT
);

CREATE INDEX IF NOT EXISTS idx_job_logs_name ON scheduled_job_logs(job_name);
CREATE INDEX IF NOT EXISTS idx_job_logs_started ON scheduled_job_logs(started_at DESC);

-- =====================================================
-- STEP 2: Wrapper functions with logging
-- =====================================================

-- Cleanup job with logging
CREATE OR REPLACE FUNCTION public.run_cleanup_job()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_log_id UUID;
    v_result RECORD;
BEGIN
    -- Create log entry
    INSERT INTO scheduled_job_logs (job_name, status)
    VALUES ('cleanup_expired_verifications', 'running')
    RETURNING id INTO v_log_id;

    -- Run cleanup
    SELECT * INTO v_result FROM public.cleanup_expired_verifications();

    -- Update log with results
    UPDATE scheduled_job_logs
    SET
        completed_at = NOW(),
        status = 'completed',
        details = jsonb_build_object(
            'deleted_verifications', v_result.deleted_verifications,
            'deleted_rate_limits', v_result.deleted_rate_limits
        )
    WHERE id = v_log_id;

EXCEPTION WHEN OTHERS THEN
    UPDATE scheduled_job_logs
    SET
        completed_at = NOW(),
        status = 'failed',
        error_message = SQLERRM
    WHERE id = v_log_id;
END;
$$;

-- Daily metrics aggregation with logging
CREATE OR REPLACE FUNCTION public.run_daily_metrics_job()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_log_id UUID;
    v_date DATE := CURRENT_DATE;
BEGIN
    -- Create log entry
    INSERT INTO scheduled_job_logs (job_name, status, details)
    VALUES ('aggregate_daily_metrics', 'running', jsonb_build_object('target_date', v_date))
    RETURNING id INTO v_log_id;

    -- Run aggregation for yesterday (complete day data)
    PERFORM public.aggregate_daily_metrics(v_date - 1);

    -- Update log
    UPDATE scheduled_job_logs
    SET
        completed_at = NOW(),
        status = 'completed'
    WHERE id = v_log_id;

EXCEPTION WHEN OTHERS THEN
    UPDATE scheduled_job_logs
    SET
        completed_at = NOW(),
        status = 'failed',
        error_message = SQLERRM
    WHERE id = v_log_id;
END;
$$;

-- =====================================================
-- STEP 3: Setup pg_cron jobs (if extension is enabled)
-- =====================================================

-- Check if pg_cron is available
DO $$
BEGIN
    -- Try to use pg_cron
    IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
        -- Schedule cleanup every 15 minutes
        PERFORM cron.schedule(
            'cleanup-verifications',
            '*/15 * * * *',
            $$SELECT public.run_cleanup_job()$$
        );

        -- Schedule daily metrics at midnight (in project timezone)
        PERFORM cron.schedule(
            'daily-metrics-aggregation',
            '0 0 * * *',
            $$SELECT public.run_daily_metrics_job()$$
        );

        RAISE NOTICE 'pg_cron jobs scheduled successfully';
    ELSE
        RAISE NOTICE 'pg_cron extension not enabled - jobs not scheduled';
        RAISE NOTICE 'Enable pg_cron in Supabase Dashboard → Database → Extensions';
    END IF;
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Could not schedule pg_cron jobs: %', SQLERRM;
    RAISE NOTICE 'You may need to enable pg_cron extension first';
END;
$$;

-- =====================================================
-- STEP 4: Create manual trigger functions (alternative)
-- =====================================================

-- These can be called manually or via external scheduler

-- API-callable cleanup (for external cron services)
CREATE OR REPLACE FUNCTION public.api_trigger_cleanup()
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_result RECORD;
BEGIN
    SELECT * INTO v_result FROM public.cleanup_expired_verifications();

    RETURN json_build_object(
        'success', true,
        'deleted_verifications', v_result.deleted_verifications,
        'deleted_rate_limits', v_result.deleted_rate_limits,
        'timestamp', NOW()
    );
END;
$$;

-- API-callable daily metrics (for external cron services)
CREATE OR REPLACE FUNCTION public.api_trigger_daily_metrics(target_date DATE DEFAULT NULL)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    PERFORM public.aggregate_daily_metrics(COALESCE(target_date, CURRENT_DATE - 1));

    RETURN json_build_object(
        'success', true,
        'target_date', COALESCE(target_date, CURRENT_DATE - 1),
        'timestamp', NOW()
    );
END;
$$;

-- Grant execute to service role only (for secure API calls)
-- These should be called via Supabase service role, not anon
REVOKE ALL ON FUNCTION public.api_trigger_cleanup() FROM anon, authenticated;
REVOKE ALL ON FUNCTION public.api_trigger_daily_metrics(DATE) FROM anon, authenticated;

-- Only service role can execute these
GRANT EXECUTE ON FUNCTION public.api_trigger_cleanup() TO service_role;
GRANT EXECUTE ON FUNCTION public.api_trigger_daily_metrics(DATE) TO service_role;

-- =====================================================
-- STEP 5: Create view for monitoring job status
-- =====================================================

CREATE OR REPLACE VIEW scheduled_jobs_status AS
SELECT
    job_name,
    COUNT(*) FILTER (WHERE started_at > NOW() - INTERVAL '24 hours') as runs_last_24h,
    COUNT(*) FILTER (WHERE status = 'completed' AND started_at > NOW() - INTERVAL '24 hours') as successful_runs_24h,
    COUNT(*) FILTER (WHERE status = 'failed' AND started_at > NOW() - INTERVAL '24 hours') as failed_runs_24h,
    MAX(started_at) as last_run,
    (
        SELECT status FROM scheduled_job_logs s2
        WHERE s2.job_name = scheduled_job_logs.job_name
        ORDER BY started_at DESC LIMIT 1
    ) as last_status
FROM scheduled_job_logs
GROUP BY job_name;

GRANT SELECT ON scheduled_jobs_status TO authenticated;

-- =====================================================
-- STEP 6: Verification
-- =====================================================

SELECT 'Scheduled jobs setup complete!' as status;

-- Show pg_cron status if available
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
        RAISE NOTICE 'pg_cron is enabled - scheduled jobs active';
    ELSE
        RAISE NOTICE 'pg_cron not enabled - use external scheduler or Supabase Edge Functions';
    END IF;
END;
$$;

-- =====================================================
-- ALTERNATIVE: Using Supabase Edge Functions for Scheduling
-- =====================================================
-- If pg_cron is not available, create an Edge Function:
--
-- supabase/functions/scheduled-cleanup/index.ts
-- - Run cleanup every 15 minutes via Supabase Cron
-- - Configure in supabase/config.toml:
--   [functions.scheduled-cleanup]
--   schedule = "*/15 * * * *"
--
-- =====================================================

-- =====================================================
-- SUCCESS! Scheduling infrastructure created.
--
-- Options:
-- 1. pg_cron (recommended): Enable in Supabase Dashboard
-- 2. External cron: Call api_trigger_* functions via service role
-- 3. Supabase Edge Functions: Create scheduled functions
--
-- Jobs to run:
-- - cleanup_expired_verifications: Every 15 minutes
-- - aggregate_daily_metrics: Daily at midnight
-- =====================================================
