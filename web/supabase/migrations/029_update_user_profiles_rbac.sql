-- =====================================================
-- Migration 029: Update user_profiles for RBAC System
-- Version: 1.0
-- Date: 2025-11-19
-- Purpose: Add multi-store support and enhanced permissions
-- =====================================================

-- =====================================================
-- STEP 1: Add new columns to user_profiles
-- =====================================================

-- Add assigned_stores array for multi-store Admins
ALTER TABLE user_profiles
ADD COLUMN IF NOT EXISTS assigned_stores INT[] DEFAULT ARRAY[]::INT[];

COMMENT ON COLUMN user_profiles.assigned_stores IS 'Array of store IDs assigned to this user (for Admins managing multiple stores)';

-- Add detailed permissions JSON
ALTER TABLE user_profiles
ADD COLUMN IF NOT EXISTS detailed_permissions JSONB DEFAULT '{}'::jsonb;

COMMENT ON COLUMN user_profiles.detailed_permissions IS 'Detailed permission structure for fine-grained access control';

-- Add created_by to track who created this user
ALTER TABLE user_profiles
ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL;

COMMENT ON COLUMN user_profiles.created_by IS 'User ID of who created this account (for hierarchy tracking)';

-- Add can_hire_roles array
ALTER TABLE user_profiles
ADD COLUMN IF NOT EXISTS can_hire_roles VARCHAR[] DEFAULT ARRAY[]::VARCHAR[];

COMMENT ON COLUMN user_profiles.can_hire_roles IS 'Array of roles this user can hire (e.g., admin can hire manager and staff)';

-- Add last_store_access for tracking
ALTER TABLE user_profiles
ADD COLUMN IF NOT EXISTS last_store_access INT;

COMMENT ON COLUMN user_profiles.last_store_access IS 'Last store ID this user accessed (for quick access)';

-- Add is_system_admin flag for Super Admins
ALTER TABLE user_profiles
ADD COLUMN IF NOT EXISTS is_system_admin BOOLEAN DEFAULT FALSE;

COMMENT ON COLUMN user_profiles.is_system_admin IS 'True if this is a system-wide Super Admin with unrestricted access';

-- =====================================================
-- STEP 2: Update existing roles to new system
-- =====================================================

-- Set Super Admin properties
UPDATE user_profiles
SET
  is_system_admin = TRUE,
  assigned_stores = (SELECT ARRAY_AGG(id) FROM stores),  -- All stores
  can_hire_roles = ARRAY['super_admin', 'admin', 'manager', 'staff'],
  detailed_permissions = '{
    "users": {
      "create_admin": true,
      "create_manager": true,
      "create_staff": true,
      "edit_all": true,
      "delete_all": true,
      "promote_to_admin": true,
      "view_all_users": true
    },
    "stores": {
      "create_store": true,
      "edit_all_stores": true,
      "delete_store": true,
      "assign_stores": true,
      "view_all_stores": true
    },
    "orders": {
      "view_all_stores": true,
      "manage_all_stores": true,
      "refund": true,
      "void": true
    },
    "menu": {
      "create_items_all_stores": true,
      "edit_items_all_stores": true,
      "delete_items_all_stores": true,
      "set_pricing_all_stores": true
    },
    "analytics": {
      "view_all_stores": true,
      "compare_stores": true,
      "export_reports": true,
      "financial_reports": true
    },
    "settings": {
      "system_settings": true,
      "security_settings": true,
      "integration_settings": true
    }
  }'::jsonb
WHERE role = 'super_admin';

-- Set Admin properties (assuming they manage their assigned store)
UPDATE user_profiles
SET
  is_system_admin = FALSE,
  assigned_stores = ARRAY[COALESCE(store_id, 1)]::INT[],  -- Their current store
  can_hire_roles = ARRAY['manager', 'staff'],
  detailed_permissions = '{
    "users": {
      "create_admin": false,
      "create_manager": true,
      "create_staff": true,
      "edit_assigned_stores": true,
      "delete_assigned_stores": true,
      "promote_to_manager": true,
      "view_assigned_stores": true
    },
    "stores": {
      "edit_assigned_only": true,
      "view_assigned_only": true,
      "request_new_store": true
    },
    "orders": {
      "view_assigned_stores": true,
      "manage_assigned_stores": true,
      "refund_assigned_stores": true
    },
    "menu": {
      "create_items_assigned_stores": true,
      "edit_items_assigned_stores": true,
      "delete_items_assigned_stores": true,
      "set_pricing_assigned_stores": true
    },
    "analytics": {
      "view_assigned_stores": true,
      "compare_assigned_stores": true,
      "export_reports": true,
      "financial_reports_assigned": true
    },
    "settings": {
      "store_settings_assigned": true,
      "staff_settings_assigned": true
    }
  }'::jsonb
WHERE role = 'admin';

-- Set Manager properties
UPDATE user_profiles
SET
  is_system_admin = FALSE,
  assigned_stores = ARRAY[COALESCE(store_id, 1)]::INT[],  -- Their single store
  can_hire_roles = ARRAY['staff'],
  detailed_permissions = '{
    "users": {
      "create_staff": true,
      "edit_staff_own_store": true,
      "delete_staff_own_store": true,
      "view_own_store": true
    },
    "stores": {
      "edit_own_store_limited": true,
      "view_own_store": true
    },
    "orders": {
      "view_own_store": true,
      "manage_own_store": true,
      "accept_reject": true,
      "update_status": true,
      "refund_limited": true
    },
    "menu": {
      "edit_availability_own_store": true,
      "mark_unavailable": true
    },
    "analytics": {
      "view_own_store": true,
      "export_reports_own_store": true
    },
    "settings": {
      "store_hours": true,
      "staff_schedules": true,
      "notifications": true
    }
  }'::jsonb
WHERE role = 'manager';

-- Set Staff properties
UPDATE user_profiles
SET
  is_system_admin = FALSE,
  assigned_stores = ARRAY[COALESCE(store_id, 1)]::INT[],  -- Their single store
  can_hire_roles = ARRAY[]::VARCHAR[],  -- Cannot hire anyone
  detailed_permissions = '{
    "users": {
      "view_coworkers": true
    },
    "stores": {
      "view_own_store": true
    },
    "orders": {
      "view_own_store": true,
      "accept_reject": true,
      "update_status": true
    },
    "menu": {
      "view_own_store": true,
      "mark_unavailable": true
    },
    "analytics": {
      "view_basic_metrics": true
    },
    "settings": {
      "profile_settings_own": true
    }
  }'::jsonb
WHERE role = 'staff';

-- =====================================================
-- STEP 3: Add constraints and validations
-- =====================================================

-- Ensure role is valid
ALTER TABLE user_profiles
DROP CONSTRAINT IF EXISTS valid_role;

ALTER TABLE user_profiles
ADD CONSTRAINT valid_role CHECK (role IN ('super_admin', 'admin', 'manager', 'staff'));

-- Ensure super_admin flag matches role
ALTER TABLE user_profiles
ADD CONSTRAINT super_admin_role_match
CHECK (
  (role = 'super_admin' AND is_system_admin = TRUE) OR
  (role != 'super_admin' AND is_system_admin = FALSE)
);

-- =====================================================
-- STEP 4: Create indexes for performance
-- =====================================================

-- Index for assigned_stores (GIN index for array operations)
CREATE INDEX IF NOT EXISTS idx_user_profiles_assigned_stores
ON user_profiles USING GIN(assigned_stores);

-- Index for created_by (to find who created users)
CREATE INDEX IF NOT EXISTS idx_user_profiles_created_by
ON user_profiles(created_by);

-- Index for is_system_admin (to quickly find super admins)
CREATE INDEX IF NOT EXISTS idx_user_profiles_is_system_admin
ON user_profiles(is_system_admin) WHERE is_system_admin = TRUE;

-- Index for role (to filter by role)
CREATE INDEX IF NOT EXISTS idx_user_profiles_role
ON user_profiles(role);

-- Composite index for store and role queries
CREATE INDEX IF NOT EXISTS idx_user_profiles_store_role
ON user_profiles(store_id, role);

-- =====================================================
-- STEP 5: Create helper functions
-- =====================================================

-- Function to check if user has access to a store
CREATE OR REPLACE FUNCTION user_has_store_access(
  p_user_id UUID,
  p_store_id INT
) RETURNS BOOLEAN AS $$
DECLARE
  v_is_system_admin BOOLEAN;
  v_assigned_stores INT[];
BEGIN
  -- Get user's store access info
  SELECT is_system_admin, assigned_stores
  INTO v_is_system_admin, v_assigned_stores
  FROM user_profiles
  WHERE id = p_user_id;

  -- Super admins have access to all stores
  IF v_is_system_admin THEN
    RETURN TRUE;
  END IF;

  -- Check if store is in assigned stores
  RETURN p_store_id = ANY(v_assigned_stores);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get user's accessible stores
CREATE OR REPLACE FUNCTION get_user_accessible_stores(p_user_id UUID)
RETURNS TABLE(store_id INT) AS $$
BEGIN
  RETURN QUERY
  SELECT unnest(assigned_stores)
  FROM user_profiles
  WHERE id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user can manage another user
CREATE OR REPLACE FUNCTION can_user_manage_user(
  p_manager_id UUID,
  p_target_user_id UUID
) RETURNS BOOLEAN AS $$
DECLARE
  v_manager_role VARCHAR;
  v_target_role VARCHAR;
  v_manager_stores INT[];
  v_target_store INT;
BEGIN
  -- Get roles
  SELECT role, assigned_stores INTO v_manager_role, v_manager_stores
  FROM user_profiles WHERE id = p_manager_id;

  SELECT role, store_id INTO v_target_role, v_target_store
  FROM user_profiles WHERE id = p_target_user_id;

  -- Super admin can manage anyone
  IF v_manager_role = 'super_admin' THEN
    RETURN TRUE;
  END IF;

  -- Admin can manage manager and staff in their stores
  IF v_manager_role = 'admin' THEN
    IF v_target_role IN ('manager', 'staff') AND v_target_store = ANY(v_manager_stores) THEN
      RETURN TRUE;
    END IF;
  END IF;

  -- Manager can manage staff in their store
  IF v_manager_role = 'manager' THEN
    IF v_target_role = 'staff' AND v_target_store = ANY(v_manager_stores) THEN
      RETURN TRUE;
    END IF;
  END IF;

  RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- SUCCESS! Migration 029 complete.
--
-- Added:
-- ✅ assigned_stores[] - Multi-store support for Admins
-- ✅ detailed_permissions - Fine-grained permission control
-- ✅ created_by - Hierarchy tracking
-- ✅ can_hire_roles[] - Role creation permissions
-- ✅ is_system_admin - Super Admin flag
-- ✅ Helper functions for permission checks
-- ✅ Indexes for performance
-- ✅ Updated all existing users with new permissions
--
-- Next: Run 030_create_store_assignments.sql
-- =====================================================
