-- =====================================================
-- Migration 037: Comprehensive Policy Migration
-- Version: 1.0
-- Date: 2025-11-20
-- Purpose: Update ALL policies across ALL tables to use new helper functions
-- =====================================================

-- =====================================================
-- STEP 1: Ensure new helper functions exist
-- =====================================================

CREATE OR REPLACE FUNCTION public.get_current_user_role()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    user_role TEXT;
BEGIN
    SELECT role INTO user_role
    FROM public.user_profiles
    WHERE id = auth.uid();

    RETURN COALESCE(user_role, 'customer');
END;
$$;

CREATE OR REPLACE FUNCTION public.is_current_user_system_admin()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    is_admin BOOLEAN;
BEGIN
    SELECT COALESCE(is_system_admin, FALSE) INTO is_admin
    FROM public.user_profiles
    WHERE id = auth.uid();

    RETURN COALESCE(is_admin, FALSE);
END;
$$;

CREATE OR REPLACE FUNCTION public.get_current_user_assigned_stores()
RETURNS INT[]
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    stores INT[];
BEGIN
    SELECT COALESCE(assigned_stores, ARRAY[]::INT[]) INTO stores
    FROM public.user_profiles
    WHERE id = auth.uid();

    RETURN COALESCE(stores, ARRAY[]::INT[]);
END;
$$;

CREATE OR REPLACE FUNCTION public.get_current_user_store_id()
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    user_store_id INT;
BEGIN
    SELECT store_id INTO user_store_id
    FROM public.user_profiles
    WHERE id = auth.uid();

    RETURN user_store_id;
END;
$$;

-- =====================================================
-- STEP 2: Update STORES table policies
-- =====================================================

DROP POLICY IF EXISTS "Super admins can update stores" ON stores;
DROP POLICY IF EXISTS "Super admins can insert stores" ON stores;
DROP POLICY IF EXISTS "Super admins can delete stores" ON stores;

CREATE POLICY "Super admins can update stores"
ON stores FOR UPDATE
TO authenticated
USING (public.is_current_user_system_admin() = TRUE);

CREATE POLICY "Super admins can insert stores"
ON stores FOR INSERT
TO authenticated
WITH CHECK (public.is_current_user_system_admin() = TRUE);

CREATE POLICY "Super admins can delete stores"
ON stores FOR DELETE
TO authenticated
USING (public.is_current_user_system_admin() = TRUE);

-- =====================================================
-- STEP 3: Update MENU_CATEGORIES table policies
-- =====================================================

DROP POLICY IF EXISTS "Categories viewable by all" ON menu_categories;
DROP POLICY IF EXISTS "Staff can manage categories" ON menu_categories;

CREATE POLICY "Categories viewable by all"
ON menu_categories FOR SELECT
TO public
USING (true);

CREATE POLICY "Staff can manage categories"
ON menu_categories FOR ALL
TO authenticated
USING (
    public.get_current_user_role() IN ('super_admin', 'admin', 'manager', 'staff')
);

-- =====================================================
-- STEP 4: Update MENU_ITEMS table policies
-- =====================================================

DROP POLICY IF EXISTS "Menu items viewable by everyone" ON menu_items;
DROP POLICY IF EXISTS "Staff can insert menu items" ON menu_items;
DROP POLICY IF EXISTS "Staff can update menu items" ON menu_items;
DROP POLICY IF EXISTS "Staff can delete menu items" ON menu_items;

CREATE POLICY "Menu items viewable by everyone"
ON menu_items FOR SELECT
TO public
USING (true);

CREATE POLICY "Staff can insert menu items"
ON menu_items FOR INSERT
TO authenticated
WITH CHECK (
    public.get_current_user_role() IN ('super_admin', 'admin', 'manager')
);

CREATE POLICY "Staff can update menu items"
ON menu_items FOR UPDATE
TO authenticated
USING (
    public.get_current_user_role() IN ('super_admin', 'admin', 'manager')
);

CREATE POLICY "Staff can delete menu items"
ON menu_items FOR DELETE
TO authenticated
USING (
    public.get_current_user_role() IN ('super_admin', 'admin', 'manager')
);

-- =====================================================
-- STEP 5: Update MENU_ITEM_CUSTOMIZATIONS table policies
-- =====================================================

DROP POLICY IF EXISTS "Staff can manage customizations" ON menu_item_customizations;

CREATE POLICY "Staff can manage customizations"
ON menu_item_customizations FOR ALL
TO authenticated
USING (
    public.get_current_user_role() IN ('super_admin', 'admin', 'manager')
);

-- =====================================================
-- STEP 6: Update STORE_MENU_ITEMS table policies
-- =====================================================

DROP POLICY IF EXISTS "Staff can manage store menu" ON store_menu_items;

CREATE POLICY "Staff can manage store menu"
ON store_menu_items FOR ALL
TO authenticated
USING (
    public.get_current_user_role() IN ('super_admin', 'admin', 'manager')
    AND (
        public.is_current_user_system_admin() = TRUE
        OR store_id = ANY(public.get_current_user_assigned_stores())
        OR store_id = public.get_current_user_store_id()
    )
);

-- =====================================================
-- STEP 7: Update ORDERS table policies
-- =====================================================

DROP POLICY IF EXISTS "Customers can view own orders" ON orders;
DROP POLICY IF EXISTS "Staff can view store orders" ON orders;

CREATE POLICY "Customers can view own orders"
ON orders FOR SELECT
TO authenticated
USING (
    public.get_current_user_role() = 'customer'
    AND (
        user_id = auth.uid()
        OR customer_email = (SELECT email FROM auth.users WHERE id = auth.uid())
    )
);

CREATE POLICY "Staff can view store orders"
ON orders FOR SELECT
TO authenticated
USING (
    public.get_current_user_role() IN ('super_admin', 'admin', 'manager', 'staff')
    AND (
        public.is_current_user_system_admin() = TRUE
        OR store_id = ANY(public.get_current_user_assigned_stores())
        OR store_id = public.get_current_user_store_id()
    )
);

-- =====================================================
-- STEP 8: Update ORDER_ITEMS table policies
-- =====================================================

DROP POLICY IF EXISTS "Order items viewable with order" ON order_items;
DROP POLICY IF EXISTS "Staff can update order items" ON order_items;

CREATE POLICY "Order items viewable with order"
ON order_items FOR SELECT
TO public
USING (true);

CREATE POLICY "Staff can update order items"
ON order_items FOR UPDATE
TO authenticated
USING (
    public.get_current_user_role() IN ('super_admin', 'admin', 'manager', 'staff')
);

-- =====================================================
-- STEP 9: Update ORDER_STATUS_HISTORY table policies
-- =====================================================

DROP POLICY IF EXISTS "Staff can view order history" ON order_status_history;

CREATE POLICY "Staff can view order history"
ON order_status_history FOR SELECT
TO authenticated
USING (
    public.get_current_user_role() IN ('super_admin', 'admin', 'manager', 'staff')
);

-- =====================================================
-- STEP 10: Update CUSTOMER_REWARDS table policies
-- =====================================================

DROP POLICY IF EXISTS "Staff can view customer rewards" ON customer_rewards;
DROP POLICY IF EXISTS "Super admin can update rewards" ON customer_rewards;

CREATE POLICY "Staff can view customer rewards"
ON customer_rewards FOR SELECT
TO authenticated
USING (
    public.get_current_user_role() IN ('super_admin', 'admin', 'manager', 'staff')
);

CREATE POLICY "Super admin can update rewards"
ON customer_rewards FOR UPDATE
TO authenticated
USING (
    public.is_current_user_system_admin() = TRUE
);

-- =====================================================
-- STEP 11: Update REWARDS_TRANSACTIONS table policies
-- =====================================================

DROP POLICY IF EXISTS "Staff can view transactions" ON rewards_transactions;
DROP POLICY IF EXISTS "Super admin can manage transactions" ON rewards_transactions;

CREATE POLICY "Staff can view transactions"
ON rewards_transactions FOR SELECT
TO authenticated
USING (
    public.get_current_user_role() IN ('super_admin', 'admin', 'manager', 'staff')
);

CREATE POLICY "Super admin can manage transactions"
ON rewards_transactions FOR ALL
TO authenticated
USING (
    public.is_current_user_system_admin() = TRUE
);

-- =====================================================
-- STEP 12: Update DAILY_ANALYTICS table policies
-- =====================================================

DROP POLICY IF EXISTS "Staff can view analytics" ON daily_analytics;
DROP POLICY IF EXISTS "Super admin can manage analytics" ON daily_analytics;

CREATE POLICY "Staff can view analytics"
ON daily_analytics FOR SELECT
TO authenticated
USING (
    public.get_current_user_role() IN ('super_admin', 'admin', 'manager', 'staff')
);

CREATE POLICY "Super admin can manage analytics"
ON daily_analytics FOR ALL
TO authenticated
USING (
    public.is_current_user_system_admin() = TRUE
);

-- =====================================================
-- STEP 13: Drop ALL old policies on user_profiles
-- =====================================================

DROP POLICY IF EXISTS "Admins can insert profiles" ON user_profiles;
DROP POLICY IF EXISTS "Admins can update profiles" ON user_profiles;
DROP POLICY IF EXISTS "Staff can view store profiles" ON user_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can view own profile" ON user_profiles;
DROP POLICY IF EXISTS "rbac_super_admin_view_all_users" ON user_profiles;
DROP POLICY IF EXISTS "rbac_admin_view_their_store_users" ON user_profiles;
DROP POLICY IF EXISTS "rbac_manager_view_own_store_users" ON user_profiles;
DROP POLICY IF EXISTS "rbac_staff_view_coworkers" ON user_profiles;
DROP POLICY IF EXISTS "rbac_super_admin_create_users" ON user_profiles;
DROP POLICY IF EXISTS "rbac_admin_create_users" ON user_profiles;
DROP POLICY IF EXISTS "rbac_admin_create_staff_and_managers" ON user_profiles;
DROP POLICY IF EXISTS "rbac_manager_create_users" ON user_profiles;
DROP POLICY IF EXISTS "rbac_manager_create_staff" ON user_profiles;
DROP POLICY IF EXISTS "rbac_super_admin_update_users" ON user_profiles;
DROP POLICY IF EXISTS "rbac_admin_update_users" ON user_profiles;
DROP POLICY IF EXISTS "rbac_admin_update_their_users" ON user_profiles;
DROP POLICY IF EXISTS "rbac_manager_update_users" ON user_profiles;
DROP POLICY IF EXISTS "rbac_manager_update_their_staff" ON user_profiles;
DROP POLICY IF EXISTS "rbac_users_update_own_profile" ON user_profiles;
DROP POLICY IF EXISTS "rbac_super_admin_delete_users" ON user_profiles;
DROP POLICY IF EXISTS "rbac_admin_delete_their_users" ON user_profiles;
DROP POLICY IF EXISTS "rbac_manager_delete_their_staff" ON user_profiles;
DROP POLICY IF EXISTS "users_view_own_profile" ON user_profiles;
DROP POLICY IF EXISTS "super_admin_view_all" ON user_profiles;
DROP POLICY IF EXISTS "admin_view_store_users" ON user_profiles;
DROP POLICY IF EXISTS "manager_view_store_users" ON user_profiles;
DROP POLICY IF EXISTS "staff_view_coworkers" ON user_profiles;
DROP POLICY IF EXISTS "super_admin_create_users" ON user_profiles;
DROP POLICY IF EXISTS "admin_create_users" ON user_profiles;
DROP POLICY IF EXISTS "manager_create_staff" ON user_profiles;
DROP POLICY IF EXISTS "users_update_own_profile" ON user_profiles;
DROP POLICY IF EXISTS "super_admin_update_users" ON user_profiles;
DROP POLICY IF EXISTS "admin_update_store_users" ON user_profiles;
DROP POLICY IF EXISTS "manager_update_staff" ON user_profiles;
DROP POLICY IF EXISTS "super_admin_delete_users" ON user_profiles;

-- =====================================================
-- STEP 14: Create CLEAN user_profiles policies
-- =====================================================

CREATE POLICY "users_view_own_profile"
ON user_profiles FOR SELECT
TO authenticated
USING (id = auth.uid());

CREATE POLICY "super_admin_view_all"
ON user_profiles FOR SELECT
TO authenticated
USING (public.is_current_user_system_admin() = TRUE);

CREATE POLICY "admin_view_store_users"
ON user_profiles FOR SELECT
TO authenticated
USING (
    public.get_current_user_role() = 'admin'
    AND (
        store_id = ANY(public.get_current_user_assigned_stores())
        OR
        EXISTS (
            SELECT 1 FROM store_assignments sa
            WHERE sa.user_id = user_profiles.id
            AND sa.store_id = ANY(public.get_current_user_assigned_stores())
        )
    )
);

CREATE POLICY "manager_view_store_users"
ON user_profiles FOR SELECT
TO authenticated
USING (
    public.get_current_user_role() = 'manager'
    AND store_id = public.get_current_user_store_id()
);

CREATE POLICY "staff_view_coworkers"
ON user_profiles FOR SELECT
TO authenticated
USING (
    public.get_current_user_role() = 'staff'
    AND store_id = public.get_current_user_store_id()
);

CREATE POLICY "super_admin_create_users"
ON user_profiles FOR INSERT
TO authenticated
WITH CHECK (public.is_current_user_system_admin() = TRUE);

CREATE POLICY "admin_create_users"
ON user_profiles FOR INSERT
TO authenticated
WITH CHECK (
    public.get_current_user_role() = 'admin'
    AND role IN ('manager', 'staff')
    AND store_id = ANY(public.get_current_user_assigned_stores())
);

CREATE POLICY "manager_create_staff"
ON user_profiles FOR INSERT
TO authenticated
WITH CHECK (
    public.get_current_user_role() = 'manager'
    AND role = 'staff'
    AND store_id = public.get_current_user_store_id()
);

CREATE POLICY "users_update_own_profile"
ON user_profiles FOR UPDATE
TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

CREATE POLICY "super_admin_update_users"
ON user_profiles FOR UPDATE
TO authenticated
USING (public.is_current_user_system_admin() = TRUE);

CREATE POLICY "admin_update_store_users"
ON user_profiles FOR UPDATE
TO authenticated
USING (
    public.get_current_user_role() = 'admin'
    AND store_id = ANY(public.get_current_user_assigned_stores())
);

CREATE POLICY "manager_update_staff"
ON user_profiles FOR UPDATE
TO authenticated
USING (
    public.get_current_user_role() = 'manager'
    AND role = 'staff'
    AND store_id = public.get_current_user_store_id()
);

CREATE POLICY "super_admin_delete_users"
ON user_profiles FOR DELETE
TO authenticated
USING (public.is_current_user_system_admin() = TRUE);

-- =====================================================
-- STEP 15: Drop old helper functions
-- =====================================================

DROP FUNCTION IF EXISTS public.user_role() CASCADE;
DROP FUNCTION IF EXISTS public.user_store_id() CASCADE;
DROP FUNCTION IF EXISTS public.has_permission(text) CASCADE;

-- =====================================================
-- STEP 16: Grant execute permissions
-- =====================================================

GRANT EXECUTE ON FUNCTION public.get_current_user_role() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_current_user_role() TO anon;
GRANT EXECUTE ON FUNCTION public.is_current_user_system_admin() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_current_user_assigned_stores() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_current_user_store_id() TO authenticated;

-- =====================================================
-- SUCCESS! Complete migration across all tables.
--
-- This migration:
-- ✅ Updated policies on 12+ tables to use new helper functions
-- ✅ Dropped all old policies on user_profiles
-- ✅ Created clean policies on user_profiles
-- ✅ Dropped old helper functions (user_role, user_store_id, etc.)
-- ✅ No more infinite recursion!
-- ✅ Login should now work!
-- =====================================================
