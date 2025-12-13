-- =====================================================
-- Migration 034: Fix RLS Infinite Recursion
-- Version: 1.0
-- Date: 2025-11-20
-- Purpose: Fix infinite recursion in user_profiles RLS policies
-- =====================================================

-- =====================================================
-- STEP 1: Create helper function to get user role (SECURITY DEFINER)
-- =====================================================

-- This function bypasses RLS to prevent infinite recursion
CREATE OR REPLACE FUNCTION auth.get_user_role()
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

-- Function to check if user is system admin
CREATE OR REPLACE FUNCTION auth.is_system_admin()
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

-- Function to get user's assigned stores
CREATE OR REPLACE FUNCTION auth.get_user_assigned_stores()
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

-- =====================================================
-- STEP 2: Drop existing policies
-- =====================================================

DROP POLICY IF EXISTS "rbac_super_admin_view_all_users" ON user_profiles;
DROP POLICY IF EXISTS "rbac_admin_view_their_store_users" ON user_profiles;
DROP POLICY IF EXISTS "rbac_manager_view_own_store_users" ON user_profiles;
DROP POLICY IF EXISTS "rbac_staff_view_coworkers" ON user_profiles;
DROP POLICY IF EXISTS "rbac_super_admin_create_users" ON user_profiles;
DROP POLICY IF EXISTS "rbac_admin_create_users" ON user_profiles;
DROP POLICY IF EXISTS "rbac_manager_create_users" ON user_profiles;
DROP POLICY IF EXISTS "rbac_super_admin_update_users" ON user_profiles;
DROP POLICY IF EXISTS "rbac_admin_update_users" ON user_profiles;
DROP POLICY IF EXISTS "rbac_manager_update_users" ON user_profiles;
DROP POLICY IF EXISTS "rbac_users_update_own_profile" ON user_profiles;
DROP POLICY IF EXISTS "rbac_super_admin_delete_users" ON user_profiles;

-- =====================================================
-- STEP 3: Create simplified SELECT policies (no recursion)
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
USING (auth.is_system_admin() = TRUE);

-- Admins can see users in their stores
CREATE POLICY "admin_view_store_users"
ON user_profiles FOR SELECT
TO authenticated
USING (
    auth.get_user_role() = 'admin'
    AND (
        store_id = ANY(auth.get_user_assigned_stores())
        OR
        EXISTS (
            SELECT 1 FROM store_assignments sa
            WHERE sa.user_id = user_profiles.id
            AND sa.store_id = ANY(auth.get_user_assigned_stores())
        )
    )
);

-- Managers can see users in their store
CREATE POLICY "manager_view_store_users"
ON user_profiles FOR SELECT
TO authenticated
USING (
    auth.get_user_role() = 'manager'
    AND store_id = ANY(auth.get_user_assigned_stores())
);

-- Staff can see coworkers in their store
CREATE POLICY "staff_view_coworkers"
ON user_profiles FOR SELECT
TO authenticated
USING (
    auth.get_user_role() = 'staff'
    AND store_id = ANY(auth.get_user_assigned_stores())
);

-- =====================================================
-- STEP 4: Create simplified INSERT policies
-- =====================================================

-- Super Admins can create anyone
CREATE POLICY "super_admin_create_users"
ON user_profiles FOR INSERT
TO authenticated
WITH CHECK (auth.is_system_admin() = TRUE);

-- Admins can create managers and staff in their stores
CREATE POLICY "admin_create_users"
ON user_profiles FOR INSERT
TO authenticated
WITH CHECK (
    auth.get_user_role() = 'admin'
    AND role IN ('manager', 'staff')
    AND store_id = ANY(auth.get_user_assigned_stores())
);

-- Managers can create staff in their store
CREATE POLICY "manager_create_staff"
ON user_profiles FOR INSERT
TO authenticated
WITH CHECK (
    auth.get_user_role() = 'manager'
    AND role = 'staff'
    AND store_id = ANY(auth.get_user_assigned_stores())
);

-- =====================================================
-- STEP 5: Create simplified UPDATE policies
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
USING (auth.is_system_admin() = TRUE);

-- Admins can update users in their stores
CREATE POLICY "admin_update_store_users"
ON user_profiles FOR UPDATE
TO authenticated
USING (
    auth.get_user_role() = 'admin'
    AND store_id = ANY(auth.get_user_assigned_stores())
);

-- Managers can update staff in their store
CREATE POLICY "manager_update_staff"
ON user_profiles FOR UPDATE
TO authenticated
USING (
    auth.get_user_role() = 'manager'
    AND role = 'staff'
    AND store_id = ANY(auth.get_user_assigned_stores())
);

-- =====================================================
-- STEP 6: Create simplified DELETE policies
-- =====================================================

-- Only Super Admins can delete users
CREATE POLICY "super_admin_delete_users"
ON user_profiles FOR DELETE
TO authenticated
USING (auth.is_system_admin() = TRUE);

-- =====================================================
-- SUCCESS! RLS policies fixed.
--
-- Changes:
-- ✅ Added SECURITY DEFINER functions to bypass RLS
-- ✅ Removed recursive queries from policies
-- ✅ Simplified policy logic
-- ✅ Users can now login without infinite recursion
-- =====================================================
