-- ============================================================================
-- Migration 065: Multi-App Versioning & Compatibility Framework
-- Purpose: Enable backward compatibility across iOS apps and Web Dashboard
-- ============================================================================

-- ============================================================================
-- SCHEMA MIGRATIONS CONTRACT
-- Tracks breaking changes and minimum version requirements
-- ============================================================================

CREATE TABLE IF NOT EXISTS schema_migrations_contract (
    id SERIAL PRIMARY KEY,
    change_description TEXT NOT NULL,
    added_on TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    min_app_version TEXT NOT NULL, -- e.g., '1.2.0'
    breaking_change BOOLEAN DEFAULT false,
    affected_apps TEXT[] DEFAULT ARRAY['web', 'customer', 'business'],
    migration_file TEXT, -- Reference to the migration that introduced this
    notes TEXT
);

CREATE INDEX IF NOT EXISTS idx_schema_migrations_breaking
    ON schema_migrations_contract(breaking_change, min_app_version);

-- Insert current schema contract baseline
INSERT INTO schema_migrations_contract (change_description, min_app_version, breaking_change, notes)
VALUES
    ('Initial schema baseline', '1.0.0', false, 'All apps at 1.0.0 are compatible'),
    ('Portion-based customizations', '1.1.0', false, 'Added portion_pricing to customizations'),
    ('Runtime metrics system', '1.2.0', false, 'New runtime_metrics table for monitoring'),
    ('Versioning framework', '1.3.0', false, 'This migration - adds version negotiation')
ON CONFLICT DO NOTHING;

-- ============================================================================
-- FEATURE FLAGS TABLE
-- Controls feature availability per app and version
-- ============================================================================

CREATE TABLE IF NOT EXISTS app_feature_flags (
    id SERIAL PRIMARY KEY,
    app_name TEXT NOT NULL, -- 'web', 'customer', 'business', or '*' for all
    min_version TEXT NOT NULL DEFAULT '1.0.0',
    max_version TEXT, -- NULL means no upper limit
    feature TEXT NOT NULL,
    enabled BOOLEAN DEFAULT true,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,

    CONSTRAINT valid_app_name CHECK (app_name IN ('web', 'customer', 'business', '*')),
    CONSTRAINT unique_feature_per_app UNIQUE (app_name, feature, min_version)
);

CREATE INDEX IF NOT EXISTS idx_feature_flags_lookup
    ON app_feature_flags(app_name, feature, enabled);

-- Insert default feature flags
INSERT INTO app_feature_flags (app_name, min_version, feature, enabled, description)
VALUES
    -- Core features (all apps)
    ('*', '1.0.0', 'guest_checkout', true, 'Allow guest checkout without account'),
    ('*', '1.0.0', 'order_tracking', true, 'Real-time order status tracking'),
    ('*', '1.0.0', 'menu_browsing', true, 'Browse menu items'),

    -- Customer features
    ('customer', '1.0.0', 'rewards_program', true, 'Customer rewards points and tiers'),
    ('customer', '1.1.0', 'portion_customization', true, 'None/Light/Regular/Extra portions'),
    ('customer', '1.2.0', 'order_history', true, 'View past orders'),

    -- Business features
    ('business', '1.0.0', 'order_management', true, 'Accept/reject/update orders'),
    ('business', '1.1.0', 'menu_editing', true, 'Edit menu items and prices'),
    ('business', '1.2.0', 'analytics_basic', true, 'Basic analytics dashboard'),
    ('business', '1.3.0', 'analytics_advanced', true, 'Advanced analytics with trends'),

    -- Web-only features
    ('web', '1.0.0', 'multi_store_view', true, 'View all stores (super admin)'),
    ('web', '1.2.0', 'staff_management', true, 'Manage staff accounts'),
    ('web', '1.3.0', 'system_health', true, 'System health dashboard')
ON CONFLICT DO NOTHING;

-- ============================================================================
-- API VERSION REGISTRY
-- Tracks which API versions are supported
-- ============================================================================

CREATE TABLE IF NOT EXISTS api_versions (
    version TEXT PRIMARY KEY, -- 'v1', 'v2', etc.
    status TEXT NOT NULL DEFAULT 'active', -- 'active', 'deprecated', 'sunset'
    min_app_version TEXT NOT NULL,
    sunset_date DATE, -- When this version will be removed
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    notes TEXT,

    CONSTRAINT valid_status CHECK (status IN ('active', 'deprecated', 'sunset'))
);

INSERT INTO api_versions (version, status, min_app_version, notes)
VALUES
    ('v1', 'active', '1.0.0', 'Initial API version'),
    ('v2', 'active', '1.2.0', 'Enhanced API with metrics and versioning')
ON CONFLICT DO NOTHING;

-- ============================================================================
-- RLS POLICIES
-- ============================================================================

ALTER TABLE schema_migrations_contract ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_feature_flags ENABLE ROW LEVEL SECURITY;
ALTER TABLE api_versions ENABLE ROW LEVEL SECURITY;

-- Public read for feature flags (needed at app startup)
CREATE POLICY "Public read feature flags"
    ON app_feature_flags FOR SELECT
    TO anon, authenticated
    USING (true);

-- Public read for API versions
CREATE POLICY "Public read API versions"
    ON api_versions FOR SELECT
    TO anon, authenticated
    USING (true);

-- Public read for schema contract
CREATE POLICY "Public read schema contract"
    ON schema_migrations_contract FOR SELECT
    TO anon, authenticated
    USING (true);

-- Only super admin can modify
CREATE POLICY "Super admin manage feature flags"
    ON app_feature_flags FOR ALL
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM user_profiles
            WHERE user_id = auth.uid()
            AND role = 'super_admin'
        )
    );

CREATE POLICY "Super admin manage API versions"
    ON api_versions FOR ALL
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM user_profiles
            WHERE user_id = auth.uid()
            AND role = 'super_admin'
        )
    );

-- ============================================================================
-- VERSION COMPARISON FUNCTIONS
-- ============================================================================

-- Parse semantic version into sortable integer
CREATE OR REPLACE FUNCTION parse_semver(version TEXT)
RETURNS INTEGER
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
    parts TEXT[];
    major INTEGER;
    minor INTEGER;
    patch INTEGER;
BEGIN
    -- Remove 'v' prefix if present
    version := LTRIM(version, 'v');

    -- Split by '.'
    parts := string_to_array(version, '.');

    major := COALESCE(parts[1]::INTEGER, 0);
    minor := COALESCE(parts[2]::INTEGER, 0);
    patch := COALESCE(parts[3]::INTEGER, 0);

    -- Return sortable integer (major * 10000 + minor * 100 + patch)
    RETURN major * 10000 + minor * 100 + patch;
END;
$$;

-- Compare two semantic versions
-- Returns: -1 if a < b, 0 if a == b, 1 if a > b
CREATE OR REPLACE FUNCTION compare_versions(a TEXT, b TEXT)
RETURNS INTEGER
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
    a_int INTEGER;
    b_int INTEGER;
BEGIN
    a_int := parse_semver(a);
    b_int := parse_semver(b);

    IF a_int < b_int THEN RETURN -1;
    ELSIF a_int > b_int THEN RETURN 1;
    ELSE RETURN 0;
    END IF;
END;
$$;

-- Check if version meets minimum requirement
CREATE OR REPLACE FUNCTION meets_min_version(current_version TEXT, min_version TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
IMMUTABLE
AS $$
BEGIN
    RETURN compare_versions(current_version, min_version) >= 0;
END;
$$;

-- ============================================================================
-- SCHEMA COMPATIBILITY CHECK
-- ============================================================================

-- Check if a client version is compatible with current schema
CREATE OR REPLACE FUNCTION can_client_use_schema(p_app_version TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    breaking_record RECORD;
BEGIN
    -- Check all breaking changes
    FOR breaking_record IN
        SELECT min_app_version, change_description
        FROM schema_migrations_contract
        WHERE breaking_change = true
        ORDER BY added_on DESC
    LOOP
        -- If client version is below the min required for a breaking change
        IF NOT meets_min_version(p_app_version, breaking_record.min_app_version) THEN
            RETURN false;
        END IF;
    END LOOP;

    RETURN true;
END;
$$;

-- Get required minimum version for schema compatibility
CREATE OR REPLACE FUNCTION get_min_compatible_version()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    min_version TEXT := '1.0.0';
    record RECORD;
BEGIN
    FOR record IN
        SELECT min_app_version
        FROM schema_migrations_contract
        WHERE breaking_change = true
        ORDER BY parse_semver(min_app_version) DESC
        LIMIT 1
    LOOP
        min_version := record.min_app_version;
    END LOOP;

    RETURN min_version;
END;
$$;

-- ============================================================================
-- FEATURE FLAGS RPC
-- ============================================================================

-- Get feature flags for a specific app and version
CREATE OR REPLACE FUNCTION get_feature_flags(
    p_app_name TEXT,
    p_app_version TEXT
)
RETURNS TABLE (
    feature TEXT,
    enabled BOOLEAN,
    min_version TEXT,
    description TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT DISTINCT ON (f.feature)
        f.feature,
        f.enabled,
        f.min_version,
        f.description
    FROM app_feature_flags f
    WHERE (f.app_name = p_app_name OR f.app_name = '*')
    AND meets_min_version(p_app_version, f.min_version)
    AND (f.max_version IS NULL OR meets_min_version(f.max_version, p_app_version))
    ORDER BY f.feature, f.app_name DESC, parse_semver(f.min_version) DESC;
END;
$$;

-- Check if a specific feature is enabled for an app/version
CREATE OR REPLACE FUNCTION is_feature_enabled(
    p_app_name TEXT,
    p_app_version TEXT,
    p_feature TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    flag_enabled BOOLEAN;
BEGIN
    SELECT f.enabled INTO flag_enabled
    FROM app_feature_flags f
    WHERE (f.app_name = p_app_name OR f.app_name = '*')
    AND f.feature = p_feature
    AND meets_min_version(p_app_version, f.min_version)
    AND (f.max_version IS NULL OR meets_min_version(f.max_version, p_app_version))
    ORDER BY f.app_name DESC, parse_semver(f.min_version) DESC
    LIMIT 1;

    RETURN COALESCE(flag_enabled, false);
END;
$$;

-- ============================================================================
-- VERSIONED RPC DISPATCH (V1)
-- Routes calls to v1 implementations
-- ============================================================================

CREATE OR REPLACE FUNCTION rpc_v1_dispatch(
    p_name TEXT,
    p_payload JSONB
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    result JSONB;
BEGIN
    CASE p_name
        -- Store metrics (basic version)
        WHEN 'get_store_metrics' THEN
            SELECT to_jsonb(r.*) INTO result
            FROM get_store_metrics_secure(
                (p_payload->>'store_id')::BIGINT,
                COALESCE(p_payload->>'date_range', 'today')
            ) r;

        -- Get menu items
        WHEN 'get_menu_items' THEN
            SELECT jsonb_agg(to_jsonb(mi.*)) INTO result
            FROM menu_items mi
            WHERE mi.is_available = true
            ORDER BY mi.category_id, mi.name;

        -- Get stores
        WHEN 'get_stores' THEN
            SELECT jsonb_agg(to_jsonb(s.*)) INTO result
            FROM stores s
            ORDER BY s.name;

        -- Get order by ID
        WHEN 'get_order' THEN
            SELECT to_jsonb(o.*) INTO result
            FROM orders o
            WHERE o.id = (p_payload->>'order_id')::BIGINT;

        -- Place order (v1 - basic)
        WHEN 'place_order' THEN
            INSERT INTO orders (
                store_id,
                customer_name,
                customer_email,
                customer_phone,
                subtotal,
                tax,
                total,
                status,
                payment_method,
                notes
            )
            SELECT
                (p_payload->>'store_id')::BIGINT,
                p_payload->>'customer_name',
                p_payload->>'customer_email',
                p_payload->>'customer_phone',
                (p_payload->>'subtotal')::NUMERIC,
                (p_payload->>'tax')::NUMERIC,
                (p_payload->>'total')::NUMERIC,
                'pending',
                COALESCE(p_payload->>'payment_method', 'card'),
                p_payload->>'notes'
            RETURNING jsonb_build_object(
                'order_id', id,
                'status', status,
                'created_at', created_at
            ) INTO result;

        -- Get rewards (v1 - basic)
        WHEN 'get_rewards' THEN
            SELECT to_jsonb(c.*) INTO result
            FROM customers c
            WHERE c.user_id = auth.uid();

        ELSE
            RAISE EXCEPTION 'Unknown RPC for v1: %', p_name;
    END CASE;

    RETURN COALESCE(result, 'null'::JSONB);
END;
$$;

-- ============================================================================
-- VERSIONED RPC DISPATCH (V2)
-- Routes calls to v2 implementations with enhanced features
-- ============================================================================

CREATE OR REPLACE FUNCTION rpc_v2_dispatch(
    p_name TEXT,
    p_payload JSONB
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    result JSONB;
    app_version TEXT;
    app_name TEXT;
BEGIN
    -- Get client info from session (set by api-dispatch Edge Function)
    app_version := COALESCE(current_setting('request.session.app_version', true), '1.0.0');
    app_name := COALESCE(current_setting('request.session.app_name', true), 'web');

    CASE p_name
        -- Store metrics (enhanced with trends)
        WHEN 'get_store_metrics' THEN
            SELECT jsonb_build_object(
                'metrics', (SELECT to_jsonb(r.*) FROM get_store_metrics_secure(
                    (p_payload->>'store_id')::BIGINT,
                    COALESCE(p_payload->>'date_range', 'today')
                ) r),
                'api_version', 'v2',
                'client_version', app_version
            ) INTO result;

        -- Get menu items (with customizations)
        WHEN 'get_menu_items' THEN
            SELECT jsonb_agg(
                to_jsonb(mi.*) || jsonb_build_object(
                    'customizations', (
                        SELECT jsonb_agg(to_jsonb(mc.*))
                        FROM menu_item_customizations mc
                        WHERE mc.menu_item_id = mi.id
                    )
                )
            ) INTO result
            FROM menu_items mi
            WHERE mi.is_available = true
            ORDER BY mi.category_id, mi.name;

        -- Get stores (with hours)
        WHEN 'get_stores' THEN
            SELECT jsonb_agg(to_jsonb(s.*)) INTO result
            FROM stores s
            ORDER BY s.name;

        -- Get order with items
        WHEN 'get_order' THEN
            SELECT jsonb_build_object(
                'order', to_jsonb(o.*),
                'items', (
                    SELECT jsonb_agg(to_jsonb(oi.*))
                    FROM order_items oi
                    WHERE oi.order_id = o.id
                )
            ) INTO result
            FROM orders o
            WHERE o.id = (p_payload->>'order_id')::BIGINT;

        -- Place order (v2 - with items)
        WHEN 'place_order' THEN
            WITH new_order AS (
                INSERT INTO orders (
                    store_id,
                    customer_id,
                    customer_name,
                    customer_email,
                    customer_phone,
                    subtotal,
                    tax,
                    total,
                    status,
                    payment_method,
                    notes
                )
                SELECT
                    (p_payload->>'store_id')::BIGINT,
                    CASE WHEN p_payload->>'customer_id' IS NOT NULL
                        THEN (p_payload->>'customer_id')::UUID
                        ELSE auth.uid()
                    END,
                    p_payload->>'customer_name',
                    p_payload->>'customer_email',
                    p_payload->>'customer_phone',
                    (p_payload->>'subtotal')::NUMERIC,
                    (p_payload->>'tax')::NUMERIC,
                    (p_payload->>'total')::NUMERIC,
                    'pending',
                    COALESCE(p_payload->>'payment_method', 'card'),
                    p_payload->>'notes'
                RETURNING *
            ),
            inserted_items AS (
                INSERT INTO order_items (order_id, menu_item_id, quantity, customizations, notes)
                SELECT
                    (SELECT id FROM new_order),
                    (item->>'menu_item_id')::BIGINT,
                    (item->>'quantity')::INTEGER,
                    (item->'customizations')::TEXT[],
                    item->>'notes'
                FROM jsonb_array_elements(p_payload->'items') AS item
                RETURNING *
            )
            SELECT jsonb_build_object(
                'order_id', o.id,
                'status', o.status,
                'created_at', o.created_at,
                'items_count', (SELECT COUNT(*) FROM inserted_items)
            ) INTO result
            FROM new_order o;

        -- Get rewards (v2 - with history)
        WHEN 'get_rewards' THEN
            SELECT jsonb_build_object(
                'customer', to_jsonb(c.*),
                'recent_orders', (
                    SELECT jsonb_agg(jsonb_build_object(
                        'id', o.id,
                        'total', o.total,
                        'status', o.status,
                        'created_at', o.created_at
                    ))
                    FROM orders o
                    WHERE o.customer_id = c.user_id
                    ORDER BY o.created_at DESC
                    LIMIT 10
                )
            ) INTO result
            FROM customers c
            WHERE c.user_id = auth.uid();

        -- Get feature flags
        WHEN 'get_features' THEN
            SELECT jsonb_agg(to_jsonb(f.*)) INTO result
            FROM get_feature_flags(app_name, app_version) f;

        -- Check compatibility
        WHEN 'check_compatibility' THEN
            SELECT jsonb_build_object(
                'compatible', can_client_use_schema(app_version),
                'min_required', get_min_compatible_version(),
                'client_version', app_version,
                'api_version', 'v2'
            ) INTO result;

        ELSE
            -- Fall back to v1 for unknown RPCs
            result := rpc_v1_dispatch(p_name, p_payload);
    END CASE;

    RETURN COALESCE(result, 'null'::JSONB);
END;
$$;

-- ============================================================================
-- HELPER: Set session variables from Edge Function
-- ============================================================================

CREATE OR REPLACE FUNCTION set_client_context(
    p_app_version TEXT,
    p_app_name TEXT,
    p_api_version TEXT DEFAULT 'v2'
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    PERFORM set_config('request.session.app_version', p_app_version, true);
    PERFORM set_config('request.session.app_name', p_app_name, true);
    PERFORM set_config('request.session.api_version', p_api_version, true);
END;
$$;

-- ============================================================================
-- UPDATED_AT TRIGGER
-- ============================================================================

CREATE OR REPLACE FUNCTION update_feature_flags_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_feature_flags_updated ON app_feature_flags;
CREATE TRIGGER trigger_feature_flags_updated
    BEFORE UPDATE ON app_feature_flags
    FOR EACH ROW
    EXECUTE FUNCTION update_feature_flags_timestamp();

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE schema_migrations_contract IS 'Tracks breaking schema changes and version requirements';
COMMENT ON TABLE app_feature_flags IS 'Feature flags per app and version';
COMMENT ON TABLE api_versions IS 'Registry of supported API versions';

COMMENT ON FUNCTION can_client_use_schema IS 'Check if client version is compatible with schema';
COMMENT ON FUNCTION get_feature_flags IS 'Get enabled features for app/version';
COMMENT ON FUNCTION rpc_v1_dispatch IS 'Route RPC calls to v1 implementations';
COMMENT ON FUNCTION rpc_v2_dispatch IS 'Route RPC calls to v2 implementations';
COMMENT ON FUNCTION set_client_context IS 'Set session variables for client info';
