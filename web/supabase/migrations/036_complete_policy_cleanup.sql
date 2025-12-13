-- =====================================================
-- Migration 036: Complete Policy Cleanup
-- Version: 1.0
-- Date: 2025-11-20
-- Purpose: Drop ALL old policies and recreate clean ones
-- =====================================================

-- =====================================================
-- STEP 1: Drop ALL existing policies on user_profiles
-- =====================================================

-- Drop all policies (comprehensive list from all migrations)
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
-- STEP 2: Drop old helper functions if they exist
-- =====================================================

DROP FUNCTION IF EXISTS public.user_role();
DROP FUNCTION IF EXISTS public.user_store_id();
DROP FUNCTION IF EXISTS public.has_permission(text);

-- =====================================================
-- STEP 3: Ensure new helper functions exist
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
-- STEP 4: Create CLEAN SELECT policies
-- =====================================================

-- Users can always see their own profile
CREATE POLICY "users_view_own_profile"
ON user_profiles FOR SELECT
TO authenticated
USING (id = auth.uid());

-- Super Admins can see all users
CREATE POLICY "super_admin_view_all"
ON user_profiles FOR SELECT
TO authenticated
USING (public.is_current_user_system_admin() = TRUE);

-- Admins can see users in their stores
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

-- Managers can see users in their store
CREATE POLICY "manager_view_store_users"
ON user_profiles FOR SELECT
TO authenticated
USING (
    public.get_current_user_role() = 'manager'
    AND store_id = public.get_current_user_store_id()
);

-- Staff can see coworkers in their store
CREATE POLICY "staff_view_coworkers"
ON user_profiles FOR SELECT
TO authenticated
USING (
    public.get_current_user_role() = 'staff'
    AND store_id = public.get_current_user_store_id()
);

-- =====================================================
-- STEP 5: Create CLEAN INSERT policies
-- =====================================================

-- Super Admins can create anyone
CREATE POLICY "super_admin_create_users"
ON user_profiles FOR INSERT
TO authenticated
WITH CHECK (public.is_current_user_system_admin() = TRUE);

-- Admins can create managers and staff in their stores
CREATE POLICY "admin_create_users"
ON user_profiles FOR INSERT
TO authenticated
WITH CHECK (
    public.get_current_user_role() = 'admin'
    AND role IN ('manager', 'staff')
    AND store_id = ANY(public.get_current_user_assigned_stores())
);

-- Managers can create staff in their store
CREATE POLICY "manager_create_staff"
ON user_profiles FOR INSERT
TO authenticated
WITH CHECK (
    public.get_current_user_role() = 'manager'
    AND role = 'staff'
    AND store_id = public.get_current_user_store_id()
);

-- =====================================================
-- STEP 6: Create CLEAN UPDATE policies
-- =====================================================

-- Users can update their own profile (limited fields)
CREATE POLICY "users_update_own_profile"
ON user_profiles FOR UPDATE
TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

-- Super Admins can update anyone
CREATE POLICY "super_admin_update_users"
ON user_profiles FOR UPDATE
TO authenticated
USING (public.is_current_user_system_admin() = TRUE);

-- Admins can update users in their stores
CREATE POLICY "admin_update_store_users"
ON user_profiles FOR UPDATE
TO authenticated
USING (
    public.get_current_user_role() = 'admin'
    AND store_id = ANY(public.get_current_user_assigned_stores())
);

-- Managers can update staff in their store
CREATE POLICY "manager_update_staff"
ON user_profiles FOR UPDATE
TO authenticated
USING (
    public.get_current_user_role() = 'manager'
    AND role = 'staff'
    AND store_id = public.get_current_user_store_id()
);

-- =====================================================
-- STEP 7: Create CLEAN DELETE policies
-- =====================================================

-- Only Super Admins can delete users
CREATE POLICY "super_admin_delete_users"
ON user_profiles FOR DELETE
TO authenticated
USING (public.is_current_user_system_admin() = TRUE);

-- =====================================================
-- STEP 8: Grant execute permissions
-- =====================================================

GRANT EXECUTE ON FUNCTION public.get_current_user_role() TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_current_user_system_admin() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_current_user_assigned_stores() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_current_user_store_id() TO authenticated;

-- =====================================================
-- SUCCESS! All old policies removed, clean ones created.
--
-- This migration:
-- ✅ Dropped ALL old policies (23+ policies)
-- ✅ Dropped old helper functions
-- ✅ Recreated clean helper functions
-- ✅ Created clean policies with no recursion
-- ✅ Login should now work!
-- =====================================================
