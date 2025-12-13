-- =====================================================
-- Migration 039: Fix ALL Remaining Recursive Policies
-- Version: 1.0
-- Date: 2025-11-20
-- Purpose: Fix all policies across all tables that query user_profiles
-- =====================================================

-- =====================================================
-- COUPONS TABLE
-- =====================================================

DROP POLICY IF EXISTS "Allow staff to manage coupons" ON coupons;

CREATE POLICY "staff_manage_coupons"
ON coupons FOR ALL
TO authenticated
USING (
    public.get_current_user_role() IN ('super_admin', 'admin', 'manager')
);

-- =====================================================
-- CUSTOMERS TABLE
-- =====================================================

DROP POLICY IF EXISTS "Allow staff to read customers" ON customers;

CREATE POLICY "staff_read_customers"
ON customers FOR SELECT
TO authenticated
USING (
    public.get_current_user_role() IN ('super_admin', 'admin', 'manager', 'staff')
);

-- =====================================================
-- MENU_ITEMS TABLE (additional RBAC policies)
-- =====================================================

DROP POLICY IF EXISTS "rbac_admin_manage_their_store_menu" ON menu_items;
DROP POLICY IF EXISTS "rbac_manager_update_menu_availability" ON menu_items;
DROP POLICY IF EXISTS "rbac_super_admin_manage_menu_items" ON menu_items;

CREATE POLICY "admin_manage_store_menu"
ON menu_items FOR ALL
TO authenticated
USING (public.get_current_user_role() = 'admin');

CREATE POLICY "manager_update_menu_availability"
ON menu_items FOR UPDATE
TO authenticated
USING (public.get_current_user_role() = 'manager');

CREATE POLICY "super_admin_manage_menu"
ON menu_items FOR ALL
TO authenticated
USING (public.is_current_user_system_admin() = TRUE);

-- =====================================================
-- ORDER_SEQUENCES TABLE
-- =====================================================

DROP POLICY IF EXISTS "Staff can update order sequences" ON order_sequences;
DROP POLICY IF EXISTS "Staff can view order sequences" ON order_sequences;

CREATE POLICY "staff_update_order_sequences"
ON order_sequences FOR UPDATE
TO authenticated
USING (
    public.get_current_user_role() IN ('staff', 'manager', 'admin', 'super_admin')
);

CREATE POLICY "staff_view_order_sequences"
ON order_sequences FOR SELECT
TO authenticated
USING (
    public.get_current_user_role() IN ('staff', 'manager', 'admin', 'super_admin')
    AND (
        public.get_current_user_store_id() = store_id
        OR public.is_current_user_system_admin() = TRUE
    )
);

-- =====================================================
-- ORDERS TABLE (additional RBAC policies)
-- =====================================================

DROP POLICY IF EXISTS "rbac_admin_view_their_store_orders" ON orders;
DROP POLICY IF EXISTS "rbac_staff_view_own_store_orders" ON orders;
DROP POLICY IF EXISTS "rbac_super_admin_view_all_orders" ON orders;

CREATE POLICY "admin_view_store_orders"
ON orders FOR SELECT
TO authenticated
USING (
    public.get_current_user_role() = 'admin'
    AND store_id = ANY(public.get_current_user_assigned_stores())
);

CREATE POLICY "staff_view_store_orders"
ON orders FOR SELECT
TO authenticated
USING (
    public.get_current_user_role() IN ('manager', 'staff')
    AND store_id = ANY(public.get_current_user_assigned_stores())
);

CREATE POLICY "super_admin_view_all_orders"
ON orders FOR SELECT
TO authenticated
USING (public.is_current_user_system_admin() = TRUE);

-- =====================================================
-- STORE_ASSIGNMENTS TABLE
-- =====================================================

DROP POLICY IF EXISTS "Admins can delete assignments for their stores" ON store_assignments;
DROP POLICY IF EXISTS "Admins can update assignments for their stores" ON store_assignments;
DROP POLICY IF EXISTS "Admins can view assignments for their stores" ON store_assignments;
DROP POLICY IF EXISTS "Managers can view assignments for their store" ON store_assignments;
DROP POLICY IF EXISTS "Super admins can manage all store assignments" ON store_assignments;
DROP POLICY IF EXISTS "Super admins can view all store assignments" ON store_assignments;

CREATE POLICY "admin_view_store_assignments"
ON store_assignments FOR SELECT
TO authenticated
USING (
    public.get_current_user_role() = 'admin'
    AND store_id = ANY(public.get_current_user_assigned_stores())
);

CREATE POLICY "admin_update_store_assignments"
ON store_assignments FOR UPDATE
TO authenticated
USING (
    public.get_current_user_role() = 'admin'
    AND store_id = ANY(public.get_current_user_assigned_stores())
);

CREATE POLICY "admin_delete_store_assignments"
ON store_assignments FOR DELETE
TO authenticated
USING (
    public.get_current_user_role() = 'admin'
    AND store_id = ANY(public.get_current_user_assigned_stores())
);

CREATE POLICY "manager_view_store_assignments"
ON store_assignments FOR SELECT
TO authenticated
USING (
    public.get_current_user_role() = 'manager'
    AND store_id = ANY(public.get_current_user_assigned_stores())
);

CREATE POLICY "super_admin_view_all_assignments"
ON store_assignments FOR SELECT
TO authenticated
USING (public.is_current_user_system_admin() = TRUE);

CREATE POLICY "super_admin_manage_all_assignments"
ON store_assignments FOR ALL
TO authenticated
USING (public.is_current_user_system_admin() = TRUE);

-- =====================================================
-- STORES TABLE (additional RBAC policies)
-- =====================================================

DROP POLICY IF EXISTS "rbac_admin_update_their_stores" ON stores;
DROP POLICY IF EXISTS "rbac_super_admin_manage_stores" ON stores;

CREATE POLICY "admin_update_their_stores"
ON stores FOR UPDATE
TO authenticated
USING (
    public.get_current_user_role() = 'admin'
    AND id = ANY(public.get_current_user_assigned_stores())
);

CREATE POLICY "super_admin_manage_all_stores"
ON stores FOR ALL
TO authenticated
USING (public.is_current_user_system_admin() = TRUE);

-- =====================================================
-- USER_HIERARCHY TABLE
-- =====================================================

DROP POLICY IF EXISTS "Super admins can manage all hierarchy" ON user_hierarchy;
DROP POLICY IF EXISTS "Super admins can view all hierarchy" ON user_hierarchy;

CREATE POLICY "super_admin_view_all_hierarchy"
ON user_hierarchy FOR SELECT
TO authenticated
USING (public.is_current_user_system_admin() = TRUE);

CREATE POLICY "super_admin_manage_all_hierarchy"
ON user_hierarchy FOR ALL
TO authenticated
USING (public.is_current_user_system_admin() = TRUE);

-- =====================================================
-- SUCCESS! All recursive policies fixed.
--
-- Fixed policies on:
-- ✅ coupons (1 policy)
-- ✅ customers (1 policy)
-- ✅ menu_items (3 policies)
-- ✅ order_sequences (2 policies)
-- ✅ orders (3 policies)
-- ✅ store_assignments (6 policies)
-- ✅ stores (2 policies)
-- ✅ user_hierarchy (2 policies)
--
-- Total: 20 policies updated across 8 tables
-- All now use helper functions instead of querying user_profiles
-- No more cross-table recursion!
-- =====================================================
