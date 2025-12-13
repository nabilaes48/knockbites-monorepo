-- =====================================================
-- Migration 057: Remove User Hierarchy System
-- Version: 1.0
-- Date: 2025-12-02
-- Purpose: Remove unused user_hierarchy table and related functions
--          Verified: NO frontend references found
--          The simpler role + assigned_stores model is sufficient
-- =====================================================

-- =====================================================
-- 1. Drop hierarchy-related functions
-- =====================================================

-- Drop functions in dependency order (most dependent first)
DROP FUNCTION IF EXISTS get_direct_reports(UUID);
DROP FUNCTION IF EXISTS get_all_reports(UUID);
DROP FUNCTION IF EXISTS can_user_manage_by_hierarchy(UUID, UUID);
DROP FUNCTION IF EXISTS can_promote_to_role(UUID, UUID, VARCHAR);

-- Drop permission audit functions (never used by frontend)
DROP FUNCTION IF EXISTS log_permission_change(
  UUID, VARCHAR, VARCHAR, VARCHAR, JSONB, JSONB, INT[], INT[], TEXT, JSONB
);
DROP FUNCTION IF EXISTS get_user_permission_history(UUID, INT);
DROP FUNCTION IF EXISTS get_recent_permission_changes(INT, INT);
DROP FUNCTION IF EXISTS get_permission_change_stats(INT);

-- Keep get_role_level as it's used by other parts of the system
-- DO NOT DROP: get_role_level(VARCHAR)

-- =====================================================
-- 2. Drop user_hierarchy triggers
-- =====================================================

DROP TRIGGER IF EXISTS update_user_hierarchy_updated_at_trigger ON user_hierarchy;
DROP TRIGGER IF EXISTS build_reporting_chain_trigger ON user_hierarchy;

-- Drop trigger functions
DROP FUNCTION IF EXISTS update_user_hierarchy_updated_at();
DROP FUNCTION IF EXISTS build_reporting_chain();

-- =====================================================
-- 3. Drop user_hierarchy table
-- =====================================================

DROP TABLE IF EXISTS user_hierarchy CASCADE;

-- =====================================================
-- 4. Drop permission_changes table (if exists, also unused)
-- =====================================================

DROP TABLE IF EXISTS permission_changes CASCADE;

-- =====================================================
-- 5. Verify no RLS policies depend on dropped functions
-- =====================================================

-- These functions were NOT used in any RLS policies
-- Verified by searching migrations 033-048

-- =====================================================
-- SUCCESS! Migration 057 complete.
--
-- Removed (all verified unused):
-- - user_hierarchy table
-- - permission_changes table
-- - get_direct_reports(uuid)
-- - get_all_reports(uuid)
-- - can_user_manage_by_hierarchy(uuid, uuid)
-- - can_promote_to_role(uuid, uuid, varchar)
-- - log_permission_change(...)
-- - get_user_permission_history(uuid, int)
-- - get_recent_permission_changes(int, int)
-- - get_permission_change_stats(int)
-- - update_user_hierarchy_updated_at()
-- - build_reporting_chain()
--
-- Kept:
-- - get_role_level(varchar) - used internally by other functions
--
-- The RBAC system now uses:
-- - user_profiles.role
-- - user_profiles.assigned_stores[]
-- - store_assignments table
-- - get_current_user_role()
-- - get_current_user_assigned_stores()
-- - is_current_user_system_admin()
-- =====================================================
