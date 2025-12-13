-- ============================================
-- ANALYTICS VIEWS AND FUNCTIONS
-- Real-time analytics using Postgres aggregations
-- ============================================

-- View 1: Daily Revenue and Orders
CREATE OR REPLACE VIEW analytics_daily_stats AS
SELECT
  o.store_id,
  DATE(o.created_at) as order_date,
  COUNT(o.id) as total_orders,
  SUM(o.subtotal) as total_revenue,
  SUM(o.tax) as total_tax,
  SUM(o.total) as total_with_tax,
  AVG(o.total) as avg_order_value,
  COUNT(DISTINCT o.customer_phone) as unique_customers
FROM orders o
WHERE o.status != 'cancelled'
GROUP BY o.store_id, DATE(o.created_at)
ORDER BY order_date DESC;

-- View 2: Hourly Stats (Today)
CREATE OR REPLACE VIEW analytics_hourly_today AS
SELECT
  o.store_id,
  EXTRACT(HOUR FROM o.created_at) as hour,
  COUNT(o.id) as orders,
  SUM(o.total) as revenue
FROM orders o
WHERE DATE(o.created_at) = CURRENT_DATE
AND o.status != 'cancelled'
GROUP BY o.store_id, EXTRACT(HOUR FROM o.created_at)
ORDER BY hour;

-- View 3: Order Distribution by Time of Day
CREATE OR REPLACE VIEW analytics_time_distribution AS
SELECT
  o.store_id,
  CASE
    WHEN EXTRACT(HOUR FROM o.created_at) BETWEEN 6 AND 10 THEN 'Breakfast'
    WHEN EXTRACT(HOUR FROM o.created_at) BETWEEN 11 AND 14 THEN 'Lunch'
    WHEN EXTRACT(HOUR FROM o.created_at) BETWEEN 15 AND 20 THEN 'Dinner'
    ELSE 'Late Night'
  END as time_period,
  COUNT(o.id) as order_count,
  SUM(o.total) as revenue
FROM orders o
WHERE o.status != 'cancelled'
GROUP BY o.store_id, time_period;

-- View 4: Category Distribution
CREATE OR REPLACE VIEW analytics_category_distribution AS
SELECT
  mc.id as category_id,
  mc.name as category,
  COUNT(oi.id) as order_count,
  SUM(oi.quantity) as items_sold,
  SUM(oi.subtotal) as total_revenue
FROM order_items oi
JOIN menu_items mi ON mi.id = oi.menu_item_id
LEFT JOIN menu_categories mc ON mc.id = mi.category_id
JOIN orders o ON o.id = oi.order_id
WHERE o.status != 'cancelled'
GROUP BY mc.id, mc.name
ORDER BY order_count DESC;

-- View 5: Popular Menu Items
CREATE OR REPLACE VIEW analytics_popular_items AS
SELECT
  o.store_id,
  oi.menu_item_id,
  oi.item_name,
  COUNT(oi.id) as times_ordered,
  SUM(oi.quantity) as total_quantity,
  SUM(oi.subtotal) as total_revenue,
  AVG(oi.item_price) as avg_price
FROM order_items oi
JOIN orders o ON o.id = oi.order_id
WHERE o.status != 'cancelled'
GROUP BY o.store_id, oi.menu_item_id, oi.item_name
ORDER BY times_ordered DESC
LIMIT 50;

-- View 6: Store Performance Summary
CREATE OR REPLACE VIEW analytics_store_summary AS
SELECT
  s.id as store_id,
  s.name as store_name,
  s.store_code,
  COUNT(o.id) as total_orders,
  SUM(o.total) as total_revenue,
  AVG(o.total) as avg_order_value,
  COUNT(DISTINCT o.customer_phone) as unique_customers,
  COUNT(CASE WHEN o.is_repeat_customer THEN 1 END) as repeat_customers
FROM stores s
LEFT JOIN orders o ON o.store_id = s.id
WHERE o.status != 'cancelled' OR o.status IS NULL
GROUP BY s.id, s.name, s.store_code
ORDER BY total_revenue DESC NULLS LAST;

-- Function: Get Revenue Data for Date Range
CREATE OR REPLACE FUNCTION get_revenue_chart_data(
  p_store_id BIGINT,
  p_date_range TEXT DEFAULT 'today'
)
RETURNS TABLE (
  time_label TEXT,
  revenue NUMERIC,
  orders BIGINT
) AS $$
BEGIN
  IF p_date_range = 'today' THEN
    -- Hourly data for today
    RETURN QUERY
    SELECT
      TO_CHAR(EXTRACT(HOUR FROM o.created_at), 'FM12') || CASE
        WHEN EXTRACT(HOUR FROM o.created_at) < 12 THEN 'am'
        ELSE 'pm'
      END as time_label,
      COALESCE(SUM(o.total), 0)::NUMERIC as revenue,
      COUNT(o.id) as orders
    FROM orders o
    WHERE o.store_id = p_store_id
    AND DATE(o.created_at) = CURRENT_DATE
    AND o.status != 'cancelled'
    GROUP BY EXTRACT(HOUR FROM o.created_at)
    ORDER BY EXTRACT(HOUR FROM o.created_at);

  ELSIF p_date_range = 'week' THEN
    -- Daily data for past 7 days
    RETURN QUERY
    SELECT
      TO_CHAR(DATE(o.created_at), 'Dy') as time_label,
      COALESCE(SUM(o.total), 0)::NUMERIC as revenue,
      COUNT(o.id) as orders
    FROM orders o
    WHERE o.store_id = p_store_id
    AND o.created_at >= CURRENT_DATE - INTERVAL '7 days'
    AND o.status != 'cancelled'
    GROUP BY DATE(o.created_at)
    ORDER BY DATE(o.created_at);

  ELSIF p_date_range = 'month' THEN
    -- Weekly aggregates for past 30 days
    RETURN QUERY
    SELECT
      TO_CHAR(DATE_TRUNC('week', o.created_at), 'Mon DD') as time_label,
      COALESCE(SUM(o.total), 0)::NUMERIC as revenue,
      COUNT(o.id) as orders
    FROM orders o
    WHERE o.store_id = p_store_id
    AND o.created_at >= CURRENT_DATE - INTERVAL '30 days'
    AND o.status != 'cancelled'
    GROUP BY DATE_TRUNC('week', o.created_at)
    ORDER BY DATE_TRUNC('week', o.created_at);

  ELSIF p_date_range = 'quarter' THEN
    -- Monthly data for past 3 months
    RETURN QUERY
    SELECT
      TO_CHAR(DATE_TRUNC('month', o.created_at), 'Mon') as time_label,
      COALESCE(SUM(o.total), 0)::NUMERIC as revenue,
      COUNT(o.id) as orders
    FROM orders o
    WHERE o.store_id = p_store_id
    AND o.created_at >= CURRENT_DATE - INTERVAL '3 months'
    AND o.status != 'cancelled'
    GROUP BY DATE_TRUNC('month', o.created_at)
    ORDER BY DATE_TRUNC('month', o.created_at);

  ELSE -- 'year'
    -- Monthly data for past 12 months
    RETURN QUERY
    SELECT
      TO_CHAR(DATE_TRUNC('month', o.created_at), 'Mon') as time_label,
      COALESCE(SUM(o.total), 0)::NUMERIC as revenue,
      COUNT(o.id) as orders
    FROM orders o
    WHERE o.store_id = p_store_id
    AND o.created_at >= CURRENT_DATE - INTERVAL '12 months'
    AND o.status != 'cancelled'
    GROUP BY DATE_TRUNC('month', o.created_at)
    ORDER BY DATE_TRUNC('month', o.created_at);
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Function: Get Store Metrics (KPIs)
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
  orders_change BIGINT
) AS $$
DECLARE
  v_start_date TIMESTAMP;
  v_prev_start_date TIMESTAMP;
  v_prev_end_date TIMESTAMP;
BEGIN
  -- Calculate date ranges
  IF p_date_range = 'today' THEN
    v_start_date := CURRENT_DATE;
    v_prev_start_date := CURRENT_DATE - INTERVAL '1 day';
    v_prev_end_date := CURRENT_DATE;
  ELSIF p_date_range = 'week' THEN
    v_start_date := CURRENT_DATE - INTERVAL '7 days';
    v_prev_start_date := CURRENT_DATE - INTERVAL '14 days';
    v_prev_end_date := CURRENT_DATE - INTERVAL '7 days';
  ELSIF p_date_range = 'month' THEN
    v_start_date := CURRENT_DATE - INTERVAL '30 days';
    v_prev_start_date := CURRENT_DATE - INTERVAL '60 days';
    v_prev_end_date := CURRENT_DATE - INTERVAL '30 days';
  ELSE
    v_start_date := CURRENT_DATE - INTERVAL '365 days';
    v_prev_start_date := CURRENT_DATE - INTERVAL '730 days';
    v_prev_end_date := CURRENT_DATE - INTERVAL '365 days';
  END IF;

  RETURN QUERY
  WITH current_period AS (
    SELECT
      COALESCE(SUM(o.total), 0) as revenue,
      COUNT(o.id) as orders,
      COALESCE(AVG(o.total), 0) as avg_value,
      COUNT(DISTINCT o.customer_phone) as customers
    FROM orders o
    WHERE o.store_id = p_store_id
    AND o.created_at >= v_start_date
    AND o.status != 'cancelled'
  ),
  previous_period AS (
    SELECT
      COALESCE(SUM(o.total), 1) as revenue,
      COUNT(o.id) as orders
    FROM orders o
    WHERE o.store_id = p_store_id
    AND o.created_at >= v_prev_start_date
    AND o.created_at < v_prev_end_date
    AND o.status != 'cancelled'
  )
  SELECT
    cp.revenue::NUMERIC,
    cp.orders,
    cp.avg_value::NUMERIC,
    cp.customers,
    CASE
      WHEN pp.revenue > 0 THEN ((cp.revenue - pp.revenue) / pp.revenue * 100)::NUMERIC
      ELSE 0::NUMERIC
    END as revenue_change,
    (cp.orders - pp.orders) as orders_change
  FROM current_period cp, previous_period pp;
END;
$$ LANGUAGE plpgsql;

-- Grant permissions for analytics views
GRANT SELECT ON analytics_daily_stats TO anon, authenticated;
GRANT SELECT ON analytics_hourly_today TO anon, authenticated;
GRANT SELECT ON analytics_time_distribution TO anon, authenticated;
GRANT SELECT ON analytics_category_distribution TO anon, authenticated;
GRANT SELECT ON analytics_popular_items TO anon, authenticated;
GRANT SELECT ON analytics_store_summary TO anon, authenticated;

-- View 7: Customer Insights
CREATE OR REPLACE VIEW analytics_customer_insights AS
SELECT
  o.store_id,
  COUNT(DISTINCT o.customer_phone) as total_customers,
  COUNT(CASE WHEN o.is_repeat_customer THEN 1 END) as repeat_customers,
  ROUND(COUNT(CASE WHEN o.is_repeat_customer THEN 1 END)::NUMERIC /
    NULLIF(COUNT(DISTINCT o.customer_phone), 0) * 100, 1) as repeat_rate,
  AVG(o.total) as avg_spent_per_customer,
  MAX(o.total) as highest_order,
  MIN(o.total) as lowest_order
FROM orders o
WHERE o.status != 'cancelled'
GROUP BY o.store_id;

-- View 8: Peak Hours Analysis
CREATE OR REPLACE VIEW analytics_peak_hours AS
SELECT
  o.store_id,
  EXTRACT(HOUR FROM o.created_at) as hour,
  COUNT(o.id) as order_count,
  SUM(o.total) as revenue,
  AVG(o.total) as avg_order_value
FROM orders o
WHERE o.status != 'cancelled'
AND o.created_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY o.store_id, EXTRACT(HOUR FROM o.created_at)
ORDER BY o.store_id, hour;

-- View 9: Order Status Funnel
CREATE OR REPLACE VIEW analytics_order_funnel AS
SELECT
  o.store_id,
  o.status,
  COUNT(o.id) as order_count,
  SUM(o.total) as revenue,
  ROUND(AVG(EXTRACT(EPOCH FROM (o.updated_at - o.created_at)) / 60), 2) as avg_processing_minutes
FROM orders o
GROUP BY o.store_id, o.status
ORDER BY o.store_id,
  CASE o.status
    WHEN 'pending' THEN 1
    WHEN 'confirmed' THEN 2
    WHEN 'preparing' THEN 3
    WHEN 'ready' THEN 4
    WHEN 'completed' THEN 5
    WHEN 'cancelled' THEN 6
  END;

-- View 10: Revenue Goals and Targets
CREATE OR REPLACE VIEW analytics_revenue_goals AS
WITH daily_stats AS (
  SELECT
    store_id,
    DATE(created_at) as order_date,
    SUM(total) as daily_revenue,
    COUNT(id) as daily_orders
  FROM orders
  WHERE status != 'cancelled'
  AND created_at >= CURRENT_DATE - INTERVAL '30 days'
  GROUP BY store_id, DATE(created_at)
)
SELECT
  store_id,
  ROUND(AVG(daily_revenue), 2) as avg_daily_revenue,
  ROUND(MAX(daily_revenue), 2) as best_day_revenue,
  ROUND(MIN(daily_revenue), 2) as worst_day_revenue,
  ROUND(AVG(daily_orders), 2) as avg_daily_orders,
  -- Goal: 20% above average
  ROUND(AVG(daily_revenue) * 1.2, 2) as revenue_goal,
  ROUND(AVG(daily_orders) * 1.2, 2) as orders_goal
FROM daily_stats
GROUP BY store_id;

-- View 11: Day of Week Performance
CREATE OR REPLACE VIEW analytics_day_of_week AS
SELECT
  o.store_id,
  TO_CHAR(o.created_at, 'Day') as day_name,
  EXTRACT(DOW FROM o.created_at) as day_number,
  COUNT(o.id) as order_count,
  SUM(o.total) as total_revenue,
  AVG(o.total) as avg_order_value
FROM orders o
WHERE o.status != 'cancelled'
AND o.created_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY o.store_id, TO_CHAR(o.created_at, 'Day'), EXTRACT(DOW FROM o.created_at)
ORDER BY day_number;

-- View 12: Top Customers
CREATE OR REPLACE VIEW analytics_top_customers AS
SELECT
  o.store_id,
  o.customer_name,
  o.customer_phone,
  COUNT(o.id) as total_orders,
  SUM(o.total) as total_spent,
  AVG(o.total) as avg_order_value,
  MAX(o.created_at) as last_order_date
FROM orders o
WHERE o.status != 'cancelled'
GROUP BY o.store_id, o.customer_name, o.customer_phone
HAVING COUNT(o.id) > 1
ORDER BY total_spent DESC
LIMIT 100;

-- Function: Get Business Insights Summary
CREATE OR REPLACE FUNCTION get_business_insights(p_store_id BIGINT)
RETURNS JSON AS $$
DECLARE
  v_result JSON;
BEGIN
  SELECT json_build_object(
    'peak_hour', (
      SELECT hour
      FROM analytics_peak_hours
      WHERE store_id = p_store_id
      ORDER BY order_count DESC
      LIMIT 1
    ),
    'busiest_day', (
      SELECT day_name
      FROM analytics_day_of_week
      WHERE store_id = p_store_id
      ORDER BY order_count DESC
      LIMIT 1
    ),
    'top_category', (
      SELECT category
      FROM analytics_category_distribution
      WHERE category IS NOT NULL
      ORDER BY order_count DESC
      LIMIT 1
    ),
    'customer_retention', (
      SELECT repeat_rate
      FROM analytics_customer_insights
      WHERE store_id = p_store_id
    ),
    'avg_wait_time', (
      SELECT ROUND(AVG(avg_processing_minutes), 1)
      FROM analytics_order_funnel
      WHERE store_id = p_store_id
      AND status IN ('preparing', 'ready')
    )
  ) INTO v_result;

  RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- Grant permissions
GRANT SELECT ON analytics_customer_insights TO anon, authenticated;
GRANT SELECT ON analytics_peak_hours TO anon, authenticated;
GRANT SELECT ON analytics_order_funnel TO anon, authenticated;
GRANT SELECT ON analytics_revenue_goals TO anon, authenticated;
GRANT SELECT ON analytics_day_of_week TO anon, authenticated;
GRANT SELECT ON analytics_top_customers TO anon, authenticated;

-- Test the functions
SELECT * FROM get_store_metrics(1, 'today');
SELECT * FROM get_revenue_chart_data(1, 'today');
SELECT get_business_insights(1);
