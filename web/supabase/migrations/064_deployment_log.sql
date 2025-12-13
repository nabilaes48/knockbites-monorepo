-- ============================================================================
-- Migration 064: Deployment Log and Auto-Heal System
-- Purpose: Track deployments, enable rollback, and auto-heal stuck orders
-- ============================================================================

-- ============================================================================
-- Deployment Log Table
-- ============================================================================

CREATE TABLE IF NOT EXISTS deployment_log (
    id BIGSERIAL PRIMARY KEY,
    deployment_id TEXT NOT NULL UNIQUE, -- External ID (e.g., Vercel deployment ID)
    environment TEXT NOT NULL DEFAULT 'production', -- 'staging', 'production'
    version TEXT, -- App version from package.json
    commit_sha TEXT,
    commit_message TEXT,
    branch TEXT DEFAULT 'main',
    deployed_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    deployed_by TEXT, -- GitHub user or 'automated'
    status TEXT NOT NULL DEFAULT 'deploying', -- 'deploying', 'success', 'failed', 'rolled_back'
    rollback_target_id BIGINT REFERENCES deployment_log(id), -- If this is a rollback, points to target
    smoke_test_passed BOOLEAN,
    smoke_test_results JSONB,
    health_check_url TEXT,
    metadata JSONB DEFAULT '{}'::JSONB,

    CONSTRAINT valid_environment CHECK (environment IN ('staging', 'production', 'preview')),
    CONSTRAINT valid_status CHECK (status IN ('deploying', 'success', 'failed', 'rolled_back'))
);

-- ============================================================================
-- Indexes
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_deployment_log_deployed_at
    ON deployment_log(deployed_at DESC);

CREATE INDEX IF NOT EXISTS idx_deployment_log_environment
    ON deployment_log(environment, deployed_at DESC);

CREATE INDEX IF NOT EXISTS idx_deployment_log_status
    ON deployment_log(status, deployed_at DESC);

-- ============================================================================
-- Row Level Security
-- ============================================================================

ALTER TABLE deployment_log ENABLE ROW LEVEL SECURITY;

-- Allow service role to insert (from Edge Functions)
-- Super admin can view all
CREATE POLICY "Super admin view deployments"
    ON deployment_log
    FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM user_profiles
            WHERE user_id = auth.uid()
            AND role = 'super_admin'
        )
    );

-- Allow insert from anon (for Edge Functions with service key)
CREATE POLICY "Allow deployment logging"
    ON deployment_log
    FOR INSERT
    TO anon, authenticated
    WITH CHECK (true);

-- ============================================================================
-- Deployment Helper Functions
-- ============================================================================

-- Log a new deployment
CREATE OR REPLACE FUNCTION log_deployment(
    p_deployment_id TEXT,
    p_environment TEXT DEFAULT 'production',
    p_version TEXT DEFAULT NULL,
    p_commit_sha TEXT DEFAULT NULL,
    p_commit_message TEXT DEFAULT NULL,
    p_branch TEXT DEFAULT 'main',
    p_deployed_by TEXT DEFAULT 'automated'
)
RETURNS BIGINT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    new_id BIGINT;
BEGIN
    INSERT INTO deployment_log (
        deployment_id,
        environment,
        version,
        commit_sha,
        commit_message,
        branch,
        deployed_by,
        status
    ) VALUES (
        p_deployment_id,
        p_environment,
        p_version,
        p_commit_sha,
        p_commit_message,
        p_branch,
        p_deployed_by,
        'deploying'
    )
    RETURNING id INTO new_id;

    -- Log to metrics
    INSERT INTO runtime_metrics (session_id, event_type, event_data)
    VALUES (
        'system',
        'deployment',
        jsonb_build_object(
            'action', 'started',
            'deployment_id', p_deployment_id,
            'environment', p_environment,
            'version', p_version,
            'commit_sha', p_commit_sha
        )
    );

    RETURN new_id;
END;
$$;

-- Update deployment status
CREATE OR REPLACE FUNCTION update_deployment_status(
    p_deployment_id TEXT,
    p_status TEXT,
    p_smoke_test_passed BOOLEAN DEFAULT NULL,
    p_smoke_test_results JSONB DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    UPDATE deployment_log
    SET
        status = p_status,
        smoke_test_passed = COALESCE(p_smoke_test_passed, smoke_test_passed),
        smoke_test_results = COALESCE(p_smoke_test_results, smoke_test_results)
    WHERE deployment_id = p_deployment_id;

    -- Log to metrics
    INSERT INTO runtime_metrics (session_id, event_type, event_data)
    VALUES (
        'system',
        'deployment',
        jsonb_build_object(
            'action', 'status_update',
            'deployment_id', p_deployment_id,
            'status', p_status,
            'smoke_test_passed', p_smoke_test_passed
        )
    );

    RETURN FOUND;
END;
$$;

-- Get last successful deployment for rollback
CREATE OR REPLACE FUNCTION get_last_successful_deployment(
    p_environment TEXT DEFAULT 'production'
)
RETURNS TABLE (
    id BIGINT,
    deployment_id TEXT,
    version TEXT,
    commit_sha TEXT,
    deployed_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT
        dl.id,
        dl.deployment_id,
        dl.version,
        dl.commit_sha,
        dl.deployed_at
    FROM deployment_log dl
    WHERE dl.environment = p_environment
    AND dl.status = 'success'
    AND dl.smoke_test_passed = true
    ORDER BY dl.deployed_at DESC
    LIMIT 1;
END;
$$;

-- Log a rollback
CREATE OR REPLACE FUNCTION log_rollback(
    p_new_deployment_id TEXT,
    p_target_deployment_id TEXT,
    p_environment TEXT DEFAULT 'production',
    p_rolled_back_by TEXT DEFAULT 'automated'
)
RETURNS BIGINT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    target_record RECORD;
    new_id BIGINT;
BEGIN
    -- Get target deployment
    SELECT * INTO target_record
    FROM deployment_log
    WHERE deployment_id = p_target_deployment_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Target deployment not found: %', p_target_deployment_id;
    END IF;

    -- Create rollback entry
    INSERT INTO deployment_log (
        deployment_id,
        environment,
        version,
        commit_sha,
        commit_message,
        branch,
        deployed_by,
        status,
        rollback_target_id,
        metadata
    ) VALUES (
        p_new_deployment_id,
        p_environment,
        target_record.version,
        target_record.commit_sha,
        'ROLLBACK: ' || COALESCE(target_record.commit_message, 'No message'),
        target_record.branch,
        p_rolled_back_by,
        'success',
        target_record.id,
        jsonb_build_object(
            'is_rollback', true,
            'original_deployment', p_target_deployment_id
        )
    )
    RETURNING id INTO new_id;

    -- Log to metrics
    INSERT INTO runtime_metrics (session_id, event_type, event_data)
    VALUES (
        'system',
        'deployment',
        jsonb_build_object(
            'action', 'rollback',
            'new_deployment_id', p_new_deployment_id,
            'target_deployment_id', p_target_deployment_id,
            'environment', p_environment
        )
    );

    RETURN new_id;
END;
$$;

-- ============================================================================
-- Auto-Heal System for Orders
-- ============================================================================

-- Auto-heal stuck orders
CREATE OR REPLACE FUNCTION auto_heal_stuck_orders()
RETURNS TABLE (
    order_id BIGINT,
    previous_status TEXT,
    new_status TEXT,
    action_taken TEXT,
    duration_minutes INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    stuck_order RECORD;
    minutes_stuck INTEGER;
BEGIN
    -- Find orders stuck in 'preparing' for >45 minutes
    FOR stuck_order IN
        SELECT
            o.id,
            o.status,
            o.updated_at,
            EXTRACT(EPOCH FROM (NOW() - o.updated_at)) / 60 AS minutes_in_status
        FROM orders o
        WHERE o.status = 'preparing'
        AND o.updated_at < NOW() - INTERVAL '45 minutes'
    LOOP
        minutes_stuck := stuck_order.minutes_in_status::INTEGER;

        -- Mark as ready (assume prepared but not updated)
        UPDATE orders
        SET
            status = 'ready',
            updated_at = NOW()
        WHERE id = stuck_order.id;

        order_id := stuck_order.id;
        previous_status := stuck_order.status;
        new_status := 'ready';
        action_taken := 'Auto-promoted to ready (likely prepared but not updated)';
        duration_minutes := minutes_stuck;

        -- Log the auto-heal
        INSERT INTO runtime_metrics (session_id, event_type, event_data)
        VALUES (
            'system',
            'auto_heal',
            jsonb_build_object(
                'action', 'order_status_fix',
                'order_id', stuck_order.id,
                'previous_status', stuck_order.status,
                'new_status', 'ready',
                'minutes_stuck', minutes_stuck
            )
        );

        RETURN NEXT;
    END LOOP;

    -- Find orders stuck in 'ready' for >2 hours
    FOR stuck_order IN
        SELECT
            o.id,
            o.status,
            o.updated_at,
            EXTRACT(EPOCH FROM (NOW() - o.updated_at)) / 60 AS minutes_in_status
        FROM orders o
        WHERE o.status = 'ready'
        AND o.updated_at < NOW() - INTERVAL '2 hours'
    LOOP
        minutes_stuck := stuck_order.minutes_in_status::INTEGER;

        -- Mark as completed (assume picked up but not updated)
        UPDATE orders
        SET
            status = 'completed',
            updated_at = NOW()
        WHERE id = stuck_order.id;

        order_id := stuck_order.id;
        previous_status := stuck_order.status;
        new_status := 'completed';
        action_taken := 'Auto-completed (likely picked up but not updated)';
        duration_minutes := minutes_stuck;

        -- Log the auto-heal
        INSERT INTO runtime_metrics (session_id, event_type, event_data)
        VALUES (
            'system',
            'auto_heal',
            jsonb_build_object(
                'action', 'order_status_fix',
                'order_id', stuck_order.id,
                'previous_status', stuck_order.status,
                'new_status', 'completed',
                'minutes_stuck', minutes_stuck
            )
        );

        RETURN NEXT;
    END LOOP;
END;
$$;

-- ============================================================================
-- Order Health Materialized View
-- ============================================================================

CREATE MATERIALIZED VIEW IF NOT EXISTS mv_order_health AS
SELECT
    DATE_TRUNC('hour', o.created_at) AS hour_bucket,
    o.store_id,
    COUNT(*) AS total_orders,
    COUNT(*) FILTER (WHERE o.status = 'completed') AS completed_orders,
    COUNT(*) FILTER (WHERE o.status = 'cancelled') AS cancelled_orders,
    COUNT(*) FILTER (WHERE o.status IN ('pending', 'confirmed', 'preparing', 'ready')) AS active_orders,

    -- Stuck orders (preparing > 30 min, ready > 1 hour)
    COUNT(*) FILTER (
        WHERE o.status = 'preparing'
        AND o.updated_at < NOW() - INTERVAL '30 minutes'
    ) AS stuck_preparing,
    COUNT(*) FILTER (
        WHERE o.status = 'ready'
        AND o.updated_at < NOW() - INTERVAL '1 hour'
    ) AS stuck_ready,

    -- Average time in each status
    AVG(
        CASE WHEN o.status IN ('completed', 'cancelled')
        THEN EXTRACT(EPOCH FROM (o.updated_at - o.created_at)) / 60
        END
    ) AS avg_completion_minutes,

    -- Order value stats
    AVG(o.total) AS avg_order_value,
    SUM(o.total) AS total_revenue

FROM orders o
WHERE o.created_at > NOW() - INTERVAL '7 days'
GROUP BY DATE_TRUNC('hour', o.created_at), o.store_id;

CREATE UNIQUE INDEX IF NOT EXISTS idx_mv_order_health_pk
    ON mv_order_health(hour_bucket, store_id);

-- Function to refresh order health view
CREATE OR REPLACE FUNCTION refresh_order_health()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY mv_order_health;

    -- Log refresh
    INSERT INTO runtime_metrics (session_id, event_type, event_data)
    VALUES (
        'system',
        'auto_heal',
        jsonb_build_object('action', 'refresh_order_health')
    );
END;
$$;

-- ============================================================================
-- Get Order Health Summary (for dashboard)
-- ============================================================================

CREATE OR REPLACE FUNCTION get_order_health_summary(
    p_store_id BIGINT DEFAULT NULL,
    p_hours INTEGER DEFAULT 24
)
RETURNS TABLE (
    total_orders BIGINT,
    completed_orders BIGINT,
    cancelled_orders BIGINT,
    active_orders BIGINT,
    stuck_preparing BIGINT,
    stuck_ready BIGINT,
    completion_rate NUMERIC,
    avg_completion_minutes NUMERIC,
    avg_order_value NUMERIC
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Check permissions
    IF NOT EXISTS (
        SELECT 1 FROM user_profiles
        WHERE user_id = auth.uid()
        AND role IN ('super_admin', 'admin', 'manager')
    ) THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

    RETURN QUERY
    SELECT
        SUM(moh.total_orders)::BIGINT AS total_orders,
        SUM(moh.completed_orders)::BIGINT AS completed_orders,
        SUM(moh.cancelled_orders)::BIGINT AS cancelled_orders,
        SUM(moh.active_orders)::BIGINT AS active_orders,
        SUM(moh.stuck_preparing)::BIGINT AS stuck_preparing,
        SUM(moh.stuck_ready)::BIGINT AS stuck_ready,
        ROUND(
            SUM(moh.completed_orders)::NUMERIC /
            NULLIF(SUM(moh.total_orders), 0) * 100,
            2
        ) AS completion_rate,
        ROUND(AVG(moh.avg_completion_minutes), 2) AS avg_completion_minutes,
        ROUND(AVG(moh.avg_order_value), 2) AS avg_order_value
    FROM mv_order_health moh
    WHERE moh.hour_bucket > NOW() - (p_hours || ' hours')::INTERVAL
    AND (p_store_id IS NULL OR moh.store_id = p_store_id);
END;
$$;

-- ============================================================================
-- Scheduled Job Functions (to be called by cron)
-- ============================================================================

-- Run auto-heal and alert evaluation (every 15 minutes)
CREATE OR REPLACE FUNCTION run_system_maintenance()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    healed_count INTEGER := 0;
    alerts_triggered INTEGER := 0;
    result JSONB;
BEGIN
    -- Auto-heal stuck orders
    SELECT COUNT(*) INTO healed_count
    FROM auto_heal_stuck_orders();

    -- Refresh order health view
    PERFORM refresh_order_health();

    -- Evaluate alert rules (alerts will be triggered by separate function)
    SELECT COUNT(*) INTO alerts_triggered
    FROM evaluate_alert_rules()
    WHERE should_trigger = true;

    result := jsonb_build_object(
        'timestamp', NOW(),
        'orders_healed', healed_count,
        'alerts_to_trigger', alerts_triggered
    );

    -- Log maintenance run
    INSERT INTO runtime_metrics (session_id, event_type, event_data)
    VALUES (
        'system',
        'auto_heal',
        jsonb_build_object(
            'action', 'system_maintenance',
            'result', result
        )
    );

    RETURN result;
END;
$$;

-- ============================================================================
-- Comments
-- ============================================================================

COMMENT ON TABLE deployment_log IS 'Tracks all deployments for rollback and audit';
COMMENT ON FUNCTION auto_heal_stuck_orders IS 'Automatically resolves orders stuck in intermediate states';
COMMENT ON MATERIALIZED VIEW mv_order_health IS 'Pre-computed order health metrics by hour and store';
COMMENT ON FUNCTION run_system_maintenance IS 'Periodic maintenance: auto-heal, refresh views, check alerts';
