-- ============================================================================
-- Migration 063: Alert Rules and Alert History
-- Purpose: Define alert conditions and track triggered alerts
-- ============================================================================

-- ============================================================================
-- Alert Rules Table
-- ============================================================================

CREATE TABLE IF NOT EXISTS alert_rules (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    metric_type TEXT NOT NULL,
    condition TEXT NOT NULL, -- 'gt', 'lt', 'gte', 'lte', 'eq'
    threshold NUMERIC NOT NULL,
    window_minutes INTEGER NOT NULL DEFAULT 15,
    cooldown_minutes INTEGER NOT NULL DEFAULT 60, -- Prevent alert spam
    severity TEXT NOT NULL DEFAULT 'warning', -- 'info', 'warning', 'critical'
    enabled BOOLEAN NOT NULL DEFAULT true,
    channels JSONB DEFAULT '["email"]'::JSONB, -- Array of: email, slack, sms
    metadata JSONB DEFAULT '{}'::JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,

    CONSTRAINT valid_condition CHECK (condition IN ('gt', 'lt', 'gte', 'lte', 'eq')),
    CONSTRAINT valid_severity CHECK (severity IN ('info', 'warning', 'critical')),
    CONSTRAINT positive_threshold CHECK (threshold >= 0),
    CONSTRAINT positive_window CHECK (window_minutes > 0),
    CONSTRAINT positive_cooldown CHECK (cooldown_minutes > 0)
);

-- ============================================================================
-- Alert History Table
-- ============================================================================

CREATE TABLE IF NOT EXISTS alert_history (
    id BIGSERIAL PRIMARY KEY,
    alert_rule_id INTEGER REFERENCES alert_rules(id) ON DELETE SET NULL,
    triggered_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    resolved_at TIMESTAMPTZ,
    status TEXT NOT NULL DEFAULT 'triggered', -- 'triggered', 'acknowledged', 'resolved'
    severity TEXT NOT NULL,
    metric_value NUMERIC,
    threshold_value NUMERIC,
    message TEXT NOT NULL,
    channels_notified JSONB DEFAULT '[]'::JSONB,
    acknowledged_by UUID REFERENCES auth.users(id),
    resolved_by UUID REFERENCES auth.users(id),
    notes TEXT,
    metadata JSONB DEFAULT '{}'::JSONB,

    CONSTRAINT valid_status CHECK (status IN ('triggered', 'acknowledged', 'resolved'))
);

-- ============================================================================
-- Indexes
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_alert_rules_enabled
    ON alert_rules(enabled, metric_type);

CREATE INDEX IF NOT EXISTS idx_alert_history_triggered
    ON alert_history(triggered_at DESC);

CREATE INDEX IF NOT EXISTS idx_alert_history_status
    ON alert_history(status, triggered_at DESC);

CREATE INDEX IF NOT EXISTS idx_alert_history_rule
    ON alert_history(alert_rule_id, triggered_at DESC);

-- ============================================================================
-- Row Level Security
-- ============================================================================

ALTER TABLE alert_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE alert_history ENABLE ROW LEVEL SECURITY;

-- Only super_admin can manage alert rules
CREATE POLICY "Super admin manage alert rules"
    ON alert_rules
    FOR ALL
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM user_profiles
            WHERE user_id = auth.uid()
            AND role = 'super_admin'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM user_profiles
            WHERE user_id = auth.uid()
            AND role = 'super_admin'
        )
    );

-- Only super_admin can view/manage alert history
CREATE POLICY "Super admin manage alert history"
    ON alert_history
    FOR ALL
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM user_profiles
            WHERE user_id = auth.uid()
            AND role = 'super_admin'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM user_profiles
            WHERE user_id = auth.uid()
            AND role = 'super_admin'
        )
    );

-- ============================================================================
-- Default Alert Rules
-- ============================================================================

INSERT INTO alert_rules (name, description, metric_type, condition, threshold, window_minutes, cooldown_minutes, severity, channels) VALUES
    ('High Error Rate', 'Alert when error rate exceeds 5% in 15 minutes', 'error_rate', 'gt', 5, 15, 60, 'critical', '["email", "slack"]'),
    ('High API Latency', 'Alert when P95 latency exceeds 2000ms', 'api_latency_p95', 'gt', 2000, 15, 30, 'warning', '["email"]'),
    ('Stuck Orders', 'Alert when orders are stuck for >45 minutes', 'stuck_orders', 'gt', 0, 45, 60, 'warning', '["email", "slack"]'),
    ('Payment Failures', 'Alert on any payment webhook failure', 'payment_failure', 'gt', 0, 5, 15, 'critical', '["email", "slack", "sms"]'),
    ('Low Disk Space', 'Alert when storage usage exceeds 80%', 'storage_usage', 'gt', 80, 60, 120, 'warning', '["email"]'),
    ('Database Connection Pool', 'Alert when connection pool is near exhaustion', 'db_connections', 'gt', 90, 5, 15, 'critical', '["email", "slack"]')
ON CONFLICT DO NOTHING;

-- ============================================================================
-- Alert Evaluation Functions
-- ============================================================================

-- Evaluate alert rules against current metrics
CREATE OR REPLACE FUNCTION evaluate_alert_rules()
RETURNS TABLE (
    rule_id INTEGER,
    rule_name TEXT,
    should_trigger BOOLEAN,
    current_value NUMERIC,
    threshold_value NUMERIC
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    rule RECORD;
    metric_value NUMERIC;
    last_alert TIMESTAMPTZ;
BEGIN
    FOR rule IN
        SELECT * FROM alert_rules WHERE enabled = true
    LOOP
        -- Calculate metric value based on type
        CASE rule.metric_type
            WHEN 'error_rate' THEN
                SELECT
                    COALESCE(
                        COUNT(*) FILTER (WHERE event_type = 'error')::NUMERIC /
                        NULLIF(COUNT(*), 0) * 100,
                        0
                    ) INTO metric_value
                FROM runtime_metrics
                WHERE created_at > NOW() - (rule.window_minutes || ' minutes')::INTERVAL;

            WHEN 'api_latency_p95' THEN
                SELECT
                    COALESCE(
                        PERCENTILE_CONT(0.95) WITHIN GROUP (
                            ORDER BY (event_data->>'latency_ms')::NUMERIC
                        ),
                        0
                    ) INTO metric_value
                FROM runtime_metrics
                WHERE event_type = 'api_latency'
                AND created_at > NOW() - (rule.window_minutes || ' minutes')::INTERVAL;

            WHEN 'stuck_orders' THEN
                SELECT COUNT(*) INTO metric_value
                FROM orders
                WHERE status IN ('preparing', 'ready')
                AND updated_at < NOW() - (rule.window_minutes || ' minutes')::INTERVAL;

            WHEN 'payment_failure' THEN
                SELECT COUNT(*) INTO metric_value
                FROM runtime_metrics
                WHERE event_type = 'error'
                AND event_data->>'error_type' = 'payment_failure'
                AND created_at > NOW() - (rule.window_minutes || ' minutes')::INTERVAL;

            ELSE
                metric_value := 0;
        END CASE;

        -- Check cooldown
        SELECT MAX(triggered_at) INTO last_alert
        FROM alert_history
        WHERE alert_rule_id = rule.id
        AND triggered_at > NOW() - (rule.cooldown_minutes || ' minutes')::INTERVAL;

        -- Evaluate condition
        rule_id := rule.id;
        rule_name := rule.name;
        current_value := metric_value;
        threshold_value := rule.threshold;

        should_trigger := CASE rule.condition
            WHEN 'gt' THEN metric_value > rule.threshold
            WHEN 'lt' THEN metric_value < rule.threshold
            WHEN 'gte' THEN metric_value >= rule.threshold
            WHEN 'lte' THEN metric_value <= rule.threshold
            WHEN 'eq' THEN metric_value = rule.threshold
            ELSE false
        END;

        -- Don't trigger if within cooldown
        IF should_trigger AND last_alert IS NOT NULL THEN
            should_trigger := false;
        END IF;

        RETURN NEXT;
    END LOOP;
END;
$$;

-- Trigger an alert and record it
CREATE OR REPLACE FUNCTION trigger_alert(
    p_rule_id INTEGER,
    p_metric_value NUMERIC,
    p_message TEXT DEFAULT NULL
)
RETURNS BIGINT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    rule RECORD;
    alert_id BIGINT;
    alert_message TEXT;
BEGIN
    -- Get rule details
    SELECT * INTO rule FROM alert_rules WHERE id = p_rule_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Alert rule not found: %', p_rule_id;
    END IF;

    -- Build message
    alert_message := COALESCE(p_message,
        format('%s: %s %s %s (current: %s)',
            rule.name,
            rule.metric_type,
            rule.condition,
            rule.threshold,
            p_metric_value
        )
    );

    -- Insert alert history
    INSERT INTO alert_history (
        alert_rule_id,
        severity,
        metric_value,
        threshold_value,
        message,
        channels_notified,
        metadata
    ) VALUES (
        p_rule_id,
        rule.severity,
        p_metric_value,
        rule.threshold,
        alert_message,
        rule.channels,
        jsonb_build_object(
            'rule_name', rule.name,
            'metric_type', rule.metric_type,
            'window_minutes', rule.window_minutes
        )
    )
    RETURNING id INTO alert_id;

    -- Log to metrics
    INSERT INTO runtime_metrics (session_id, event_type, event_data)
    VALUES (
        'system',
        'alert_triggered',
        jsonb_build_object(
            'alert_id', alert_id,
            'rule_id', p_rule_id,
            'rule_name', rule.name,
            'severity', rule.severity,
            'metric_value', p_metric_value,
            'threshold', rule.threshold
        )
    );

    RETURN alert_id;
END;
$$;

-- Acknowledge an alert
CREATE OR REPLACE FUNCTION acknowledge_alert(
    p_alert_id BIGINT,
    p_notes TEXT DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Check permissions
    IF NOT EXISTS (
        SELECT 1 FROM user_profiles
        WHERE user_id = auth.uid()
        AND role IN ('super_admin', 'admin')
    ) THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

    UPDATE alert_history
    SET
        status = 'acknowledged',
        acknowledged_by = auth.uid(),
        notes = COALESCE(p_notes, notes)
    WHERE id = p_alert_id
    AND status = 'triggered';

    RETURN FOUND;
END;
$$;

-- Resolve an alert
CREATE OR REPLACE FUNCTION resolve_alert(
    p_alert_id BIGINT,
    p_notes TEXT DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Check permissions
    IF NOT EXISTS (
        SELECT 1 FROM user_profiles
        WHERE user_id = auth.uid()
        AND role IN ('super_admin', 'admin')
    ) THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

    UPDATE alert_history
    SET
        status = 'resolved',
        resolved_at = NOW(),
        resolved_by = auth.uid(),
        notes = COALESCE(p_notes, notes)
    WHERE id = p_alert_id
    AND status IN ('triggered', 'acknowledged');

    RETURN FOUND;
END;
$$;

-- ============================================================================
-- Updated At Trigger
-- ============================================================================

CREATE OR REPLACE FUNCTION update_alert_rules_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_alert_rules_updated_at ON alert_rules;
CREATE TRIGGER trigger_alert_rules_updated_at
    BEFORE UPDATE ON alert_rules
    FOR EACH ROW
    EXECUTE FUNCTION update_alert_rules_updated_at();

-- ============================================================================
-- Comments
-- ============================================================================

COMMENT ON TABLE alert_rules IS 'Defines conditions for triggering alerts';
COMMENT ON TABLE alert_history IS 'History of triggered alerts and their resolution';
COMMENT ON FUNCTION evaluate_alert_rules IS 'Evaluate all enabled alert rules against current metrics';
COMMENT ON FUNCTION trigger_alert IS 'Create an alert record and prepare for notification';
COMMENT ON FUNCTION acknowledge_alert IS 'Mark an alert as acknowledged by staff';
COMMENT ON FUNCTION resolve_alert IS 'Mark an alert as resolved';
