-- @requires_version: 1.3.0
-- @affects: customer, business, web
-- @breaking: false
-- @description: Multi-region infrastructure for global deployment

-- ============================================================================
-- Migration 066: Multi-Region Infrastructure
-- ============================================================================
-- Adds support for:
-- - Region tracking and routing
-- - Client telemetry by region
-- - Cross-region sync coordination
-- - V3 API dispatcher with enhanced routing
-- - Hot version switching for zero-downtime releases
-- ============================================================================

-- ============================================================================
-- Region Configuration Table
-- ============================================================================

CREATE TABLE IF NOT EXISTS regions (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  is_primary BOOLEAN DEFAULT false,
  is_read_replica BOOLEAN DEFAULT false,
  supabase_project_id TEXT,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'degraded', 'offline', 'maintenance')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default regions
INSERT INTO regions (id, name, is_primary, is_read_replica) VALUES
  ('us-east-1', 'US East (N. Virginia)', true, false),
  ('us-west-2', 'US West (Oregon)', false, true),
  ('eu-west-1', 'EU (Ireland)', false, true),
  ('ap-southeast-1', 'Asia Pacific (Singapore)', false, true)
ON CONFLICT (id) DO NOTHING;

-- Index for quick primary lookup
CREATE INDEX IF NOT EXISTS idx_regions_primary ON regions(is_primary) WHERE is_primary = true;

-- ============================================================================
-- Region Health Tracking
-- ============================================================================

CREATE TABLE IF NOT EXISTS region_health (
  id SERIAL PRIMARY KEY,
  region_id TEXT REFERENCES regions(id),
  healthy BOOLEAN NOT NULL,
  latency_ms INTEGER,
  consecutive_failures INTEGER DEFAULT 0,
  last_check_at TIMESTAMPTZ DEFAULT NOW(),
  error_message TEXT,
  UNIQUE(region_id)
);

-- Function to update region health
CREATE OR REPLACE FUNCTION update_region_health(
  p_region_id TEXT,
  p_healthy BOOLEAN,
  p_latency_ms INTEGER DEFAULT NULL,
  p_error_message TEXT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO region_health (region_id, healthy, latency_ms, error_message, last_check_at)
  VALUES (p_region_id, p_healthy, p_latency_ms, p_error_message, NOW())
  ON CONFLICT (region_id) DO UPDATE SET
    healthy = EXCLUDED.healthy,
    latency_ms = EXCLUDED.latency_ms,
    error_message = EXCLUDED.error_message,
    consecutive_failures = CASE
      WHEN EXCLUDED.healthy THEN 0
      ELSE region_health.consecutive_failures + 1
    END,
    last_check_at = NOW();
END;
$$;

-- ============================================================================
-- Client Region Telemetry
-- ============================================================================

CREATE TABLE IF NOT EXISTS client_region_telemetry (
  id SERIAL PRIMARY KEY,
  client_id TEXT NOT NULL,
  region_id TEXT REFERENCES regions(id),
  app_name TEXT NOT NULL,
  app_version TEXT NOT NULL,
  api_version TEXT DEFAULT 'v2',
  first_seen_at TIMESTAMPTZ DEFAULT NOW(),
  last_seen_at TIMESTAMPTZ DEFAULT NOW(),
  request_count INTEGER DEFAULT 1,
  UNIQUE(client_id)
);

-- Index for telemetry queries
CREATE INDEX IF NOT EXISTS idx_client_telemetry_region ON client_region_telemetry(region_id);
CREATE INDEX IF NOT EXISTS idx_client_telemetry_app ON client_region_telemetry(app_name, app_version);
CREATE INDEX IF NOT EXISTS idx_client_telemetry_last_seen ON client_region_telemetry(last_seen_at);

-- Function to register/update client region
CREATE OR REPLACE FUNCTION register_client_region(
  p_region TEXT,
  p_client_id TEXT,
  p_app_name TEXT DEFAULT 'web',
  p_app_version TEXT DEFAULT '1.0.0',
  p_api_version TEXT DEFAULT 'v2'
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO client_region_telemetry (
    client_id, region_id, app_name, app_version, api_version
  ) VALUES (
    p_client_id, p_region, p_app_name, p_app_version, p_api_version
  )
  ON CONFLICT (client_id) DO UPDATE SET
    region_id = EXCLUDED.region_id,
    app_name = EXCLUDED.app_name,
    app_version = EXCLUDED.app_version,
    api_version = EXCLUDED.api_version,
    last_seen_at = NOW(),
    request_count = client_region_telemetry.request_count + 1;
END;
$$;

-- ============================================================================
-- Cross-Region Sync Tracking
-- ============================================================================

CREATE TABLE IF NOT EXISTS region_sync_status (
  id SERIAL PRIMARY KEY,
  source_region TEXT REFERENCES regions(id),
  target_region TEXT REFERENCES regions(id),
  last_sync_lsn TEXT,
  lag_bytes BIGINT DEFAULT 0,
  lag_ms INTEGER DEFAULT 0,
  synced_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(source_region, target_region)
);

-- Function to get sync status
CREATE OR REPLACE FUNCTION get_region_sync_status()
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
AS $$
DECLARE
  v_result JSONB;
  v_primary TEXT;
BEGIN
  -- Get primary region
  SELECT id INTO v_primary FROM regions WHERE is_primary = true LIMIT 1;

  -- Build sync status object
  SELECT jsonb_build_object(
    'primaryRegion', v_primary,
    'replicaLag', (
      SELECT jsonb_object_agg(target_region, lag_ms)
      FROM region_sync_status
      WHERE source_region = v_primary
    ),
    'lastSyncAt', (
      SELECT MAX(synced_at)
      FROM region_sync_status
      WHERE source_region = v_primary
    )
  ) INTO v_result;

  RETURN COALESCE(v_result, '{}'::JSONB);
END;
$$;

-- ============================================================================
-- V3 API Dispatcher
-- ============================================================================

-- Extend api_versions table with V3
INSERT INTO api_versions (version, status, min_app_version)
VALUES ('v3', 'active', '1.4.0')
ON CONFLICT (version) DO NOTHING;

-- V3 dispatch function with enhanced routing
CREATE OR REPLACE FUNCTION rpc_v3_dispatch(
  p_name TEXT,
  p_payload JSONB DEFAULT '{}'::JSONB
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_result JSONB;
  v_client_region TEXT;
  v_client_version TEXT;
  v_start_ts TIMESTAMPTZ;
  v_execution_ms INTEGER;
BEGIN
  v_start_ts := clock_timestamp();

  -- Get client context
  v_client_region := current_setting('request.session.region', true);
  v_client_version := current_setting('request.session.app_version', true);

  -- V3 RPCs with enhanced features
  CASE p_name
    -- Menu with full customization tree
    WHEN 'get_menu_items' THEN
      SELECT jsonb_agg(
        jsonb_build_object(
          'id', m.id,
          'name', m.name,
          'description', m.description,
          'price', m.price,
          'category', m.category,
          'image_url', m.image_url,
          'is_available', m.is_available,
          'customizations', (
            SELECT COALESCE(jsonb_agg(
              jsonb_build_object(
                'id', c.id,
                'name', c.name,
                'category', c.category,
                'supports_portions', c.supports_portions,
                'portion_pricing', c.portion_pricing,
                'default_portion', c.default_portion
              )
            ), '[]'::JSONB)
            FROM menu_item_customizations c
            WHERE c.menu_item_id = m.id
          ),
          'allergens', m.allergens,
          'calories', m.calories
        )
      )
      INTO v_result
      FROM menu_items m
      WHERE m.is_available = true;

    -- Orders with full items and tracking
    WHEN 'place_order' THEN
      -- Enhanced order placement with region tracking
      WITH new_order AS (
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
          special_instructions,
          source_region
        )
        SELECT
          (p_payload->>'store_id')::INTEGER,
          p_payload->>'customer_name',
          p_payload->>'customer_email',
          p_payload->>'customer_phone',
          COALESCE((p_payload->>'subtotal')::DECIMAL, 0),
          COALESCE((p_payload->>'tax')::DECIMAL, 0),
          COALESCE((p_payload->>'total')::DECIMAL, 0),
          'pending',
          COALESCE(p_payload->>'payment_method', 'card'),
          p_payload->>'special_instructions',
          v_client_region
        RETURNING *
      ),
      inserted_items AS (
        INSERT INTO order_items (order_id, menu_item_id, quantity, customizations, notes, unit_price)
        SELECT
          (SELECT id FROM new_order),
          (item->>'menu_item_id')::INTEGER,
          COALESCE((item->>'quantity')::INTEGER, 1),
          item->'customizations',
          item->>'notes',
          COALESCE((item->>'unit_price')::DECIMAL, 0)
        FROM jsonb_array_elements(COALESCE(p_payload->'items', '[]'::JSONB)) AS item
        RETURNING id
      )
      SELECT jsonb_build_object(
        'order_id', o.id,
        'status', o.status,
        'created_at', o.created_at,
        'items_count', (SELECT COUNT(*) FROM inserted_items),
        'tracking_url', '/order/' || o.id,
        'region', v_client_region,
        'api_version', 'v3'
      )
      INTO v_result
      FROM new_order o;

    -- Feature flags with region awareness
    WHEN 'get_features' THEN
      SELECT jsonb_agg(
        jsonb_build_object(
          'feature', f.feature,
          'enabled', f.enabled,
          'description', f.description
        )
      )
      INTO v_result
      FROM app_feature_flags f
      WHERE f.enabled = true
        AND (f.app_name = 'all' OR f.app_name = current_setting('request.session.app_name', true))
        AND meets_min_version(
          COALESCE(v_client_version, '1.0.0'),
          f.min_version
        );

    -- Enhanced compatibility check
    WHEN 'check_compatibility' THEN
      SELECT jsonb_build_object(
        'compatible', can_client_use_schema(COALESCE(v_client_version, '1.0.0')),
        'min_required', get_min_compatible_version(),
        'client_version', v_client_version,
        'api_version', 'v3',
        'region', v_client_region,
        'features_available', (
          SELECT COUNT(*) FROM app_feature_flags
          WHERE enabled = true
          AND meets_min_version(COALESCE(v_client_version, '1.0.0'), min_version)
        )
      )
      INTO v_result;

    -- Region health status
    WHEN 'get_region_health' THEN
      SELECT jsonb_agg(
        jsonb_build_object(
          'region', r.id,
          'name', r.name,
          'status', r.status,
          'is_primary', r.is_primary,
          'healthy', COALESCE(h.healthy, true),
          'latency_ms', h.latency_ms,
          'last_check', h.last_check_at
        )
      )
      INTO v_result
      FROM regions r
      LEFT JOIN region_health h ON h.region_id = r.id
      WHERE r.status != 'offline';

    -- Fallback to V2 for unknown RPCs
    ELSE
      v_result := rpc_v2_dispatch(p_name, p_payload);
  END CASE;

  -- Calculate execution time
  v_execution_ms := EXTRACT(MILLISECONDS FROM (clock_timestamp() - v_start_ts))::INTEGER;

  -- Log to runtime metrics
  INSERT INTO runtime_metrics (metric_name, metric_value, metadata)
  VALUES (
    'rpc_v3_' || p_name,
    v_execution_ms,
    jsonb_build_object(
      'region', v_client_region,
      'version', v_client_version,
      'success', v_result IS NOT NULL
    )
  );

  RETURN COALESCE(v_result, '{}'::JSONB);
END;
$$;

-- ============================================================================
-- Hot Version Switching
-- ============================================================================

CREATE TABLE IF NOT EXISTS active_api_version (
  id INTEGER PRIMARY KEY DEFAULT 1 CHECK (id = 1), -- Singleton
  current_version TEXT NOT NULL DEFAULT 'v2',
  fallback_version TEXT NOT NULL DEFAULT 'v1',
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  updated_by TEXT
);

-- Insert default active version
INSERT INTO active_api_version (current_version, fallback_version)
VALUES ('v2', 'v1')
ON CONFLICT (id) DO NOTHING;

-- Function to switch active API version (hot switch)
CREATE OR REPLACE FUNCTION switch_api_version(
  p_new_version TEXT,
  p_fallback_version TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_old_version TEXT;
  v_result JSONB;
BEGIN
  -- Verify version exists
  IF NOT EXISTS (SELECT 1 FROM api_versions WHERE version = p_new_version AND status = 'active') THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Version ' || p_new_version || ' is not active'
    );
  END IF;

  -- Get current version for logging
  SELECT current_version INTO v_old_version FROM active_api_version WHERE id = 1;

  -- Update active version
  UPDATE active_api_version
  SET
    current_version = p_new_version,
    fallback_version = COALESCE(p_fallback_version, v_old_version),
    updated_at = NOW(),
    updated_by = current_user
  WHERE id = 1;

  -- Log the switch
  INSERT INTO deployment_log (action, version, metadata)
  VALUES (
    'api_version_switch',
    p_new_version,
    jsonb_build_object(
      'previous_version', v_old_version,
      'fallback_version', COALESCE(p_fallback_version, v_old_version)
    )
  );

  v_result := jsonb_build_object(
    'success', true,
    'previous_version', v_old_version,
    'current_version', p_new_version,
    'fallback_version', COALESCE(p_fallback_version, v_old_version)
  );

  RETURN v_result;
END;
$$;

-- Function to get current active API version
CREATE OR REPLACE FUNCTION get_active_api_version()
RETURNS JSONB
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT jsonb_build_object(
    'current', current_version,
    'fallback', fallback_version,
    'updated_at', updated_at
  )
  FROM active_api_version
  WHERE id = 1;
$$;

-- ============================================================================
-- Universal API Router (used by gateway)
-- ============================================================================

CREATE OR REPLACE FUNCTION route_api_call(
  p_name TEXT,
  p_payload JSONB DEFAULT '{}'::JSONB,
  p_requested_version TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_active_version TEXT;
  v_fallback_version TEXT;
  v_target_version TEXT;
  v_result JSONB;
  v_client_version TEXT;
BEGIN
  -- Get active API version
  SELECT current_version, fallback_version
  INTO v_active_version, v_fallback_version
  FROM active_api_version
  WHERE id = 1;

  -- Get client version from session
  v_client_version := current_setting('request.session.app_version', true);

  -- Determine target version
  IF p_requested_version IS NOT NULL THEN
    -- Client requested specific version
    v_target_version := p_requested_version;
  ELSE
    -- Use active version, but check client compatibility
    IF v_client_version IS NOT NULL AND NOT meets_min_version(v_client_version, '1.4.0') THEN
      -- Old client, use fallback
      v_target_version := v_fallback_version;
    ELSE
      v_target_version := v_active_version;
    END IF;
  END IF;

  -- Route to appropriate dispatcher
  CASE v_target_version
    WHEN 'v3' THEN
      v_result := rpc_v3_dispatch(p_name, p_payload);
    WHEN 'v2' THEN
      v_result := rpc_v2_dispatch(p_name, p_payload);
    WHEN 'v1' THEN
      v_result := rpc_v1_dispatch(p_name, p_payload);
    ELSE
      v_result := rpc_v2_dispatch(p_name, p_payload);
  END CASE;

  RETURN v_result;
END;
$$;

-- ============================================================================
-- Order Region Tracking (add column if not exists)
-- ============================================================================

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'orders' AND column_name = 'source_region'
  ) THEN
    ALTER TABLE orders ADD COLUMN source_region TEXT;
  END IF;
END;
$$;

-- Index for region-based order queries
CREATE INDEX IF NOT EXISTS idx_orders_source_region ON orders(source_region) WHERE source_region IS NOT NULL;

-- ============================================================================
-- Realtime Fanout Tracking
-- ============================================================================

CREATE TABLE IF NOT EXISTS realtime_fanout_log (
  id SERIAL PRIMARY KEY,
  event_type TEXT NOT NULL,
  source_region TEXT REFERENCES regions(id),
  target_regions TEXT[],
  payload_size INTEGER,
  fanout_at TIMESTAMPTZ DEFAULT NOW(),
  delivery_status JSONB DEFAULT '{}'::JSONB
);

-- Index for recent fanout queries
CREATE INDEX IF NOT EXISTS idx_fanout_log_time ON realtime_fanout_log(fanout_at DESC);

-- Function to log fanout event
CREATE OR REPLACE FUNCTION log_realtime_fanout(
  p_event_type TEXT,
  p_source_region TEXT,
  p_target_regions TEXT[],
  p_payload_size INTEGER DEFAULT 0
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_id INTEGER;
BEGIN
  INSERT INTO realtime_fanout_log (event_type, source_region, target_regions, payload_size)
  VALUES (p_event_type, p_source_region, p_target_regions, p_payload_size)
  RETURNING id INTO v_id;

  RETURN v_id;
END;
$$;

-- ============================================================================
-- RLS Policies
-- ============================================================================

-- Regions table - public read
ALTER TABLE regions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public can read regions" ON regions;
CREATE POLICY "Public can read regions" ON regions
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "Super admin can manage regions" ON regions;
CREATE POLICY "Super admin can manage regions" ON regions
  FOR ALL USING (
    EXISTS (SELECT 1 FROM user_profiles WHERE user_id = auth.uid() AND role = 'super_admin')
  );

-- Region health - public read
ALTER TABLE region_health ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public can read region health" ON region_health;
CREATE POLICY "Public can read region health" ON region_health
  FOR SELECT USING (true);

-- Client telemetry - restricted
ALTER TABLE client_region_telemetry ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins can read telemetry" ON client_region_telemetry;
CREATE POLICY "Admins can read telemetry" ON client_region_telemetry
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM user_profiles WHERE user_id = auth.uid() AND role IN ('admin', 'super_admin'))
  );

-- Active API version - public read
ALTER TABLE active_api_version ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public can read active version" ON active_api_version;
CREATE POLICY "Public can read active version" ON active_api_version
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "Super admin can update version" ON active_api_version;
CREATE POLICY "Super admin can update version" ON active_api_version
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM user_profiles WHERE user_id = auth.uid() AND role = 'super_admin')
  );

-- Fanout log - admin read
ALTER TABLE realtime_fanout_log ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins can read fanout log" ON realtime_fanout_log;
CREATE POLICY "Admins can read fanout log" ON realtime_fanout_log
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM user_profiles WHERE user_id = auth.uid() AND role IN ('admin', 'super_admin'))
  );

-- ============================================================================
-- Grant Permissions
-- ============================================================================

GRANT SELECT ON regions TO anon, authenticated;
GRANT SELECT ON region_health TO anon, authenticated;
GRANT SELECT ON active_api_version TO anon, authenticated;
GRANT EXECUTE ON FUNCTION get_region_sync_status() TO anon, authenticated;
GRANT EXECUTE ON FUNCTION register_client_region(TEXT, TEXT, TEXT, TEXT, TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION rpc_v3_dispatch(TEXT, JSONB) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION route_api_call(TEXT, JSONB, TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION get_active_api_version() TO anon, authenticated;

-- ============================================================================
-- Summary
-- ============================================================================
-- This migration adds:
-- 1. Region configuration and health tracking tables
-- 2. Client region telemetry for analytics
-- 3. Cross-region sync status tracking
-- 4. V3 API dispatcher with enhanced features
-- 5. Hot version switching for zero-downtime releases
-- 6. Universal API router for intelligent version selection
-- 7. Order region tracking
-- 8. Realtime fanout logging
-- ============================================================================
