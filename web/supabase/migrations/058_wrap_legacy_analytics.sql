-- =====================================================
-- Migration 058: Wrap Legacy Analytics Functions
-- Version: 1.0
-- Date: 2025-12-02
-- Purpose: Make legacy (non-secure) analytics functions call
--          their secure counterparts for backwards compatibility
-- =====================================================

-- =====================================================
-- 1. Wrap get_store_metrics to call get_store_metrics_secure
-- =====================================================

-- Drop existing function first (signature may differ)
DROP FUNCTION IF EXISTS get_store_metrics(BIGINT, TEXT);

CREATE OR REPLACE FUNCTION get_store_metrics(
  p_store_id BIGINT,
  p_date_range TEXT DEFAULT 'today'
)
RETURNS TABLE (
  total_revenue NUMERIC,
  total_orders BIGINT,
  avg_order_value NUMERIC,
  unique_customers BIGINT,
  revenue_change NUMERIC,
  orders_change NUMERIC
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Delegate to secure version which validates access
  RETURN QUERY SELECT * FROM get_store_metrics_secure(p_store_id, p_date_range);
END;
$$;

COMMENT ON FUNCTION get_store_metrics(BIGINT, TEXT) IS
'DEPRECATED: Use get_store_metrics_secure instead. This wrapper exists for backwards compatibility.';

-- =====================================================
-- 2. Wrap get_revenue_chart_data to call secure version
-- =====================================================

-- Drop existing function first (signature may differ)
DROP FUNCTION IF EXISTS get_revenue_chart_data(BIGINT, TEXT);

CREATE OR REPLACE FUNCTION get_revenue_chart_data(
  p_store_id BIGINT,
  p_date_range TEXT DEFAULT 'today'
)
RETURNS TABLE (
  time_label TEXT,
  revenue NUMERIC,
  orders BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Delegate to secure version which validates access
  RETURN QUERY SELECT * FROM get_revenue_chart_data_secure(p_store_id, p_date_range);
END;
$$;

COMMENT ON FUNCTION get_revenue_chart_data(BIGINT, TEXT) IS
'DEPRECATED: Use get_revenue_chart_data_secure instead. This wrapper exists for backwards compatibility.';

-- =====================================================
-- 3. Wrap get_business_insights to call secure version
-- =====================================================

-- Drop existing function first (signature may differ)
DROP FUNCTION IF EXISTS get_business_insights(BIGINT);

CREATE OR REPLACE FUNCTION get_business_insights(
  p_store_id BIGINT
)
RETURNS TABLE (
  peak_hour INTEGER,
  busiest_day TEXT,
  top_category TEXT,
  customer_retention NUMERIC,
  avg_wait_time NUMERIC
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Delegate to secure version which validates access
  RETURN QUERY SELECT * FROM get_business_insights_secure(p_store_id);
END;
$$;

COMMENT ON FUNCTION get_business_insights(BIGINT) IS
'DEPRECATED: Use get_business_insights_secure instead. This wrapper exists for backwards compatibility.';

-- =====================================================
-- 4. Grant execute permissions
-- =====================================================

GRANT EXECUTE ON FUNCTION get_store_metrics(BIGINT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION get_revenue_chart_data(BIGINT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION get_business_insights(BIGINT) TO authenticated;

-- =====================================================
-- SUCCESS! Migration 058 complete.
--
-- Legacy analytics functions now wrap secure versions:
-- - get_store_metrics() → get_store_metrics_secure()
-- - get_revenue_chart_data() → get_revenue_chart_data_secure()
-- - get_business_insights() → get_business_insights_secure()
--
-- Any old code calling non-secure versions will now get
-- the same security checks as the secure versions.
--
-- Frontend has been updated to use _secure directly.
-- These wrappers exist only for backwards compatibility
-- with any external integrations or iOS apps.
-- =====================================================
