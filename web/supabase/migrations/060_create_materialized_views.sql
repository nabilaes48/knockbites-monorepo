-- =====================================================
-- Migration 060: Materialized Views for Analytics Performance
-- Version: 1.0
-- Date: 2025-12-02
-- Purpose: Create materialized views for expensive analytics queries
-- =====================================================

-- =====================================================
-- 1. mv_popular_items - Most ordered items per store
-- =====================================================

-- Create unique index requirement for CONCURRENTLY refresh
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_popular_items AS
SELECT
  oi.menu_item_id,
  mi.name AS item_name,
  mi.category_id,
  o.store_id,
  COUNT(*) AS order_count,
  SUM(oi.quantity) AS total_quantity,
  SUM(mi.price * oi.quantity) AS total_revenue,
  DATE_TRUNC('day', o.created_at) AS order_date
FROM order_items oi
JOIN orders o ON o.id = oi.order_id
JOIN menu_items mi ON mi.id = oi.menu_item_id
WHERE o.status IN ('completed', 'ready', 'preparing')
  AND o.created_at >= NOW() - INTERVAL '90 days'
GROUP BY oi.menu_item_id, mi.name, mi.category_id, o.store_id, DATE_TRUNC('day', o.created_at);

-- Unique index for CONCURRENTLY refresh
CREATE UNIQUE INDEX IF NOT EXISTS mv_popular_items_unique_idx
ON mv_popular_items (menu_item_id, store_id, order_date);

-- Additional indexes for query performance
CREATE INDEX IF NOT EXISTS mv_popular_items_store_idx
ON mv_popular_items (store_id);

CREATE INDEX IF NOT EXISTS mv_popular_items_category_idx
ON mv_popular_items (category_id);

CREATE INDEX IF NOT EXISTS mv_popular_items_revenue_idx
ON mv_popular_items (total_revenue DESC);

-- =====================================================
-- 2. mv_top_customers - Highest value customers
-- =====================================================

CREATE MATERIALIZED VIEW IF NOT EXISTS mv_top_customers AS
SELECT
  COALESCE(o.customer_id, o.user_id) AS customer_identifier,
  o.customer_email,
  o.customer_name,
  o.store_id,
  COUNT(DISTINCT o.id) AS total_orders,
  SUM(o.total) AS lifetime_value,
  AVG(o.total) AS average_order_value,
  MAX(o.created_at) AS last_order_date,
  MIN(o.created_at) AS first_order_date
FROM orders o
WHERE o.status IN ('completed', 'ready')
  AND o.total > 0
  AND (o.customer_email IS NOT NULL OR o.customer_id IS NOT NULL OR o.user_id IS NOT NULL)
GROUP BY COALESCE(o.customer_id, o.user_id), o.customer_email, o.customer_name, o.store_id;

-- Unique index for CONCURRENTLY refresh
CREATE UNIQUE INDEX IF NOT EXISTS mv_top_customers_unique_idx
ON mv_top_customers (customer_identifier, customer_email, store_id);

-- Additional indexes
CREATE INDEX IF NOT EXISTS mv_top_customers_store_idx
ON mv_top_customers (store_id);

CREATE INDEX IF NOT EXISTS mv_top_customers_ltv_idx
ON mv_top_customers (lifetime_value DESC);

CREATE INDEX IF NOT EXISTS mv_top_customers_orders_idx
ON mv_top_customers (total_orders DESC);

-- =====================================================
-- 3. mv_store_daily_summary - Daily aggregates per store
-- =====================================================

CREATE MATERIALIZED VIEW IF NOT EXISTS mv_store_daily_summary AS
SELECT
  o.store_id,
  DATE_TRUNC('day', o.created_at) AS summary_date,
  COUNT(*) AS total_orders,
  COUNT(*) FILTER (WHERE o.status = 'completed') AS completed_orders,
  COUNT(*) FILTER (WHERE o.status = 'cancelled') AS cancelled_orders,
  SUM(o.total) AS gross_revenue,
  SUM(o.total) FILTER (WHERE o.status IN ('completed', 'ready')) AS net_revenue,
  AVG(o.total) AS average_order_value,
  COUNT(DISTINCT COALESCE(o.customer_id::TEXT, o.customer_email)) AS unique_customers,
  MIN(o.created_at) AS first_order_time,
  MAX(o.created_at) AS last_order_time
FROM orders o
WHERE o.created_at >= NOW() - INTERVAL '365 days'
GROUP BY o.store_id, DATE_TRUNC('day', o.created_at);

-- Unique index for CONCURRENTLY refresh
CREATE UNIQUE INDEX IF NOT EXISTS mv_store_daily_summary_unique_idx
ON mv_store_daily_summary (store_id, summary_date);

-- Additional indexes
CREATE INDEX IF NOT EXISTS mv_store_daily_summary_date_idx
ON mv_store_daily_summary (summary_date DESC);

CREATE INDEX IF NOT EXISTS mv_store_daily_summary_revenue_idx
ON mv_store_daily_summary (net_revenue DESC);

-- =====================================================
-- 4. mv_hourly_traffic - Hourly order patterns
-- =====================================================

CREATE MATERIALIZED VIEW IF NOT EXISTS mv_hourly_traffic AS
SELECT
  o.store_id,
  EXTRACT(DOW FROM o.created_at) AS day_of_week,
  EXTRACT(HOUR FROM o.created_at) AS hour_of_day,
  COUNT(*) AS order_count,
  AVG(o.total) AS average_order_value,
  SUM(o.total) AS total_revenue
FROM orders o
WHERE o.status IN ('completed', 'ready', 'preparing')
  AND o.created_at >= NOW() - INTERVAL '90 days'
GROUP BY o.store_id, EXTRACT(DOW FROM o.created_at), EXTRACT(HOUR FROM o.created_at);

-- Unique index for CONCURRENTLY refresh
CREATE UNIQUE INDEX IF NOT EXISTS mv_hourly_traffic_unique_idx
ON mv_hourly_traffic (store_id, day_of_week, hour_of_day);

-- =====================================================
-- 5. Refresh Function - Call periodically
-- =====================================================

CREATE OR REPLACE FUNCTION refresh_analytics_materialized_views()
RETURNS void AS $func$
BEGIN
  -- Use CONCURRENTLY to avoid locking reads during refresh
  REFRESH MATERIALIZED VIEW CONCURRENTLY mv_popular_items;
  REFRESH MATERIALIZED VIEW CONCURRENTLY mv_top_customers;
  REFRESH MATERIALIZED VIEW CONCURRENTLY mv_store_daily_summary;
  REFRESH MATERIALIZED VIEW CONCURRENTLY mv_hourly_traffic;
END;
$func$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 6. Grant access to authenticated users
-- =====================================================

GRANT SELECT ON mv_popular_items TO authenticated;
GRANT SELECT ON mv_top_customers TO authenticated;
GRANT SELECT ON mv_store_daily_summary TO authenticated;
GRANT SELECT ON mv_hourly_traffic TO authenticated;

-- =====================================================
-- 7. Initial refresh
-- =====================================================

-- Perform initial non-concurrent refresh (required for first population)
REFRESH MATERIALIZED VIEW mv_popular_items;
REFRESH MATERIALIZED VIEW mv_top_customers;
REFRESH MATERIALIZED VIEW mv_store_daily_summary;
REFRESH MATERIALIZED VIEW mv_hourly_traffic;

-- =====================================================
-- SUCCESS! Migration 060 complete.
--
-- Created materialized views:
-- - mv_popular_items: Top selling items per store (90 days)
-- - mv_top_customers: Highest value customers
-- - mv_store_daily_summary: Daily revenue/order aggregates (365 days)
-- - mv_hourly_traffic: Peak hours analysis (90 days)
--
-- Refresh Strategy:
-- - Call refresh_analytics_materialized_views() via cron job
-- - Recommended: Every 15-30 minutes during business hours
-- - Or use pg_cron: SELECT cron.schedule('*/15 * * * *', 'SELECT refresh_analytics_materialized_views()');
--
-- Query Examples:
-- SELECT * FROM mv_popular_items WHERE store_id = 1 ORDER BY total_quantity DESC LIMIT 10;
-- SELECT * FROM mv_top_customers WHERE store_id = 1 ORDER BY lifetime_value DESC LIMIT 20;
-- SELECT * FROM mv_store_daily_summary WHERE store_id = 1 AND summary_date >= CURRENT_DATE - 30;
-- SELECT * FROM mv_hourly_traffic WHERE store_id = 1 ORDER BY order_count DESC;
-- =====================================================
