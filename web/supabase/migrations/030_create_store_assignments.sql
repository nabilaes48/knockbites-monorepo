-- =====================================================
-- Migration 030: Create store_assignments Table
-- Version: 1.0
-- Date: 2025-11-19
-- Purpose: Track which users are assigned to which stores
-- =====================================================

-- =====================================================
-- STEP 1: Create store_assignments table
-- =====================================================

CREATE TABLE IF NOT EXISTS store_assignments (
    id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    store_id INT NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    role_at_store VARCHAR(50) NOT NULL,  -- Role this user has at this specific store
    assigned_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,  -- Who assigned this user
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_primary_store BOOLEAN DEFAULT FALSE,  -- Is this their primary/home store?
    access_level VARCHAR(50) DEFAULT 'full',  -- 'full', 'read_only', 'limited'
    notes TEXT,  -- Optional notes about this assignment
    UNIQUE(user_id, store_id)  -- User can only be assigned to a store once
);

-- Add comments for documentation
COMMENT ON TABLE store_assignments IS 'Tracks which users have access to which stores and their role at each store';
COMMENT ON COLUMN store_assignments.user_id IS 'User ID from auth.users';
COMMENT ON COLUMN store_assignments.store_id IS 'Store ID from stores table';
COMMENT ON COLUMN store_assignments.role_at_store IS 'Role this user has at this store (for multi-role users)';
COMMENT ON COLUMN store_assignments.assigned_by IS 'User ID of who made this assignment';
COMMENT ON COLUMN store_assignments.is_primary_store IS 'True if this is the user''s primary store (for default view)';
COMMENT ON COLUMN store_assignments.access_level IS 'Level of access: full, read_only, or limited';

-- =====================================================
-- STEP 2: Create indexes for performance
-- =====================================================

CREATE INDEX idx_store_assignments_user ON store_assignments(user_id);
CREATE INDEX idx_store_assignments_store ON store_assignments(store_id);
CREATE INDEX idx_store_assignments_assigned_by ON store_assignments(assigned_by);
CREATE INDEX idx_store_assignments_primary ON store_assignments(user_id, is_primary_store) WHERE is_primary_store = TRUE;
CREATE INDEX idx_store_assignments_role ON store_assignments(role_at_store);

-- Composite index for common queries
CREATE INDEX idx_store_assignments_user_store ON store_assignments(user_id, store_id);

-- =====================================================
-- STEP 3: Create triggers
-- =====================================================

-- Ensure only one primary store per user
CREATE OR REPLACE FUNCTION ensure_single_primary_store()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.is_primary_store = TRUE THEN
        -- Set all other stores for this user to non-primary
        UPDATE store_assignments
        SET is_primary_store = FALSE
        WHERE user_id = NEW.user_id
        AND id != NEW.id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ensure_single_primary_store_trigger
BEFORE INSERT OR UPDATE ON store_assignments
FOR EACH ROW
WHEN (NEW.is_primary_store = TRUE)
EXECUTE FUNCTION ensure_single_primary_store();

-- Auto-update user_profiles.assigned_stores when store_assignments changes
CREATE OR REPLACE FUNCTION sync_user_assigned_stores()
RETURNS TRIGGER AS $$
DECLARE
    v_user_id UUID;
BEGIN
    -- Get the affected user_id
    IF TG_OP = 'DELETE' THEN
        v_user_id := OLD.user_id;
    ELSE
        v_user_id := NEW.user_id;
    END IF;

    -- Update user_profiles.assigned_stores with current assignments
    UPDATE user_profiles
    SET assigned_stores = (
        SELECT ARRAY_AGG(store_id)
        FROM store_assignments
        WHERE user_id = v_user_id
    )
    WHERE id = v_user_id;

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER sync_user_assigned_stores_trigger
AFTER INSERT OR UPDATE OR DELETE ON store_assignments
FOR EACH ROW
EXECUTE FUNCTION sync_user_assigned_stores();

-- =====================================================
-- STEP 4: Populate existing assignments
-- =====================================================

-- Create store assignments for existing users
INSERT INTO store_assignments (user_id, store_id, role_at_store, is_primary_store, access_level)
SELECT
    id AS user_id,
    store_id,
    role AS role_at_store,
    TRUE AS is_primary_store,  -- Their current store is primary
    'full' AS access_level
FROM user_profiles
WHERE store_id IS NOT NULL
ON CONFLICT (user_id, store_id) DO NOTHING;

-- For Super Admins, create assignments for ALL stores
INSERT INTO store_assignments (user_id, store_id, role_at_store, is_primary_store, access_level)
SELECT
    up.id AS user_id,
    s.id AS store_id,
    'super_admin' AS role_at_store,
    (s.id = 1) AS is_primary_store,  -- Store 1 (Highland Mills) is default primary
    'full' AS access_level
FROM user_profiles up
CROSS JOIN stores s
WHERE up.role = 'super_admin'
ON CONFLICT (user_id, store_id) DO NOTHING;

-- =====================================================
-- STEP 5: Enable Row Level Security
-- =====================================================

ALTER TABLE store_assignments ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- STEP 6: Create RLS policies
-- =====================================================

-- Super Admins can see all assignments
CREATE POLICY "Super admins can view all store assignments"
ON store_assignments FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM user_profiles
        WHERE id = auth.uid()
        AND is_system_admin = TRUE
    )
);

-- Admins can see assignments for their stores
CREATE POLICY "Admins can view assignments for their stores"
ON store_assignments FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM user_profiles
        WHERE id = auth.uid()
        AND role = 'admin'
        AND store_assignments.store_id = ANY(assigned_stores)
    )
);

-- Managers can see assignments for their store
CREATE POLICY "Managers can view assignments for their store"
ON store_assignments FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM user_profiles
        WHERE id = auth.uid()
        AND role = 'manager'
        AND store_assignments.store_id = ANY(assigned_stores)
    )
);

-- Users can see their own assignments
CREATE POLICY "Users can view their own store assignments"
ON store_assignments FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- Super Admins can manage all assignments
CREATE POLICY "Super admins can manage all store assignments"
ON store_assignments FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM user_profiles
        WHERE id = auth.uid()
        AND is_system_admin = TRUE
    )
);

-- Admins can assign users to their stores
CREATE POLICY "Admins can assign users to their stores"
ON store_assignments FOR INSERT
TO authenticated
WITH CHECK (
    EXISTS (
        SELECT 1 FROM user_profiles
        WHERE id = auth.uid()
        AND role = 'admin'
        AND store_assignments.store_id = ANY(assigned_stores)
    )
);

-- Admins can update assignments for their stores
CREATE POLICY "Admins can update assignments for their stores"
ON store_assignments FOR UPDATE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM user_profiles
        WHERE id = auth.uid()
        AND role = 'admin'
        AND store_assignments.store_id = ANY(assigned_stores)
    )
);

-- Admins can delete assignments for their stores
CREATE POLICY "Admins can delete assignments for their stores"
ON store_assignments FOR DELETE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM user_profiles
        WHERE id = auth.uid()
        AND role = 'admin'
        AND store_assignments.store_id = ANY(assigned_stores)
    )
);

-- =====================================================
-- STEP 7: Create helper functions
-- =====================================================

-- Function to assign user to store
CREATE OR REPLACE FUNCTION assign_user_to_store(
    p_user_id UUID,
    p_store_id INT,
    p_role_at_store VARCHAR,
    p_assigned_by UUID,
    p_is_primary BOOLEAN DEFAULT FALSE
) RETURNS store_assignments AS $$
DECLARE
    v_assignment store_assignments;
BEGIN
    INSERT INTO store_assignments (
        user_id,
        store_id,
        role_at_store,
        assigned_by,
        is_primary_store
    ) VALUES (
        p_user_id,
        p_store_id,
        p_role_at_store,
        p_assigned_by,
        p_is_primary
    )
    ON CONFLICT (user_id, store_id)
    DO UPDATE SET
        role_at_store = EXCLUDED.role_at_store,
        assigned_by = EXCLUDED.assigned_by,
        is_primary_store = EXCLUDED.is_primary_store,
        assigned_at = NOW()
    RETURNING * INTO v_assignment;

    RETURN v_assignment;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to remove user from store
CREATE OR REPLACE FUNCTION remove_user_from_store(
    p_user_id UUID,
    p_store_id INT
) RETURNS BOOLEAN AS $$
BEGIN
    DELETE FROM store_assignments
    WHERE user_id = p_user_id
    AND store_id = p_store_id;

    RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get user's stores
CREATE OR REPLACE FUNCTION get_user_stores(p_user_id UUID)
RETURNS TABLE (
    store_id INT,
    store_name VARCHAR,
    role_at_store VARCHAR,
    is_primary BOOLEAN,
    assigned_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        sa.store_id,
        s.name AS store_name,
        sa.role_at_store,
        sa.is_primary_store AS is_primary,
        sa.assigned_at
    FROM store_assignments sa
    JOIN stores s ON s.id = sa.store_id
    WHERE sa.user_id = p_user_id
    ORDER BY sa.is_primary_store DESC, s.name ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to set primary store
CREATE OR REPLACE FUNCTION set_primary_store(
    p_user_id UUID,
    p_store_id INT
) RETURNS BOOLEAN AS $$
BEGIN
    -- Update the assignment to be primary
    UPDATE store_assignments
    SET is_primary_store = TRUE
    WHERE user_id = p_user_id
    AND store_id = p_store_id;

    -- Trigger will automatically set others to non-primary
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- SUCCESS! Migration 030 complete.
--
-- Created:
-- ✅ store_assignments table - Track user-store relationships
-- ✅ Indexes for performance
-- ✅ Triggers for data integrity
-- ✅ Auto-sync with user_profiles.assigned_stores
-- ✅ RLS policies for security
-- ✅ Helper functions for management
-- ✅ Populated existing assignments
--
-- Next: Run 031_create_user_hierarchy.sql
-- =====================================================
