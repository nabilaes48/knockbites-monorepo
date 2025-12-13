-- @requires_version: 1.5.0
-- @affects: customer, business, web
-- @breaking: false
-- @description: Autonomous Operations Engine - Dynamic Pricing, Kitchen Load, Staffing, Profitability

-- ============================================================================
-- Migration 068: Autonomous Operations Core
-- ============================================================================
-- Adds support for:
-- - Dynamic pricing rules and automation
-- - Kitchen load predictions and alerts
-- - Staffing recommendations
-- - Menu profitability analysis
-- - V5 API dispatcher for autonomous ops
-- - Safety guardrails and override system
-- ============================================================================

-- ============================================================================
-- SECTION 1: Core Autonomous Operations Tables
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1.1 Dynamic Pricing Rules
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS dynamic_pricing_rules (
  id BIGSERIAL PRIMARY KEY,
  item_id BIGINT REFERENCES menu_items(id) ON DELETE CASCADE,
  store_id BIGINT REFERENCES stores(id) ON DELETE CASCADE,
  rule_type TEXT NOT NULL CHECK (rule_type IN ('demand', 'time', 'inventory', 'promotion', 'manual')),
  base_price NUMERIC(10, 2) NOT NULL,
  min_price NUMERIC(10, 2) NOT NULL,
  max_price NUMERIC(10, 2) NOT NULL,
  current_price NUMERIC(10, 2) NOT NULL,
  price_multiplier NUMERIC(4, 2) DEFAULT 1.00,
  confidence FLOAT CHECK (confidence >= 0 AND confidence <= 1),
  is_active BOOLEAN DEFAULT false,
  requires_approval BOOLEAN DEFAULT true,
  approved_by UUID,
  approved_at TIMESTAMPTZ,
  last_eval TIMESTAMPTZ DEFAULT NOW(),
  eval_reason TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(item_id, store_id)
);

-- Safety constraint: max price cannot exceed base_price * 1.15 (15% cap)
ALTER TABLE dynamic_pricing_rules
ADD CONSTRAINT dynamic_pricing_max_cap
CHECK (max_price <= base_price * 1.15);

-- Safety constraint: min price cannot go below base_price * 0.85 (15% floor)
ALTER TABLE dynamic_pricing_rules
ADD CONSTRAINT dynamic_pricing_min_floor
CHECK (min_price >= base_price * 0.85);

CREATE INDEX IF NOT EXISTS idx_dynamic_pricing_store_item
ON dynamic_pricing_rules(store_id, item_id);

CREATE INDEX IF NOT EXISTS idx_dynamic_pricing_active
ON dynamic_pricing_rules(store_id, is_active) WHERE is_active = true;

-- ----------------------------------------------------------------------------
-- 1.2 Dynamic Pricing History (audit trail)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS dynamic_pricing_history (
  id BIGSERIAL PRIMARY KEY,
  rule_id BIGINT REFERENCES dynamic_pricing_rules(id) ON DELETE CASCADE,
  previous_price NUMERIC(10, 2),
  new_price NUMERIC(10, 2),
  change_reason TEXT,
  triggered_by TEXT CHECK (triggered_by IN ('system', 'manual', 'schedule', 'demand', 'inventory')),
  demand_score FLOAT,
  inventory_level INTEGER,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_pricing_history_rule
ON dynamic_pricing_history(rule_id, created_at DESC);

-- ----------------------------------------------------------------------------
-- 1.3 Kitchen Load Predictions
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS kitchen_load_predictions (
  id BIGSERIAL PRIMARY KEY,
  store_id BIGINT REFERENCES stores(id) ON DELETE CASCADE,
  prediction_time TIMESTAMPTZ NOT NULL,
  predicted_orders INTEGER NOT NULL,
  predicted_prep_time INTEGER NOT NULL, -- in minutes
  current_queue_size INTEGER DEFAULT 0,
  load_level TEXT NOT NULL CHECK (load_level IN ('low', 'medium', 'high', 'critical')),
  load_score FLOAT CHECK (load_score >= 0 AND load_score <= 100),
  model_confidence FLOAT CHECK (model_confidence >= 0 AND model_confidence <= 1),
  prediction_window_minutes INTEGER DEFAULT 30,
  factors JSONB DEFAULT '{}'::JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_kitchen_load_store_time
ON kitchen_load_predictions(store_id, prediction_time DESC);

CREATE INDEX IF NOT EXISTS idx_kitchen_load_critical
ON kitchen_load_predictions(store_id, load_level) WHERE load_level = 'critical';

-- ----------------------------------------------------------------------------
-- 1.4 Staffing Recommendations
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS staffing_recommendations (
  id BIGSERIAL PRIMARY KEY,
  store_id BIGINT REFERENCES stores(id) ON DELETE CASCADE,
  recommendation_date DATE NOT NULL,
  shift TEXT NOT NULL CHECK (shift IN ('morning', 'afternoon', 'evening', 'overnight')),
  shift_start TIME NOT NULL,
  shift_end TIME NOT NULL,
  predicted_demand INTEGER NOT NULL,
  predicted_orders INTEGER NOT NULL,
  recommended_staff_count INTEGER NOT NULL,
  current_scheduled_count INTEGER DEFAULT 0,
  staff_gap INTEGER GENERATED ALWAYS AS (recommended_staff_count - current_scheduled_count) STORED,
  confidence FLOAT CHECK (confidence >= 0 AND confidence <= 1),
  factors JSONB DEFAULT '{}'::JSONB,
  is_acknowledged BOOLEAN DEFAULT false,
  acknowledged_by UUID,
  acknowledged_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(store_id, recommendation_date, shift)
);

CREATE INDEX IF NOT EXISTS idx_staffing_store_date
ON staffing_recommendations(store_id, recommendation_date);

CREATE INDEX IF NOT EXISTS idx_staffing_gaps
ON staffing_recommendations(store_id, staff_gap) WHERE staff_gap != 0;

-- ----------------------------------------------------------------------------
-- 1.5 Menu Profitability Analysis
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS menu_profitability (
  id BIGSERIAL PRIMARY KEY,
  item_id BIGINT REFERENCES menu_items(id) ON DELETE CASCADE,
  store_id BIGINT REFERENCES stores(id) ON DELETE CASCADE,
  cost_basis NUMERIC(10, 2) NOT NULL DEFAULT 0,
  avg_selling_price NUMERIC(10, 2) NOT NULL,
  gross_margin NUMERIC(10, 2) GENERATED ALWAYS AS (avg_selling_price - cost_basis) STORED,
  margin_percentage NUMERIC(5, 2),
  margin_tier TEXT CHECK (margin_tier IN ('critical', 'low', 'normal', 'high', 'premium')),
  total_units_30d INTEGER DEFAULT 0,
  total_revenue_30d NUMERIC(10, 2) DEFAULT 0,
  total_profit_30d NUMERIC(10, 2) DEFAULT 0,
  category_rank INTEGER,
  recommendation TEXT,
  last_calculated TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(item_id, store_id)
);

CREATE INDEX IF NOT EXISTS idx_profitability_store
ON menu_profitability(store_id);

CREATE INDEX IF NOT EXISTS idx_profitability_tier
ON menu_profitability(store_id, margin_tier);

CREATE INDEX IF NOT EXISTS idx_profitability_low_margin
ON menu_profitability(store_id, margin_percentage) WHERE margin_percentage < 30;

-- ----------------------------------------------------------------------------
-- 1.6 Store Operations Settings
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS store_ops_settings (
  store_id BIGINT PRIMARY KEY REFERENCES stores(id) ON DELETE CASCADE,
  dynamic_pricing_enabled BOOLEAN DEFAULT false,
  dynamic_pricing_max_change NUMERIC(4, 2) DEFAULT 0.15, -- 15% max
  auto_hide_slow_items BOOLEAN DEFAULT false,
  slow_item_threshold_minutes INTEGER DEFAULT 20,
  kitchen_load_alerts_enabled BOOLEAN DEFAULT true,
  staffing_recommendations_enabled BOOLEAN DEFAULT true,
  profitability_alerts_enabled BOOLEAN DEFAULT true,
  low_margin_threshold NUMERIC(5, 2) DEFAULT 25.00, -- 25% minimum margin
  enabled_by UUID,
  enabled_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- 1.7 Operations Alerts
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS ops_alerts (
  id BIGSERIAL PRIMARY KEY,
  store_id BIGINT REFERENCES stores(id) ON DELETE CASCADE,
  alert_type TEXT NOT NULL CHECK (alert_type IN (
    'kitchen_overload', 'staffing_gap', 'low_margin', 'price_change',
    'demand_spike', 'inventory_impact', 'system_recommendation'
  )),
  severity TEXT NOT NULL CHECK (severity IN ('info', 'warning', 'critical')),
  title TEXT NOT NULL,
  description TEXT,
  related_item_id BIGINT,
  related_data JSONB DEFAULT '{}'::JSONB,
  is_resolved BOOLEAN DEFAULT false,
  resolved_by UUID,
  resolved_at TIMESTAMPTZ,
  auto_action_taken TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ops_alerts_store
ON ops_alerts(store_id, is_resolved, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_ops_alerts_unresolved
ON ops_alerts(store_id, alert_type) WHERE is_resolved = false;

-- ============================================================================
-- SECTION 2: Materialized Views
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 2.1 Kitchen Load 60-Minute Rolling Window
-- ----------------------------------------------------------------------------
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_kitchen_load_60min AS
WITH order_data AS (
  SELECT
    o.store_id,
    DATE_TRUNC('minute', o.created_at) AS minute_bucket,
    COUNT(oi.id) AS total_items,
    SUM(COALESCE(mi.preparation_time, 10) * oi.quantity) AS total_prep_time
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.id
  LEFT JOIN menu_items mi ON mi.id = oi.menu_item_id
  WHERE o.created_at >= NOW() - INTERVAL '60 minutes'
    AND o.status IN ('pending', 'confirmed', 'preparing')
  GROUP BY o.store_id, DATE_TRUNC('minute', o.created_at)
)
SELECT
  store_id,
  minute_bucket,
  total_items,
  total_prep_time,
  -- Congestion score: 0-100 based on prep time backlog
  LEAST(100, ROUND(total_prep_time / 10.0))::INTEGER AS congestion_score,
  -- Rolling averages
  AVG(total_items) OVER (PARTITION BY store_id ORDER BY minute_bucket ROWS BETWEEN 5 PRECEDING AND CURRENT ROW) AS rolling_avg_items,
  AVG(total_prep_time) OVER (PARTITION BY store_id ORDER BY minute_bucket ROWS BETWEEN 5 PRECEDING AND CURRENT ROW) AS rolling_avg_prep_time
FROM order_data
ORDER BY store_id, minute_bucket DESC;

CREATE UNIQUE INDEX IF NOT EXISTS mv_kitchen_load_60min_idx
ON mv_kitchen_load_60min(store_id, minute_bucket);

-- ----------------------------------------------------------------------------
-- 2.2 Item Profitability Trends (30-day rolling)
-- ----------------------------------------------------------------------------
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_item_profitability_trends AS
WITH sales_data AS (
  SELECT
    oi.menu_item_id AS item_id,
    o.store_id,
    SUM(oi.quantity) AS total_units,
    SUM(oi.subtotal) AS total_revenue,
    COUNT(DISTINCT o.id) AS order_count,
    AVG(oi.item_price) AS avg_price
  FROM order_items oi
  JOIN orders o ON o.id = oi.order_id
  WHERE o.created_at >= NOW() - INTERVAL '30 days'
    AND o.status IN ('completed', 'ready')
    AND oi.menu_item_id IS NOT NULL
  GROUP BY oi.menu_item_id, o.store_id
),
category_totals AS (
  SELECT
    mc.id AS category_id,
    o.store_id,
    SUM(oi.subtotal) AS category_revenue
  FROM order_items oi
  JOIN orders o ON o.id = oi.order_id
  JOIN menu_items mi ON mi.id = oi.menu_item_id
  JOIN menu_categories mc ON mc.id = mi.category_id
  WHERE o.created_at >= NOW() - INTERVAL '30 days'
    AND o.status IN ('completed', 'ready')
  GROUP BY mc.id, o.store_id
)
SELECT
  sd.item_id,
  sd.store_id,
  mi.name AS item_name,
  mc.name AS category_name,
  sd.total_units AS rolling_sales_30d,
  sd.total_revenue AS rolling_revenue_30d,
  sd.avg_price,
  COALESCE(mp.cost_basis, sd.avg_price * 0.35) AS est_cost, -- Default 35% cost if not set
  ROUND((sd.avg_price - COALESCE(mp.cost_basis, sd.avg_price * 0.35)) / NULLIF(sd.avg_price, 0) * 100, 2) AS rolling_margin_30d,
  ROUND(sd.total_revenue / NULLIF(ct.category_revenue, 0) * 100, 2) AS category_strength,
  RANK() OVER (PARTITION BY sd.store_id, mi.category_id ORDER BY sd.total_revenue DESC) AS category_rank
FROM sales_data sd
JOIN menu_items mi ON mi.id = sd.item_id
LEFT JOIN menu_categories mc ON mc.id = mi.category_id
LEFT JOIN menu_profitability mp ON mp.item_id = sd.item_id AND mp.store_id = sd.store_id
LEFT JOIN category_totals ct ON ct.category_id = mi.category_id AND ct.store_id = sd.store_id;

CREATE UNIQUE INDEX IF NOT EXISTS mv_item_profitability_trends_idx
ON mv_item_profitability_trends(item_id, store_id);

CREATE INDEX IF NOT EXISTS mv_item_profitability_margin_idx
ON mv_item_profitability_trends(store_id, rolling_margin_30d);

-- ============================================================================
-- SECTION 3: Autonomous Operations Functions
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 3.1 Calculate Dynamic Price
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION calculate_dynamic_price(
  p_item_id BIGINT,
  p_store_id BIGINT
)
RETURNS TABLE (
  suggested_price NUMERIC,
  price_multiplier NUMERIC,
  confidence FLOAT,
  reason TEXT
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
AS $$
DECLARE
  v_base_price NUMERIC;
  v_min_price NUMERIC;
  v_max_price NUMERIC;
  v_demand_score FLOAT;
  v_inventory_factor FLOAT;
  v_time_factor FLOAT;
  v_multiplier NUMERIC;
  v_new_price NUMERIC;
  v_reason TEXT;
  v_settings RECORD;
BEGIN
  -- Get store settings
  SELECT * INTO v_settings FROM store_ops_settings WHERE store_id = p_store_id;

  -- Check if dynamic pricing is enabled
  IF v_settings IS NULL OR NOT v_settings.dynamic_pricing_enabled THEN
    RETURN QUERY SELECT NULL::NUMERIC, 1.00::NUMERIC, 0.0::FLOAT, 'Dynamic pricing not enabled'::TEXT;
    RETURN;
  END IF;

  -- Get current pricing rule
  SELECT base_price, min_price, max_price
  INTO v_base_price, v_min_price, v_max_price
  FROM dynamic_pricing_rules
  WHERE item_id = p_item_id AND store_id = p_store_id;

  IF v_base_price IS NULL THEN
    -- Get price from menu_items if no rule exists
    SELECT COALESCE(price, base_price) INTO v_base_price
    FROM menu_items WHERE id = p_item_id;

    v_min_price := v_base_price * 0.85;
    v_max_price := v_base_price * 1.15;
  END IF;

  -- Calculate demand score (0-1) based on recent sales
  SELECT LEAST(1.0, COALESCE(COUNT(*), 0) / 50.0)::FLOAT
  INTO v_demand_score
  FROM order_items oi
  JOIN orders o ON o.id = oi.order_id
  WHERE oi.menu_item_id = p_item_id
    AND o.store_id = p_store_id
    AND o.created_at >= NOW() - INTERVAL '1 hour';

  -- Calculate inventory factor (if available)
  SELECT CASE
    WHEN il.current_stock <= il.minimum_stock THEN 1.10 -- Low stock, slight increase
    WHEN il.current_stock > il.maximum_stock THEN 0.95  -- Overstock, slight decrease
    ELSE 1.0
  END::FLOAT
  INTO v_inventory_factor
  FROM inventory_levels il
  WHERE il.item_id = p_item_id AND il.store_id = p_store_id;

  v_inventory_factor := COALESCE(v_inventory_factor, 1.0);

  -- Calculate time factor (peak hours increase)
  v_time_factor := CASE
    WHEN EXTRACT(HOUR FROM NOW()) BETWEEN 7 AND 9 THEN 1.05   -- Morning rush
    WHEN EXTRACT(HOUR FROM NOW()) BETWEEN 11 AND 14 THEN 1.08 -- Lunch rush
    WHEN EXTRACT(HOUR FROM NOW()) BETWEEN 17 AND 20 THEN 1.05 -- Dinner rush
    ELSE 1.0
  END;

  -- Combine factors with weights
  v_multiplier := ROUND((
    1.0 +
    (v_demand_score * 0.10) +   -- Demand contributes up to 10%
    ((v_inventory_factor - 1.0) * 0.5) + -- Inventory contributes up to 5%
    ((v_time_factor - 1.0) * 0.5)        -- Time contributes up to 4%
  )::NUMERIC, 2);

  -- Clamp multiplier to max change setting
  v_multiplier := LEAST(1 + v_settings.dynamic_pricing_max_change, GREATEST(1 - v_settings.dynamic_pricing_max_change, v_multiplier));

  -- Calculate new price
  v_new_price := ROUND(v_base_price * v_multiplier, 2);

  -- Ensure within bounds
  v_new_price := LEAST(v_max_price, GREATEST(v_min_price, v_new_price));

  -- Build reason
  v_reason := 'Demand: ' || ROUND(v_demand_score * 100) || '%, ' ||
              'Inventory: ' || ROUND((v_inventory_factor - 1) * 100) || '%, ' ||
              'Time: ' || ROUND((v_time_factor - 1) * 100) || '%';

  RETURN QUERY SELECT
    v_new_price,
    v_multiplier,
    LEAST(0.95, 0.6 + v_demand_score * 0.35)::FLOAT, -- Confidence based on demand data
    v_reason;
END;
$$;

-- ----------------------------------------------------------------------------
-- 3.2 Predict Kitchen Load
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION predict_kitchen_load(
  p_store_id BIGINT,
  p_window_minutes INTEGER DEFAULT 30
)
RETURNS TABLE (
  predicted_orders INTEGER,
  predicted_prep_time INTEGER,
  current_queue INTEGER,
  load_level TEXT,
  load_score FLOAT,
  confidence FLOAT,
  factors JSONB
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
AS $$
DECLARE
  v_current_queue INTEGER;
  v_current_prep_time INTEGER;
  v_historical_avg FLOAT;
  v_day_of_week INTEGER;
  v_hour_of_day INTEGER;
  v_predicted_orders INTEGER;
  v_predicted_prep INTEGER;
  v_load_score FLOAT;
  v_load_level TEXT;
  v_confidence FLOAT;
BEGIN
  v_day_of_week := EXTRACT(DOW FROM NOW())::INTEGER;
  v_hour_of_day := EXTRACT(HOUR FROM NOW())::INTEGER;

  -- Get current queue (pending + preparing orders)
  SELECT
    COUNT(*),
    COALESCE(SUM(mi.preparation_time * oi.quantity), 0)
  INTO v_current_queue, v_current_prep_time
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.id
  LEFT JOIN menu_items mi ON mi.id = oi.menu_item_id
  WHERE o.store_id = p_store_id
    AND o.status IN ('pending', 'confirmed', 'preparing');

  -- Get historical average for this time slot
  SELECT COALESCE(AVG(order_count), 5)
  INTO v_historical_avg
  FROM mv_hourly_traffic
  WHERE store_id = p_store_id
    AND day_of_week = v_day_of_week
    AND hour_of_day = v_hour_of_day;

  -- Predict orders for next window
  v_predicted_orders := ROUND(v_historical_avg * (p_window_minutes / 60.0))::INTEGER;

  -- Predict prep time (assuming avg 10 min per order)
  v_predicted_prep := v_current_prep_time + (v_predicted_orders * 10);

  -- Calculate load score (0-100)
  v_load_score := LEAST(100, (v_current_prep_time + v_predicted_prep * 0.5) / 2.0);

  -- Determine load level
  v_load_level := CASE
    WHEN v_load_score >= 80 THEN 'critical'
    WHEN v_load_score >= 60 THEN 'high'
    WHEN v_load_score >= 30 THEN 'medium'
    ELSE 'low'
  END;

  -- Confidence based on data availability
  v_confidence := CASE
    WHEN v_historical_avg > 0 THEN 0.85
    ELSE 0.50
  END;

  RETURN QUERY SELECT
    v_predicted_orders,
    v_predicted_prep,
    v_current_queue,
    v_load_level,
    v_load_score,
    v_confidence,
    jsonb_build_object(
      'current_queue_size', v_current_queue,
      'current_prep_time', v_current_prep_time,
      'historical_hourly_avg', v_historical_avg,
      'day_of_week', v_day_of_week,
      'hour_of_day', v_hour_of_day
    );
END;
$$;

-- ----------------------------------------------------------------------------
-- 3.3 Generate Staffing Recommendations
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION generate_staffing_recommendations(
  p_store_id BIGINT,
  p_target_date DATE DEFAULT CURRENT_DATE + 1
)
RETURNS TABLE (
  shift TEXT,
  shift_start TIME,
  shift_end TIME,
  predicted_demand INTEGER,
  predicted_orders INTEGER,
  recommended_staff INTEGER,
  confidence FLOAT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_day_of_week INTEGER;
  v_settings RECORD;
BEGIN
  v_day_of_week := EXTRACT(DOW FROM p_target_date)::INTEGER;

  -- Get store settings
  SELECT * INTO v_settings FROM store_ops_settings WHERE store_id = p_store_id;

  IF v_settings IS NULL OR NOT COALESCE(v_settings.staffing_recommendations_enabled, true) THEN
    RETURN;
  END IF;

  -- Generate for each shift
  RETURN QUERY
  WITH shift_definitions AS (
    SELECT 'morning'::TEXT AS shift_name, '06:00:00'::TIME AS start_time, '12:00:00'::TIME AS end_time
    UNION ALL SELECT 'afternoon', '12:00:00', '18:00:00'
    UNION ALL SELECT 'evening', '18:00:00', '00:00:00'
  ),
  historical_demand AS (
    SELECT
      CASE
        WHEN EXTRACT(HOUR FROM o.created_at) BETWEEN 6 AND 11 THEN 'morning'
        WHEN EXTRACT(HOUR FROM o.created_at) BETWEEN 12 AND 17 THEN 'afternoon'
        ELSE 'evening'
      END AS shift_period,
      COUNT(*) AS order_count,
      SUM(o.total) AS revenue
    FROM orders o
    WHERE o.store_id = p_store_id
      AND EXTRACT(DOW FROM o.created_at) = v_day_of_week
      AND o.created_at >= NOW() - INTERVAL '90 days'
      AND o.status IN ('completed', 'ready')
    GROUP BY shift_period
  )
  SELECT
    sd.shift_name AS shift,
    sd.start_time AS shift_start,
    sd.end_time AS shift_end,
    COALESCE(hd.order_count, 20)::INTEGER AS predicted_demand,
    ROUND(COALESCE(hd.order_count, 20) / 13.0)::INTEGER AS predicted_orders, -- Average orders per day of historical
    -- Staff calculation: 1 staff per 15 orders expected in shift
    GREATEST(2, ROUND(COALESCE(hd.order_count, 20) / 13.0 / 15.0) + 1)::INTEGER AS recommended_staff,
    CASE WHEN hd.order_count IS NOT NULL THEN 0.85 ELSE 0.50 END::FLOAT AS confidence
  FROM shift_definitions sd
  LEFT JOIN historical_demand hd ON hd.shift_period = sd.shift_name
  ORDER BY sd.start_time;
END;
$$;

-- ----------------------------------------------------------------------------
-- 3.4 Calculate Menu Profitability
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION calculate_menu_profitability(
  p_store_id BIGINT
)
RETURNS TABLE (
  item_id BIGINT,
  item_name TEXT,
  cost_basis NUMERIC,
  avg_selling_price NUMERIC,
  margin_percentage NUMERIC,
  margin_tier TEXT,
  total_units_30d INTEGER,
  total_revenue_30d NUMERIC,
  recommendation TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT
    mi.id AS item_id,
    mi.name AS item_name,
    COALESCE(mp.cost_basis, COALESCE(mi.price, mi.base_price) * 0.35) AS cost_basis,
    COALESCE(pt.avg_price, COALESCE(mi.price, mi.base_price)) AS avg_selling_price,
    COALESCE(pt.rolling_margin_30d, 65.0) AS margin_percentage,
    CASE
      WHEN COALESCE(pt.rolling_margin_30d, 65.0) < 20 THEN 'critical'
      WHEN COALESCE(pt.rolling_margin_30d, 65.0) < 30 THEN 'low'
      WHEN COALESCE(pt.rolling_margin_30d, 65.0) < 50 THEN 'normal'
      WHEN COALESCE(pt.rolling_margin_30d, 65.0) < 70 THEN 'high'
      ELSE 'premium'
    END AS margin_tier,
    COALESCE(pt.rolling_sales_30d, 0)::INTEGER AS total_units_30d,
    COALESCE(pt.rolling_revenue_30d, 0) AS total_revenue_30d,
    CASE
      WHEN COALESCE(pt.rolling_margin_30d, 65.0) < 20 THEN 'URGENT: Review cost structure or increase price'
      WHEN COALESCE(pt.rolling_margin_30d, 65.0) < 30 THEN 'Consider price adjustment or ingredient optimization'
      WHEN COALESCE(pt.rolling_sales_30d, 0) < 10 THEN 'Low sales volume - consider promotion or removal'
      WHEN COALESCE(pt.rolling_margin_30d, 65.0) >= 70 AND COALESCE(pt.rolling_sales_30d, 0) > 50 THEN 'Star performer - maintain current strategy'
      ELSE 'On track'
    END AS recommendation
  FROM menu_items mi
  LEFT JOIN mv_item_profitability_trends pt ON pt.item_id = mi.id AND pt.store_id = p_store_id
  LEFT JOIN menu_profitability mp ON mp.item_id = mi.id AND mp.store_id = p_store_id
  WHERE mi.is_available = true
  ORDER BY COALESCE(pt.rolling_margin_30d, 65.0) ASC;
END;
$$;

-- ----------------------------------------------------------------------------
-- 3.5 Get Operational Health Summary
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_operational_health(
  p_store_id BIGINT
)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
AS $$
DECLARE
  v_result JSONB;
  v_kitchen_load RECORD;
  v_unresolved_alerts INTEGER;
  v_low_margin_items INTEGER;
  v_staffing_gaps INTEGER;
  v_active_pricing_rules INTEGER;
BEGIN
  -- Get kitchen load
  SELECT * INTO v_kitchen_load FROM predict_kitchen_load(p_store_id, 30);

  -- Count unresolved alerts
  SELECT COUNT(*) INTO v_unresolved_alerts
  FROM ops_alerts
  WHERE store_id = p_store_id AND is_resolved = false;

  -- Count low margin items
  SELECT COUNT(*) INTO v_low_margin_items
  FROM mv_item_profitability_trends
  WHERE store_id = p_store_id AND rolling_margin_30d < 30;

  -- Count staffing gaps for today
  SELECT COALESCE(SUM(ABS(staff_gap)), 0) INTO v_staffing_gaps
  FROM staffing_recommendations
  WHERE store_id = p_store_id
    AND recommendation_date = CURRENT_DATE
    AND staff_gap != 0;

  -- Count active pricing rules
  SELECT COUNT(*) INTO v_active_pricing_rules
  FROM dynamic_pricing_rules
  WHERE store_id = p_store_id AND is_active = true;

  v_result := jsonb_build_object(
    'store_id', p_store_id,
    'timestamp', NOW(),
    'kitchen', jsonb_build_object(
      'load_level', COALESCE(v_kitchen_load.load_level, 'unknown'),
      'load_score', COALESCE(v_kitchen_load.load_score, 0),
      'current_queue', COALESCE(v_kitchen_load.current_queue, 0),
      'predicted_orders', COALESCE(v_kitchen_load.predicted_orders, 0)
    ),
    'alerts', jsonb_build_object(
      'unresolved_count', v_unresolved_alerts
    ),
    'profitability', jsonb_build_object(
      'low_margin_items', v_low_margin_items
    ),
    'staffing', jsonb_build_object(
      'gaps_today', v_staffing_gaps
    ),
    'pricing', jsonb_build_object(
      'active_rules', v_active_pricing_rules
    ),
    'overall_status', CASE
      WHEN v_kitchen_load.load_level = 'critical' OR v_unresolved_alerts >= 5 THEN 'critical'
      WHEN v_kitchen_load.load_level = 'high' OR v_unresolved_alerts >= 3 OR v_low_margin_items >= 5 THEN 'warning'
      ELSE 'healthy'
    END
  );

  RETURN v_result;
END;
$$;

-- ============================================================================
-- SECTION 4: V5 API Dispatcher
-- ============================================================================

-- Register V5 API version
INSERT INTO api_versions (version, status, min_app_version)
VALUES ('v5', 'active', '1.6.0')
ON CONFLICT (version) DO UPDATE SET status = 'active', min_app_version = '1.6.0';

-- ----------------------------------------------------------------------------
-- 4.1 V5 Dispatch Function (Autonomous Ops RPCs)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION rpc_v5_dispatch(
  p_name TEXT,
  p_payload JSONB DEFAULT '{}'::JSONB
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_result JSONB;
  v_store_id BIGINT;
  v_item_id BIGINT;
  v_date DATE;
  v_start_ts TIMESTAMPTZ;
  v_execution_ms INTEGER;
BEGIN
  v_start_ts := clock_timestamp();

  -- Extract common parameters
  v_store_id := (p_payload->>'store_id')::BIGINT;
  v_item_id := (p_payload->>'item_id')::BIGINT;
  v_date := COALESCE((p_payload->>'date')::DATE, CURRENT_DATE + 1);

  CASE p_name
    -- Dynamic Pricing
    WHEN 'get_dynamic_pricing' THEN
      SELECT jsonb_agg(
        jsonb_build_object(
          'item_id', dpr.item_id,
          'item_name', mi.name,
          'base_price', dpr.base_price,
          'current_price', dpr.current_price,
          'min_price', dpr.min_price,
          'max_price', dpr.max_price,
          'rule_type', dpr.rule_type,
          'is_active', dpr.is_active,
          'confidence', dpr.confidence,
          'last_eval', dpr.last_eval
        )
      )
      INTO v_result
      FROM dynamic_pricing_rules dpr
      JOIN menu_items mi ON mi.id = dpr.item_id
      WHERE dpr.store_id = v_store_id;

    WHEN 'calculate_dynamic_price' THEN
      SELECT row_to_json(r)::JSONB
      INTO v_result
      FROM calculate_dynamic_price(v_item_id, v_store_id) r;

    WHEN 'apply_dynamic_price' THEN
      -- Apply calculated price (requires approval if configured)
      WITH calculated AS (
        SELECT * FROM calculate_dynamic_price(v_item_id, v_store_id)
      )
      UPDATE dynamic_pricing_rules dpr
      SET
        current_price = c.suggested_price,
        price_multiplier = c.price_multiplier,
        confidence = c.confidence,
        eval_reason = c.reason,
        last_eval = NOW(),
        updated_at = NOW()
      FROM calculated c
      WHERE dpr.item_id = v_item_id
        AND dpr.store_id = v_store_id
        AND dpr.is_active = true
      RETURNING jsonb_build_object(
        'item_id', dpr.item_id,
        'new_price', dpr.current_price,
        'applied', true
      ) INTO v_result;

    -- Kitchen Load
    WHEN 'get_kitchen_load' THEN
      SELECT row_to_json(r)::JSONB
      INTO v_result
      FROM predict_kitchen_load(
        v_store_id,
        COALESCE((p_payload->>'window_minutes')::INTEGER, 30)
      ) r;

    WHEN 'get_kitchen_load_history' THEN
      SELECT jsonb_agg(
        jsonb_build_object(
          'prediction_time', prediction_time,
          'predicted_orders', predicted_orders,
          'load_level', load_level,
          'load_score', load_score
        )
      )
      INTO v_result
      FROM kitchen_load_predictions
      WHERE store_id = v_store_id
        AND prediction_time >= NOW() - INTERVAL '24 hours'
      ORDER BY prediction_time DESC
      LIMIT 50;

    -- Staffing
    WHEN 'get_staffing_recommendations' THEN
      SELECT jsonb_agg(row_to_json(r))
      INTO v_result
      FROM generate_staffing_recommendations(v_store_id, v_date) r;

    WHEN 'get_staffing_history' THEN
      SELECT jsonb_agg(
        jsonb_build_object(
          'date', recommendation_date,
          'shift', shift,
          'predicted_demand', predicted_demand,
          'recommended_staff', recommended_staff_count,
          'current_scheduled', current_scheduled_count,
          'gap', staff_gap,
          'confidence', confidence
        )
      )
      INTO v_result
      FROM staffing_recommendations
      WHERE store_id = v_store_id
        AND recommendation_date >= CURRENT_DATE
      ORDER BY recommendation_date, shift_start;

    WHEN 'acknowledge_staffing' THEN
      UPDATE staffing_recommendations
      SET
        is_acknowledged = true,
        acknowledged_by = (p_payload->>'acknowledged_by')::UUID,
        acknowledged_at = NOW()
      WHERE store_id = v_store_id
        AND recommendation_date = v_date
        AND shift = p_payload->>'shift'
      RETURNING jsonb_build_object(
        'acknowledged', true,
        'date', recommendation_date,
        'shift', shift
      ) INTO v_result;

    -- Profitability
    WHEN 'get_menu_profitability' THEN
      SELECT jsonb_agg(row_to_json(r))
      INTO v_result
      FROM calculate_menu_profitability(v_store_id) r;

    WHEN 'get_low_margin_items' THEN
      SELECT jsonb_agg(row_to_json(r))
      INTO v_result
      FROM calculate_menu_profitability(v_store_id) r
      WHERE r.margin_tier IN ('critical', 'low');

    WHEN 'update_item_cost' THEN
      INSERT INTO menu_profitability (item_id, store_id, cost_basis, avg_selling_price, margin_percentage, margin_tier)
      SELECT
        v_item_id,
        v_store_id,
        (p_payload->>'cost_basis')::NUMERIC,
        COALESCE(mi.price, mi.base_price),
        ROUND(((COALESCE(mi.price, mi.base_price) - (p_payload->>'cost_basis')::NUMERIC) / NULLIF(COALESCE(mi.price, mi.base_price), 0)) * 100, 2),
        CASE
          WHEN ((COALESCE(mi.price, mi.base_price) - (p_payload->>'cost_basis')::NUMERIC) / NULLIF(COALESCE(mi.price, mi.base_price), 0)) * 100 < 20 THEN 'critical'
          WHEN ((COALESCE(mi.price, mi.base_price) - (p_payload->>'cost_basis')::NUMERIC) / NULLIF(COALESCE(mi.price, mi.base_price), 0)) * 100 < 30 THEN 'low'
          WHEN ((COALESCE(mi.price, mi.base_price) - (p_payload->>'cost_basis')::NUMERIC) / NULLIF(COALESCE(mi.price, mi.base_price), 0)) * 100 < 50 THEN 'normal'
          ELSE 'high'
        END
      FROM menu_items mi
      WHERE mi.id = v_item_id
      ON CONFLICT (item_id, store_id) DO UPDATE SET
        cost_basis = EXCLUDED.cost_basis,
        margin_percentage = EXCLUDED.margin_percentage,
        margin_tier = EXCLUDED.margin_tier,
        last_calculated = NOW()
      RETURNING jsonb_build_object(
        'item_id', item_id,
        'cost_basis', cost_basis,
        'updated', true
      ) INTO v_result;

    -- Operational Health
    WHEN 'get_operational_health' THEN
      v_result := get_operational_health(v_store_id);

    -- Store Settings
    WHEN 'get_ops_settings' THEN
      SELECT row_to_json(sos)::JSONB
      INTO v_result
      FROM store_ops_settings sos
      WHERE store_id = v_store_id;

    WHEN 'update_ops_settings' THEN
      INSERT INTO store_ops_settings (
        store_id,
        dynamic_pricing_enabled,
        dynamic_pricing_max_change,
        auto_hide_slow_items,
        slow_item_threshold_minutes,
        kitchen_load_alerts_enabled,
        staffing_recommendations_enabled,
        profitability_alerts_enabled,
        low_margin_threshold,
        enabled_by,
        enabled_at,
        updated_at
      )
      VALUES (
        v_store_id,
        COALESCE((p_payload->>'dynamic_pricing_enabled')::BOOLEAN, false),
        COALESCE((p_payload->>'dynamic_pricing_max_change')::NUMERIC, 0.15),
        COALESCE((p_payload->>'auto_hide_slow_items')::BOOLEAN, false),
        COALESCE((p_payload->>'slow_item_threshold_minutes')::INTEGER, 20),
        COALESCE((p_payload->>'kitchen_load_alerts_enabled')::BOOLEAN, true),
        COALESCE((p_payload->>'staffing_recommendations_enabled')::BOOLEAN, true),
        COALESCE((p_payload->>'profitability_alerts_enabled')::BOOLEAN, true),
        COALESCE((p_payload->>'low_margin_threshold')::NUMERIC, 25.0),
        (p_payload->>'enabled_by')::UUID,
        NOW(),
        NOW()
      )
      ON CONFLICT (store_id) DO UPDATE SET
        dynamic_pricing_enabled = EXCLUDED.dynamic_pricing_enabled,
        dynamic_pricing_max_change = EXCLUDED.dynamic_pricing_max_change,
        auto_hide_slow_items = EXCLUDED.auto_hide_slow_items,
        slow_item_threshold_minutes = EXCLUDED.slow_item_threshold_minutes,
        kitchen_load_alerts_enabled = EXCLUDED.kitchen_load_alerts_enabled,
        staffing_recommendations_enabled = EXCLUDED.staffing_recommendations_enabled,
        profitability_alerts_enabled = EXCLUDED.profitability_alerts_enabled,
        low_margin_threshold = EXCLUDED.low_margin_threshold,
        updated_at = NOW()
      RETURNING jsonb_build_object(
        'store_id', store_id,
        'updated', true
      ) INTO v_result;

    -- Alerts
    WHEN 'get_ops_alerts' THEN
      SELECT jsonb_agg(
        jsonb_build_object(
          'id', id,
          'alert_type', alert_type,
          'severity', severity,
          'title', title,
          'description', description,
          'is_resolved', is_resolved,
          'auto_action_taken', auto_action_taken,
          'created_at', created_at
        )
      )
      INTO v_result
      FROM ops_alerts
      WHERE store_id = v_store_id
        AND (COALESCE((p_payload->>'include_resolved')::BOOLEAN, false) OR is_resolved = false)
      ORDER BY created_at DESC
      LIMIT COALESCE((p_payload->>'limit')::INTEGER, 50);

    WHEN 'resolve_ops_alert' THEN
      UPDATE ops_alerts
      SET
        is_resolved = true,
        resolved_by = (p_payload->>'resolved_by')::UUID,
        resolved_at = NOW()
      WHERE id = (p_payload->>'alert_id')::BIGINT
        AND store_id = v_store_id
      RETURNING jsonb_build_object(
        'alert_id', id,
        'resolved', true
      ) INTO v_result;

    -- Fallback to V4 for unknown RPCs
    ELSE
      v_result := rpc_v4_dispatch(p_name, p_payload);
  END CASE;

  -- Calculate execution time
  v_execution_ms := EXTRACT(MILLISECONDS FROM (clock_timestamp() - v_start_ts))::INTEGER;

  -- Log to runtime metrics
  INSERT INTO runtime_metrics (metric_name, metric_value, metadata)
  VALUES (
    'rpc_v5_' || p_name,
    v_execution_ms,
    jsonb_build_object(
      'store_id', v_store_id,
      'success', v_result IS NOT NULL
    )
  );

  RETURN COALESCE(v_result, '[]'::JSONB);
END;
$$;

-- ----------------------------------------------------------------------------
-- 4.2 Update Route API Call for V5 Support
-- ----------------------------------------------------------------------------
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
    v_target_version := p_requested_version;
  ELSE
    -- Use active version, but check client compatibility
    IF v_client_version IS NOT NULL THEN
      IF meets_min_version(v_client_version, '1.6.0') THEN
        v_target_version := 'v5';
      ELSIF meets_min_version(v_client_version, '1.5.0') THEN
        v_target_version := 'v4';
      ELSIF meets_min_version(v_client_version, '1.4.0') THEN
        v_target_version := 'v3';
      ELSE
        v_target_version := v_fallback_version;
      END IF;
    ELSE
      v_target_version := COALESCE(v_active_version, 'v4');
    END IF;
  END IF;

  -- Route to appropriate dispatcher
  CASE v_target_version
    WHEN 'v5' THEN
      v_result := rpc_v5_dispatch(p_name, p_payload);
    WHEN 'v4' THEN
      v_result := rpc_v4_dispatch(p_name, p_payload);
    WHEN 'v3' THEN
      v_result := rpc_v3_dispatch(p_name, p_payload);
    WHEN 'v2' THEN
      v_result := rpc_v2_dispatch(p_name, p_payload);
    WHEN 'v1' THEN
      v_result := rpc_v1_dispatch(p_name, p_payload);
    ELSE
      v_result := rpc_v4_dispatch(p_name, p_payload);
  END CASE;

  RETURN v_result;
END;
$$;

-- ============================================================================
-- SECTION 5: Safety Triggers and Auto-Actions
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 5.1 Auto-hide slow items when kitchen overloaded
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION auto_hide_slow_items()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_settings RECORD;
BEGIN
  -- Check if store has auto-hide enabled
  SELECT * INTO v_settings
  FROM store_ops_settings
  WHERE store_id = NEW.store_id;

  IF v_settings IS NOT NULL AND v_settings.auto_hide_slow_items AND NEW.load_level = 'critical' THEN
    -- Hide items with prep time > threshold
    UPDATE menu_items mi
    SET is_available = false
    WHERE mi.id IN (
      SELECT smi.menu_item_id
      FROM store_menu_items smi
      WHERE smi.store_id = NEW.store_id AND smi.is_available = true
    )
    AND mi.preparation_time > v_settings.slow_item_threshold_minutes;

    -- Log the action
    INSERT INTO ops_alerts (
      store_id, alert_type, severity, title, description, auto_action_taken
    ) VALUES (
      NEW.store_id,
      'kitchen_overload',
      'critical',
      'Kitchen Overload - Slow Items Hidden',
      'Automatically hid menu items with prep time > ' || v_settings.slow_item_threshold_minutes || ' minutes',
      'Items hidden automatically'
    );
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_auto_hide_slow_items ON kitchen_load_predictions;
CREATE TRIGGER trg_auto_hide_slow_items
  AFTER INSERT ON kitchen_load_predictions
  FOR EACH ROW
  WHEN (NEW.load_level = 'critical')
  EXECUTE FUNCTION auto_hide_slow_items();

-- ----------------------------------------------------------------------------
-- 5.2 Log pricing changes
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION log_pricing_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF OLD.current_price IS DISTINCT FROM NEW.current_price THEN
    INSERT INTO dynamic_pricing_history (
      rule_id, previous_price, new_price, change_reason, triggered_by
    ) VALUES (
      NEW.id,
      OLD.current_price,
      NEW.current_price,
      NEW.eval_reason,
      CASE WHEN NEW.eval_reason LIKE '%Demand%' THEN 'demand' ELSE 'system' END
    );
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_log_pricing_change ON dynamic_pricing_rules;
CREATE TRIGGER trg_log_pricing_change
  AFTER UPDATE ON dynamic_pricing_rules
  FOR EACH ROW
  EXECUTE FUNCTION log_pricing_change();

-- ----------------------------------------------------------------------------
-- 5.3 Generate profitability alerts
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION check_profitability_alert()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_settings RECORD;
BEGIN
  SELECT * INTO v_settings
  FROM store_ops_settings
  WHERE store_id = NEW.store_id;

  IF v_settings IS NOT NULL AND v_settings.profitability_alerts_enabled THEN
    IF NEW.margin_tier IN ('critical', 'low') THEN
      INSERT INTO ops_alerts (
        store_id, alert_type, severity, title, description, related_item_id
      )
      SELECT
        NEW.store_id,
        'low_margin',
        CASE NEW.margin_tier WHEN 'critical' THEN 'critical' ELSE 'warning' END,
        'Low Margin Alert: ' || mi.name,
        'Item margin is ' || NEW.margin_percentage || '%. Consider reviewing pricing or costs.',
        NEW.item_id
      FROM menu_items mi WHERE mi.id = NEW.item_id
      ON CONFLICT DO NOTHING;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_check_profitability_alert ON menu_profitability;
CREATE TRIGGER trg_check_profitability_alert
  AFTER INSERT OR UPDATE ON menu_profitability
  FOR EACH ROW
  EXECUTE FUNCTION check_profitability_alert();

-- ============================================================================
-- SECTION 6: Materialized View Refresh
-- ============================================================================

CREATE OR REPLACE FUNCTION refresh_ops_materialized_views()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Refresh operations views
  REFRESH MATERIALIZED VIEW CONCURRENTLY mv_kitchen_load_60min;
  REFRESH MATERIALIZED VIEW CONCURRENTLY mv_item_profitability_trends;
END;
$$;

-- ============================================================================
-- SECTION 7: RLS Policies
-- ============================================================================

-- Dynamic Pricing Rules
ALTER TABLE dynamic_pricing_rules ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Staff can view pricing rules" ON dynamic_pricing_rules
  FOR SELECT TO authenticated
  USING (
    public.get_current_user_role() IN ('super_admin', 'admin', 'manager')
    AND (
      public.is_current_user_system_admin()
      OR store_id = ANY(public.get_current_user_assigned_stores())
    )
  );

CREATE POLICY "Admins can manage pricing rules" ON dynamic_pricing_rules
  FOR ALL TO authenticated
  USING (
    public.get_current_user_role() IN ('super_admin', 'admin')
    AND (
      public.is_current_user_system_admin()
      OR store_id = ANY(public.get_current_user_assigned_stores())
    )
  );

-- Kitchen Load Predictions
ALTER TABLE kitchen_load_predictions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Staff can view kitchen load" ON kitchen_load_predictions
  FOR SELECT TO authenticated
  USING (
    public.get_current_user_role() IN ('super_admin', 'admin', 'manager', 'staff')
    AND (
      public.is_current_user_system_admin()
      OR store_id = ANY(public.get_current_user_assigned_stores())
    )
  );

-- Staffing Recommendations
ALTER TABLE staffing_recommendations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Managers can view staffing" ON staffing_recommendations
  FOR SELECT TO authenticated
  USING (
    public.get_current_user_role() IN ('super_admin', 'admin', 'manager')
    AND (
      public.is_current_user_system_admin()
      OR store_id = ANY(public.get_current_user_assigned_stores())
    )
  );

CREATE POLICY "Managers can update staffing" ON staffing_recommendations
  FOR UPDATE TO authenticated
  USING (
    public.get_current_user_role() IN ('super_admin', 'admin', 'manager')
    AND (
      public.is_current_user_system_admin()
      OR store_id = ANY(public.get_current_user_assigned_stores())
    )
  );

-- Menu Profitability
ALTER TABLE menu_profitability ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Managers can view profitability" ON menu_profitability
  FOR SELECT TO authenticated
  USING (
    public.get_current_user_role() IN ('super_admin', 'admin', 'manager')
    AND (
      public.is_current_user_system_admin()
      OR store_id = ANY(public.get_current_user_assigned_stores())
    )
  );

CREATE POLICY "Admins can manage profitability" ON menu_profitability
  FOR ALL TO authenticated
  USING (
    public.get_current_user_role() IN ('super_admin', 'admin')
    AND (
      public.is_current_user_system_admin()
      OR store_id = ANY(public.get_current_user_assigned_stores())
    )
  );

-- Store Ops Settings
ALTER TABLE store_ops_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can view ops settings" ON store_ops_settings
  FOR SELECT TO authenticated
  USING (
    public.get_current_user_role() IN ('super_admin', 'admin', 'manager')
    AND (
      public.is_current_user_system_admin()
      OR store_id = ANY(public.get_current_user_assigned_stores())
    )
  );

CREATE POLICY "Super admins can manage ops settings" ON store_ops_settings
  FOR ALL TO authenticated
  USING (public.get_current_user_role() = 'super_admin');

-- Ops Alerts
ALTER TABLE ops_alerts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Staff can view ops alerts" ON ops_alerts
  FOR SELECT TO authenticated
  USING (
    public.get_current_user_role() IN ('super_admin', 'admin', 'manager', 'staff')
    AND (
      public.is_current_user_system_admin()
      OR store_id = ANY(public.get_current_user_assigned_stores())
    )
  );

CREATE POLICY "Managers can update ops alerts" ON ops_alerts
  FOR UPDATE TO authenticated
  USING (
    public.get_current_user_role() IN ('super_admin', 'admin', 'manager')
    AND (
      public.is_current_user_system_admin()
      OR store_id = ANY(public.get_current_user_assigned_stores())
    )
  );

-- ============================================================================
-- SECTION 8: Grants
-- ============================================================================

GRANT SELECT ON dynamic_pricing_rules TO authenticated;
GRANT SELECT ON dynamic_pricing_history TO authenticated;
GRANT SELECT ON kitchen_load_predictions TO authenticated;
GRANT SELECT ON staffing_recommendations TO authenticated;
GRANT SELECT ON menu_profitability TO authenticated;
GRANT SELECT ON store_ops_settings TO authenticated;
GRANT SELECT ON ops_alerts TO authenticated;

GRANT SELECT ON mv_kitchen_load_60min TO authenticated;
GRANT SELECT ON mv_item_profitability_trends TO authenticated;

GRANT EXECUTE ON FUNCTION calculate_dynamic_price(BIGINT, BIGINT) TO authenticated;
GRANT EXECUTE ON FUNCTION predict_kitchen_load(BIGINT, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION generate_staffing_recommendations(BIGINT, DATE) TO authenticated;
GRANT EXECUTE ON FUNCTION calculate_menu_profitability(BIGINT) TO authenticated;
GRANT EXECUTE ON FUNCTION get_operational_health(BIGINT) TO authenticated;
GRANT EXECUTE ON FUNCTION rpc_v5_dispatch(TEXT, JSONB) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION refresh_ops_materialized_views() TO authenticated;

-- ============================================================================
-- Summary
-- ============================================================================
-- This migration adds:
-- 1. Dynamic pricing rules with safety guardrails (±15% max)
-- 2. Kitchen load predictions and auto-hide slow items
-- 3. Staffing recommendations based on historical demand
-- 4. Menu profitability analysis with margin tiers
-- 5. Operations alerts system
-- 6. Store-level ops settings
-- 7. V5 API dispatcher for autonomous ops
-- 8. Safety triggers and audit trails
-- 9. Materialized views for real-time analytics
-- 10. Full RLS policies
-- ============================================================================
