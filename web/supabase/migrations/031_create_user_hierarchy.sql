-- =====================================================
-- Migration 031: Create user_hierarchy Table
-- Version: 1.0
-- Date: 2025-11-19
-- Purpose: Track reporting structure and user creation chain
-- =====================================================

-- =====================================================
-- STEP 1: Create user_hierarchy table
-- =====================================================

CREATE TABLE IF NOT EXISTS user_hierarchy (
    id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    manager_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,  -- Who this user reports to
    created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,  -- Who created this user account
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    level INT NOT NULL,  -- Hierarchy level: 4=super_admin, 3=admin, 2=manager, 1=staff
    can_promote_to_level INT NOT NULL,  -- Max level this user can promote others to
    reporting_chain UUID[],  -- Array of user IDs in reporting chain (for quick lookups)
    notes TEXT
);

-- Add comments for documentation
COMMENT ON TABLE user_hierarchy IS 'Tracks user reporting structure and creation chain for permission enforcement';
COMMENT ON COLUMN user_hierarchy.user_id IS 'User ID from auth.users (unique)';
COMMENT ON COLUMN user_hierarchy.manager_id IS 'User ID of this user''s direct manager/supervisor';
COMMENT ON COLUMN user_hierarchy.created_by IS 'User ID of who created this account';
COMMENT ON COLUMN user_hierarchy.level IS 'Numeric hierarchy level: 4=super_admin, 3=admin, 2=manager, 1=staff';
COMMENT ON COLUMN user_hierarchy.can_promote_to_level IS 'Maximum level this user can promote others to (usually same as their level)';
COMMENT ON COLUMN user_hierarchy.reporting_chain IS 'Array of all manager IDs up the chain for quick permission checks';

-- =====================================================
-- STEP 2: Create indexes for performance
-- =====================================================

CREATE INDEX idx_user_hierarchy_manager ON user_hierarchy(manager_id);
CREATE INDEX idx_user_hierarchy_created_by ON user_hierarchy(created_by);
CREATE INDEX idx_user_hierarchy_level ON user_hierarchy(level);
CREATE INDEX idx_user_hierarchy_reporting_chain ON user_hierarchy USING GIN(reporting_chain);

-- =====================================================
-- STEP 3: Create triggers
-- =====================================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_user_hierarchy_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_user_hierarchy_updated_at_trigger
BEFORE UPDATE ON user_hierarchy
FOR EACH ROW
EXECUTE FUNCTION update_user_hierarchy_updated_at();

-- Auto-build reporting chain when manager changes
CREATE OR REPLACE FUNCTION build_reporting_chain()
RETURNS TRIGGER AS $$
DECLARE
    v_chain UUID[];
    v_current_manager UUID;
    v_depth INT := 0;
    v_max_depth INT := 10;  -- Prevent infinite loops
BEGIN
    -- Only rebuild if manager changed or this is a new insert
    IF TG_OP = 'INSERT' OR (TG_OP = 'UPDATE' AND NEW.manager_id IS DISTINCT FROM OLD.manager_id) THEN
        v_chain := ARRAY[]::UUID[];
        v_current_manager := NEW.manager_id;

        -- Build chain by following manager_id up the tree
        WHILE v_current_manager IS NOT NULL AND v_depth < v_max_depth LOOP
            v_chain := v_chain || v_current_manager;

            -- Get next manager up the chain
            SELECT manager_id INTO v_current_manager
            FROM user_hierarchy
            WHERE user_id = v_current_manager;

            v_depth := v_depth + 1;
        END LOOP;

        NEW.reporting_chain := v_chain;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER build_reporting_chain_trigger
BEFORE INSERT OR UPDATE ON user_hierarchy
FOR EACH ROW
EXECUTE FUNCTION build_reporting_chain();

-- =====================================================
-- STEP 4: Populate existing users
-- =====================================================

-- Insert hierarchy records for existing users
INSERT INTO user_hierarchy (user_id, manager_id, created_by, level, can_promote_to_level)
SELECT
    id AS user_id,
    created_by AS manager_id,  -- Their creator is their manager
    created_by,
    CASE role
        WHEN 'super_admin' THEN 4
        WHEN 'admin' THEN 3
        WHEN 'manager' THEN 2
        WHEN 'staff' THEN 1
        ELSE 1
    END AS level,
    CASE role
        WHEN 'super_admin' THEN 4  -- Can promote to super_admin
        WHEN 'admin' THEN 3        -- Can promote to admin
        WHEN 'manager' THEN 2      -- Can promote to manager
        WHEN 'staff' THEN 1        -- Can only promote to staff
        ELSE 1
    END AS can_promote_to_level
FROM user_profiles
ON CONFLICT (user_id) DO NOTHING;

-- Set super admins to have no manager (they're top level)
UPDATE user_hierarchy
SET manager_id = NULL
WHERE user_id IN (
    SELECT id FROM user_profiles WHERE role = 'super_admin'
);

-- =====================================================
-- STEP 5: Enable Row Level Security
-- =====================================================

ALTER TABLE user_hierarchy ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- STEP 6: Create RLS policies
-- =====================================================

-- Super Admins can see all hierarchy
CREATE POLICY "Super admins can view all hierarchy"
ON user_hierarchy FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM user_profiles
        WHERE id = auth.uid()
        AND is_system_admin = TRUE
    )
);

-- Users can see their own hierarchy
CREATE POLICY "Users can view their own hierarchy"
ON user_hierarchy FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- Users can see hierarchy of their direct reports
CREATE POLICY "Users can view their reports' hierarchy"
ON user_hierarchy FOR SELECT
TO authenticated
USING (
    manager_id = auth.uid() OR
    auth.uid() = ANY(reporting_chain)
);

-- Super Admins can manage all hierarchy
CREATE POLICY "Super admins can manage all hierarchy"
ON user_hierarchy FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM user_profiles
        WHERE id = auth.uid()
        AND is_system_admin = TRUE
    )
);

-- Users can update hierarchy for their subordinates
CREATE POLICY "Users can update hierarchy for subordinates"
ON user_hierarchy FOR UPDATE
TO authenticated
USING (
    manager_id = auth.uid() OR
    created_by = auth.uid()
);

-- =====================================================
-- STEP 7: Create helper functions
-- =====================================================

-- Function to get role level number
CREATE OR REPLACE FUNCTION get_role_level(p_role VARCHAR)
RETURNS INT AS $$
BEGIN
    RETURN CASE p_role
        WHEN 'super_admin' THEN 4
        WHEN 'admin' THEN 3
        WHEN 'manager' THEN 2
        WHEN 'staff' THEN 1
        ELSE 0
    END;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Function to check if user can manage another user (by hierarchy)
CREATE OR REPLACE FUNCTION can_user_manage_by_hierarchy(
    p_manager_id UUID,
    p_target_id UUID
) RETURNS BOOLEAN AS $$
DECLARE
    v_manager_level INT;
    v_target_level INT;
    v_is_in_chain BOOLEAN;
BEGIN
    -- Get levels
    SELECT level INTO v_manager_level
    FROM user_hierarchy
    WHERE user_id = p_manager_id;

    SELECT level INTO v_target_level
    FROM user_hierarchy
    WHERE user_id = p_target_id;

    -- Super admins can manage anyone
    IF v_manager_level = 4 THEN
        RETURN TRUE;
    END IF;

    -- Check if manager is in target's reporting chain
    SELECT (p_manager_id = ANY(reporting_chain)) INTO v_is_in_chain
    FROM user_hierarchy
    WHERE user_id = p_target_id;

    -- Can manage if they're in chain AND have higher or equal level
    RETURN v_is_in_chain AND v_manager_level >= v_target_level;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get all direct reports
CREATE OR REPLACE FUNCTION get_direct_reports(p_user_id UUID)
RETURNS TABLE (
    user_id UUID,
    user_name VARCHAR,
    user_role VARCHAR,
    level INT,
    created_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        uh.user_id,
        up.full_name AS user_name,
        up.role AS user_role,
        uh.level,
        uh.created_at
    FROM user_hierarchy uh
    JOIN user_profiles up ON up.id = uh.user_id
    WHERE uh.manager_id = p_user_id
    ORDER BY uh.level DESC, up.full_name ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get all reports (direct and indirect)
CREATE OR REPLACE FUNCTION get_all_reports(p_user_id UUID)
RETURNS TABLE (
    user_id UUID,
    user_name VARCHAR,
    user_role VARCHAR,
    level INT,
    depth INT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        uh.user_id,
        up.full_name AS user_name,
        up.role AS user_role,
        uh.level,
        array_length(uh.reporting_chain, 1) -
        array_position(uh.reporting_chain, p_user_id) + 1 AS depth
    FROM user_hierarchy uh
    JOIN user_profiles up ON up.id = uh.user_id
    WHERE p_user_id = ANY(uh.reporting_chain)
    ORDER BY depth ASC, uh.level DESC, up.full_name ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user can promote target to new role
CREATE OR REPLACE FUNCTION can_promote_to_role(
    p_promoter_id UUID,
    p_target_id UUID,
    p_new_role VARCHAR
) RETURNS BOOLEAN AS $$
DECLARE
    v_promoter_level INT;
    v_new_role_level INT;
BEGIN
    -- Get promoter's max promotion level
    SELECT can_promote_to_level INTO v_promoter_level
    FROM user_hierarchy
    WHERE user_id = p_promoter_id;

    -- Get target role level
    v_new_role_level := get_role_level(p_new_role);

    -- Can promote if new role level is <= promoter's max level
    RETURN v_new_role_level <= v_promoter_level;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- SUCCESS! Migration 031 complete.
--
-- Created:
-- ✅ user_hierarchy table - Track reporting structure
-- ✅ Automatic reporting chain building
-- ✅ Level-based permission checks
-- ✅ RLS policies for security
-- ✅ Helper functions for hierarchy management
-- ✅ Populated existing users
--
-- Next: Run 032_create_permission_changes.sql
-- =====================================================
