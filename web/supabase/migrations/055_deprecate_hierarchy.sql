-- =====================================================
-- Migration 055: Deprecate User Hierarchy System
-- Version: 1.0
-- Date: 2025-12-02
-- Purpose: Mark user_hierarchy table and related functions as deprecated
--          These are not currently used by frontend and add unnecessary complexity.
--          The simpler role + assigned_stores model is sufficient for RBAC.
-- =====================================================

-- =====================================================
-- DEPRECATION NOTICE
-- This migration DOES NOT drop any tables or functions.
-- It only adds comments marking them as deprecated.
-- A future migration will handle actual removal after verification.
-- =====================================================

-- =====================================================
-- 1. Deprecate user_hierarchy table
-- =====================================================

COMMENT ON TABLE user_hierarchy IS
'DEPRECATED (Migration 055, 2025-12-02): This table is not used by the frontend application.
The simpler role + assigned_stores[] model in user_profiles provides sufficient RBAC.
Scheduled for removal in a future cleanup migration.
DO NOT build new features against this table.';

-- =====================================================
-- 2. Deprecate hierarchy-related functions
-- =====================================================

-- get_role_level - KEEP but mark as internal
COMMENT ON FUNCTION get_role_level(VARCHAR) IS
'Internal helper function. Returns numeric level for role comparison.
Levels: super_admin=4, admin=3, manager=2, staff=1, other=0.
Still used by some RLS policies. DO NOT remove.';

-- can_user_manage_by_hierarchy
COMMENT ON FUNCTION can_user_manage_by_hierarchy(UUID, UUID) IS
'DEPRECATED (Migration 055, 2025-12-02): Not used by frontend.
Use role-based checks with assigned_stores instead.
Scheduled for removal in a future cleanup migration.';

-- get_direct_reports
COMMENT ON FUNCTION get_direct_reports(UUID) IS
'DEPRECATED (Migration 055, 2025-12-02): Not used by frontend.
The user_hierarchy table tracking is not integrated with the app.
Scheduled for removal in a future cleanup migration.';

-- get_all_reports
COMMENT ON FUNCTION get_all_reports(UUID) IS
'DEPRECATED (Migration 055, 2025-12-02): Not used by frontend.
The user_hierarchy table tracking is not integrated with the app.
Scheduled for removal in a future cleanup migration.';

-- can_promote_to_role
COMMENT ON FUNCTION can_promote_to_role(UUID, UUID, VARCHAR) IS
'DEPRECATED (Migration 055, 2025-12-02): Not used by frontend.
Frontend uses its own role-level logic in permissions.ts.
Scheduled for removal in a future cleanup migration.';

-- =====================================================
-- 3. Deprecate permission audit functions (if they exist)
-- =====================================================

DO $$
BEGIN
  -- log_permission_change (10 parameters)
  IF EXISTS (
    SELECT 1 FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public' AND p.proname = 'log_permission_change'
  ) THEN
    COMMENT ON FUNCTION log_permission_change IS
    'DEPRECATED (Migration 055, 2025-12-02): Permission audit logging not implemented in frontend.
    Scheduled for removal in a future cleanup migration.';
  END IF;

  -- get_user_permission_history
  IF EXISTS (
    SELECT 1 FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public' AND p.proname = 'get_user_permission_history'
  ) THEN
    COMMENT ON FUNCTION get_user_permission_history IS
    'DEPRECATED (Migration 055, 2025-12-02): Permission audit UI not implemented.
    Scheduled for removal in a future cleanup migration.';
  END IF;

  -- get_recent_permission_changes
  IF EXISTS (
    SELECT 1 FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public' AND p.proname = 'get_recent_permission_changes'
  ) THEN
    COMMENT ON FUNCTION get_recent_permission_changes IS
    'DEPRECATED (Migration 055, 2025-12-02): Permission audit UI not implemented.
    Scheduled for removal in a future cleanup migration.';
  END IF;

  -- get_permission_change_stats
  IF EXISTS (
    SELECT 1 FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public' AND p.proname = 'get_permission_change_stats'
  ) THEN
    COMMENT ON FUNCTION get_permission_change_stats IS
    'DEPRECATED (Migration 055, 2025-12-02): Permission audit UI not implemented.
    Scheduled for removal in a future cleanup migration.';
  END IF;
END $$;

-- =====================================================
-- 4. Deprecate permission_changes table (if it exists)
-- =====================================================

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'permission_changes'
  ) THEN
    COMMENT ON TABLE permission_changes IS
    'DEPRECATED (Migration 055, 2025-12-02): Permission audit logging not implemented in frontend.
    Scheduled for removal in a future cleanup migration.';
  END IF;
END $$;

-- =====================================================
-- SUCCESS! Migration 055 complete.
--
-- Marked as DEPRECATED (but NOT removed):
-- - user_hierarchy table
-- - permission_changes table (if exists)
-- - can_user_manage_by_hierarchy(uuid, uuid)
-- - get_direct_reports(uuid)
-- - get_all_reports(uuid)
-- - can_promote_to_role(uuid, uuid, varchar)
-- - log_permission_change(...)
-- - get_user_permission_history(uuid, int)
-- - get_recent_permission_changes(int, int)
-- - get_permission_change_stats(int)
--
-- KEPT (not deprecated):
-- - get_role_level(varchar) - still used internally
--
-- Next Steps:
-- 1. Verify no production code uses these
-- 2. Create removal migration in Phase 6
-- =====================================================
