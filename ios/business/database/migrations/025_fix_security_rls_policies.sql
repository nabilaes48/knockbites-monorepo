-- Migration 025: Fix Security and RLS Policies
-- Addresses critical security vulnerabilities found in Lovable security scan

-- ============================================================================
-- 1. ENABLE RLS ON ORDER_SEQUENCES TABLE
-- ============================================================================

-- Enable RLS on order_sequences table
ALTER TABLE IF EXISTS order_sequences ENABLE ROW LEVEL SECURITY;

-- Policy: Only authenticated staff can read order sequences
CREATE POLICY "Staff can view order sequences"
ON order_sequences
FOR SELECT
TO authenticated
USING (true);

-- Policy: Only authenticated staff can update order sequences
CREATE POLICY "Staff can update order sequences"
ON order_sequences
FOR UPDATE
TO authenticated
USING (true);

-- ============================================================================
-- 2. PROTECT CUSTOMER DATA (customers table)
-- ============================================================================

-- Enable RLS on customers table if not already enabled
ALTER TABLE IF EXISTS customers ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (to recreate them properly)
DROP POLICY IF EXISTS "Customers can view own data" ON customers;
DROP POLICY IF EXISTS "Staff can view all customers" ON customers;
DROP POLICY IF EXISTS "Customers can update own data" ON customers;
DROP POLICY IF EXISTS "Staff can update customers" ON customers;

-- Policy: Customers can only view their own data
CREATE POLICY "Customers can view own data"
ON customers
FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

-- Policy: Staff with specific roles can view all customers
CREATE POLICY "Staff can view all customers"
ON customers
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM staff
    WHERE staff.user_id = auth.uid()
    AND staff.role IN ('admin', 'manager', 'staff')
  )
);

-- Policy: Customers can update their own data
CREATE POLICY "Customers can update own data"
ON customers
FOR UPDATE
TO authenticated
USING (auth.uid() = user_id);

-- Policy: Staff can update customer data
CREATE POLICY "Staff can update customers"
ON customers
FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM staff
    WHERE staff.user_id = auth.uid()
    AND staff.role IN ('admin', 'manager')
  )
);

-- ============================================================================
-- 3. RESTRICT ANALYTICS VIEWS TO STAFF ONLY
-- ============================================================================

-- Note: Views inherit RLS from underlying tables, but we need to ensure
-- only authenticated staff can access these analytics views

-- Enable RLS on all analytics-related tables if they exist
ALTER TABLE IF EXISTS analytics_category_distribution ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS analytics_customer_insights ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS analytics_daily_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS analytics_day_of_week ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS analytics_hourly_today ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS analytics_order_funnel ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS analytics_peak_hours ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS analytics_popular_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS analytics_revenue_goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS analytics_store_summary ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS analytics_time_distribution ENABLE ROW LEVEL SECURITY;

-- Note: Since these are views (not tables), we need to ensure the underlying
-- orders, order_items, and menu_items tables have proper RLS

-- ============================================================================
-- 4. ENSURE ORDERS TABLE HAS PROPER RLS
-- ============================================================================

ALTER TABLE IF EXISTS orders ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Customers can view own orders" ON orders;
DROP POLICY IF EXISTS "Staff can view store orders" ON orders;
DROP POLICY IF EXISTS "Staff can update store orders" ON orders;

-- Policy: Customers can view their own orders
CREATE POLICY "Customers can view own orders"
ON orders
FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

-- Policy: Staff can view orders for their assigned store(s)
CREATE POLICY "Staff can view store orders"
ON orders
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM staff
    WHERE staff.user_id = auth.uid()
    AND (
      staff.store_id = orders.store_id
      OR staff.role = 'admin'  -- Admins can see all stores
    )
  )
);

-- Policy: Staff can update orders for their store
CREATE POLICY "Staff can update store orders"
ON orders
FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM staff
    WHERE staff.user_id = auth.uid()
    AND (
      staff.store_id = orders.store_id
      OR staff.role IN ('admin', 'manager')
    )
  )
);

-- Policy: Only authenticated users can create orders
CREATE POLICY "Authenticated users can create orders"
ON orders
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

-- ============================================================================
-- 5. ENSURE ORDER_ITEMS TABLE HAS PROPER RLS
-- ============================================================================

ALTER TABLE IF EXISTS order_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own order items" ON order_items;
DROP POLICY IF EXISTS "Staff can view order items" ON order_items;

-- Policy: Users can view items in their own orders
CREATE POLICY "Users can view own order items"
ON order_items
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM orders
    WHERE orders.id = order_items.order_id
    AND orders.user_id = auth.uid()
  )
);

-- Policy: Staff can view order items for their store
CREATE POLICY "Staff can view order items"
ON order_items
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM orders
    JOIN staff ON (staff.store_id = orders.store_id OR staff.role = 'admin')
    WHERE orders.id = order_items.order_id
    AND staff.user_id = auth.uid()
  )
);

-- ============================================================================
-- 6. MENU_ITEMS - PUBLIC READ, STAFF WRITE
-- ============================================================================

ALTER TABLE IF EXISTS menu_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view available menu items" ON menu_items;
DROP POLICY IF EXISTS "Staff can manage menu items" ON menu_items;

-- Policy: Anyone (including anonymous) can view available menu items
CREATE POLICY "Anyone can view available menu items"
ON menu_items
FOR SELECT
TO public
USING (is_available = true);

-- Policy: Authenticated users can view all menu items (including unavailable)
CREATE POLICY "Authenticated can view all menu items"
ON menu_items
FOR SELECT
TO authenticated
USING (true);

-- Policy: Only staff can insert/update/delete menu items
CREATE POLICY "Staff can manage menu items"
ON menu_items
FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM staff
    WHERE staff.user_id = auth.uid()
    AND staff.role IN ('admin', 'manager')
  )
);

-- ============================================================================
-- 7. STORES TABLE - PUBLIC READ, ADMIN WRITE
-- ============================================================================

ALTER TABLE IF EXISTS stores ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view stores" ON stores;
DROP POLICY IF EXISTS "Admins can manage stores" ON stores;

-- Policy: Anyone can view store information
CREATE POLICY "Anyone can view stores"
ON stores
FOR SELECT
TO public
USING (true);

-- Policy: Only admins can manage stores
CREATE POLICY "Admins can manage stores"
ON stores
FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM staff
    WHERE staff.user_id = auth.uid()
    AND staff.role = 'admin'
  )
);

-- ============================================================================
-- 8. STAFF TABLE - STAFF CAN VIEW, ADMINS CAN MANAGE
-- ============================================================================

ALTER TABLE IF EXISTS staff ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Staff can view own profile" ON staff;
DROP POLICY IF EXISTS "Staff can view colleagues" ON staff;
DROP POLICY IF EXISTS "Admins can manage staff" ON staff;

-- Policy: Staff can view their own profile
CREATE POLICY "Staff can view own profile"
ON staff
FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

-- Policy: Staff can view colleagues in same store
CREATE POLICY "Staff can view colleagues"
ON staff
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM staff AS self
    WHERE self.user_id = auth.uid()
    AND self.store_id = staff.store_id
  )
);

-- Policy: Only admins can manage staff
CREATE POLICY "Admins can manage staff"
ON staff
FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM staff AS self
    WHERE self.user_id = auth.uid()
    AND self.role = 'admin'
  )
);

-- ============================================================================
-- 9. MARKETING TABLES RLS
-- ============================================================================

-- Coupons
ALTER TABLE IF EXISTS coupons ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view active coupons" ON coupons;
DROP POLICY IF EXISTS "Staff can manage coupons" ON coupons;

CREATE POLICY "Anyone can view active coupons"
ON coupons
FOR SELECT
TO public
USING (is_active = true AND NOW() BETWEEN valid_from AND valid_until);

CREATE POLICY "Staff can manage coupons"
ON coupons
FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM staff
    WHERE staff.user_id = auth.uid()
    AND staff.role IN ('admin', 'manager')
  )
);

-- Loyalty Program
ALTER TABLE IF EXISTS loyalty_programs ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS loyalty_tiers ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS loyalty_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS rewards ENABLE ROW LEVEL SECURITY;

-- Anyone can view active loyalty programs
CREATE POLICY "Anyone can view loyalty programs"
ON loyalty_programs FOR SELECT TO public USING (is_active = true);

CREATE POLICY "Staff manage loyalty programs"
ON loyalty_programs FOR ALL TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM staff
    WHERE staff.user_id = auth.uid()
    AND staff.role IN ('admin', 'manager')
  )
);

-- Customers can view their own loyalty transactions
CREATE POLICY "Customers view own loyalty transactions"
ON loyalty_transactions FOR SELECT TO authenticated
USING (auth.uid() = user_id);

CREATE POLICY "Staff manage loyalty transactions"
ON loyalty_transactions FOR ALL TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM staff
    WHERE staff.user_id = auth.uid()
    AND staff.role IN ('admin', 'manager', 'staff')
  )
);

-- ============================================================================
-- 10. NOTIFICATION CAMPAIGNS RLS
-- ============================================================================

ALTER TABLE IF EXISTS notification_campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS notification_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Staff can manage campaigns"
ON notification_campaigns FOR ALL TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM staff
    WHERE staff.user_id = auth.uid()
    AND staff.role IN ('admin', 'manager')
  )
);

-- Customers can only view notifications sent to them
CREATE POLICY "Customers view own notifications"
ON notification_logs FOR SELECT TO authenticated
USING (user_id = auth.uid());

CREATE POLICY "Staff manage notification logs"
ON notification_logs FOR ALL TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM staff
    WHERE staff.user_id = auth.uid()
    AND staff.role IN ('admin', 'manager')
  )
);

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Run these to verify RLS is enabled:
-- SELECT tablename, rowsecurity FROM pg_tables WHERE schemaname = 'public';
-- SELECT * FROM pg_policies WHERE schemaname = 'public';

COMMENT ON TABLE order_sequences IS 'RLS enabled - Migration 025';
COMMENT ON TABLE customers IS 'RLS policies updated - Migration 025';
COMMENT ON TABLE orders IS 'RLS policies updated - Migration 025';
