# RBAC Quick Reference Guide
**TL;DR for developers working with the Phase 2-3 RBAC system**

---

## ✅ What Changed

### UserProfile Now Has
```swift
let assignedStores: [Int]              // Multi-store assignments
let detailedPermissions: [String: [String: Bool]]  // Granular permissions
let isSystemAdmin: Bool                // Super admin flag
let canHireRoles: [String]             // Who you can hire
```

### New Permission Checking
```swift
// OLD (simple)
if authManager.hasPermission(.orders) { }

// NEW (granular)
if authManager.hasDetailedPermission("orders.create") { }
if authManager.hasDetailedPermission("menu.update") { }
if authManager.hasDetailedPermission("analytics.financial") { }
```

### New Store Access Control
```swift
// Check single store access
if authManager.hasStoreAccess(storeId: 5) { }

// Get all accessible stores
let stores = authManager.getAccessibleStores()  // [1, 5, 12]

// Filter data by accessible stores
orders = allOrders.filter { stores.contains($0.storeId) }
```

---

## 🚀 Common Use Cases

### 1. Show/Hide UI Elements
```swift
struct OrderManagementView: View {
    @EnvironmentObject var auth: AuthManager

    var body: some View {
        VStack {
            // Show create button only if permitted
            if auth.hasDetailedPermission("orders.create") {
                Button("Create Order") { }
            }

            // Show delete only for admins
            if auth.isAdmin() {
                Button("Delete Order", role: .destructive) { }
            }
        }
    }
}
```

### 2. Filter Database Queries
```swift
func loadOrders() async {
    let storeIds = AuthManager.shared.getAccessibleStores()

    let orders = try await supabase
        .from("orders")
        .select()
        .in("store_id", values: storeIds)  // Filter by accessible stores
        .execute()
}
```

### 3. Check Hiring Permissions
```swift
// Can current user hire a manager?
if authManager.canHireRole("manager") {
    showHireManagerButton()
}

// Can current user edit this other user?
if authManager.canManageUser(targetUser) {
    showEditUserButton()
}
```

---

## 📋 Permission Strings

### Orders
- `orders.view` - Can view orders
- `orders.create` - Can create new orders
- `orders.update` - Can update order status
- `orders.delete` - Can delete orders
- `orders.manage` - Can do all of the above

### Menu
- `menu.view` - Can view menu items
- `menu.create` - Can add menu items
- `menu.update` - Can edit menu items
- `menu.delete` - Can remove menu items
- `menu.manage` - Can do all of the above

### Analytics
- `analytics.view` - Can view basic analytics
- `analytics.financial` - Can view financial reports
- `analytics.manage` - Can export data, configure analytics

### Settings
- `settings.view` - Can view settings
- `settings.update` - Can change settings

### Users
- `users.view` - Can view staff list
- `users.create` - Can add staff members
- `users.update` - Can edit staff
- `users.delete` - Can remove staff
- `users.manage` - Can do all of the above

### Stores
- `stores.view` - Can view store info
- `stores.update` - Can edit store settings

### Inventory
- `inventory.view` - Can view inventory
- `inventory.update` - Can update stock levels

---

## 🎭 Role Hierarchy

```
Super Admin (is_system_admin = true)
  ↓ ALL permissions
  ↓ ALL stores
  ↓ Can hire: everyone

Admin (role = 'admin')
  ↓ Most permissions
  ↓ Multiple stores (assigned_stores)
  ↓ Can hire: managers, staff

Manager (role = 'manager')
  ↓ Limited permissions
  ↓ Single store
  ↓ Can hire: staff only

Staff (role = 'staff')
  ↓ View/update orders
  ↓ Single store
  ↓ Cannot hire
```

---

## 🔍 Debugging Permissions

### Check User Profile
```swift
print("User: \(authManager.userProfile?.fullName ?? "Unknown")")
print("Role: \(authManager.userProfile?.role.rawValue ?? "none")")
print("Is Super Admin: \(authManager.isSuperAdmin())")
print("Assigned Stores: \(authManager.userProfile?.assignedStores ?? [])")
print("Can Hire: \(authManager.userProfile?.canHireRoles ?? [])")
```

### Check Specific Permission
```swift
let permission = "orders.delete"
let hasIt = authManager.hasDetailedPermission(permission)
print("Has \(permission): \(hasIt)")

// Debug detailed permissions
if let detailed = authManager.userProfile?.detailedPermissions {
    print("Detailed Permissions:")
    for (resource, actions) in detailed {
        print("  \(resource):")
        for (action, allowed) in actions {
            print("    \(action): \(allowed)")
        }
    }
}
```

---

## ⚠️ Common Mistakes

### ❌ DON'T: Assume Super Admin
```swift
// Bad
if isSuperAdmin {
    showEverything()
}
```

### ✅ DO: Always Check Permissions
```swift
// Good
if hasDetailedPermission("feature.access") {
    showFeature()
}
// Super admin will pass anyway, but code is clearer
```

### ❌ DON'T: Hardcode Store IDs
```swift
// Bad
let orders = fetchOrders(storeId: 1)
```

### ✅ DO: Use Accessible Stores
```swift
// Good
let storeIds = authManager.getAccessibleStores()
let orders = fetchOrders(storeIds: storeIds)
```

### ❌ DON'T: Skip Permission Checks
```swift
// Bad
func deleteOrder(id: String) {
    // Just delete it
    supabase.from("orders").delete().eq("id", id)
}
```

### ✅ DO: Verify Permission First
```swift
// Good
func deleteOrder(id: String) async {
    guard authManager.hasDetailedPermission("orders.delete") else {
        showError("You don't have permission to delete orders")
        return
    }

    try await supabase.from("orders").delete().eq("id", id)
}
```

---

## 📦 New Data Models

### StoreAssignment
```swift
let assignments = try await StoreAssignment.fetchAssignments(
    for: userId,
    from: supabaseClient
)
```

### UserHierarchy
```swift
let hierarchy = try await UserHierarchy.fetchHierarchy(
    for: userId,
    from: supabaseClient
)

let reports = try await UserHierarchy.fetchDirectReports(
    for: userId,
    from: supabaseClient
)
```

### PermissionChange (Audit Log)
```swift
// View history
let history = try await PermissionChange.fetchHistory(
    for: userId,
    from: supabaseClient
)

// Log a change
try await PermissionChange.log(
    targetUserId: "user-123",
    changedBy: currentUserId,
    action: "role_change",
    oldRole: "staff",
    newRole: "manager",
    reason: "Promotion",
    from: supabaseClient
)
```

---

## 🧪 Testing

### Create Test Users
```sql
-- Super Admin
INSERT INTO user_profiles (id, role, full_name, is_system_admin, assigned_stores, detailed_permissions, can_hire_roles)
VALUES (
  'super-admin-id',
  'super_admin',
  'Super Admin',
  true,
  ARRAY[]::INTEGER[],
  '{}'::jsonb,
  ARRAY['super_admin', 'admin', 'manager', 'staff']
);

-- Admin (multiple stores)
INSERT INTO user_profiles (id, role, full_name, assigned_stores, detailed_permissions, can_hire_roles)
VALUES (
  'admin-id',
  'admin',
  'Admin User',
  ARRAY[1, 5, 12],
  '{"orders": {"view": true, "create": true, "update": true, "delete": true}, "menu": {"view": true, "update": true}}'::jsonb,
  ARRAY['manager', 'staff']
);

-- Manager (single store)
INSERT INTO user_profiles (id, role, full_name, store_id, assigned_stores, detailed_permissions, can_hire_roles)
VALUES (
  'manager-id',
  'manager',
  'Manager User',
  1,
  ARRAY[1],
  '{"orders": {"view": true, "create": true, "update": true}, "menu": {"view": true}}'::jsonb,
  ARRAY['staff']
);

-- Staff (single store, limited)
INSERT INTO user_profiles (id, role, full_name, store_id, assigned_stores, detailed_permissions, can_hire_roles)
VALUES (
  'staff-id',
  'staff',
  'Staff User',
  1,
  ARRAY[1],
  '{"orders": {"view": true, "update": true}}'::jsonb,
  ARRAY[]::TEXT[]
);
```

---

## 📞 Need Help?

1. **Build failed?** Check that you imported Supabase in all files
2. **Permission not working?** Print `detailedPermissions` to debug
3. **User sees wrong stores?** Check `assignedStores` array
4. **Can't hire/edit users?** Check `canHireRoles` array

---

**Files Changed:**
- `camerons-Bussiness-app/Auth/UserProfile.swift` ✅
- `camerons-Bussiness-app/Auth/AuthManager.swift` ✅
- `camerons-Bussiness-app/Auth/RBACModels.swift` ✅ (new)

**Build Status:** ✅ **SUCCESS**

**Next:** Update database schema, then test with different user roles!

---

*Last updated: November 20, 2025*
