-- @requires_version: 1.4.0
-- @affects: customer, business, web
-- @breaking: false
-- @description: AI Infrastructure for Menu Engine, Demand Forecasting, and Inventory Intelligence

-- ============================================================================
-- Migration 067: AI Infrastructure
-- ============================================================================
-- Adds support for:
-- - Customer taste profiles with embeddings
-- - Menu item embeddings for semantic search
-- - Inventory levels and tracking
-- - Demand forecasting tables
-- - AI-powered RPC functions (V4 dispatcher)
-- - Materialized views for demand analytics
-- - Auto-update triggers for inventory
-- ============================================================================

-- Enable pgvector extension for embedding support
CREATE EXTENSION IF NOT EXISTS vector;

-- ============================================================================
-- SECTION 1: AI Core Tables
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1.1 Customer Taste Profile (stores customer preferences as embeddings)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS customer_taste_profile (
  customer_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  embedding VECTOR(1536),
  favorite_categories TEXT[],
  dietary_preferences JSONB DEFAULT '[]'::JSONB,
  flavor_preferences JSONB DEFAULT '{}'::JSONB,
  order_history_summary JSONB DEFAULT '{}'::JSONB,
  last_updated TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for vector similarity search
CREATE INDEX IF NOT EXISTS idx_customer_taste_embedding
ON customer_taste_profile USING ivfflat (embedding vector_l2_ops)
WITH (lists = 100);

CREATE INDEX IF NOT EXISTS idx_customer_taste_categories
ON customer_taste_profile USING GIN (favorite_categories);

-- ----------------------------------------------------------------------------
-- 1.2 Menu Item Embeddings (semantic representations of menu items)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS menu_item_embedding (
  item_id BIGINT PRIMARY KEY REFERENCES menu_items(id) ON DELETE CASCADE,
  embedding VECTOR(1536),
  category TEXT,
  tags TEXT[],
  semantic_description TEXT,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for vector similarity search
CREATE INDEX IF NOT EXISTS idx_menu_item_embedding
ON menu_item_embedding USING ivfflat (embedding vector_l2_ops)
WITH (lists = 100);

CREATE INDEX IF NOT EXISTS idx_menu_item_embedding_category
ON menu_item_embedding(category);

-- ----------------------------------------------------------------------------
-- 1.3 Inventory Levels (real-time stock tracking per store)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS inventory_levels (
  id BIGSERIAL,
  store_id BIGINT REFERENCES stores(id) ON DELETE CASCADE,
  item_id BIGINT REFERENCES menu_items(id) ON DELETE CASCADE,
  ingredient_name TEXT,
  current_stock INTEGER DEFAULT 0,
  minimum_stock INTEGER DEFAULT 10,
  maximum_stock INTEGER DEFAULT 100,
  unit_type TEXT DEFAULT 'units' CHECK (unit_type IN ('units', 'lbs', 'oz', 'gallons', 'each')),
  cost_per_unit DECIMAL(10, 2),
  supplier_name TEXT,
  reorder_point INTEGER DEFAULT 15,
  auto_reorder BOOLEAN DEFAULT false,
  last_restock_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (store_id, item_id)
);

CREATE INDEX IF NOT EXISTS idx_inventory_store ON inventory_levels(store_id);
CREATE INDEX IF NOT EXISTS idx_inventory_low_stock ON inventory_levels(store_id, current_stock)
  WHERE current_stock <= minimum_stock;

-- ----------------------------------------------------------------------------
-- 1.4 Demand Forecast (AI predictions for future demand)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS demand_forecast (
  id BIGSERIAL,
  store_id BIGINT REFERENCES stores(id) ON DELETE CASCADE,
  item_id BIGINT REFERENCES menu_items(id) ON DELETE CASCADE,
  forecast_date DATE NOT NULL,
  predicted_quantity INTEGER NOT NULL,
  confidence FLOAT CHECK (confidence >= 0 AND confidence <= 1),
  prediction_factors JSONB DEFAULT '[]'::JSONB,
  actual_quantity INTEGER,
  model_version TEXT DEFAULT 'v1',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (store_id, item_id, forecast_date)
);

CREATE INDEX IF NOT EXISTS idx_demand_forecast_store_date
ON demand_forecast(store_id, forecast_date);

CREATE INDEX IF NOT EXISTS idx_demand_forecast_item
ON demand_forecast(item_id, forecast_date);

-- ----------------------------------------------------------------------------
-- 1.5 AI Recommendations Log (tracking what AI suggested)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS ai_recommendations_log (
  id BIGSERIAL PRIMARY KEY,
  customer_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  store_id BIGINT REFERENCES stores(id) ON DELETE SET NULL,
  recommendation_type TEXT NOT NULL CHECK (recommendation_type IN (
    'personalized_menu', 'upsell', 'substitute', 'restock', 'promotion', 'staffing'
  )),
  recommended_items BIGINT[],
  reasoning TEXT,
  was_accepted BOOLEAN,
  response_time_ms INTEGER,
  model_used TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ai_recommendations_customer
ON ai_recommendations_log(customer_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_ai_recommendations_type
ON ai_recommendations_log(recommendation_type, created_at DESC);

-- ----------------------------------------------------------------------------
-- 1.6 Inventory Alerts (low stock notifications)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS inventory_alerts (
  id BIGSERIAL PRIMARY KEY,
  store_id BIGINT REFERENCES stores(id) ON DELETE CASCADE,
  item_id BIGINT REFERENCES menu_items(id) ON DELETE CASCADE,
  alert_type TEXT NOT NULL CHECK (alert_type IN ('low_stock', 'out_of_stock', 'expiring_soon', 'overstock')),
  current_level INTEGER,
  threshold_level INTEGER,
  severity TEXT DEFAULT 'warning' CHECK (severity IN ('info', 'warning', 'critical')),
  is_resolved BOOLEAN DEFAULT false,
  resolved_at TIMESTAMPTZ,
  resolved_by UUID,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_inventory_alerts_store
ON inventory_alerts(store_id, is_resolved, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_inventory_alerts_unresolved
ON inventory_alerts(store_id) WHERE is_resolved = false;

-- ============================================================================
-- SECTION 2: Materialized Views for Demand Forecasting
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 2.1 Item Sales Last 90 Days (for trend analysis)
-- ----------------------------------------------------------------------------
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_item_sales_last_90_days AS
SELECT
  oi.menu_item_id AS item_id,
  o.store_id,
  DATE(o.created_at) AS sale_date,
  SUM(oi.quantity) AS quantity_sold,
  COUNT(DISTINCT o.id) AS order_count,
  SUM(oi.subtotal) AS revenue,
  AVG(oi.quantity) AS avg_quantity_per_order,
  EXTRACT(DOW FROM o.created_at) AS day_of_week,
  EXTRACT(HOUR FROM o.created_at) AS hour_of_day
FROM order_items oi
JOIN orders o ON o.id = oi.order_id
WHERE o.created_at >= NOW() - INTERVAL '90 days'
  AND o.status IN ('completed', 'ready', 'preparing')
  AND oi.menu_item_id IS NOT NULL
GROUP BY oi.menu_item_id, o.store_id, DATE(o.created_at),
         EXTRACT(DOW FROM o.created_at), EXTRACT(HOUR FROM o.created_at);

CREATE UNIQUE INDEX IF NOT EXISTS mv_item_sales_90d_unique
ON mv_item_sales_last_90_days (item_id, store_id, sale_date, day_of_week, hour_of_day);

CREATE INDEX IF NOT EXISTS mv_item_sales_90d_store
ON mv_item_sales_last_90_days (store_id, sale_date);

-- ----------------------------------------------------------------------------
-- 2.2 Daily Store Demand (aggregated daily patterns)
-- ----------------------------------------------------------------------------
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_daily_store_demand AS
SELECT
  item_id,
  store_id,
  day_of_week,
  ROUND(AVG(quantity_sold), 2) AS daily_avg,
  ROUND(STDDEV(quantity_sold), 2) AS daily_stddev,
  MAX(quantity_sold) AS daily_max,
  MIN(quantity_sold) AS daily_min,
  COUNT(*) AS sample_days,
  -- Seasonal multiplier based on recent vs historical average
  CASE
    WHEN COUNT(*) >= 7 THEN
      ROUND(
        (SELECT AVG(quantity_sold) FROM mv_item_sales_last_90_days sub
         WHERE sub.item_id = mv_item_sales_last_90_days.item_id
         AND sub.store_id = mv_item_sales_last_90_days.store_id
         AND sub.sale_date >= NOW() - INTERVAL '14 days') /
        NULLIF(AVG(quantity_sold), 0), 2
      )
    ELSE 1.0
  END AS seasonal_multiplier,
  -- 30-day weighted trend (more recent = higher weight)
  ROUND(
    SUM(quantity_sold * (1.0 + (EXTRACT(EPOCH FROM (sale_date - (CURRENT_DATE - INTERVAL '90 days'))) / 7776000.0)))
    / NULLIF(SUM(1.0 + (EXTRACT(EPOCH FROM (sale_date - (CURRENT_DATE - INTERVAL '90 days'))) / 7776000.0)), 0)
  , 2) AS weighted_trend
FROM mv_item_sales_last_90_days
GROUP BY item_id, store_id, day_of_week;

CREATE UNIQUE INDEX IF NOT EXISTS mv_daily_demand_unique
ON mv_daily_store_demand (item_id, store_id, day_of_week);

CREATE INDEX IF NOT EXISTS mv_daily_demand_store
ON mv_daily_store_demand (store_id);

-- ----------------------------------------------------------------------------
-- 2.3 Hourly Demand Patterns
-- ----------------------------------------------------------------------------
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_hourly_demand_patterns AS
SELECT
  item_id,
  store_id,
  hour_of_day::INTEGER,
  day_of_week::INTEGER,
  ROUND(AVG(quantity_sold), 2) AS avg_quantity,
  COUNT(*) AS occurrences,
  ROUND(SUM(revenue), 2) AS total_revenue
FROM mv_item_sales_last_90_days
GROUP BY item_id, store_id, hour_of_day, day_of_week;

CREATE UNIQUE INDEX IF NOT EXISTS mv_hourly_patterns_unique
ON mv_hourly_demand_patterns (item_id, store_id, hour_of_day, day_of_week);

-- ----------------------------------------------------------------------------
-- 2.4 Item Affinity (items frequently purchased together)
-- ----------------------------------------------------------------------------
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_item_affinity AS
SELECT
  a.menu_item_id AS item_a,
  b.menu_item_id AS item_b,
  o.store_id,
  COUNT(*) AS co_occurrence_count,
  COUNT(DISTINCT o.id) AS order_count
FROM order_items a
JOIN order_items b ON a.order_id = b.order_id AND a.menu_item_id < b.menu_item_id
JOIN orders o ON o.id = a.order_id
WHERE o.created_at >= NOW() - INTERVAL '90 days'
  AND o.status IN ('completed', 'ready')
GROUP BY a.menu_item_id, b.menu_item_id, o.store_id
HAVING COUNT(*) >= 3;

CREATE UNIQUE INDEX IF NOT EXISTS mv_item_affinity_unique
ON mv_item_affinity (item_a, item_b, store_id);

CREATE INDEX IF NOT EXISTS mv_item_affinity_item_a
ON mv_item_affinity (item_a, store_id);

-- ============================================================================
-- SECTION 3: AI Helper Functions
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 3.1 Get Similar Items (vector similarity search)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_similar_items(
  p_item_id BIGINT,
  p_limit INTEGER DEFAULT 5,
  p_threshold FLOAT DEFAULT 0.8
)
RETURNS TABLE (
  item_id BIGINT,
  name TEXT,
  category TEXT,
  price DECIMAL,
  similarity FLOAT
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
AS $$
DECLARE
  v_embedding VECTOR(1536);
BEGIN
  -- Get the embedding for the source item
  SELECT embedding INTO v_embedding
  FROM menu_item_embedding
  WHERE menu_item_embedding.item_id = p_item_id;

  IF v_embedding IS NULL THEN
    RETURN;
  END IF;

  -- Find similar items using cosine similarity
  RETURN QUERY
  SELECT
    m.id AS item_id,
    m.name,
    m.category_id::TEXT AS category,
    COALESCE(m.price, m.base_price) AS price,
    (1 - (e.embedding <=> v_embedding))::FLOAT AS similarity
  FROM menu_item_embedding e
  JOIN menu_items m ON m.id = e.item_id
  WHERE e.item_id != p_item_id
    AND m.is_available = true
    AND (1 - (e.embedding <=> v_embedding)) >= p_threshold
  ORDER BY e.embedding <=> v_embedding
  LIMIT p_limit;
END;
$$;

-- ----------------------------------------------------------------------------
-- 3.2 Get Personalized Recommendations
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_personalized_recommendations(
  p_customer_id UUID,
  p_store_id BIGINT DEFAULT NULL,
  p_limit INTEGER DEFAULT 10
)
RETURNS TABLE (
  item_id BIGINT,
  name TEXT,
  category TEXT,
  price DECIMAL,
  relevance_score FLOAT,
  reason TEXT
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
AS $$
DECLARE
  v_customer_embedding VECTOR(1536);
  v_favorite_categories TEXT[];
BEGIN
  -- Get customer profile
  SELECT embedding, favorite_categories
  INTO v_customer_embedding, v_favorite_categories
  FROM customer_taste_profile
  WHERE customer_id = p_customer_id;

  -- If customer has embedding, use vector search
  IF v_customer_embedding IS NOT NULL THEN
    RETURN QUERY
    SELECT
      m.id AS item_id,
      m.name,
      mc.name AS category,
      COALESCE(m.price, m.base_price) AS price,
      (1 - (e.embedding <=> v_customer_embedding))::FLOAT AS relevance_score,
      'Based on your taste profile' AS reason
    FROM menu_item_embedding e
    JOIN menu_items m ON m.id = e.item_id
    LEFT JOIN menu_categories mc ON mc.id = m.category_id
    WHERE m.is_available = true
      AND (p_store_id IS NULL OR EXISTS (
        SELECT 1 FROM store_menu_items sm
        WHERE sm.store_id = p_store_id AND sm.menu_item_id = m.id AND sm.is_available = true
      ))
    ORDER BY e.embedding <=> v_customer_embedding
    LIMIT p_limit;
  -- If customer has favorite categories, recommend from those
  ELSIF v_favorite_categories IS NOT NULL AND array_length(v_favorite_categories, 1) > 0 THEN
    RETURN QUERY
    SELECT
      m.id AS item_id,
      m.name,
      mc.name AS category,
      COALESCE(m.price, m.base_price) AS price,
      0.7::FLOAT AS relevance_score,
      'Popular in categories you like' AS reason
    FROM menu_items m
    LEFT JOIN menu_categories mc ON mc.id = m.category_id
    WHERE m.is_available = true
      AND mc.name = ANY(v_favorite_categories)
    ORDER BY m.is_featured DESC, RANDOM()
    LIMIT p_limit;
  -- Fallback to popular items
  ELSE
    RETURN QUERY
    SELECT
      m.id AS item_id,
      m.name,
      mc.name AS category,
      COALESCE(m.price, m.base_price) AS price,
      COALESCE(p.order_count::FLOAT / 100, 0.5)::FLOAT AS relevance_score,
      'Popular with other customers' AS reason
    FROM menu_items m
    LEFT JOIN menu_categories mc ON mc.id = m.category_id
    LEFT JOIN mv_popular_items p ON p.menu_item_id = m.id
    WHERE m.is_available = true
    ORDER BY COALESCE(p.order_count, 0) DESC, m.is_featured DESC
    LIMIT p_limit;
  END IF;
END;
$$;

-- ----------------------------------------------------------------------------
-- 3.3 Predict Inventory Needs
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION predict_inventory_needs(
  p_store_id BIGINT,
  p_days_ahead INTEGER DEFAULT 7
)
RETURNS TABLE (
  item_id BIGINT,
  item_name TEXT,
  current_stock INTEGER,
  predicted_demand INTEGER,
  days_until_stockout INTEGER,
  recommended_reorder INTEGER,
  confidence FLOAT,
  priority TEXT
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  WITH demand_prediction AS (
    SELECT
      d.item_id,
      ROUND(d.daily_avg * d.seasonal_multiplier * p_days_ahead)::INTEGER AS predicted_demand,
      d.daily_avg,
      COALESCE(d.seasonal_multiplier, 1.0) AS multiplier
    FROM mv_daily_store_demand d
    WHERE d.store_id = p_store_id
      AND d.day_of_week = EXTRACT(DOW FROM CURRENT_DATE)
  )
  SELECT
    m.id AS item_id,
    m.name AS item_name,
    COALESCE(i.current_stock, 0)::INTEGER AS current_stock,
    COALESCE(dp.predicted_demand, 10)::INTEGER AS predicted_demand,
    CASE
      WHEN COALESCE(dp.daily_avg, 1) > 0
      THEN FLOOR(COALESCE(i.current_stock, 0) / dp.daily_avg)::INTEGER
      ELSE 30
    END AS days_until_stockout,
    GREATEST(
      COALESCE(i.minimum_stock, 10) + COALESCE(dp.predicted_demand, 10) - COALESCE(i.current_stock, 0),
      0
    )::INTEGER AS recommended_reorder,
    CASE
      WHEN dp.daily_avg IS NOT NULL THEN 0.85
      ELSE 0.5
    END::FLOAT AS confidence,
    CASE
      WHEN COALESCE(i.current_stock, 0) <= COALESCE(i.minimum_stock, 10) THEN 'critical'
      WHEN COALESCE(i.current_stock, 0) <= COALESCE(i.reorder_point, 15) THEN 'high'
      WHEN COALESCE(i.current_stock, 0) <= COALESCE(i.minimum_stock, 10) * 2 THEN 'medium'
      ELSE 'low'
    END AS priority
  FROM menu_items m
  LEFT JOIN inventory_levels i ON i.item_id = m.id AND i.store_id = p_store_id
  LEFT JOIN demand_prediction dp ON dp.item_id = m.id
  WHERE m.is_available = true
  ORDER BY
    CASE
      WHEN COALESCE(i.current_stock, 0) <= COALESCE(i.minimum_stock, 10) THEN 1
      WHEN COALESCE(i.current_stock, 0) <= COALESCE(i.reorder_point, 15) THEN 2
      ELSE 3
    END,
    COALESCE(dp.predicted_demand, 0) DESC;
END;
$$;

-- ----------------------------------------------------------------------------
-- 3.4 Get Top Sellers Predicted
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_top_sellers_predicted(
  p_store_id BIGINT,
  p_days_ahead INTEGER DEFAULT 7,
  p_limit INTEGER DEFAULT 10
)
RETURNS TABLE (
  item_id BIGINT,
  item_name TEXT,
  category TEXT,
  predicted_quantity INTEGER,
  predicted_revenue DECIMAL,
  confidence FLOAT,
  trend TEXT
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  WITH recent_trend AS (
    SELECT
      item_id,
      ROUND(AVG(quantity_sold))::INTEGER AS recent_avg,
      COUNT(*)::INTEGER AS data_points
    FROM mv_item_sales_last_90_days
    WHERE store_id = p_store_id
      AND sale_date >= CURRENT_DATE - INTERVAL '14 days'
    GROUP BY item_id
  ),
  historical_avg AS (
    SELECT
      item_id,
      ROUND(AVG(quantity_sold))::INTEGER AS historical_avg
    FROM mv_item_sales_last_90_days
    WHERE store_id = p_store_id
      AND sale_date < CURRENT_DATE - INTERVAL '14 days'
    GROUP BY item_id
  )
  SELECT
    m.id AS item_id,
    m.name AS item_name,
    mc.name AS category,
    (COALESCE(rt.recent_avg, 5) * p_days_ahead)::INTEGER AS predicted_quantity,
    (COALESCE(rt.recent_avg, 5) * p_days_ahead * COALESCE(m.price, m.base_price))::DECIMAL AS predicted_revenue,
    CASE
      WHEN rt.data_points >= 10 THEN 0.9
      WHEN rt.data_points >= 5 THEN 0.75
      ELSE 0.5
    END::FLOAT AS confidence,
    CASE
      WHEN COALESCE(ha.historical_avg, rt.recent_avg) = 0 THEN 'new'
      WHEN rt.recent_avg > COALESCE(ha.historical_avg, rt.recent_avg) * 1.1 THEN 'rising'
      WHEN rt.recent_avg < COALESCE(ha.historical_avg, rt.recent_avg) * 0.9 THEN 'declining'
      ELSE 'stable'
    END AS trend
  FROM menu_items m
  LEFT JOIN menu_categories mc ON mc.id = m.category_id
  LEFT JOIN recent_trend rt ON rt.item_id = m.id
  LEFT JOIN historical_avg ha ON ha.item_id = m.id
  WHERE m.is_available = true
  ORDER BY COALESCE(rt.recent_avg, 0) DESC
  LIMIT p_limit;
END;
$$;

-- ----------------------------------------------------------------------------
-- 3.5 Get Substitute Items (when out of stock)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_substitute_items(
  p_item_id BIGINT,
  p_store_id BIGINT DEFAULT NULL,
  p_limit INTEGER DEFAULT 3
)
RETURNS TABLE (
  item_id BIGINT,
  name TEXT,
  price DECIMAL,
  similarity_score FLOAT,
  in_stock BOOLEAN,
  reason TEXT
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
AS $$
DECLARE
  v_category_id BIGINT;
  v_price DECIMAL;
BEGIN
  -- Get source item details
  SELECT category_id, COALESCE(price, base_price)
  INTO v_category_id, v_price
  FROM menu_items
  WHERE id = p_item_id;

  RETURN QUERY
  SELECT
    m.id AS item_id,
    m.name,
    COALESCE(m.price, m.base_price) AS price,
    CASE
      WHEN e_src.embedding IS NOT NULL AND e_tgt.embedding IS NOT NULL
      THEN (1 - (e_src.embedding <=> e_tgt.embedding))::FLOAT
      ELSE 0.5 + (1 - ABS(COALESCE(m.price, m.base_price) - v_price) / GREATEST(v_price, 1)) * 0.3
    END AS similarity_score,
    COALESCE(i.current_stock, 100) > COALESCE(i.minimum_stock, 10) AS in_stock,
    CASE
      WHEN m.category_id = v_category_id THEN 'Same category'
      WHEN ABS(COALESCE(m.price, m.base_price) - v_price) < 2 THEN 'Similar price point'
      ELSE 'Similar item'
    END AS reason
  FROM menu_items m
  LEFT JOIN menu_item_embedding e_src ON e_src.item_id = p_item_id
  LEFT JOIN menu_item_embedding e_tgt ON e_tgt.item_id = m.id
  LEFT JOIN inventory_levels i ON i.item_id = m.id AND i.store_id = p_store_id
  WHERE m.id != p_item_id
    AND m.is_available = true
    AND (
      m.category_id = v_category_id
      OR ABS(COALESCE(m.price, m.base_price) - v_price) < 5
    )
    AND COALESCE(i.current_stock, 100) > COALESCE(i.minimum_stock, 10)
  ORDER BY
    CASE WHEN m.category_id = v_category_id THEN 0 ELSE 1 END,
    ABS(COALESCE(m.price, m.base_price) - v_price)
  LIMIT p_limit;
END;
$$;

-- ============================================================================
-- SECTION 4: V4 API Dispatcher
-- ============================================================================

-- Register V4 API version
INSERT INTO api_versions (version, status, min_app_version)
VALUES ('v4', 'active', '1.5.0')
ON CONFLICT (version) DO UPDATE SET status = 'active', min_app_version = '1.5.0';

-- ----------------------------------------------------------------------------
-- 4.1 V4 Dispatch Function (AI-focused RPCs)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION rpc_v4_dispatch(
  p_name TEXT,
  p_payload JSONB DEFAULT '{}'::JSONB
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_result JSONB;
  v_customer_id UUID;
  v_store_id BIGINT;
  v_item_id BIGINT;
  v_start_ts TIMESTAMPTZ;
  v_execution_ms INTEGER;
BEGIN
  v_start_ts := clock_timestamp();

  -- Extract common parameters
  v_customer_id := (p_payload->>'customer_id')::UUID;
  v_store_id := (p_payload->>'store_id')::BIGINT;
  v_item_id := (p_payload->>'item_id')::BIGINT;

  CASE p_name
    -- AI Menu & Recommendations
    WHEN 'get_smart_menu' THEN
      WITH recommendations AS (
        SELECT * FROM get_personalized_recommendations(
          v_customer_id,
          v_store_id,
          COALESCE((p_payload->>'limit')::INTEGER, 20)
        )
      ),
      menu_data AS (
        SELECT
          m.id,
          m.name,
          m.description,
          COALESCE(m.price, m.base_price) AS price,
          mc.name AS category,
          m.image_url,
          m.is_featured,
          COALESCE(r.relevance_score, 0) AS ai_score,
          r.reason AS ai_reason
        FROM menu_items m
        LEFT JOIN menu_categories mc ON mc.id = m.category_id
        LEFT JOIN recommendations r ON r.item_id = m.id
        WHERE m.is_available = true
        ORDER BY COALESCE(r.relevance_score, 0) DESC, m.is_featured DESC
      )
      SELECT jsonb_build_object(
        'items', COALESCE((SELECT jsonb_agg(row_to_json(menu_data)) FROM menu_data), '[]'::JSONB),
        'personalized', v_customer_id IS NOT NULL,
        'api_version', 'v4'
      ) INTO v_result;

    WHEN 'get_personalized_recommendations' THEN
      SELECT jsonb_agg(row_to_json(r))
      INTO v_result
      FROM get_personalized_recommendations(
        v_customer_id,
        v_store_id,
        COALESCE((p_payload->>'limit')::INTEGER, 10)
      ) r;

    WHEN 'get_similar_items' THEN
      SELECT jsonb_agg(row_to_json(s))
      INTO v_result
      FROM get_similar_items(
        v_item_id,
        COALESCE((p_payload->>'limit')::INTEGER, 5),
        COALESCE((p_payload->>'threshold')::FLOAT, 0.7)
      ) s;

    WHEN 'get_substitute_items' THEN
      SELECT jsonb_agg(row_to_json(s))
      INTO v_result
      FROM get_substitute_items(
        v_item_id,
        v_store_id,
        COALESCE((p_payload->>'limit')::INTEGER, 3)
      ) s;

    -- Inventory Intelligence
    WHEN 'predict_inventory_needs' THEN
      SELECT jsonb_agg(row_to_json(p))
      INTO v_result
      FROM predict_inventory_needs(
        v_store_id,
        COALESCE((p_payload->>'days_ahead')::INTEGER, 7)
      ) p;

    WHEN 'get_top_sellers_predicted' THEN
      SELECT jsonb_agg(row_to_json(t))
      INTO v_result
      FROM get_top_sellers_predicted(
        v_store_id,
        COALESCE((p_payload->>'days_ahead')::INTEGER, 7),
        COALESCE((p_payload->>'limit')::INTEGER, 10)
      ) t;

    WHEN 'get_inventory_alerts' THEN
      SELECT jsonb_agg(
        jsonb_build_object(
          'id', ia.id,
          'item_id', ia.item_id,
          'item_name', m.name,
          'alert_type', ia.alert_type,
          'current_level', ia.current_level,
          'threshold_level', ia.threshold_level,
          'severity', ia.severity,
          'created_at', ia.created_at
        )
      )
      INTO v_result
      FROM inventory_alerts ia
      JOIN menu_items m ON m.id = ia.item_id
      WHERE ia.store_id = v_store_id
        AND ia.is_resolved = false
      ORDER BY
        CASE ia.severity WHEN 'critical' THEN 1 WHEN 'warning' THEN 2 ELSE 3 END,
        ia.created_at DESC;

    WHEN 'update_inventory' THEN
      UPDATE inventory_levels
      SET
        current_stock = COALESCE((p_payload->>'current_stock')::INTEGER, current_stock),
        updated_at = NOW()
      WHERE store_id = v_store_id AND item_id = v_item_id
      RETURNING jsonb_build_object(
        'item_id', item_id,
        'current_stock', current_stock,
        'updated_at', updated_at
      ) INTO v_result;

    -- Demand Forecasting
    WHEN 'get_demand_forecast' THEN
      SELECT jsonb_agg(
        jsonb_build_object(
          'item_id', df.item_id,
          'item_name', m.name,
          'forecast_date', df.forecast_date,
          'predicted_quantity', df.predicted_quantity,
          'confidence', df.confidence,
          'actual_quantity', df.actual_quantity
        )
      )
      INTO v_result
      FROM demand_forecast df
      JOIN menu_items m ON m.id = df.item_id
      WHERE df.store_id = v_store_id
        AND df.forecast_date >= CURRENT_DATE
        AND df.forecast_date <= CURRENT_DATE + COALESCE((p_payload->>'days_ahead')::INTEGER, 7)
      ORDER BY df.forecast_date, df.predicted_quantity DESC;

    WHEN 'explain_menu_performance' THEN
      WITH performance_data AS (
        SELECT
          m.id AS item_id,
          m.name,
          mc.name AS category,
          COALESCE(SUM(oi.quantity), 0) AS total_sold,
          COALESCE(SUM(oi.subtotal), 0) AS total_revenue,
          COUNT(DISTINCT o.id) AS order_count,
          AVG(oi.quantity) AS avg_per_order
        FROM menu_items m
        LEFT JOIN menu_categories mc ON mc.id = m.category_id
        LEFT JOIN order_items oi ON oi.menu_item_id = m.id
        LEFT JOIN orders o ON o.id = oi.order_id
          AND o.store_id = v_store_id
          AND o.created_at >= NOW() - INTERVAL '30 days'
          AND o.status IN ('completed', 'ready')
        WHERE m.is_available = true
        GROUP BY m.id, m.name, mc.name
      )
      SELECT jsonb_build_object(
        'period', '30 days',
        'store_id', v_store_id,
        'items', (SELECT jsonb_agg(row_to_json(performance_data)) FROM performance_data),
        'top_performer', (
          SELECT name FROM performance_data ORDER BY total_revenue DESC LIMIT 1
        ),
        'needs_attention', (
          SELECT jsonb_agg(name) FROM performance_data WHERE total_sold < 5
        )
      ) INTO v_result;

    -- Customer Profile Management
    WHEN 'update_customer_taste' THEN
      INSERT INTO customer_taste_profile (customer_id, favorite_categories, last_updated)
      VALUES (
        v_customer_id,
        ARRAY(SELECT jsonb_array_elements_text(p_payload->'categories')),
        NOW()
      )
      ON CONFLICT (customer_id) DO UPDATE SET
        favorite_categories = ARRAY(SELECT jsonb_array_elements_text(p_payload->'categories')),
        last_updated = NOW()
      RETURNING jsonb_build_object(
        'customer_id', customer_id,
        'favorite_categories', favorite_categories,
        'updated', true
      ) INTO v_result;

    -- Fallback to V3 for unknown RPCs
    ELSE
      v_result := rpc_v3_dispatch(p_name, p_payload);
  END CASE;

  -- Calculate execution time
  v_execution_ms := EXTRACT(MILLISECONDS FROM (clock_timestamp() - v_start_ts))::INTEGER;

  -- Log to runtime metrics
  INSERT INTO runtime_metrics (metric_name, metric_value, metadata)
  VALUES (
    'rpc_v4_' || p_name,
    v_execution_ms,
    jsonb_build_object(
      'store_id', v_store_id,
      'customer_id', v_customer_id,
      'success', v_result IS NOT NULL
    )
  );

  RETURN COALESCE(v_result, '[]'::JSONB);
END;
$$;

-- ----------------------------------------------------------------------------
-- 4.2 Update Route API Call for V4 Support
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
    IF v_client_version IS NOT NULL AND NOT meets_min_version(v_client_version, '1.5.0') THEN
      -- Check for v3 compatibility
      IF meets_min_version(v_client_version, '1.4.0') THEN
        v_target_version := 'v3';
      ELSE
        v_target_version := v_fallback_version;
      END IF;
    ELSE
      v_target_version := COALESCE(v_active_version, 'v3');
    END IF;
  END IF;

  -- Route to appropriate dispatcher
  CASE v_target_version
    WHEN 'v4' THEN
      v_result := rpc_v4_dispatch(p_name, p_payload);
    WHEN 'v3' THEN
      v_result := rpc_v3_dispatch(p_name, p_payload);
    WHEN 'v2' THEN
      v_result := rpc_v2_dispatch(p_name, p_payload);
    WHEN 'v1' THEN
      v_result := rpc_v1_dispatch(p_name, p_payload);
    ELSE
      v_result := rpc_v3_dispatch(p_name, p_payload);
  END CASE;

  RETURN v_result;
END;
$$;

-- ============================================================================
-- SECTION 5: Inventory Auto-Update Triggers
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 5.1 Decrease Inventory on Order
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION decrease_inventory_on_order()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_store_id BIGINT;
BEGIN
  -- Get store_id from the order
  SELECT store_id INTO v_store_id FROM orders WHERE id = NEW.order_id;

  -- Decrease inventory for the ordered item
  UPDATE inventory_levels
  SET
    current_stock = GREATEST(current_stock - NEW.quantity, 0),
    updated_at = NOW()
  WHERE store_id = v_store_id AND item_id = NEW.menu_item_id;

  RETURN NEW;
END;
$$;

-- Create trigger (drop if exists first)
DROP TRIGGER IF EXISTS trg_decrease_inventory_on_order ON order_items;
CREATE TRIGGER trg_decrease_inventory_on_order
  AFTER INSERT ON order_items
  FOR EACH ROW
  EXECUTE FUNCTION decrease_inventory_on_order();

-- ----------------------------------------------------------------------------
-- 5.2 Generate Low Stock Alert
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION check_inventory_alert()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Check if stock is at or below minimum
  IF NEW.current_stock <= NEW.minimum_stock THEN
    -- Insert alert if one doesn't exist for this item
    INSERT INTO inventory_alerts (
      store_id,
      item_id,
      alert_type,
      current_level,
      threshold_level,
      severity
    )
    SELECT
      NEW.store_id,
      NEW.item_id,
      CASE
        WHEN NEW.current_stock = 0 THEN 'out_of_stock'
        ELSE 'low_stock'
      END,
      NEW.current_stock,
      NEW.minimum_stock,
      CASE
        WHEN NEW.current_stock = 0 THEN 'critical'
        WHEN NEW.current_stock <= NEW.minimum_stock / 2 THEN 'warning'
        ELSE 'info'
      END
    WHERE NOT EXISTS (
      SELECT 1 FROM inventory_alerts ia
      WHERE ia.store_id = NEW.store_id
        AND ia.item_id = NEW.item_id
        AND ia.is_resolved = false
        AND ia.alert_type IN ('low_stock', 'out_of_stock')
    );
  END IF;

  -- Auto-resolve alert if stock is replenished
  IF NEW.current_stock > NEW.minimum_stock AND OLD.current_stock <= OLD.minimum_stock THEN
    UPDATE inventory_alerts
    SET
      is_resolved = true,
      resolved_at = NOW()
    WHERE store_id = NEW.store_id
      AND item_id = NEW.item_id
      AND is_resolved = false
      AND alert_type IN ('low_stock', 'out_of_stock');
  END IF;

  RETURN NEW;
END;
$$;

-- Create trigger
DROP TRIGGER IF EXISTS trg_check_inventory_alert ON inventory_levels;
CREATE TRIGGER trg_check_inventory_alert
  AFTER UPDATE ON inventory_levels
  FOR EACH ROW
  EXECUTE FUNCTION check_inventory_alert();

-- ----------------------------------------------------------------------------
-- 5.3 Daily Demand Forecast Population
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION populate_demand_forecast()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_forecast_days INTEGER := 14;
BEGIN
  -- Generate forecasts for the next 14 days
  INSERT INTO demand_forecast (store_id, item_id, forecast_date, predicted_quantity, confidence, model_version)
  SELECT
    d.store_id,
    d.item_id,
    CURRENT_DATE + i AS forecast_date,
    GREATEST(
      ROUND(d.daily_avg * COALESCE(d.seasonal_multiplier, 1.0))::INTEGER,
      0
    ) AS predicted_quantity,
    0.85 - (i * 0.03) AS confidence,
    'pattern_v1' AS model_version
  FROM mv_daily_store_demand d
  CROSS JOIN generate_series(1, v_forecast_days) AS i
  WHERE d.day_of_week = EXTRACT(DOW FROM CURRENT_DATE + i)
  ON CONFLICT (store_id, item_id, forecast_date)
  DO UPDATE SET
    predicted_quantity = EXCLUDED.predicted_quantity,
    confidence = EXCLUDED.confidence,
    model_version = EXCLUDED.model_version;
END;
$$;

-- ============================================================================
-- SECTION 6: Materialized View Refresh Function
-- ============================================================================

CREATE OR REPLACE FUNCTION refresh_ai_materialized_views()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Refresh demand-related views
  REFRESH MATERIALIZED VIEW CONCURRENTLY mv_item_sales_last_90_days;
  REFRESH MATERIALIZED VIEW CONCURRENTLY mv_daily_store_demand;
  REFRESH MATERIALIZED VIEW CONCURRENTLY mv_hourly_demand_patterns;
  REFRESH MATERIALIZED VIEW CONCURRENTLY mv_item_affinity;

  -- Populate demand forecasts
  PERFORM populate_demand_forecast();
END;
$$;

-- ============================================================================
-- SECTION 7: RLS Policies
-- ============================================================================

-- Customer Taste Profile
ALTER TABLE customer_taste_profile ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own taste profile" ON customer_taste_profile
  FOR SELECT TO authenticated
  USING (customer_id = auth.uid());

CREATE POLICY "Users can update own taste profile" ON customer_taste_profile
  FOR ALL TO authenticated
  USING (customer_id = auth.uid())
  WITH CHECK (customer_id = auth.uid());

-- Menu Item Embeddings (public read)
ALTER TABLE menu_item_embedding ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public can read menu embeddings" ON menu_item_embedding
  FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY "Staff can manage embeddings" ON menu_item_embedding
  FOR ALL TO authenticated
  USING (public.get_current_user_role() IN ('super_admin', 'admin'));

-- Inventory Levels
ALTER TABLE inventory_levels ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Staff can view store inventory" ON inventory_levels
  FOR SELECT TO authenticated
  USING (
    public.get_current_user_role() IN ('super_admin', 'admin', 'manager', 'staff')
    AND (
      public.is_current_user_system_admin()
      OR store_id = ANY(public.get_current_user_assigned_stores())
    )
  );

CREATE POLICY "Managers can update inventory" ON inventory_levels
  FOR ALL TO authenticated
  USING (
    public.get_current_user_role() IN ('super_admin', 'admin', 'manager')
    AND (
      public.is_current_user_system_admin()
      OR store_id = ANY(public.get_current_user_assigned_stores())
    )
  );

-- Demand Forecast
ALTER TABLE demand_forecast ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Staff can view forecasts" ON demand_forecast
  FOR SELECT TO authenticated
  USING (
    public.get_current_user_role() IN ('super_admin', 'admin', 'manager', 'staff')
    AND (
      public.is_current_user_system_admin()
      OR store_id = ANY(public.get_current_user_assigned_stores())
    )
  );

-- AI Recommendations Log
ALTER TABLE ai_recommendations_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own recommendations" ON ai_recommendations_log
  FOR SELECT TO authenticated
  USING (customer_id = auth.uid() OR public.get_current_user_role() IN ('super_admin', 'admin'));

-- Inventory Alerts
ALTER TABLE inventory_alerts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Staff can view alerts" ON inventory_alerts
  FOR SELECT TO authenticated
  USING (
    public.get_current_user_role() IN ('super_admin', 'admin', 'manager', 'staff')
    AND (
      public.is_current_user_system_admin()
      OR store_id = ANY(public.get_current_user_assigned_stores())
    )
  );

CREATE POLICY "Staff can update alerts" ON inventory_alerts
  FOR UPDATE TO authenticated
  USING (
    public.get_current_user_role() IN ('super_admin', 'admin', 'manager', 'staff')
    AND (
      public.is_current_user_system_admin()
      OR store_id = ANY(public.get_current_user_assigned_stores())
    )
  );

-- ============================================================================
-- SECTION 8: Grants
-- ============================================================================

GRANT SELECT ON customer_taste_profile TO authenticated;
GRANT SELECT ON menu_item_embedding TO anon, authenticated;
GRANT SELECT ON inventory_levels TO authenticated;
GRANT SELECT ON demand_forecast TO authenticated;
GRANT SELECT ON ai_recommendations_log TO authenticated;
GRANT SELECT ON inventory_alerts TO authenticated;

GRANT SELECT ON mv_item_sales_last_90_days TO authenticated;
GRANT SELECT ON mv_daily_store_demand TO authenticated;
GRANT SELECT ON mv_hourly_demand_patterns TO authenticated;
GRANT SELECT ON mv_item_affinity TO authenticated;

GRANT EXECUTE ON FUNCTION get_similar_items(BIGINT, INTEGER, FLOAT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION get_personalized_recommendations(UUID, BIGINT, INTEGER) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION predict_inventory_needs(BIGINT, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_top_sellers_predicted(BIGINT, INTEGER, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_substitute_items(BIGINT, BIGINT, INTEGER) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION rpc_v4_dispatch(TEXT, JSONB) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION refresh_ai_materialized_views() TO authenticated;
GRANT EXECUTE ON FUNCTION populate_demand_forecast() TO authenticated;

-- ============================================================================
-- Summary
-- ============================================================================
-- This migration adds:
-- 1. Customer taste profiles with vector embeddings
-- 2. Menu item embeddings for semantic similarity
-- 3. Inventory levels and tracking per store
-- 4. Demand forecasting tables
-- 5. AI recommendations logging
-- 6. Inventory alerts system
-- 7. Materialized views for demand analytics
-- 8. V4 API dispatcher with AI-focused RPCs
-- 9. Auto-update triggers for inventory management
-- 10. Full RLS policies for data security
-- ============================================================================
