# RBAC Sync Implementation Summary
**Date:** November 20, 2025
**Phase:** 2-3 RBAC Synchronization with Web Platform
**Status:** Core Implementation Complete ✅

---

## 🎯 What Was Implemented

### 1. ✅ Enhanced UserProfile Model
**File:** `camerons-Bussiness-app/Auth/UserProfile.swift`

Added Phase 2-3 RBAC fields to match web platform:
- `assignedStores: [Int]` - Multi-store assignments
- `detailedPermissions: [String: [String: Bool]]` - Granular permissions (resource.action)
- `isSystemAdmin: Bool` - Super admin flag
- `createdBy: String?` - User creation tracking
- `canHireRoles: [String]` - Hiring permissions
- `isActive: Bool` - Account status
- `avatarUrl`, `createdAt`, `updatedAt` - Profile metadata

**New Permission Methods:**
```swift
// Granular permission checking
profile.hasDetailedPermission("orders.create")  // true/false

// Store access checking
profile.hasStoreAccess(storeId: 5)  // true/false

// Get accessible stores
profile.getAccessibleStores()  // [1, 5, 12]

// Role hiring permissions
profile.canHireRole("manager")  // true/false
profile.canManageUser(targetUser)  // true/false
```

---

### 2. ✅ Enhanced AuthManager
**File:** `camerons-Bussiness-app/Auth/AuthManager.swift`

**New Methods Added:**
```swift
// Granular permission checking
authManager.hasDetailedPermission("orders.create")

// Store access control
authManager.hasStoreAccess(storeId: 5)
authManager.getAccessibleStores()  // Returns [Int]

// Hiring/management permissions
authManager.canHireRole("manager")
authManager.canManageUser(targetUser)

// Enhanced role checks (now considers isSystemAdmin)
authManager.isSuperAdmin()  // Checks both role and isSystemAdmin flag
```

**Profile Fetching Updates:**
- Now fetches all RBAC fields from `user_profiles` table
- Includes detailed logging for RBAC fields
- Handles missing fields gracefully (backwards compatible)

---

### 3. ✅ New RBAC Data Models
**File:** `camerons-Bussiness-app/Auth/RBACModels.swift`

#### StoreAssignment
Tracks user-to-store relationships:
```swift
struct StoreAssignment {
    let id: String
    let userId: String
    let storeId: Int
    let isPrimaryStore: Bool
    let assignedAt: String
    let assignedBy: String?
}

// Usage
let assignments = try await StoreAssignment.fetchAssignments(
    for: userId,
    from: supabaseClient
)
```

#### UserHierarchy
Tracks organizational reporting structure:
```swift
struct UserHierarchy {
    let id: String
    let userId: String
    let reportsTo: String?
    let level: Int  // 4=Executive, 3=Admin, 2=Manager, 1=Supervisor, 0=Staff
    let createdAt: String
}

// Usage
let hierarchy = try await UserHierarchy.fetchHierarchy(
    for: userId,
    from: supabaseClient
)

let directReports = try await UserHierarchy.fetchDirectReports(
    for: userId,
    from: supabaseClient
)
```

#### PermissionChange
Audit log for all permission/role changes:
```swift
struct PermissionChange {
    let id: String
    let targetUserId: String
    let changedBy: String
    let action: String
    let oldRole: String?
    let newRole: String?
    let oldPermissions: [String: [String: Bool]]?
    let newPermissions: [String: [String: Bool]]?
    let reason: String?
    let changedAt: String
    let ipAddress: String?
    let userAgent: String?
}

// Usage
let history = try await PermissionChange.fetchHistory(
    for: userId,
    from: supabaseClient,
    limit: 50
)

// Log a permission change
try await PermissionChange.log(
    targetUserId: "user-123",
    changedBy: "admin-456",
    action: "role_change",
    oldRole: "staff",
    newRole: "manager",
    reason: "Promotion",
    from: supabaseClient
)
```

---

## 📊 Database Schema Requirements

### user_profiles Table (Enhanced)
Your Supabase `user_profiles` table should now include:
```sql
-- Core fields (existing)
id UUID PRIMARY KEY
role TEXT NOT NULL
full_name TEXT NOT NULL
phone TEXT
store_id INTEGER
permissions TEXT[]
is_active BOOLEAN DEFAULT true
avatar_url TEXT
created_at TIMESTAMPTZ DEFAULT NOW()
updated_at TIMESTAMPTZ DEFAULT NOW()

-- Phase 2-3 RBAC fields (new)
assigned_stores INTEGER[]
detailed_permissions JSONB
is_system_admin BOOLEAN DEFAULT false
created_by UUID
can_hire_roles TEXT[]
```

### New Tables Required
```sql
-- Store assignments
CREATE TABLE store_assignments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id),
  store_id INTEGER REFERENCES stores(id),
  is_primary_store BOOLEAN DEFAULT false,
  assigned_at TIMESTAMPTZ DEFAULT NOW(),
  assigned_by UUID REFERENCES auth.users(id)
);

-- User hierarchy
CREATE TABLE user_hierarchy (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID UNIQUE REFERENCES auth.users(id),
  reports_to UUID REFERENCES auth.users(id),
  level INTEGER NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Permission changes audit log
CREATE TABLE permission_changes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  target_user_id UUID REFERENCES auth.users(id),
  changed_by UUID REFERENCES auth.users(id),
  action TEXT NOT NULL,
  old_role TEXT,
  new_role TEXT,
  old_permissions JSONB,
  new_permissions JSONB,
  reason TEXT,
  changed_at TIMESTAMPTZ DEFAULT NOW(),
  ip_address INET,
  user_agent TEXT
);
```

---

## 🔄 Permission System Explained

### Legacy Permissions (Simple)
Old system using simple string permissions:
```swift
let permissions: [Permission] = [.orders, .menu, .analytics]
user.hasPermission(.orders)  // true
```

### New Granular Permissions (Phase 2-3)
New system using resource.action permissions:
```json
{
  "orders": {
    "view": true,
    "create": true,
    "update": true,
    "delete": false
  },
  "menu": {
    "view": true,
    "update": false
  },
  "analytics": {
    "view": true,
    "financial": false
  }
}
```

Usage:
```swift
user.hasDetailedPermission("orders.create")  // true
user.hasDetailedPermission("orders.delete")  // false
user.hasDetailedPermission("menu.update")    // false

// "manage" permission grants all actions
// If user has "orders.manage", they can:
// - orders.view
// - orders.create
// - orders.update
// - orders.delete
```

### Permission Hierarchy
```
Super Admin (is_system_admin = true)
  ↓ Has ALL permissions for ALL stores

Admin (role = 'admin')
  ↓ Has most permissions for assigned stores

Manager (role = 'manager')
  ↓ Has limited permissions for single store

Staff (role = 'staff')
  ↓ Can view/update orders only
```

---

## 📱 How to Use in Your App

### Example 1: Check Permission Before Creating Order
```swift
// In OrderManagementView
@EnvironmentObject var auth: AuthManager

var body: some View {
    VStack {
        if auth.hasDetailedPermission("orders.create") {
            Button("Create Order") {
                createNewOrder()
            }
        }

        if auth.hasDetailedPermission("orders.delete") {
            Button("Delete Order", role: .destructive) {
                deleteOrder()
            }
        }
    }
}
```

### Example 2: Filter Orders by Accessible Stores
```swift
// In DashboardViewModel
func loadOrders() async {
    let accessibleStores = AuthManager.shared.getAccessibleStores()

    // Super admins: accessibleStores might be empty, meaning ALL stores
    if AuthManager.shared.isSuperAdmin() && accessibleStores.isEmpty {
        // Fetch all orders
        orders = try await supabase
            .from("orders")
            .select()
            .execute()
    } else {
        // Fetch orders only for accessible stores
        orders = try await supabase
            .from("orders")
            .select()
            .in("store_id", values: accessibleStores)
            .execute()
    }
}
```

### Example 3: Check if User Can Hire Someone
```swift
// In StaffManagementView
func canHireNewManager() -> Bool {
    return AuthManager.shared.canHireRole("manager")
}

func canEditUser(_ targetUser: UserProfile) -> Bool {
    return AuthManager.shared.canManageUser(targetUser)
}
```

---

## ⚠️ Breaking Changes

### 1. UserProfile Initialization
Old code that directly created UserProfile may break:
```swift
// OLD (will fail - missing RBAC fields)
let profile = UserProfile(
    id: "123",
    role: .admin,
    fullName: "John",
    phone: nil,
    storeId: 1,
    permissions: [.orders]
)
```

**Solution:** Use JSON decoding from Supabase response (AuthManager already does this).

### 2. Permission Checking
Old code using simple permissions still works, but you should migrate:
```swift
// OLD (still works)
if authManager.hasPermission(.orders) { }

// NEW (recommended)
if authManager.hasDetailedPermission("orders.create") { }
```

---

## ✅ Build Status

**Last Build:** ✅ Success (November 20, 2025 6:39 AM)
**Warnings:** None critical
**Errors:** All resolved

---

## 🚀 Next Steps

### 1. Update Database Schema
Run the Phase 2-3 migrations on your Supabase instance to add:
- New columns to `user_profiles`
- `store_assignments` table
- `user_hierarchy` table
- `permission_changes` table

### 2. Update Existing User Records
Populate RBAC fields for existing users:
```sql
UPDATE user_profiles SET
  assigned_stores = ARRAY[store_id],
  is_system_admin = (role = 'super_admin'),
  detailed_permissions = '{
    "orders": {"view": true, "create": true, "update": true},
    "menu": {"view": true}
  }'::jsonb,
  can_hire_roles = CASE
    WHEN role = 'super_admin' THEN ARRAY['super_admin', 'admin', 'manager', 'staff']
    WHEN role = 'admin' THEN ARRAY['manager', 'staff']
    WHEN role = 'manager' THEN ARRAY['staff']
    ELSE ARRAY[]::TEXT[]
  END,
  is_active = true
WHERE assigned_stores IS NULL;
```

### 3. Update SupabaseManager Queries
Filter all data queries by `assignedStores`:
```swift
// In SupabaseManager
func fetchOrders() async throws -> [Order] {
    let storeIds = AuthManager.shared.getAccessibleStores()

    return try await client
        .from("orders")
        .select()
        .in("store_id", values: storeIds)
        .execute()
}
```

### 4. Test All Roles
Create test users for each role and verify:
- ✅ Super Admin sees all 29 stores
- ✅ Admin sees only assigned stores (multiple)
- ✅ Manager sees single store
- ✅ Staff can view/update but not delete orders
- ✅ Permission checks work correctly

### 5. Add UI Permission Gates
Update views to show/hide features based on permissions:
```swift
// Dashboard
if authManager.hasDetailedPermission("orders.delete") {
    deleteButton
}

// Menu Management
if authManager.hasDetailedPermission("menu.update") {
    editMenuButton
}

// Analytics
if authManager.hasDetailedPermission("analytics.financial") {
    financialReportsSection
}
```

---

## 📝 Testing Checklist

- [ ] **Login as Super Admin**
  - [ ] Verify `isSystemAdmin` flag is true
  - [ ] Verify access to all stores
  - [ ] Verify all permissions granted

- [ ] **Login as Admin**
  - [ ] Verify access to multiple assigned stores
  - [ ] Verify can hire managers and staff
  - [ ] Verify cannot access unassigned stores

- [ ] **Login as Manager**
  - [ ] Verify access to single store only
  - [ ] Verify can hire staff only
  - [ ] Verify limited analytics access

- [ ] **Login as Staff**
  - [ ] Verify can view/update orders
  - [ ] Verify cannot delete orders
  - [ ] Verify cannot access analytics

- [ ] **Permission Changes**
  - [ ] Promote staff to manager
  - [ ] Verify permission change logged
  - [ ] Verify new permissions applied

- [ ] **Store Assignments**
  - [ ] Assign user to additional store
  - [ ] Verify `assignedStores` updated
  - [ ] Verify data filtered correctly

---

## 🔗 Related Files

### Modified Files
- `camerons-Bussiness-app/Auth/UserProfile.swift` - Enhanced with RBAC fields
- `camerons-Bussiness-app/Auth/AuthManager.swift` - Added RBAC methods

### New Files
- `camerons-Bussiness-app/Auth/RBACModels.swift` - RBAC data models

### Reference Documentation
- `BUSINESS_APP_SYNC_GUIDE.md` - Original sync guide
- `PHASE_2_COMPLETE.md` - Web platform RBAC implementation
- Web platform: `src/lib/permissions.ts` - Permission logic reference

---

## 💡 Tips & Best Practices

### 1. Always Check Permissions
Never assume a user has permission. Always check:
```swift
guard authManager.hasDetailedPermission("orders.delete") else {
    showError("You don't have permission to delete orders")
    return
}

deleteOrder(id)
```

### 2. Filter Data Client-Side AND Server-Side
RLS policies protect the database, but also filter in the app:
```swift
// Even if RLS allows it, filter for better UX
let visibleStores = authManager.getAccessibleStores()
let filteredOrders = allOrders.filter { visibleStores.contains($0.storeId) }
```

### 3. Log Permission Changes
Always log when roles/permissions change:
```swift
try await PermissionChange.log(
    targetUserId: targetUser.id,
    changedBy: currentUser.id,
    action: "role_change",
    oldRole: "staff",
    newRole: "manager",
    reason: "Quarterly promotion",
    from: supabase
)
```

### 4. Handle Super Admins Carefully
Super admins can do anything, but that doesn't mean they should:
```swift
// Bad
if isSuperAdmin {
    showAllFeatures()
}

// Good
if hasDetailedPermission("feature.access") {
    showFeature()
}
// Super admin will pass the check anyway, but this is more maintainable
```

---

## 📞 Support & Questions

If you encounter issues:
1. Check the web platform implementation in `src/lib/permissions.ts`
2. Review RLS policies in Supabase Dashboard
3. Test with different user roles
4. Check permission_changes table for audit trail

---

**Implementation Complete:** ✅
**Build Status:** ✅ Success
**Ready for Testing:** ✅ Yes
**Next Phase:** Database migration + UI permission gates

*Generated by Claude Code on November 20, 2025*
