-- =============================================================================
-- RBAC Test Users Setup
-- =============================================================================
-- Purpose: Create test users for each role to verify RBAC implementation
-- Run this in: Supabase Dashboard → SQL Editor
-- Date: November 20, 2025
-- =============================================================================

-- IMPORTANT: Make sure migrations 029-033 have been run first (Phase 2-3 RBAC migrations)

-- =============================================================================
-- 1. CREATE TEST USER PROFILES
-- =============================================================================

-- Test User 1: Super Admin
INSERT INTO user_profiles (
    id,
    role,
    full_name,
    phone,
    email,
    is_system_admin,
    assigned_stores,
    can_hire_roles,
    detailed_permissions,
    is_active,
    created_at,
    updated_at
) VALUES (
    '00000000-0000-0000-0000-000000000001'::uuid,
    'super_admin',
    'Test Super Admin',
    '555-0001',
    'superadmin@test.com',
    true,  -- Is system admin
    ARRAY[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29],
    ARRAY['super_admin', 'admin', 'manager', 'staff']::text[],
    '{}'::jsonb,  -- Empty permissions means ALL permissions (checked via is_system_admin flag)
    true,
    NOW(),
    NOW()
) ON CONFLICT (id) DO UPDATE SET
    role = EXCLUDED.role,
    full_name = EXCLUDED.full_name,
    is_system_admin = EXCLUDED.is_system_admin,
    assigned_stores = EXCLUDED.assigned_stores,
    can_hire_roles = EXCLUDED.can_hire_roles,
    updated_at = NOW();

-- Test User 2: Admin (Multi-Store)
INSERT INTO user_profiles (
    id,
    role,
    full_name,
    phone,
    email,
    is_system_admin,
    assigned_stores,
    store_id,
    can_hire_roles,
    detailed_permissions,
    is_active,
    created_at,
    updated_at
) VALUES (
    '00000000-0000-0000-0000-000000000002'::uuid,
    'admin',
    'Test Admin (Multi-Store)',
    '555-0002',
    'admin@test.com',
    false,
    ARRAY[1,2,3],  -- Access to 3 stores
    1,  -- Primary store
    ARRAY['manager', 'staff']::text[],
    '{
        "orders": {
            "view": true,
            "create": true,
            "update": true,
            "delete": true,
            "manage": true
        },
        "menu": {
            "view": true,
            "create": true,
            "update": true,
            "delete": true,
            "manage": true
        },
        "analytics": {
            "view": true,
            "financial": true
        },
        "users": {
            "view": true,
            "create": true,
            "update": true,
            "delete": false,
            "manage": false
        },
        "settings": {
            "view": true,
            "update": true
        },
        "inventory": {
            "view": true,
            "update": true
        }
    }'::jsonb,
    true,
    NOW(),
    NOW()
) ON CONFLICT (id) DO UPDATE SET
    role = EXCLUDED.role,
    full_name = EXCLUDED.full_name,
    assigned_stores = EXCLUDED.assigned_stores,
    detailed_permissions = EXCLUDED.detailed_permissions,
    can_hire_roles = EXCLUDED.can_hire_roles,
    updated_at = NOW();

-- Test User 3: Manager (Single Store)
INSERT INTO user_profiles (
    id,
    role,
    full_name,
    phone,
    email,
    is_system_admin,
    assigned_stores,
    store_id,
    can_hire_roles,
    detailed_permissions,
    is_active,
    created_at,
    updated_at
) VALUES (
    '00000000-0000-0000-0000-000000000003'::uuid,
    'manager',
    'Test Manager (Single Store)',
    '555-0003',
    'manager@test.com',
    false,
    ARRAY[1],  -- Access to only 1 store
    1,
    ARRAY['staff']::text[],
    '{
        "orders": {
            "view": true,
            "create": true,
            "update": true,
            "delete": false
        },
        "menu": {
            "view": true,
            "create": false,
            "update": true,
            "delete": false
        },
        "analytics": {
            "view": true,
            "financial": false
        },
        "inventory": {
            "view": true,
            "update": true
        },
        "users": {
            "view": true,
            "create": false,
            "update": false,
            "delete": false
        }
    }'::jsonb,
    true,
    NOW(),
    NOW()
) ON CONFLICT (id) DO UPDATE SET
    role = EXCLUDED.role,
    full_name = EXCLUDED.full_name,
    assigned_stores = EXCLUDED.assigned_stores,
    detailed_permissions = EXCLUDED.detailed_permissions,
    can_hire_roles = EXCLUDED.can_hire_roles,
    updated_at = NOW();

-- Test User 4: Staff (Single Store, Limited Permissions)
INSERT INTO user_profiles (
    id,
    role,
    full_name,
    phone,
    email,
    is_system_admin,
    assigned_stores,
    store_id,
    can_hire_roles,
    detailed_permissions,
    is_active,
    created_at,
    updated_at
) VALUES (
    '00000000-0000-0000-0000-000000000004'::uuid,
    'staff',
    'Test Staff (Limited Access)',
    '555-0004',
    'staff@test.com',
    false,
    ARRAY[1],  -- Access to only 1 store
    1,
    ARRAY[]::text[],  -- Cannot hire anyone
    '{
        "orders": {
            "view": true,
            "create": false,
            "update": true,
            "delete": false
        },
        "menu": {
            "view": true,
            "create": false,
            "update": false,
            "delete": false
        },
        "analytics": {
            "view": false,
            "financial": false
        }
    }'::jsonb,
    true,
    NOW(),
    NOW()
) ON CONFLICT (id) DO UPDATE SET
    role = EXCLUDED.role,
    full_name = EXCLUDED.full_name,
    assigned_stores = EXCLUDED.assigned_stores,
    detailed_permissions = EXCLUDED.detailed_permissions,
    can_hire_roles = EXCLUDED.can_hire_roles,
    updated_at = NOW();

-- =============================================================================
-- 2. CREATE STORE ASSIGNMENTS
-- =============================================================================

-- Super Admin: All stores
INSERT INTO store_assignments (id, user_id, store_id, is_primary_store, assigned_at, assigned_by)
SELECT
    gen_random_uuid(),
    '00000000-0000-0000-0000-000000000001'::uuid,
    s.id,
    s.id = 1,  -- Store 1 is primary
    NOW(),
    '00000000-0000-0000-0000-000000000001'::uuid  -- Self-assigned
FROM stores s
WHERE s.id BETWEEN 1 AND 29
ON CONFLICT (user_id, store_id) DO NOTHING;

-- Admin: Stores 1, 2, 3
INSERT INTO store_assignments (id, user_id, store_id, is_primary_store, assigned_at, assigned_by)
VALUES
    (gen_random_uuid(), '00000000-0000-0000-0000-000000000002'::uuid, 1, true, NOW(), '00000000-0000-0000-0000-000000000001'::uuid),
    (gen_random_uuid(), '00000000-0000-0000-0000-000000000002'::uuid, 2, false, NOW(), '00000000-0000-0000-0000-000000000001'::uuid),
    (gen_random_uuid(), '00000000-0000-0000-0000-000000000002'::uuid, 3, false, NOW(), '00000000-0000-0000-0000-000000000001'::uuid)
ON CONFLICT (user_id, store_id) DO NOTHING;

-- Manager: Store 1 only
INSERT INTO store_assignments (id, user_id, store_id, is_primary_store, assigned_at, assigned_by)
VALUES
    (gen_random_uuid(), '00000000-0000-0000-0000-000000000003'::uuid, 1, true, NOW(), '00000000-0000-0000-0000-000000000002'::uuid)
ON CONFLICT (user_id, store_id) DO NOTHING;

-- Staff: Store 1 only
INSERT INTO store_assignments (id, user_id, store_id, is_primary_store, assigned_at, assigned_by)
VALUES
    (gen_random_uuid(), '00000000-0000-0000-0000-000000000004'::uuid, 1, true, NOW(), '00000000-0000-0000-0000-000000000003'::uuid)
ON CONFLICT (user_id, store_id) DO NOTHING;

-- =============================================================================
-- 3. CREATE USER HIERARCHY
-- =============================================================================

-- Super Admin (Level 4 - Top)
INSERT INTO user_hierarchy (id, user_id, reports_to, level, created_at)
VALUES (gen_random_uuid(), '00000000-0000-0000-0000-000000000001'::uuid, NULL, 4, NOW())
ON CONFLICT (user_id) DO UPDATE SET level = EXCLUDED.level;

-- Admin (Level 3 - Reports to Super Admin)
INSERT INTO user_hierarchy (id, user_id, reports_to, level, created_at)
VALUES (gen_random_uuid(), '00000000-0000-0000-0000-000000000002'::uuid, '00000000-0000-0000-0000-000000000001'::uuid, 3, NOW())
ON CONFLICT (user_id) DO UPDATE SET level = EXCLUDED.level, reports_to = EXCLUDED.reports_to;

-- Manager (Level 2 - Reports to Admin)
INSERT INTO user_hierarchy (id, user_id, reports_to, level, created_at)
VALUES (gen_random_uuid(), '00000000-0000-0000-0000-000000000003'::uuid, '00000000-0000-0000-0000-000000000002'::uuid, 2, NOW())
ON CONFLICT (user_id) DO UPDATE SET level = EXCLUDED.level, reports_to = EXCLUDED.reports_to;

-- Staff (Level 1 - Reports to Manager)
INSERT INTO user_hierarchy (id, user_id, reports_to, level, created_at)
VALUES (gen_random_uuid(), '00000000-0000-0000-0000-000000000004'::uuid, '00000000-0000-0000-0000-000000000003'::uuid, 1, NOW())
ON CONFLICT (user_id) DO UPDATE SET level = EXCLUDED.level, reports_to = EXCLUDED.reports_to;

-- =============================================================================
-- 4. VERIFICATION QUERIES
-- =============================================================================

-- Verify users created
SELECT
    full_name,
    role,
    is_system_admin,
    array_length(assigned_stores, 1) as store_count,
    store_id as primary_store,
    is_active
FROM user_profiles
WHERE full_name LIKE 'Test%'
ORDER BY
    CASE role
        WHEN 'super_admin' THEN 1
        WHEN 'admin' THEN 2
        WHEN 'manager' THEN 3
        WHEN 'staff' THEN 4
    END;

-- Verify store assignments
SELECT
    up.full_name,
    up.role,
    COUNT(sa.store_id) as assigned_store_count,
    ARRAY_AGG(sa.store_id ORDER BY sa.store_id) as stores
FROM user_profiles up
LEFT JOIN store_assignments sa ON sa.user_id = up.id
WHERE up.full_name LIKE 'Test%'
GROUP BY up.id, up.full_name, up.role
ORDER BY
    CASE up.role
        WHEN 'super_admin' THEN 1
        WHEN 'admin' THEN 2
        WHEN 'manager' THEN 3
        WHEN 'staff' THEN 4
    END;

-- Verify user hierarchy
SELECT
    up1.full_name as user_name,
    up1.role as user_role,
    uh.level,
    up2.full_name as reports_to_name,
    up2.role as reports_to_role
FROM user_hierarchy uh
JOIN user_profiles up1 ON up1.id = uh.user_id
LEFT JOIN user_profiles up2 ON up2.id = uh.reports_to
WHERE up1.full_name LIKE 'Test%'
ORDER BY uh.level DESC;

-- =============================================================================
-- 5. NEXT STEPS: CREATE AUTH USERS
-- =============================================================================

-- IMPORTANT: You need to create auth.users entries for these test profiles
--
-- Option 1: Supabase Dashboard (Recommended)
-- -----------------------------------------
-- 1. Go to Supabase Dashboard → Authentication → Users
-- 2. Click "Add User" for each test user
-- 3. Use these emails and create passwords:
--    - superadmin@test.com (Super Admin)
--    - admin@test.com (Admin)
--    - manager@test.com (Manager)
--    - staff@test.com (Staff)
-- 4. After creating, note the UUID assigned
-- 5. Update user_profiles.id to match the auth.users.id
--
-- Option 2: Web Platform Super Admin Dashboard
-- --------------------------------------------
-- 1. Go to your web platform super admin dashboard
-- 2. Use the "Create User" feature
-- 3. Create users with the test emails above
-- 4. The system will automatically create both auth.users and user_profiles
--
-- Option 3: Supabase SQL (Advanced)
-- ----------------------------------
-- You can also use the admin API or SQL to create auth users
-- But this requires special permissions and is more complex

-- =============================================================================
-- TESTING CHECKLIST
-- =============================================================================

/*
After running this script and creating auth.users:

✅ Test Super Admin
   □ Can see all 29 stores
   □ Can perform all actions (orders.delete, menu.delete, etc.)
   □ hasDetailedPermission() returns true for everything
   □ isSuperAdmin() returns true

✅ Test Admin
   □ Can see stores 1, 2, 3 only
   □ Can create/update/delete orders
   □ Can create/update/delete menu items
   □ Can view financial analytics
   □ Can hire managers and staff
   □ Cannot see orders from store 4+

✅ Test Manager
   □ Can see store 1 only
   □ Can create/update orders (but NOT delete)
   □ Can update menu items (but NOT create/delete)
   □ Can view analytics (but NOT financial)
   □ Can hire staff only
   □ Cannot access store 2+

✅ Test Staff
   □ Can see store 1 only
   □ Can view and update orders (but NOT create/delete)
   □ Can view menu (but NOT edit)
   □ Cannot view analytics
   □ Cannot hire anyone
   □ Cannot access other stores

*/

-- =============================================================================
-- CLEANUP (Run this if you want to remove test users)
-- =============================================================================

/*
-- WARNING: This will delete all test users and their related data

DELETE FROM permission_changes WHERE target_user_id IN (
    SELECT id FROM user_profiles WHERE full_name LIKE 'Test%'
);

DELETE FROM user_hierarchy WHERE user_id IN (
    SELECT id FROM user_profiles WHERE full_name LIKE 'Test%'
);

DELETE FROM store_assignments WHERE user_id IN (
    SELECT id FROM user_profiles WHERE full_name LIKE 'Test%'
);

DELETE FROM user_profiles WHERE full_name LIKE 'Test%';

-- Also delete from auth.users if you created them
-- (Can be done via Supabase Dashboard → Authentication → Users)
*/
