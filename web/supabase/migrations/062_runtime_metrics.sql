-- ============================================================================
-- Migration 062: Runtime Metrics Table
-- Purpose: Store runtime metrics for monitoring, alerting, and system health
-- ============================================================================

-- Create runtime_metrics table
CREATE TABLE IF NOT EXISTS runtime_metrics (
    id BIGSERIAL PRIMARY KEY,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    session_id TEXT NOT NULL,
    event_type TEXT NOT NULL,
    event_data JSONB DEFAULT '{}'::JSONB,

    -- Indexes for common queries
    CONSTRAINT valid_event_type CHECK (event_type IN (
        'page_view',
        'api_latency',
        'error',
        'user_action',
        'order_event',
        'performance',
        'edge_function',
        'alert_triggered',
        'auto_heal',
        'deployment',
        'custom'
    ))
);

-- Create indexes for efficient querying
CREATE INDEX IF NOT EXISTS idx_runtime_metrics_created_at
    ON runtime_metrics(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_runtime_metrics_event_type
    ON runtime_metrics(event_type, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_runtime_metrics_session
    ON runtime_metrics(session_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_runtime_metrics_user
    ON runtime_metrics(user_id, created_at DESC)
    WHERE user_id IS NOT NULL;

-- GIN index for JSONB queries
CREATE INDEX IF NOT EXISTS idx_runtime_metrics_event_data
    ON runtime_metrics USING GIN (event_data);

-- Composite index for error analysis
CREATE INDEX IF NOT EXISTS idx_runtime_metrics_errors
    ON runtime_metrics(created_at DESC)
    WHERE event_type = 'error';

-- Composite index for latency analysis
CREATE INDEX IF NOT EXISTS idx_runtime_metrics_latency
    ON runtime_metrics(created_at DESC)
    WHERE event_type = 'api_latency';

-- ============================================================================
-- Row Level Security
-- ============================================================================

ALTER TABLE runtime_metrics ENABLE ROW LEVEL SECURITY;

-- Allow anonymous and authenticated users to INSERT metrics
CREATE POLICY "Allow metric insertion"
    ON runtime_metrics
    FOR INSERT
    TO anon, authenticated
    WITH CHECK (true);

-- Deny SELECT for regular users (only service_role can read)
-- Super admins can read via secure RPC functions
CREATE POLICY "Deny public read"
    ON runtime_metrics
    FOR SELECT
    TO anon, authenticated
    USING (false);

-- ============================================================================
-- Secure RPC Functions for Reading Metrics (Super Admin Only)
-- ============================================================================

-- Get recent errors
CREATE OR REPLACE FUNCTION get_recent_errors(
    p_limit INTEGER DEFAULT 50,
    p_hours INTEGER DEFAULT 24
)
RETURNS TABLE (
    id BIGINT,
    created_at TIMESTAMPTZ,
    session_id TEXT,
    error_type TEXT,
    message TEXT,
    url TEXT,
    event_data JSONB
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Check if user is super_admin
    IF NOT EXISTS (
        SELECT 1 FROM user_profiles
        WHERE user_id = auth.uid()
        AND role = 'super_admin'
    ) THEN
        RAISE EXCEPTION 'Access denied: super_admin role required';
    END IF;

    RETURN QUERY
    SELECT
        rm.id,
        rm.created_at,
        rm.session_id,
        rm.event_data->>'error_type' AS error_type,
        rm.event_data->>'message' AS message,
        rm.event_data->>'url' AS url,
        rm.event_data
    FROM runtime_metrics rm
    WHERE rm.event_type = 'error'
    AND rm.created_at > NOW() - (p_hours || ' hours')::INTERVAL
    ORDER BY rm.created_at DESC
    LIMIT p_limit;
END;
$$;

-- Get API latency statistics
CREATE OR REPLACE FUNCTION get_api_latency_stats(
    p_hours INTEGER DEFAULT 24
)
RETURNS TABLE (
    endpoint TEXT,
    avg_latency_ms NUMERIC,
    p50_latency_ms NUMERIC,
    p95_latency_ms NUMERIC,
    p99_latency_ms NUMERIC,
    request_count BIGINT,
    error_count BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Check if user is super_admin
    IF NOT EXISTS (
        SELECT 1 FROM user_profiles
        WHERE user_id = auth.uid()
        AND role = 'super_admin'
    ) THEN
        RAISE EXCEPTION 'Access denied: super_admin role required';
    END IF;

    RETURN QUERY
    SELECT
        rm.event_data->>'endpoint' AS endpoint,
        ROUND(AVG((rm.event_data->>'latency_ms')::NUMERIC), 2) AS avg_latency_ms,
        ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY (rm.event_data->>'latency_ms')::NUMERIC), 2) AS p50_latency_ms,
        ROUND(PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY (rm.event_data->>'latency_ms')::NUMERIC), 2) AS p95_latency_ms,
        ROUND(PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY (rm.event_data->>'latency_ms')::NUMERIC), 2) AS p99_latency_ms,
        COUNT(*) AS request_count,
        COUNT(*) FILTER (WHERE (rm.event_data->>'status')::INTEGER >= 400) AS error_count
    FROM runtime_metrics rm
    WHERE rm.event_type = 'api_latency'
    AND rm.created_at > NOW() - (p_hours || ' hours')::INTERVAL
    GROUP BY rm.event_data->>'endpoint'
    ORDER BY request_count DESC;
END;
$$;

-- Get metrics summary for dashboard
CREATE OR REPLACE FUNCTION get_metrics_summary(
    p_hours INTEGER DEFAULT 24
)
RETURNS TABLE (
    event_type TEXT,
    event_count BIGINT,
    unique_sessions BIGINT,
    unique_users BIGINT,
    first_event TIMESTAMPTZ,
    last_event TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Check if user is super_admin
    IF NOT EXISTS (
        SELECT 1 FROM user_profiles
        WHERE user_id = auth.uid()
        AND role = 'super_admin'
    ) THEN
        RAISE EXCEPTION 'Access denied: super_admin role required';
    END IF;

    RETURN QUERY
    SELECT
        rm.event_type,
        COUNT(*) AS event_count,
        COUNT(DISTINCT rm.session_id) AS unique_sessions,
        COUNT(DISTINCT rm.user_id) AS unique_users,
        MIN(rm.created_at) AS first_event,
        MAX(rm.created_at) AS last_event
    FROM runtime_metrics rm
    WHERE rm.created_at > NOW() - (p_hours || ' hours')::INTERVAL
    GROUP BY rm.event_type
    ORDER BY event_count DESC;
END;
$$;

-- Get error rate over time
CREATE OR REPLACE FUNCTION get_error_rate_timeseries(
    p_hours INTEGER DEFAULT 24,
    p_bucket_minutes INTEGER DEFAULT 15
)
RETURNS TABLE (
    bucket TIMESTAMPTZ,
    error_count BIGINT,
    total_events BIGINT,
    error_rate NUMERIC
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Check if user is super_admin
    IF NOT EXISTS (
        SELECT 1 FROM user_profiles
        WHERE user_id = auth.uid()
        AND role = 'super_admin'
    ) THEN
        RAISE EXCEPTION 'Access denied: super_admin role required';
    END IF;

    RETURN QUERY
    SELECT
        DATE_TRUNC('minute', rm.created_at) -
            (EXTRACT(MINUTE FROM rm.created_at)::INTEGER % p_bucket_minutes) * INTERVAL '1 minute' AS bucket,
        COUNT(*) FILTER (WHERE rm.event_type = 'error') AS error_count,
        COUNT(*) AS total_events,
        ROUND(
            COUNT(*) FILTER (WHERE rm.event_type = 'error')::NUMERIC /
            NULLIF(COUNT(*), 0) * 100,
            2
        ) AS error_rate
    FROM runtime_metrics rm
    WHERE rm.created_at > NOW() - (p_hours || ' hours')::INTERVAL
    GROUP BY bucket
    ORDER BY bucket DESC;
END;
$$;

-- ============================================================================
-- Cleanup Function (for scheduled job)
-- ============================================================================

-- Delete metrics older than retention period (default 30 days)
CREATE OR REPLACE FUNCTION cleanup_old_metrics(
    p_retention_days INTEGER DEFAULT 30
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM runtime_metrics
    WHERE created_at < NOW() - (p_retention_days || ' days')::INTERVAL;

    GET DIAGNOSTICS deleted_count = ROW_COUNT;

    -- Log cleanup event
    INSERT INTO runtime_metrics (session_id, event_type, event_data)
    VALUES (
        'system',
        'auto_heal',
        jsonb_build_object(
            'action', 'cleanup_metrics',
            'deleted_count', deleted_count,
            'retention_days', p_retention_days
        )
    );

    RETURN deleted_count;
END;
$$;

-- ============================================================================
-- Comments
-- ============================================================================

COMMENT ON TABLE runtime_metrics IS 'Stores runtime metrics for monitoring and alerting';
COMMENT ON COLUMN runtime_metrics.event_type IS 'Type of metric event: page_view, api_latency, error, user_action, etc.';
COMMENT ON COLUMN runtime_metrics.event_data IS 'JSONB payload with event-specific data';
COMMENT ON COLUMN runtime_metrics.session_id IS 'Client session identifier for tracking user journeys';

COMMENT ON FUNCTION get_recent_errors IS 'Get recent error events (super_admin only)';
COMMENT ON FUNCTION get_api_latency_stats IS 'Get API latency statistics by endpoint (super_admin only)';
COMMENT ON FUNCTION get_metrics_summary IS 'Get summary of all metrics by type (super_admin only)';
COMMENT ON FUNCTION cleanup_old_metrics IS 'Delete metrics older than retention period';
