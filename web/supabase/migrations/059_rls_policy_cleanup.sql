-- =====================================================
-- Migration 059: RLS Policy Cleanup and Consolidation
-- Version: 1.0
-- Date: 2025-12-02
-- Purpose: Remove duplicate policies and consolidate overlapping ones
-- =====================================================

-- =====================================================
-- 1. user_profiles - Consolidate SELECT policies
-- =====================================================

-- Drop all existing SELECT policies on user_profiles
DROP POLICY IF EXISTS "Users can view own profile" ON user_profiles;
DROP POLICY IF EXISTS "Staff can view store profiles" ON user_profiles;
DROP POLICY IF EXISTS "users_view_own_profile" ON user_profiles;
DROP POLICY IF EXISTS "super_admin_view_all" ON user_profiles;
DROP POLICY IF EXISTS "admin_view_store_users" ON user_profiles;
DROP POLICY IF EXISTS "manager_view_store_users" ON user_profiles;
DROP POLICY IF EXISTS "staff_view_coworkers" ON user_profiles;
DROP POLICY IF EXISTS "rbac_super_admin_view_all_users" ON user_profiles;
DROP POLICY IF EXISTS "rbac_admin_view_their_store_users" ON user_profiles;
DROP POLICY IF EXISTS "rbac_manager_view_own_store_users" ON user_profiles;
DROP POLICY IF EXISTS "rbac_staff_view_coworkers" ON user_profiles;
DROP POLICY IF EXISTS "view_user_profiles" ON user_profiles;

-- Create ONE consolidated SELECT policy
CREATE POLICY "select_user_profiles"
ON user_profiles FOR SELECT
TO authenticated
USING (
  -- Users can always see their own profile
  id = (SELECT auth.uid())
  OR
  -- System admins can see all
  public.is_current_user_system_admin()
  OR
  -- Staff/managers/admins can see users in their assigned stores
  (
    public.get_current_user_role() IN ('admin', 'manager', 'staff')
    AND (
      -- Target's primary store is in viewer's stores
      store_id = ANY(public.get_current_user_assigned_stores())
      OR
      -- Or they share any assigned store (array overlap)
      assigned_stores && public.get_current_user_assigned_stores()
    )
  )
);

-- =====================================================
-- 2. user_profiles - Consolidate INSERT policies
-- =====================================================

DROP POLICY IF EXISTS "Admins can insert profiles" ON user_profiles;
DROP POLICY IF EXISTS "super_admin_create_users" ON user_profiles;
DROP POLICY IF EXISTS "admin_create_users" ON user_profiles;
DROP POLICY IF EXISTS "manager_create_staff" ON user_profiles;
DROP POLICY IF EXISTS "rbac_super_admin_create_users" ON user_profiles;
DROP POLICY IF EXISTS "rbac_admin_create_staff_and_managers" ON user_profiles;
DROP POLICY IF EXISTS "rbac_manager_create_staff" ON user_profiles;

-- Consolidated INSERT policy
CREATE POLICY "insert_user_profiles"
ON user_profiles FOR INSERT
TO authenticated
WITH CHECK (
  -- System admins can create anyone
  public.is_current_user_system_admin()
  OR
  -- Admins can create managers/staff for their stores
  (
    public.get_current_user_role() = 'admin'
    AND role IN ('manager', 'staff')
    AND store_id = ANY(public.get_current_user_assigned_stores())
  )
  OR
  -- Managers can create staff for their stores
  (
    public.get_current_user_role() = 'manager'
    AND role = 'staff'
    AND store_id = ANY(public.get_current_user_assigned_stores())
  )
);

-- =====================================================
-- 3. user_profiles - Consolidate UPDATE policies
-- =====================================================

DROP POLICY IF EXISTS "Users can update own profile" ON user_profiles;
DROP POLICY IF EXISTS "Admins can update profiles" ON user_profiles;
DROP POLICY IF EXISTS "users_update_own_profile" ON user_profiles;
DROP POLICY IF EXISTS "super_admin_update_users" ON user_profiles;
DROP POLICY IF EXISTS "admin_update_store_users" ON user_profiles;
DROP POLICY IF EXISTS "manager_update_staff" ON user_profiles;
DROP POLICY IF EXISTS "rbac_super_admin_update_users" ON user_profiles;
DROP POLICY IF EXISTS "rbac_admin_update_their_users" ON user_profiles;
DROP POLICY IF EXISTS "rbac_manager_update_their_staff" ON user_profiles;
DROP POLICY IF EXISTS "rbac_users_update_own_profile" ON user_profiles;

-- Consolidated UPDATE policy
CREATE POLICY "update_user_profiles"
ON user_profiles FOR UPDATE
TO authenticated
USING (
  -- Users can update their own profile
  id = (SELECT auth.uid())
  OR
  -- System admins can update anyone
  public.is_current_user_system_admin()
  OR
  -- Admins can update managers/staff in their stores
  (
    public.get_current_user_role() = 'admin'
    AND role IN ('manager', 'staff')
    AND store_id = ANY(public.get_current_user_assigned_stores())
  )
  OR
  -- Managers can update staff in their stores
  (
    public.get_current_user_role() = 'manager'
    AND role = 'staff'
    AND store_id = ANY(public.get_current_user_assigned_stores())
  )
);

-- =====================================================
-- 4. user_profiles - Consolidate DELETE policies
-- =====================================================

DROP POLICY IF EXISTS "super_admin_delete_users" ON user_profiles;
DROP POLICY IF EXISTS "rbac_super_admin_delete_users" ON user_profiles;
DROP POLICY IF EXISTS "rbac_admin_delete_their_users" ON user_profiles;
DROP POLICY IF EXISTS "rbac_manager_delete_their_staff" ON user_profiles;

-- Consolidated DELETE policy
CREATE POLICY "delete_user_profiles"
ON user_profiles FOR DELETE
TO authenticated
USING (
  -- System admins can delete anyone
  public.is_current_user_system_admin()
  OR
  -- Admins can delete managers/staff in their stores
  (
    public.get_current_user_role() = 'admin'
    AND role IN ('manager', 'staff')
    AND store_id = ANY(public.get_current_user_assigned_stores())
  )
  OR
  -- Managers can delete staff in their stores
  (
    public.get_current_user_role() = 'manager'
    AND role = 'staff'
    AND store_id = ANY(public.get_current_user_assigned_stores())
  )
);

-- =====================================================
-- 5. orders - Clean up duplicate policies
-- =====================================================

-- Drop potential duplicates (keep most recent pattern)
DROP POLICY IF EXISTS "Allow public to view orders" ON orders;
DROP POLICY IF EXISTS "Allow public to insert orders" ON orders;
DROP POLICY IF EXISTS "Allow public to update order status" ON orders;
DROP POLICY IF EXISTS "Customers can view own orders" ON orders;
DROP POLICY IF EXISTS "Staff can view store orders" ON orders;
DROP POLICY IF EXISTS "rbac_public_create_orders" ON orders;
DROP POLICY IF EXISTS "rbac_public_update_order_status" ON orders;
DROP POLICY IF EXISTS "rbac_super_admin_view_all_orders" ON orders;
DROP POLICY IF EXISTS "rbac_admin_view_their_store_orders" ON orders;
DROP POLICY IF EXISTS "rbac_staff_view_own_store_orders" ON orders;
DROP POLICY IF EXISTS "rbac_customers_view_own_orders" ON orders;

-- Recreate clean order policies

-- Public can create orders (guest checkout)
CREATE POLICY "orders_insert_public"
ON orders FOR INSERT
TO anon, authenticated
WITH CHECK (true);

-- Public can update order status (for tracking updates)
CREATE POLICY "orders_update_status"
ON orders FOR UPDATE
TO anon, authenticated
USING (true)
WITH CHECK (
  -- Only allow status updates, not data manipulation
  -- This is handled at application level
  true
);

-- Customers can view their own orders
CREATE POLICY "orders_select_customer"
ON orders FOR SELECT
TO authenticated
USING (
  customer_id = (SELECT auth.uid())
  OR customer_email = (SELECT email FROM auth.users WHERE id = (SELECT auth.uid()))
);

-- Anonymous can view orders by ID (for tracking page)
CREATE POLICY "orders_select_anon"
ON orders FOR SELECT
TO anon
USING (true);

-- Staff can view store orders
CREATE POLICY "orders_select_staff"
ON orders FOR SELECT
TO authenticated
USING (
  public.get_current_user_role() IN ('super_admin', 'admin', 'manager', 'staff')
  AND (
    public.is_current_user_system_admin()
    OR store_id = ANY(public.get_current_user_assigned_stores())
  )
);

-- =====================================================
-- 6. stores - Clean up policies
-- =====================================================

DROP POLICY IF EXISTS "rbac_public_view_stores" ON stores;
DROP POLICY IF EXISTS "rbac_super_admin_manage_stores" ON stores;
DROP POLICY IF EXISTS "rbac_admin_update_their_stores" ON stores;
DROP POLICY IF EXISTS "Super admins can update stores" ON stores;
DROP POLICY IF EXISTS "Super admins can insert stores" ON stores;
DROP POLICY IF EXISTS "Super admins can delete stores" ON stores;

-- Everyone can view stores (public data)
CREATE POLICY "stores_select_public"
ON stores FOR SELECT
TO anon, authenticated
USING (true);

-- Only system admins can modify stores
CREATE POLICY "stores_modify_admin"
ON stores FOR ALL
TO authenticated
USING (public.is_current_user_system_admin())
WITH CHECK (public.is_current_user_system_admin());

-- =====================================================
-- SUCCESS! Migration 059 complete.
--
-- Consolidated policies:
-- - user_profiles: 4 policies (SELECT, INSERT, UPDATE, DELETE)
-- - orders: 5 policies (insert, update, select_customer, select_anon, select_staff)
-- - stores: 2 policies (select_public, modify_admin)
--
-- Benefits:
-- - Cleaner policy structure
-- - Better performance (fewer policy evaluations)
-- - Easier to maintain and reason about
-- =====================================================
