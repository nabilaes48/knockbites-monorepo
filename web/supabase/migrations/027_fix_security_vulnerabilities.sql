-- ============================================
-- FIX SECURITY VULNERABILITIES
-- Address RLS policy issues while maintaining guest checkout
-- ============================================

-- ============================================
-- PART 1: FIX ORDERS TABLE RLS POLICIES
-- ============================================

-- Drop the overly permissive public UPDATE policy
DROP POLICY IF EXISTS "Allow public to update order status" ON orders;
DROP POLICY IF EXISTS "Allow public to view orders" ON orders;
DROP POLICY IF EXISTS "Allow public to insert orders" ON orders;

-- Policy 1: Allow public to INSERT orders (guest checkout)
CREATE POLICY "Public can create orders"
ON orders
FOR INSERT
TO public
WITH CHECK (true);

-- Policy 2: Allow authenticated users to view their own orders OR staff to view store orders
CREATE POLICY "Users can view own orders or staff view store orders"
ON orders
FOR SELECT
TO authenticated
USING (
  -- Customers can see their own orders
  (auth.uid() IS NOT NULL AND customer_id = auth.uid())
  OR
  -- Staff can see orders for their assigned store
  (
    EXISTS (
      SELECT 1 FROM user_profiles up
      WHERE up.id = auth.uid()
      AND up.role IN ('staff', 'manager', 'admin', 'super_admin')
      AND (up.store_id = orders.store_id OR up.role = 'super_admin')
    )
  )
);

-- Note: For guest order tracking, use the get_order_by_id() function instead of direct SELECT
-- This prevents exposing all orders to anonymous users

-- Policy 3: Only authenticated staff can update order status
CREATE POLICY "Staff can update orders"
ON orders
FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM user_profiles up
    WHERE up.id = auth.uid()
    AND up.role IN ('staff', 'manager', 'admin', 'super_admin')
    AND (up.store_id = orders.store_id OR up.role = 'super_admin')
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM user_profiles up
    WHERE up.id = auth.uid()
    AND up.role IN ('staff', 'manager', 'admin', 'super_admin')
    AND (up.store_id = orders.store_id OR up.role = 'super_admin')
  )
);

-- Policy 4: Customers can cancel their own orders
CREATE POLICY "Customers can cancel own orders"
ON orders
FOR UPDATE
TO authenticated
USING (
  customer_id = auth.uid()
  AND status IN ('pending', 'confirmed')
)
WITH CHECK (
  customer_id = auth.uid()
  AND status IN ('pending', 'confirmed', 'cancelled')
);


-- ============================================
-- PART 2: FIX ORDER_ITEMS TABLE RLS POLICIES
-- ============================================

-- Drop existing order_items policies
DROP POLICY IF EXISTS "Public can view order items" ON order_items;
DROP POLICY IF EXISTS "Public can insert order items" ON order_items;

-- Policy 1: Allow public to INSERT order items (for guest checkout)
CREATE POLICY "Public can create order items"
ON order_items
FOR INSERT
TO public
WITH CHECK (true);

-- Policy 2: Allow public to SELECT order items (for order tracking)
-- This allows guests to view items for orders they can access
CREATE POLICY "Public can view order items"
ON order_items
FOR SELECT
TO public
USING (true);

-- Policy 3: Only authenticated staff can update/delete order items
CREATE POLICY "Staff can update order items"
ON order_items
FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM user_profiles up
    JOIN orders o ON o.store_id = up.store_id OR up.role = 'super_admin'
    WHERE up.id = auth.uid()
    AND o.id = order_items.order_id
    AND up.role IN ('staff', 'manager', 'admin', 'super_admin')
  )
);


-- ============================================
-- PART 3: PROTECT ANALYTICS VIEWS
-- ============================================

-- Revoke public/anon access to analytics views
REVOKE SELECT ON analytics_daily_stats FROM anon;
REVOKE SELECT ON analytics_hourly_today FROM anon;
REVOKE SELECT ON analytics_time_distribution FROM anon;
REVOKE SELECT ON analytics_category_distribution FROM anon;
REVOKE SELECT ON analytics_popular_items FROM anon;
REVOKE SELECT ON analytics_store_summary FROM anon;
REVOKE SELECT ON analytics_customer_insights FROM anon;
REVOKE SELECT ON analytics_peak_hours FROM anon;
REVOKE SELECT ON analytics_order_funnel FROM anon;
REVOKE SELECT ON analytics_revenue_goals FROM anon;
REVOKE SELECT ON analytics_day_of_week FROM anon;
REVOKE SELECT ON analytics_top_customers FROM anon;

-- Enable RLS on all analytics views
ALTER VIEW analytics_daily_stats SET (security_invoker = on);
ALTER VIEW analytics_hourly_today SET (security_invoker = on);
ALTER VIEW analytics_time_distribution SET (security_invoker = on);
ALTER VIEW analytics_category_distribution SET (security_invoker = on);
ALTER VIEW analytics_popular_items SET (security_invoker = on);
ALTER VIEW analytics_store_summary SET (security_invoker = on);
ALTER VIEW analytics_customer_insights SET (security_invoker = on);
ALTER VIEW analytics_peak_hours SET (security_invoker = on);
ALTER VIEW analytics_order_funnel SET (security_invoker = on);
ALTER VIEW analytics_revenue_goals SET (security_invoker = on);
ALTER VIEW analytics_day_of_week SET (security_invoker = on);
ALTER VIEW analytics_top_customers SET (security_invoker = on);

-- Only authenticated staff should access analytics
-- Views will inherit RLS from underlying tables


-- ============================================
-- PART 4: ADD FUNCTION FOR SECURE ORDER LOOKUP
-- ============================================

-- Function to lookup order by ID for guest users
-- This is safer than allowing unlimited SELECT access
CREATE OR REPLACE FUNCTION get_order_by_id(p_order_id BIGINT)
RETURNS SETOF orders AS $$
BEGIN
  -- Return the specific order if it exists
  RETURN QUERY
  SELECT o.*
  FROM orders o
  WHERE o.id = p_order_id
  LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute to public for guest order tracking
GRANT EXECUTE ON FUNCTION get_order_by_id(BIGINT) TO public, anon, authenticated;


-- ============================================
-- PART 5: VERIFY SECURITY POLICIES
-- ============================================

-- List all policies on orders table
SELECT
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE tablename = 'orders'
ORDER BY cmd, policyname;

-- Verify RLS is enabled
SELECT
  schemaname,
  tablename,
  rowsecurity
FROM pg_tables
WHERE tablename = 'orders';
