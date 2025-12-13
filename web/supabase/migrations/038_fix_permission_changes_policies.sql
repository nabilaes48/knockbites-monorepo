-- =====================================================
-- Migration 038: Fix permission_changes RLS Policies
-- Version: 1.0
-- Date: 2025-11-20
-- Purpose: Fix permission_changes policies to prevent recursion
-- =====================================================

-- =====================================================
-- STEP 1: Drop old policies that query user_profiles
-- =====================================================

DROP POLICY IF EXISTS "Super admins can view all permission changes" ON permission_changes;
DROP POLICY IF EXISTS "Admins can view changes for their users" ON permission_changes;
DROP POLICY IF EXISTS "Users can view their own permission changes" ON permission_changes;
DROP POLICY IF EXISTS "Super admins and admins can create audit logs" ON permission_changes;

-- =====================================================
-- STEP 2: Create new policies using helper functions
-- =====================================================

-- Super Admins can see all changes (no recursion)
CREATE POLICY "super_admin_view_all_changes"
ON permission_changes FOR SELECT
TO authenticated
USING (public.is_current_user_system_admin() = TRUE);

-- Admins can see changes for users in their stores
CREATE POLICY "admin_view_store_changes"
ON permission_changes FOR SELECT
TO authenticated
USING (
    public.get_current_user_role() = 'admin'
    AND EXISTS (
        SELECT 1 FROM store_assignments sa
        WHERE sa.user_id = permission_changes.user_id
        AND sa.store_id = ANY(public.get_current_user_assigned_stores())
    )
);

-- Users can see their own permission changes
CREATE POLICY "users_view_own_changes"
ON permission_changes FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- Only super admins and admins can insert audit logs (no recursion)
CREATE POLICY "super_admin_and_admin_insert_logs"
ON permission_changes FOR INSERT
TO authenticated
WITH CHECK (
    public.get_current_user_role() IN ('super_admin', 'admin')
    OR public.is_current_user_system_admin() = TRUE
);

-- =====================================================
-- SUCCESS! Fixed permission_changes policies.
--
-- Changes:
-- ✅ Removed recursive queries to user_profiles
-- ✅ Uses helper functions instead
-- ✅ No more cross-table recursion
-- ✅ Login and profile fetching should now work!
-- =====================================================
