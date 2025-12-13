-- =====================================================
-- Migration 032: Create permission_changes Audit Table
-- Version: 1.0
-- Date: 2025-11-19
-- Purpose: Track all permission and role changes for security and compliance
-- =====================================================

-- =====================================================
-- STEP 1: Create permission_changes table
-- =====================================================

CREATE TABLE IF NOT EXISTS permission_changes (
    id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,  -- User whose permissions changed
    changed_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE SET NULL,  -- Who made the change
    change_type VARCHAR(50) NOT NULL,  -- Type of change
    old_role VARCHAR(50),  -- Previous role
    new_role VARCHAR(50),  -- New role
    old_permissions JSONB,  -- Previous permissions
    new_permissions JSONB,  -- New permissions
    old_stores INT[],  -- Previous assigned stores
    new_stores INT[],  -- New assigned stores
    reason TEXT,  -- Reason for the change
    ip_address INET,  -- IP address of who made the change
    user_agent TEXT,  -- Browser/app that made the change
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    metadata JSONB  -- Additional context data
);

-- Add comments for documentation
COMMENT ON TABLE permission_changes IS 'Audit log for all permission, role, and access changes';
COMMENT ON COLUMN permission_changes.user_id IS 'User whose permissions were changed';
COMMENT ON COLUMN permission_changes.changed_by IS 'User who made the change';
COMMENT ON COLUMN permission_changes.change_type IS 'Type: role_change, promotion, demotion, permission_grant, permission_revoke, store_assignment, store_removal';
COMMENT ON COLUMN permission_changes.reason IS 'Explanation for why the change was made';
COMMENT ON COLUMN permission_changes.metadata IS 'Additional context (e.g., request ID, approval chain)';

-- =====================================================
-- STEP 2: Create indexes for performance
-- =====================================================

CREATE INDEX idx_permission_changes_user ON permission_changes(user_id);
CREATE INDEX idx_permission_changes_changed_by ON permission_changes(changed_by);
CREATE INDEX idx_permission_changes_date ON permission_changes(changed_at DESC);
CREATE INDEX idx_permission_changes_type ON permission_changes(change_type);
CREATE INDEX idx_permission_changes_user_date ON permission_changes(user_id, changed_at DESC);

-- GIN index for metadata searches
CREATE INDEX idx_permission_changes_metadata ON permission_changes USING GIN(metadata);

-- =====================================================
-- STEP 3: Create change type constraint
-- =====================================================

ALTER TABLE permission_changes
ADD CONSTRAINT valid_change_type CHECK (
    change_type IN (
        'role_change',
        'promotion',
        'demotion',
        'permission_grant',
        'permission_revoke',
        'store_assignment',
        'store_removal',
        'user_created',
        'user_deleted',
        'access_granted',
        'access_revoked'
    )
);

-- =====================================================
-- STEP 4: Enable Row Level Security
-- =====================================================

ALTER TABLE permission_changes ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- STEP 5: Create RLS policies
-- =====================================================

-- Super Admins can see all changes
CREATE POLICY "Super admins can view all permission changes"
ON permission_changes FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM user_profiles
        WHERE id = auth.uid()
        AND is_system_admin = TRUE
    )
);

-- Admins can see changes for users in their stores
CREATE POLICY "Admins can view changes for their users"
ON permission_changes FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM user_profiles up
        JOIN store_assignments sa ON sa.user_id = permission_changes.user_id
        WHERE up.id = auth.uid()
        AND up.role = 'admin'
        AND sa.store_id = ANY(up.assigned_stores)
    )
);

-- Users can see their own permission changes
CREATE POLICY "Users can view their own permission changes"
ON permission_changes FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- Only super admins and admins can insert audit logs
CREATE POLICY "Super admins and admins can create audit logs"
ON permission_changes FOR INSERT
TO authenticated
WITH CHECK (
    EXISTS (
        SELECT 1 FROM user_profiles
        WHERE id = auth.uid()
        AND role IN ('super_admin', 'admin')
    )
);

-- =====================================================
-- STEP 6: Create audit logging functions
-- =====================================================

-- Function to log permission change
CREATE OR REPLACE FUNCTION log_permission_change(
    p_user_id UUID,
    p_change_type VARCHAR,
    p_old_role VARCHAR DEFAULT NULL,
    p_new_role VARCHAR DEFAULT NULL,
    p_old_permissions JSONB DEFAULT NULL,
    p_new_permissions JSONB DEFAULT NULL,
    p_old_stores INT[] DEFAULT NULL,
    p_new_stores INT[] DEFAULT NULL,
    p_reason TEXT DEFAULT NULL,
    p_metadata JSONB DEFAULT NULL
) RETURNS permission_changes AS $$
DECLARE
    v_change permission_changes;
BEGIN
    INSERT INTO permission_changes (
        user_id,
        changed_by,
        change_type,
        old_role,
        new_role,
        old_permissions,
        new_permissions,
        old_stores,
        new_stores,
        reason,
        metadata
    ) VALUES (
        p_user_id,
        auth.uid(),
        p_change_type,
        p_old_role,
        p_new_role,
        p_old_permissions,
        p_new_permissions,
        p_old_stores,
        p_new_stores,
        p_reason,
        p_metadata
    )
    RETURNING * INTO v_change;

    RETURN v_change;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to auto-log role changes in user_profiles
CREATE OR REPLACE FUNCTION auto_log_role_change()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.role IS DISTINCT FROM NEW.role THEN
        PERFORM log_permission_change(
            p_user_id := NEW.id,
            p_change_type := CASE
                WHEN get_role_level(NEW.role) > get_role_level(OLD.role) THEN 'promotion'
                WHEN get_role_level(NEW.role) < get_role_level(OLD.role) THEN 'demotion'
                ELSE 'role_change'
            END,
            p_old_role := OLD.role,
            p_new_role := NEW.role,
            p_old_permissions := OLD.detailed_permissions,
            p_new_permissions := NEW.detailed_permissions,
            p_reason := 'Automatic role change detection'
        );
    END IF;

    IF OLD.assigned_stores IS DISTINCT FROM NEW.assigned_stores THEN
        PERFORM log_permission_change(
            p_user_id := NEW.id,
            p_change_type := 'store_assignment',
            p_old_stores := OLD.assigned_stores,
            p_new_stores := NEW.assigned_stores,
            p_reason := 'Store assignments changed'
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER auto_log_user_profile_changes
AFTER UPDATE ON user_profiles
FOR EACH ROW
EXECUTE FUNCTION auto_log_role_change();

-- Trigger to log new user creation
CREATE OR REPLACE FUNCTION auto_log_user_creation()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM log_permission_change(
        p_user_id := NEW.id,
        p_change_type := 'user_created',
        p_new_role := NEW.role,
        p_new_permissions := NEW.detailed_permissions,
        p_new_stores := NEW.assigned_stores,
        p_reason := 'New user account created',
        p_metadata := jsonb_build_object(
            'created_by', NEW.created_by,
            'initial_role', NEW.role
        )
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER auto_log_user_profile_creation
AFTER INSERT ON user_profiles
FOR EACH ROW
EXECUTE FUNCTION auto_log_user_creation();

-- =====================================================
-- STEP 7: Create reporting functions
-- =====================================================

-- Function to get permission change history for a user
CREATE OR REPLACE FUNCTION get_user_permission_history(
    p_user_id UUID,
    p_limit INT DEFAULT 50
)
RETURNS TABLE (
    change_id INT,
    change_type VARCHAR,
    old_role VARCHAR,
    new_role VARCHAR,
    changed_by_name VARCHAR,
    changed_at TIMESTAMP WITH TIME ZONE,
    reason TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        pc.id AS change_id,
        pc.change_type,
        pc.old_role,
        pc.new_role,
        up.full_name AS changed_by_name,
        pc.changed_at,
        pc.reason
    FROM permission_changes pc
    LEFT JOIN user_profiles up ON up.id = pc.changed_by
    WHERE pc.user_id = p_user_id
    ORDER BY pc.changed_at DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get recent permission changes (audit dashboard)
CREATE OR REPLACE FUNCTION get_recent_permission_changes(
    p_days INT DEFAULT 30,
    p_limit INT DEFAULT 100
)
RETURNS TABLE (
    change_id INT,
    user_name VARCHAR,
    change_type VARCHAR,
    old_role VARCHAR,
    new_role VARCHAR,
    changed_by_name VARCHAR,
    changed_at TIMESTAMP WITH TIME ZONE,
    reason TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        pc.id AS change_id,
        u.full_name AS user_name,
        pc.change_type,
        pc.old_role,
        pc.new_role,
        cb.full_name AS changed_by_name,
        pc.changed_at,
        pc.reason
    FROM permission_changes pc
    JOIN user_profiles u ON u.id = pc.user_id
    LEFT JOIN user_profiles cb ON cb.id = pc.changed_by
    WHERE pc.changed_at >= NOW() - (p_days || ' days')::INTERVAL
    ORDER BY pc.changed_at DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get permission change statistics
CREATE OR REPLACE FUNCTION get_permission_change_stats(p_days INT DEFAULT 30)
RETURNS TABLE (
    change_type VARCHAR,
    count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        pc.change_type,
        COUNT(*) AS count
    FROM permission_changes pc
    WHERE pc.changed_at >= NOW() - (p_days || ' days')::INTERVAL
    GROUP BY pc.change_type
    ORDER BY count DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- SUCCESS! Migration 032 complete.
--
-- Created:
-- ✅ permission_changes table - Complete audit trail
-- ✅ Auto-logging triggers for role changes
-- ✅ Auto-logging for user creation
-- ✅ RLS policies for secure access
-- ✅ Helper functions for logging
-- ✅ Reporting functions for dashboards
-- ✅ Change type validation
--
-- Next: Run 033_comprehensive_rls_policies.sql
-- =====================================================
