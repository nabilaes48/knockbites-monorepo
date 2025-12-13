-- Migration 024: Analytics Views and Functions
-- Creates comprehensive analytics infrastructure for real-time business intelligence

-- ============================================================================
-- 1. ANALYTICS DAILY STATS VIEW
-- Aggregates orders by day and store
-- ============================================================================

CREATE OR REPLACE VIEW analytics_daily_stats AS
SELECT
    store_id,
    DATE(created_at) as date,
    COUNT(*) as total_orders,
    SUM(subtotal) as total_revenue,
    SUM(tax) as total_tax,
    SUM(total) as total_with_tax,
    AVG(subtotal) as avg_order_value,
    COUNT(DISTINCT user_id) as unique_customers
FROM orders
WHERE status != 'cancelled'
GROUP BY store_id, DATE(created_at)
ORDER BY date DESC;

-- ============================================================================
-- 2. ANALYTICS HOURLY TODAY VIEW
-- Hourly breakdown of orders for today
-- ============================================================================

CREATE OR REPLACE VIEW analytics_hourly_today AS
SELECT
    store_id,
    EXTRACT(HOUR FROM created_at) as hour,
    COUNT(*) as orders,
    SUM(subtotal) as revenue
FROM orders
WHERE DATE(created_at) = CURRENT_DATE
  AND status != 'cancelled'
GROUP BY store_id, EXTRACT(HOUR FROM created_at)
ORDER BY hour;

-- ============================================================================
-- 3. ANALYTICS TIME DISTRIBUTION VIEW
-- Orders grouped by time of day (Breakfast, Lunch, Dinner, Late Night)
-- ============================================================================

CREATE OR REPLACE VIEW analytics_time_distribution AS
SELECT
    store_id,
    CASE
        WHEN EXTRACT(HOUR FROM created_at) >= 6 AND EXTRACT(HOUR FROM created_at) < 11 THEN 'Breakfast'
        WHEN EXTRACT(HOUR FROM created_at) >= 11 AND EXTRACT(HOUR FROM created_at) < 15 THEN 'Lunch'
        WHEN EXTRACT(HOUR FROM created_at) >= 15 AND EXTRACT(HOUR FROM created_at) < 21 THEN 'Dinner'
        ELSE 'Late Night'
    END as time_period,
    COUNT(*) as order_count,
    SUM(subtotal) as revenue
FROM orders
WHERE status != 'cancelled'
GROUP BY store_id, time_period;

-- ============================================================================
-- 4. ANALYTICS CATEGORY DISTRIBUTION VIEW
-- Orders grouped by menu category
-- ============================================================================

CREATE OR REPLACE VIEW analytics_category_distribution AS
SELECT
    c.name as category,
    c.subcategory,
    COUNT(DISTINCT oi.order_id) as order_count,
    SUM(oi.quantity) as items_sold,
    SUM(oi.subtotal) as total_revenue
FROM order_items oi
JOIN menu_items mi ON oi.menu_item_id = mi.id
JOIN categories c ON mi.category_id = c.id
GROUP BY c.name, c.subcategory
ORDER BY total_revenue DESC;

-- ============================================================================
-- 5. ANALYTICS POPULAR ITEMS VIEW
-- Top-selling menu items per store
-- ============================================================================

CREATE OR REPLACE VIEW analytics_popular_items AS
SELECT
    o.store_id,
    oi.menu_item_id,
    oi.item_name,
    COUNT(DISTINCT oi.order_id) as times_ordered,
    SUM(oi.quantity) as total_quantity,
    SUM(oi.subtotal) as total_revenue,
    AVG(oi.item_price) as avg_price
FROM order_items oi
JOIN orders o ON oi.order_id = o.id
WHERE o.status != 'cancelled'
GROUP BY o.store_id, oi.menu_item_id, oi.item_name
ORDER BY total_revenue DESC;

-- ============================================================================
-- 6. GET STORE METRICS FUNCTION
-- Returns KPI metrics with period comparison
-- ============================================================================

CREATE OR REPLACE FUNCTION get_store_metrics(
    p_store_id INT,
    p_date_range TEXT DEFAULT 'today'
)
RETURNS TABLE (
    total_revenue NUMERIC,
    total_orders BIGINT,
    avg_order_value NUMERIC,
    unique_customers BIGINT,
    revenue_change NUMERIC,
    orders_change INT
) AS $$
DECLARE
    v_start_date DATE;
    v_end_date DATE;
    v_prev_start_date DATE;
    v_prev_end_date DATE;
    v_current_revenue NUMERIC;
    v_current_orders BIGINT;
    v_current_customers BIGINT;
    v_prev_revenue NUMERIC;
    v_prev_orders BIGINT;
BEGIN
    -- Calculate date ranges based on period
    CASE p_date_range
        WHEN 'today' THEN
            v_start_date := CURRENT_DATE;
            v_end_date := CURRENT_DATE + INTERVAL '1 day';
            v_prev_start_date := CURRENT_DATE - INTERVAL '1 day';
            v_prev_end_date := CURRENT_DATE;
        WHEN 'week' THEN
            v_start_date := CURRENT_DATE - INTERVAL '7 days';
            v_end_date := CURRENT_DATE + INTERVAL '1 day';
            v_prev_start_date := CURRENT_DATE - INTERVAL '14 days';
            v_prev_end_date := CURRENT_DATE - INTERVAL '7 days';
        WHEN 'month' THEN
            v_start_date := CURRENT_DATE - INTERVAL '30 days';
            v_end_date := CURRENT_DATE + INTERVAL '1 day';
            v_prev_start_date := CURRENT_DATE - INTERVAL '60 days';
            v_prev_end_date := CURRENT_DATE - INTERVAL '30 days';
        WHEN 'quarter' THEN
            v_start_date := CURRENT_DATE - INTERVAL '90 days';
            v_end_date := CURRENT_DATE + INTERVAL '1 day';
            v_prev_start_date := CURRENT_DATE - INTERVAL '180 days';
            v_prev_end_date := CURRENT_DATE - INTERVAL '90 days';
        WHEN 'year' THEN
            v_start_date := CURRENT_DATE - INTERVAL '365 days';
            v_end_date := CURRENT_DATE + INTERVAL '1 day';
            v_prev_start_date := CURRENT_DATE - INTERVAL '730 days';
            v_prev_end_date := CURRENT_DATE - INTERVAL '365 days';
        ELSE
            v_start_date := CURRENT_DATE;
            v_end_date := CURRENT_DATE + INTERVAL '1 day';
            v_prev_start_date := CURRENT_DATE - INTERVAL '1 day';
            v_prev_end_date := CURRENT_DATE;
    END CASE;

    -- Get current period metrics
    SELECT
        COALESCE(SUM(subtotal), 0),
        COUNT(*),
        COUNT(DISTINCT user_id)
    INTO v_current_revenue, v_current_orders, v_current_customers
    FROM orders
    WHERE store_id = p_store_id
      AND created_at >= v_start_date
      AND created_at < v_end_date
      AND status != 'cancelled';

    -- Get previous period metrics for comparison
    SELECT
        COALESCE(SUM(subtotal), 0),
        COUNT(*)
    INTO v_prev_revenue, v_prev_orders
    FROM orders
    WHERE store_id = p_store_id
      AND created_at >= v_prev_start_date
      AND created_at < v_prev_end_date
      AND status != 'cancelled';

    -- Return results
    RETURN QUERY SELECT
        v_current_revenue,
        v_current_orders,
        CASE WHEN v_current_orders > 0 THEN v_current_revenue / v_current_orders ELSE 0 END,
        v_current_customers,
        CASE WHEN v_prev_revenue > 0 THEN ((v_current_revenue - v_prev_revenue) / v_prev_revenue * 100) ELSE 0 END,
        (v_current_orders - v_prev_orders)::INT;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 7. GET REVENUE CHART DATA FUNCTION
-- Returns time-series revenue data for charts
-- ============================================================================

CREATE OR REPLACE FUNCTION get_revenue_chart_data(
    p_store_id INT,
    p_date_range TEXT DEFAULT 'today'
)
RETURNS TABLE (
    time_label TEXT,
    revenue NUMERIC,
    orders BIGINT
) AS $$
BEGIN
    IF p_date_range = 'today' THEN
        -- Hourly breakdown for today
        RETURN QUERY
        SELECT
            TO_CHAR(EXTRACT(HOUR FROM created_at), 'FM12') || CASE
                WHEN EXTRACT(HOUR FROM created_at) < 12 THEN 'am'
                WHEN EXTRACT(HOUR FROM created_at) = 12 THEN 'pm'
                ELSE 'pm'
            END as time_label,
            COALESCE(SUM(subtotal), 0) as revenue,
            COUNT(*)::BIGINT as orders
        FROM orders
        WHERE store_id = p_store_id
          AND DATE(created_at) = CURRENT_DATE
          AND status != 'cancelled'
        GROUP BY EXTRACT(HOUR FROM created_at)
        ORDER BY EXTRACT(HOUR FROM created_at);

    ELSIF p_date_range = 'week' THEN
        -- Daily breakdown for past 7 days
        RETURN QUERY
        SELECT
            TO_CHAR(DATE(created_at), 'Dy') as time_label,
            COALESCE(SUM(subtotal), 0) as revenue,
            COUNT(*)::BIGINT as orders
        FROM orders
        WHERE store_id = p_store_id
          AND created_at >= CURRENT_DATE - INTERVAL '7 days'
          AND created_at < CURRENT_DATE + INTERVAL '1 day'
          AND status != 'cancelled'
        GROUP BY DATE(created_at), TO_CHAR(DATE(created_at), 'Dy')
        ORDER BY DATE(created_at);

    ELSIF p_date_range = 'month' THEN
        -- Daily breakdown for past 30 days
        RETURN QUERY
        SELECT
            TO_CHAR(DATE(created_at), 'Mon DD') as time_label,
            COALESCE(SUM(subtotal), 0) as revenue,
            COUNT(*)::BIGINT as orders
        FROM orders
        WHERE store_id = p_store_id
          AND created_at >= CURRENT_DATE - INTERVAL '30 days'
          AND created_at < CURRENT_DATE + INTERVAL '1 day'
          AND status != 'cancelled'
        GROUP BY DATE(created_at)
        ORDER BY DATE(created_at);

    ELSIF p_date_range = 'quarter' THEN
        -- Weekly breakdown for past 90 days
        RETURN QUERY
        SELECT
            'Week ' || TO_CHAR(DATE(created_at), 'WW') as time_label,
            COALESCE(SUM(subtotal), 0) as revenue,
            COUNT(*)::BIGINT as orders
        FROM orders
        WHERE store_id = p_store_id
          AND created_at >= CURRENT_DATE - INTERVAL '90 days'
          AND created_at < CURRENT_DATE + INTERVAL '1 day'
          AND status != 'cancelled'
        GROUP BY TO_CHAR(DATE(created_at), 'WW')
        ORDER BY TO_CHAR(DATE(created_at), 'WW');

    ELSIF p_date_range = 'year' THEN
        -- Monthly breakdown for past 365 days
        RETURN QUERY
        SELECT
            TO_CHAR(DATE(created_at), 'Mon YYYY') as time_label,
            COALESCE(SUM(subtotal), 0) as revenue,
            COUNT(*)::BIGINT as orders
        FROM orders
        WHERE store_id = p_store_id
          AND created_at >= CURRENT_DATE - INTERVAL '365 days'
          AND created_at < CURRENT_DATE + INTERVAL '1 day'
          AND status != 'cancelled'
        GROUP BY TO_CHAR(DATE(created_at), 'Mon YYYY'), DATE_TRUNC('month', created_at)
        ORDER BY DATE_TRUNC('month', created_at);

    ELSE
        -- Default to today hourly
        RETURN QUERY
        SELECT
            TO_CHAR(EXTRACT(HOUR FROM created_at), 'FM12') || CASE
                WHEN EXTRACT(HOUR FROM created_at) < 12 THEN 'am'
                ELSE 'pm'
            END as time_label,
            COALESCE(SUM(subtotal), 0) as revenue,
            COUNT(*)::BIGINT as orders
        FROM orders
        WHERE store_id = p_store_id
          AND DATE(created_at) = CURRENT_DATE
          AND status != 'cancelled'
        GROUP BY EXTRACT(HOUR FROM created_at)
        ORDER BY EXTRACT(HOUR FROM created_at);
    END IF;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 8. GRANT PERMISSIONS
-- ============================================================================

-- Grant access to analytics views
GRANT SELECT ON analytics_daily_stats TO anon, authenticated;
GRANT SELECT ON analytics_hourly_today TO anon, authenticated;
GRANT SELECT ON analytics_time_distribution TO anon, authenticated;
GRANT SELECT ON analytics_category_distribution TO anon, authenticated;
GRANT SELECT ON analytics_popular_items TO anon, authenticated;

-- Grant execute permissions on functions
GRANT EXECUTE ON FUNCTION get_store_metrics(INT, TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION get_revenue_chart_data(INT, TEXT) TO anon, authenticated;

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================

COMMENT ON VIEW analytics_daily_stats IS 'Daily aggregated metrics per store';
COMMENT ON VIEW analytics_hourly_today IS 'Hourly breakdown for today';
COMMENT ON VIEW analytics_time_distribution IS 'Orders by time of day';
COMMENT ON VIEW analytics_category_distribution IS 'Orders by menu category';
COMMENT ON VIEW analytics_popular_items IS 'Top-selling menu items';
COMMENT ON FUNCTION get_store_metrics IS 'KPI metrics with period comparison';
COMMENT ON FUNCTION get_revenue_chart_data IS 'Time-series revenue for charts';
