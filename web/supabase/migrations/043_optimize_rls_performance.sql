-- ============================================
-- MIGRATION 043: Optimize RLS Performance
-- Fix auth function re-evaluation and remove duplicate indexes
-- ============================================

-- Fix: Wrap auth.uid() in SELECT to prevent re-evaluation per row
-- This significantly improves query performance at scale

-- 1. permission_changes table
DROP POLICY IF EXISTS "users_view_own_changes" ON permission_changes;
CREATE POLICY "users_view_own_changes" ON permission_changes
  FOR SELECT
  USING (user_id = (SELECT auth.uid()));

-- 2. orders table - customers_view_own_orders
DROP POLICY IF EXISTS "customers_view_own_orders" ON orders;
CREATE POLICY "customers_view_own_orders" ON orders
  FOR SELECT
  USING (customer_email = (SELECT auth.jwt()->>'email'));

-- 3. orders table - Users can view their own orders
DROP POLICY IF EXISTS "Users can view their own orders" ON orders;
CREATE POLICY "Users can view their own orders" ON orders
  FOR SELECT
  USING (user_id = (SELECT auth.uid()));

-- 4. customer_rewards table
DROP POLICY IF EXISTS "Customers view own rewards" ON customer_rewards;
CREATE POLICY "Customers view own rewards" ON customer_rewards
  FOR SELECT
  USING (customer_id = (SELECT auth.uid()));

-- 5. rewards_transactions table
DROP POLICY IF EXISTS "Customers view own transactions" ON rewards_transactions;
CREATE POLICY "Customers view own transactions" ON rewards_transactions
  FOR SELECT
  USING (customer_id = (SELECT auth.uid()));

-- 6. customers table - view own
DROP POLICY IF EXISTS "customers_view_own" ON customers;
CREATE POLICY "customers_view_own" ON customers
  FOR SELECT
  USING (id = (SELECT auth.uid()));

-- 7. customers table - update own
DROP POLICY IF EXISTS "customers_update_own" ON customers;
CREATE POLICY "customers_update_own" ON customers
  FOR UPDATE
  USING (id = (SELECT auth.uid()));

-- 8. customer_favorites table - view
DROP POLICY IF EXISTS "Customers can view their own favorites" ON customer_favorites;
CREATE POLICY "Customers can view their own favorites" ON customer_favorites
  FOR SELECT
  USING (customer_id = (SELECT auth.uid()));

-- 9. customer_favorites table - insert
DROP POLICY IF EXISTS "Customers can insert their own favorites" ON customer_favorites;
CREATE POLICY "Customers can insert their own favorites" ON customer_favorites
  FOR INSERT
  WITH CHECK (customer_id = (SELECT auth.uid()));

-- 10. customer_favorites table - delete
DROP POLICY IF EXISTS "Customers can delete their own favorites" ON customer_favorites;
CREATE POLICY "Customers can delete their own favorites" ON customer_favorites
  FOR DELETE
  USING (customer_id = (SELECT auth.uid()));

-- 11. customer_addresses table - view
DROP POLICY IF EXISTS "Customers can view their own addresses" ON customer_addresses;
CREATE POLICY "Customers can view their own addresses" ON customer_addresses
  FOR SELECT
  USING (customer_id = (SELECT auth.uid()));

-- 12. customer_addresses table - insert
DROP POLICY IF EXISTS "Customers can insert their own addresses" ON customer_addresses;
CREATE POLICY "Customers can insert their own addresses" ON customer_addresses
  FOR INSERT
  WITH CHECK (customer_id = (SELECT auth.uid()));

-- 13. customer_addresses table - update
DROP POLICY IF EXISTS "Customers can update their own addresses" ON customer_addresses;
CREATE POLICY "Customers can update their own addresses" ON customer_addresses
  FOR UPDATE
  USING (customer_id = (SELECT auth.uid()));

-- 14. customer_addresses table - delete
DROP POLICY IF EXISTS "Customers can delete their own addresses" ON customer_addresses;
CREATE POLICY "Customers can delete their own addresses" ON customer_addresses
  FOR DELETE
  USING (customer_id = (SELECT auth.uid()));

-- 15. order_sequences table
DROP POLICY IF EXISTS "Staff can insert order sequences" ON order_sequences;
CREATE POLICY "Staff can insert order sequences" ON order_sequences
  FOR INSERT
  WITH CHECK (
    public.get_current_user_role() IN ('super_admin', 'admin', 'manager', 'staff')
  );

-- 16. user_hierarchy table - update
DROP POLICY IF EXISTS "Users can update hierarchy for subordinates" ON user_hierarchy;
CREATE POLICY "Users can update hierarchy for subordinates" ON user_hierarchy
  FOR UPDATE
  USING (parent_user_id = (SELECT auth.uid()));

-- 17. user_hierarchy table - view own
DROP POLICY IF EXISTS "Users can view their own hierarchy" ON user_hierarchy;
CREATE POLICY "Users can view their own hierarchy" ON user_hierarchy
  FOR SELECT
  USING (user_id = (SELECT auth.uid()) OR parent_user_id = (SELECT auth.uid()));

-- 18. user_hierarchy table - view reports
DROP POLICY IF EXISTS "Users can view their reports' hierarchy" ON user_hierarchy;
CREATE POLICY "Users can view their reports' hierarchy" ON user_hierarchy
  FOR SELECT
  USING (parent_user_id = (SELECT auth.uid()));

-- 19. store_assignments table - view own
DROP POLICY IF EXISTS "Users can view their own store assignments" ON store_assignments;
CREATE POLICY "Users can view their own store assignments" ON store_assignments
  FOR SELECT
  USING (user_id = (SELECT auth.uid()));

-- 20. store_assignments table - insert (admins)
DROP POLICY IF EXISTS "Admins can assign users to their stores" ON store_assignments;
CREATE POLICY "Admins can assign users to their stores" ON store_assignments
  FOR INSERT
  WITH CHECK (
    public.get_current_user_role() IN ('super_admin', 'admin')
  );

-- 21. user_profiles table - view own
DROP POLICY IF EXISTS "users_view_own_profile" ON user_profiles;
CREATE POLICY "users_view_own_profile" ON user_profiles
  FOR SELECT
  USING (id = (SELECT auth.uid()));

-- 22. user_profiles table - update own
DROP POLICY IF EXISTS "users_update_own_profile" ON user_profiles;
CREATE POLICY "users_update_own_profile" ON user_profiles
  FOR UPDATE
  USING (id = (SELECT auth.uid()));

-- ============================================
-- Remove duplicate indexes
-- ============================================

-- Drop duplicate index on user_profiles.role (keep the newer one)
DROP INDEX IF EXISTS idx_user_profiles_role;
-- Keep: user_profiles_role_idx

-- ============================================
-- Verification
-- ============================================

SELECT 'RLS Performance Optimization Complete!' as status;
SELECT 'Optimized ' || COUNT(*) || ' RLS policies' as policies_updated
FROM pg_policies
WHERE schemaname = 'public';
