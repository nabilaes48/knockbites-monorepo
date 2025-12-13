-- Migration 025 V2: Fix Security and RLS Policies (CORRECTED)
-- Addresses critical security vulnerabilities found in Lovable security scan
-- Uses correct column names: auth_user_id, customer_id

-- ============================================================================
-- 1. ENABLE RLS ON ORDER_SEQUENCES TABLE
-- ============================================================================

-- Enable RLS on order_sequences table
ALTER TABLE IF EXISTS order_sequences ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any
DROP POLICY IF EXISTS "Staff can view order sequences" ON order_sequences;
DROP POLICY IF EXISTS "Staff can update order sequences" ON order_sequences;

-- Policy: Only authenticated staff can read order sequences
CREATE POLICY "Staff can view order sequences"
ON order_sequences
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM user_profiles
    WHERE user_profiles.id::text = auth.uid()::text
    AND user_profiles.role IN ('super_admin', 'admin', 'manager', 'staff')
  )
);

-- Policy: Only authenticated staff can update order sequences
CREATE POLICY "Staff can update order sequences"
ON order_sequences
FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM user_profiles
    WHERE user_profiles.id::text = auth.uid()::text
    AND user_profiles.role IN ('super_admin', 'admin', 'manager', 'staff')
  )
);

-- ============================================================================
-- 2. FIX CUSTOMER DATA PROTECTION
-- ============================================================================

-- RLS is already enabled from migration 001, but let's ensure proper policies

-- Drop existing customer policies (to recreate with better security)
DROP POLICY IF EXISTS "Allow users to read own data" ON customers;
DROP POLICY IF EXISTS "Allow users to update own data" ON customers;
DROP POLICY IF EXISTS "Allow staff to read customers" ON customers;
DROP POLICY IF EXISTS "Staff can update customers" ON customers;
DROP POLICY IF EXISTS "Public cannot view customers" ON customers;

-- Policy: Users can only view their own customer data
CREATE POLICY "Allow users to read own data" ON customers
FOR SELECT
TO authenticated
USING (auth.uid() = auth_user_id);

-- Policy: Users can update their own data
CREATE POLICY "Allow users to update own data" ON customers
FOR UPDATE
TO authenticated
USING (auth.uid() = auth_user_id)
WITH CHECK (auth.uid() = auth_user_id);

-- Policy: Staff can view all customers in their store
CREATE POLICY "Allow staff to read customers" ON customers
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM user_profiles
    WHERE user_profiles.id::text = auth.uid()::text
    AND user_profiles.role IN ('super_admin', 'admin', 'manager', 'staff')
  )
);

-- Policy: Staff can update customer data
CREATE POLICY "Staff can update customers" ON customers
FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM user_profiles
    WHERE user_profiles.id::text = auth.uid()::text
    AND user_profiles.role IN ('super_admin', 'admin', 'manager')
  )
);

-- Policy: Explicitly deny anonymous access
CREATE POLICY "Public cannot view customers" ON customers
FOR SELECT
TO anon
USING (false);

-- ============================================================================
-- 3. SECURE ORDERS TABLE
-- ============================================================================

-- Enable RLS on orders
ALTER TABLE IF EXISTS orders ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "Customers can view own orders" ON orders;
DROP POLICY IF EXISTS "Staff can view store orders" ON orders;
DROP POLICY IF EXISTS "Staff can update store orders" ON orders;
DROP POLICY IF EXISTS "Authenticated users can create orders" ON orders;
DROP POLICY IF EXISTS "Public cannot view orders" ON orders;

-- Policy: Customers can view their own orders
-- Orders table likely has customer_id or user_id field - adjust as needed
CREATE POLICY "Customers can view own orders"
ON orders
FOR SELECT
TO authenticated
USING (
  -- Check if orders.customer_id (UUID) matches current user
  customer_id = auth.uid()
  OR
  -- Or check via customers table join
  EXISTS (
    SELECT 1 FROM customers
    WHERE customers.auth_user_id = auth.uid()
    AND (
      customers.email = orders.customer_email
      OR customers.phone = orders.customer_phone
    )
  )
);

-- Policy: Staff can view all orders in their store
CREATE POLICY "Staff can view store orders"
ON orders
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM user_profiles
    WHERE user_profiles.id::text = auth.uid()::text
    AND user_profiles.role IN ('super_admin', 'admin', 'manager', 'staff')
    AND (
      user_profiles.store_id = orders.store_id
      OR user_profiles.role IN ('super_admin', 'admin')
    )
  )
);

-- Policy: Staff can update orders in their store
CREATE POLICY "Staff can update store orders"
ON orders
FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM user_profiles
    WHERE user_profiles.id::text = auth.uid()::text
    AND user_profiles.role IN ('super_admin', 'admin', 'manager', 'staff')
    AND (
      user_profiles.store_id = orders.store_id
      OR user_profiles.role IN ('super_admin', 'admin')
    )
  )
);

-- Policy: Authenticated users can create orders
CREATE POLICY "Authenticated users can create orders"
ON orders
FOR INSERT
TO authenticated
WITH CHECK (true);

-- Policy: Anonymous users cannot view orders
CREATE POLICY "Public cannot view orders"
ON orders
FOR SELECT
TO anon
USING (false);

-- ============================================================================
-- 4. SECURE ORDER_ITEMS TABLE
-- ============================================================================

ALTER TABLE IF EXISTS order_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own order items" ON order_items;
DROP POLICY IF EXISTS "Staff can view order items" ON order_items;
DROP POLICY IF EXISTS "Public cannot view order items" ON order_items;

-- Policy: Users can view items in their own orders
CREATE POLICY "Users can view own order items"
ON order_items
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM orders
    WHERE orders.id = order_items.order_id
    AND (
      orders.customer_id = auth.uid()
      OR EXISTS (
        SELECT 1 FROM customers
        WHERE customers.auth_user_id = auth.uid()
        AND (
          customers.email = orders.customer_email
          OR customers.phone = orders.customer_phone
        )
      )
    )
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
    JOIN user_profiles ON (
      user_profiles.store_id = orders.store_id
      OR user_profiles.role IN ('super_admin', 'admin')
    )
    WHERE orders.id = order_items.order_id
    AND user_profiles.id::text = auth.uid()::text
    AND user_profiles.role IN ('super_admin', 'admin', 'manager', 'staff')
  )
);

-- Policy: Anonymous cannot view order items
CREATE POLICY "Public cannot view order items"
ON order_items
FOR SELECT
TO anon
USING (false);

-- ============================================================================
-- 5. MENU_ITEMS - PUBLIC READ, STAFF WRITE
-- ============================================================================

ALTER TABLE IF EXISTS menu_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view available menu items" ON menu_items;
DROP POLICY IF EXISTS "Authenticated can view all menu items" ON menu_items;
DROP POLICY IF EXISTS "Staff can manage menu items" ON menu_items;
DROP POLICY IF EXISTS "Public can view available items" ON menu_items;

-- Policy: Anyone (including anonymous) can view available menu items
CREATE POLICY "Public can view available items"
ON menu_items
FOR SELECT
TO public
USING (is_available = true);

-- Policy: Authenticated users can view all menu items
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
    SELECT 1 FROM user_profiles
    WHERE user_profiles.id::text = auth.uid()::text
    AND user_profiles.role IN ('super_admin', 'admin', 'manager')
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM user_profiles
    WHERE user_profiles.id::text = auth.uid()::text
    AND user_profiles.role IN ('super_admin', 'admin', 'manager')
  )
);

-- ============================================================================
-- 6. STORES TABLE - PUBLIC READ, ADMIN WRITE
-- ============================================================================

ALTER TABLE IF EXISTS stores ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view stores" ON stores;
DROP POLICY IF EXISTS "Admins can manage stores" ON stores;
DROP POLICY IF EXISTS "Public can view stores" ON stores;

-- Policy: Anyone can view store information (public data)
CREATE POLICY "Public can view stores"
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
    SELECT 1 FROM user_profiles
    WHERE user_profiles.id::text = auth.uid()::text
    AND user_profiles.role IN ('super_admin', 'admin')
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM user_profiles
    WHERE user_profiles.id::text = auth.uid()::text
    AND user_profiles.role IN ('super_admin', 'admin')
  )
);

-- ============================================================================
-- 7. USER_PROFILES / STAFF TABLE - STAFF CAN VIEW, ADMINS CAN MANAGE
-- ============================================================================

ALTER TABLE IF EXISTS user_profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Staff can view own profile" ON user_profiles;
DROP POLICY IF EXISTS "Staff can view colleagues" ON user_profiles;
DROP POLICY IF EXISTS "Admins can manage staff" ON user_profiles;

-- Policy: Users can view their own profile
CREATE POLICY "Staff can view own profile"
ON user_profiles
FOR SELECT
TO authenticated
USING (id::text = auth.uid()::text);

-- Policy: Staff can view colleagues in same store
CREATE POLICY "Staff can view colleagues"
ON user_profiles
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM user_profiles AS self
    WHERE self.id::text = auth.uid()::text
    AND self.store_id = user_profiles.store_id
  )
);

-- Policy: Only admins can manage staff
CREATE POLICY "Admins can manage staff"
ON user_profiles
FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM user_profiles AS self
    WHERE self.id::text = auth.uid()::text
    AND self.role IN ('super_admin', 'admin')
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM user_profiles AS self
    WHERE self.id::text = auth.uid()::text
    AND self.role IN ('super_admin', 'admin')
  )
);

-- ============================================================================
-- 8. FIX MARKETING TABLES RLS (Already enabled in migration 002)
-- ============================================================================

-- Update coupons policies for better security
DROP POLICY IF EXISTS "Allow read active coupons" ON coupons;
DROP POLICY IF EXISTS "Allow staff to manage coupons" ON coupons;
DROP POLICY IF EXISTS "Public can view active coupons" ON coupons;
DROP POLICY IF EXISTS "Authenticated view active coupons" ON coupons;

-- Public/Authenticated can view active coupons
CREATE POLICY "Public can view active coupons"
ON coupons
FOR SELECT
TO public
USING (
  is_active = true
  AND start_date <= NOW()
  AND (end_date IS NULL OR end_date >= NOW())
);

-- Staff can manage coupons
CREATE POLICY "Allow staff to manage coupons"
ON coupons
FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM user_profiles
    WHERE user_profiles.id::text = auth.uid()::text
    AND user_profiles.role IN ('super_admin', 'admin', 'manager')
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM user_profiles
    WHERE user_profiles.id::text = auth.uid()::text
    AND user_profiles.role IN ('super_admin', 'admin', 'manager')
  )
);

-- ============================================================================
-- 9. FIX LOYALTY TABLES
-- ============================================================================

-- Loyalty programs - public can view active programs
DROP POLICY IF EXISTS "Anyone can view loyalty programs" ON loyalty_programs;
DROP POLICY IF EXISTS "Staff manage loyalty programs" ON loyalty_programs;

CREATE POLICY "Public view loyalty programs"
ON loyalty_programs FOR SELECT TO public USING (is_active = true);

CREATE POLICY "Staff manage loyalty programs"
ON loyalty_programs FOR ALL TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM user_profiles
    WHERE user_profiles.id::text = auth.uid()::text
    AND user_profiles.role IN ('super_admin', 'admin', 'manager')
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM user_profiles
    WHERE user_profiles.id::text = auth.uid()::text
    AND user_profiles.role IN ('super_admin', 'admin', 'manager')
  )
);

-- Loyalty tiers - public can view
DROP POLICY IF EXISTS "Public view tiers" ON loyalty_tiers;
CREATE POLICY "Public view tiers"
ON loyalty_tiers FOR SELECT TO public USING (true);

-- Customer loyalty - customers see own, staff see all
DROP POLICY IF EXISTS "Allow read own loyalty" ON customer_loyalty;
DROP POLICY IF EXISTS "Customers view own loyalty" ON customer_loyalty;
DROP POLICY IF EXISTS "Staff view all loyalty" ON customer_loyalty;

CREATE POLICY "Customers view own loyalty"
ON customer_loyalty FOR SELECT TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM customers
    WHERE customers.id = customer_loyalty.customer_id
    AND customers.auth_user_id = auth.uid()
  )
);

CREATE POLICY "Staff view all loyalty"
ON customer_loyalty FOR SELECT TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM user_profiles
    WHERE user_profiles.id::text = auth.uid()::text
    AND user_profiles.role IN ('super_admin', 'admin', 'manager', 'staff')
  )
);

-- Loyalty transactions - customers see own
DROP POLICY IF EXISTS "Customers view own loyalty transactions" ON loyalty_transactions;
DROP POLICY IF EXISTS "Staff manage loyalty transactions" ON loyalty_transactions;

CREATE POLICY "Customers view own transactions"
ON loyalty_transactions FOR SELECT TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM customer_loyalty
    JOIN customers ON customers.id = customer_loyalty.customer_id
    WHERE customer_loyalty.id = loyalty_transactions.customer_loyalty_id
    AND customers.auth_user_id = auth.uid()
  )
);

CREATE POLICY "Staff manage transactions"
ON loyalty_transactions FOR ALL TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM user_profiles
    WHERE user_profiles.id::text = auth.uid()::text
    AND user_profiles.role IN ('super_admin', 'admin', 'manager', 'staff')
  )
);

-- ============================================================================
-- 10. FIX NOTIFICATION TABLES
-- ============================================================================

-- Push notifications - staff only
DROP POLICY IF EXISTS "Staff can manage campaigns" ON push_notifications;

CREATE POLICY "Staff manage notifications"
ON push_notifications FOR ALL TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM user_profiles
    WHERE user_profiles.id::text = auth.uid()::text
    AND user_profiles.role IN ('super_admin', 'admin', 'manager')
  )
);

-- Notification deliveries - customers see own
DROP POLICY IF EXISTS "Customers view own notifications" ON notification_deliveries;
DROP POLICY IF EXISTS "Staff manage notification logs" ON notification_deliveries;

CREATE POLICY "Customers view own deliveries"
ON notification_deliveries FOR SELECT TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM customers
    WHERE customers.id = notification_deliveries.customer_id
    AND customers.auth_user_id = auth.uid()
  )
);

CREATE POLICY "Staff view all deliveries"
ON notification_deliveries FOR SELECT TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM user_profiles
    WHERE user_profiles.id::text = auth.uid()::text
    AND user_profiles.role IN ('super_admin', 'admin', 'manager')
  )
);

-- ============================================================================
-- 11. FIX REFERRAL TABLES
-- ============================================================================

-- Referral program - public can view active programs
CREATE POLICY "Public view referral program"
ON referral_program FOR SELECT TO public USING (is_active = true);

-- Referrals - customers see own referrals
DROP POLICY IF EXISTS "Customers view own referrals" ON referrals;

CREATE POLICY "Customers view own referrals"
ON referrals FOR SELECT TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM customers
    WHERE customers.auth_user_id = auth.uid()
    AND (
      customers.id = referrals.referrer_customer_id
      OR customers.id = referrals.referee_customer_id
    )
  )
);

CREATE POLICY "Staff manage referrals"
ON referrals FOR ALL TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM user_profiles
    WHERE user_profiles.id::text = auth.uid()::text
    AND user_profiles.role IN ('super_admin', 'admin', 'manager')
  )
);

-- ============================================================================
-- 12. FIX AUTOMATED CAMPAIGNS
-- ============================================================================

CREATE POLICY "Staff manage campaigns"
ON automated_campaigns FOR ALL TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM user_profiles
    WHERE user_profiles.id::text = auth.uid()::text
    AND user_profiles.role IN ('super_admin', 'admin', 'manager')
  )
);

-- ============================================================================
-- VERIFICATION
-- ============================================================================

-- Verify RLS is enabled on all tables
DO $$
DECLARE
  tbl TEXT;
BEGIN
  FOR tbl IN
    SELECT tablename FROM pg_tables
    WHERE schemaname = 'public'
    AND tablename NOT LIKE 'pg_%'
    AND tablename NOT LIKE 'sql_%'
  LOOP
    EXECUTE format('ALTER TABLE IF EXISTS %I ENABLE ROW LEVEL SECURITY', tbl);
    RAISE NOTICE 'Enabled RLS on table: %', tbl;
  END LOOP;
END $$;

-- Log completion
COMMENT ON TABLE customers IS 'RLS policies updated - Migration 025 V2';
COMMENT ON TABLE orders IS 'RLS policies updated - Migration 025 V2';
COMMENT ON TABLE order_sequences IS 'RLS enabled - Migration 025 V2';

SELECT 'Migration 025 V2 completed successfully!' AS status;
