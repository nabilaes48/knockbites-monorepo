# Phase 2 Testing Guide - Permission System

**Date:** November 20, 2025
**Status:** Ready for Testing
**Phase:** 2 of 6 - Permission System Backend

---

## ✅ What Was Built (Phase 2)

### **Files Created:**

1. ✅ `src/lib/permissions.ts` (420 lines)
   - Core permission checking logic
   - 20+ helper functions
   - Role hierarchy management
   - Store access validation

2. ✅ `src/hooks/usePermissions.ts` (265 lines)
   - React hook for permissions
   - Multiple specialized hooks
   - Real-time store access loading
   - Memoized permission checks

3. ✅ `src/components/PermissionGate.tsx` (280 lines)
   - Main PermissionGate component
   - 10+ specialized gate components
   - Fallback content support
   - Multiple permission logic (AND/OR)

4. ✅ `src/contexts/AuthContext.tsx` (Updated)
   - Extended UserProfile interface
   - RBAC fields loading
   - Auto-initialization of arrays/objects

---

## 🧪 How to Test the Permission System

### **Step 1: Verify TypeScript Compilation**

```bash
cd /Users/nabilimran/camerons-connect
npm run build:dev
```

**Expected Result:** No TypeScript errors

---

### **Step 2: Create Test Users (SQL)**

Open Supabase Dashboard → SQL Editor → Run this:

```sql
-- Test User 1: Super Admin
INSERT INTO user_profiles (
  id,
  role,
  full_name,
  phone,
  is_system_admin,
  assigned_stores,
  can_hire_roles,
  detailed_permissions,
  is_active
) VALUES (
  '00000000-0000-0000-0000-000000000001'::uuid,
  'super_admin',
  'Test Super Admin',
  '555-0001',
  true,
  ARRAY[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29],
  ARRAY['admin', 'manager', 'staff']::text[],
  '{}'::jsonb,
  true
) ON CONFLICT (id) DO UPDATE SET
  role = EXCLUDED.role,
  is_system_admin = EXCLUDED.is_system_admin,
  assigned_stores = EXCLUDED.assigned_stores,
  can_hire_roles = EXCLUDED.can_hire_roles;

-- Test User 2: Admin (Multi-Store)
INSERT INTO user_profiles (
  id,
  role,
  full_name,
  phone,
  is_system_admin,
  assigned_stores,
  store_id,
  can_hire_roles,
  detailed_permissions,
  is_active
) VALUES (
  '00000000-0000-0000-0000-000000000002'::uuid,
  'admin',
  'Test Admin',
  '555-0002',
  false,
  ARRAY[1,2,3],
  1,
  ARRAY['manager', 'staff']::text[],
  '{
    "orders": {"manage": true},
    "menu": {"manage": true},
    "analytics": {"view": true, "financial": true},
    "users": {"manage": true},
    "settings": {"manage": true}
  }'::jsonb,
  true
) ON CONFLICT (id) DO UPDATE SET
  role = EXCLUDED.role,
  assigned_stores = EXCLUDED.assigned_stores,
  can_hire_roles = EXCLUDED.can_hire_roles,
  detailed_permissions = EXCLUDED.detailed_permissions;

-- Test User 3: Manager (Single Store)
INSERT INTO user_profiles (
  id,
  role,
  full_name,
  phone,
  is_system_admin,
  assigned_stores,
  store_id,
  can_hire_roles,
  detailed_permissions,
  is_active
) VALUES (
  '00000000-0000-0000-0000-000000000003'::uuid,
  'manager',
  'Test Manager',
  '555-0003',
  false,
  ARRAY[1],
  1,
  ARRAY['staff']::text[],
  '{
    "orders": {"view": true, "update": true},
    "menu": {"view": true, "update": true},
    "analytics": {"view": true},
    "inventory": {"view": true, "update": true}
  }'::jsonb,
  true
) ON CONFLICT (id) DO UPDATE SET
  role = EXCLUDED.role,
  assigned_stores = EXCLUDED.assigned_stores,
  can_hire_roles = EXCLUDED.can_hire_roles,
  detailed_permissions = EXCLUDED.detailed_permissions;

-- Test User 4: Staff (Limited Access)
INSERT INTO user_profiles (
  id,
  role,
  full_name,
  phone,
  is_system_admin,
  assigned_stores,
  store_id,
  can_hire_roles,
  detailed_permissions,
  is_active
) VALUES (
  '00000000-0000-0000-0000-000000000004'::uuid,
  'staff',
  'Test Staff',
  '555-0004',
  false,
  ARRAY[1],
  1,
  ARRAY[]::text[],
  '{
    "orders": {"view": true, "update": true},
    "menu": {"view": true}
  }'::jsonb,
  true
) ON CONFLICT (id) DO UPDATE SET
  role = EXCLUDED.role,
  assigned_stores = EXCLUDED.assigned_stores,
  detailed_permissions = EXCLUDED.detailed_permissions;

-- Verify users created
SELECT
  full_name,
  role,
  is_system_admin,
  array_length(assigned_stores, 1) as store_count,
  can_hire_roles
FROM user_profiles
WHERE full_name LIKE 'Test%'
ORDER BY role DESC;
```

---

### **Step 3: Test Permission Functions (Browser Console)**

Start the dev server:
```bash
npm run dev
```

Open browser to `http://localhost:8080`

Open DevTools Console and run:

```javascript
// Import the permission functions
import { canUserPerformAction, hasStoreAccess } from '/src/lib/permissions.ts'

// Test Super Admin (should have all permissions)
const superAdmin = {
  id: '00000000-0000-0000-0000-000000000001',
  role: 'super_admin',
  is_system_admin: true,
  is_active: true,
  assigned_stores: [1,2,3],
  detailed_permissions: {}
}

console.log('Super Admin - orders.create:', canUserPerformAction(superAdmin, 'orders.create'))
// Expected: true

console.log('Super Admin - Store 99 access:', hasStoreAccess(superAdmin, 99))
// Expected: true (super admin has access to all stores)

// Test Staff (limited permissions)
const staff = {
  id: '00000000-0000-0000-0000-000000000004',
  role: 'staff',
  is_system_admin: false,
  is_active: true,
  assigned_stores: [1],
  detailed_permissions: {
    orders: { view: true, update: true }
  }
}

console.log('Staff - orders.view:', canUserPerformAction(staff, 'orders.view'))
// Expected: true

console.log('Staff - orders.delete:', canUserPerformAction(staff, 'orders.delete'))
// Expected: false

console.log('Staff - Store 2 access:', hasStoreAccess(staff, 2))
// Expected: false (only has access to store 1)
```

---

### **Step 4: Test React Hooks**

Create a test component:

**File:** `src/pages/PermissionTest.tsx`

```tsx
import { usePermissions } from '@/hooks/usePermissions'
import { PermissionGate, SuperAdminGate } from '@/components/PermissionGate'

export default function PermissionTest() {
  const {
    can,
    canCreate,
    canEdit,
    isSuperAdmin,
    isAdmin,
    isManager,
    isStaff,
    accessibleStores,
    hireableRoles,
    profile,
  } = usePermissions()

  return (
    <div className="p-8">
      <h1 className="text-2xl font-bold mb-4">Permission System Test</h1>

      {/* User Info */}
      <div className="mb-8 p-4 bg-gray-100 rounded">
        <h2 className="font-bold mb-2">Current User</h2>
        <p>Name: {profile?.full_name || 'Not logged in'}</p>
        <p>Role: {profile?.role || 'N/A'}</p>
        <p>System Admin: {profile?.is_system_admin ? 'Yes' : 'No'}</p>
        <p>Accessible Stores: {accessibleStores.join(', ') || 'None'}</p>
        <p>Can Hire: {hireableRoles().join(', ') || 'None'}</p>
      </div>

      {/* Role Flags */}
      <div className="mb-8">
        <h2 className="font-bold mb-2">Role Flags</h2>
        <ul className="list-disc ml-6">
          <li>Is Super Admin: {isSuperAdmin ? '✅' : '❌'}</li>
          <li>Is Admin: {isAdmin ? '✅' : '❌'}</li>
          <li>Is Manager: {isManager ? '✅' : '❌'}</li>
          <li>Is Staff: {isStaff ? '✅' : '❌'}</li>
        </ul>
      </div>

      {/* Permission Checks */}
      <div className="mb-8">
        <h2 className="font-bold mb-2">Permission Checks</h2>
        <ul className="list-disc ml-6">
          <li>Can view orders: {can('orders.view') ? '✅' : '❌'}</li>
          <li>Can create orders: {canCreate('orders') ? '✅' : '❌'}</li>
          <li>Can edit menu: {canEdit('menu') ? '✅' : '❌'}</li>
          <li>Can view analytics: {can('analytics.view') ? '✅' : '❌'}</li>
          <li>Can view financials: {can('analytics.financial') ? '✅' : '❌'}</li>
          <li>Can manage users: {can('users.update') ? '✅' : '❌'}</li>
        </ul>
      </div>

      {/* Permission Gates */}
      <div className="mb-8">
        <h2 className="font-bold mb-2">Permission Gates</h2>

        <PermissionGate requires="orders.create">
          <div className="p-2 bg-green-100 mb-2">
            ✅ You can create orders
          </div>
        </PermissionGate>

        <PermissionGate
          requires="analytics.financial"
          fallback={<div className="p-2 bg-red-100 mb-2">❌ No access to financials</div>}
        >
          <div className="p-2 bg-green-100 mb-2">
            ✅ You can view financial analytics
          </div>
        </PermissionGate>

        <SuperAdminGate
          fallback={<div className="p-2 bg-yellow-100 mb-2">⚠️ Super Admin only</div>}
        >
          <div className="p-2 bg-green-100 mb-2">
            ✅ Welcome, Super Admin!
          </div>
        </SuperAdminGate>
      </div>
    </div>
  )
}
```

**Add route to `App.tsx`:**

```tsx
const PermissionTest = lazy(() => import("./pages/PermissionTest"));

// In routes (above the catch-all):
<Route path="/permission-test" element={<PermissionTest />} />
```

**Visit:** `http://localhost:8080/permission-test`

---

### **Step 5: Verify Database Functions Work**

Run in Supabase SQL Editor:

```sql
-- Test 1: Check if user has store access
SELECT user_has_store_access(
  '00000000-0000-0000-0000-000000000004'::uuid, -- Test Staff
  1  -- Store 1
);
-- Expected: true

SELECT user_has_store_access(
  '00000000-0000-0000-0000-000000000004'::uuid, -- Test Staff
  2  -- Store 2
);
-- Expected: false

-- Test 2: Get accessible stores
SELECT * FROM get_user_accessible_stores(
  '00000000-0000-0000-0000-000000000002'::uuid  -- Test Admin
);
-- Expected: [1, 2, 3]

-- Test 3: Check hierarchy permission
SELECT user_has_hierarchy_permission(
  '00000000-0000-0000-0000-000000000002'::uuid,  -- Test Admin
  '00000000-0000-0000-0000-000000000004'::uuid   -- Test Staff
);
-- Expected: true (Admin can manage Staff)

-- Test 4: Check if user can manage target
SELECT can_user_manage_target(
  '00000000-0000-0000-0000-000000000003'::uuid,  -- Test Manager
  '00000000-0000-0000-0000-000000000002'::uuid   -- Test Admin
);
-- Expected: false (Manager cannot manage Admin)
```

---

## 📋 Test Checklist

Run through this checklist to verify everything works:

### **Permission Helper Functions:**
- [ ] `canUserPerformAction()` works correctly
- [ ] `getUserPermissions()` fetches user data
- [ ] `hasStoreAccess()` validates store access
- [ ] `canManageUser()` checks hierarchy
- [ ] `getAccessibleStores()` returns correct stores
- [ ] `canPromoteToRole()` validates hiring permissions
- [ ] Role hierarchy levels work (customer < staff < manager < admin < super_admin)

### **React Hooks:**
- [ ] `usePermissions()` hook works in components
- [ ] `usePermission()` single permission check works
- [ ] `useStoreAccess()` validates store access
- [ ] `useRole()` returns correct role info
- [ ] `useAccessibleStores()` loads store details

### **Permission Gate Components:**
- [ ] `<PermissionGate>` shows/hides content correctly
- [ ] `<SuperAdminGate>` only shows to super admins
- [ ] `<AdminGate>` shows to admin and above
- [ ] `<ManagerGate>` shows to manager and above
- [ ] `<StaffGate>` shows to staff and above
- [ ] `<StoreGate>` validates store access
- [ ] Fallback content renders when permission denied
- [ ] `<AllPermissionsGate>` requires all permissions (AND)
- [ ] `<AnyPermissionGate>` requires any permission (OR)

### **AuthContext Updates:**
- [ ] UserProfile interface includes all RBAC fields
- [ ] `assigned_stores` array loads correctly
- [ ] `detailed_permissions` JSONB loads correctly
- [ ] `can_hire_roles` array loads correctly
- [ ] `is_system_admin` flag loads correctly
- [ ] Arrays/objects auto-initialize when missing

### **Role-Based Permissions:**
- [ ] Super Admin has all permissions
- [ ] Admin has most permissions (except system settings)
- [ ] Manager has limited permissions (no user management)
- [ ] Staff has view/update orders only
- [ ] Customers have no business permissions

### **Store Access:**
- [ ] Super Admin can access all 29 stores
- [ ] Admin can access only assigned stores
- [ ] Manager can access single store
- [ ] Staff can access single store
- [ ] Users cannot access non-assigned stores

---

## 🐛 Troubleshooting

### **Issue: TypeScript errors about missing properties**

**Fix:** Make sure `detailed_permissions` and `can_hire_roles` are initialized:

```typescript
// In AuthContext fetchProfile:
detailed_permissions: data.detailed_permissions || {},
can_hire_roles: Array.isArray(data.can_hire_roles) ? data.can_hire_roles : [],
```

---

### **Issue: Permission checks always return false**

**Check:**
1. User is logged in
2. User profile loaded (`profile !== null`)
3. User is active (`is_active = true`)
4. Check browser console for errors

---

### **Issue: Database functions not found**

**Fix:** Run migration 031 again:
```sql
-- Check if functions exist
SELECT routine_name
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name LIKE '%user%'
  AND routine_name LIKE '%store%';
```

If missing, re-run `031_create_user_hierarchy.sql`

---

### **Issue: Store access not working**

**Check:**
1. `assigned_stores` array is populated
2. `store_id` is set for single-store users
3. Super admins bypass store checks

**Debug SQL:**
```sql
SELECT id, full_name, role, assigned_stores, store_id
FROM user_profiles
WHERE id = '[user-id]';
```

---

## ✅ Success Criteria

**Phase 2 is complete when:**

✅ All permission helper functions work correctly
✅ React hooks integrate with components
✅ Permission gates show/hide content based on permissions
✅ AuthContext loads all RBAC fields
✅ All 4 role types tested (Super Admin, Admin, Manager, Staff)
✅ Store access validation works
✅ Role hierarchy enforced
✅ No TypeScript errors
✅ No console errors

---

## 🎯 Next Steps - Phase 3

Once testing is complete, move to Phase 3:

**Phase 3: Super Admin Dashboard**
- Create Super Admin panel
- User management UI
- Store assignment interface
- System-wide analytics
- Audit log viewer

**Estimated Time:** 2-3 hours

See `RBAC_SCALABILITY_PLAN.md` for Phase 3 details.

---

## 📊 Progress Update

```
✅ Phase 1: Database Foundation         [████████████] 100% COMPLETE
✅ Phase 2: Permission Backend          [████████████] 100% COMPLETE ← YOU ARE HERE
⏳ Phase 3: Super Admin Dashboard       [░░░░░░░░░░░░]   0%
⏳ Phase 4: Admin Features               [░░░░░░░░░░░░]   0%
⏳ Phase 5: Manager/Staff Features       [░░░░░░░░░░░░]   0%
⏳ Phase 6: Testing & Security           [░░░░░░░░░░░░]   0%
```

**Total Project Progress:** ~33% Complete (Phase 2 of 6)

---

*Generated by Claude Code on November 20, 2025*
*Phase 2 Complete - Ready for Testing!*
