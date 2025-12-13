# 📱 Business App Sync Guide

**Date Created:** November 20, 2025
**Purpose:** Sync the business iOS/Android app with the Phase 2-3 RBAC implementation
**Target:** Ensure the business app uses the same backend, permissions, and authentication

---

## 🎯 Overview

The web platform now has a complete RBAC (Role-Based Access Control) system implemented through **Phase 1** (Database) and **Phase 2** (Permission Backend). The business mobile app needs to be updated to use these same systems for consistency and security.

---

## 📊 Current State

### **Web Platform (camerons-connect):**
✅ Phase 1: Database Foundation (Complete)
✅ Phase 2: Permission System Backend (Complete)
✅ Phase 3: Super Admin Dashboard (Complete)

### **Business Mobile App:**
❓ Status: Needs sync with Phase 1-3 changes
❓ Repository: [Check for business app repo]

---

## 🗄️ Database Changes to Sync

### **1. Enhanced user_profiles Table**

The `user_profiles` table now has additional RBAC fields:

```sql
-- NEW FIELDS ADDED IN PHASE 1:
assigned_stores integer[]                 -- Multi-store assignments
detailed_permissions jsonb                 -- Granular permissions
is_system_admin boolean DEFAULT false      -- Super admin flag
created_by uuid                           -- Who created this user
can_hire_roles text[]                     -- Roles this user can hire
```

**Action Required:**
- Update any business app queries that fetch `user_profiles` to include these new fields
- Handle the new fields in your user profile models/interfaces

### **2. New Tables to Use**

Three new tables were added for RBAC:

#### **store_assignments**
```sql
CREATE TABLE store_assignments (
  id uuid PRIMARY KEY,
  user_id uuid REFERENCES user_profiles(id),
  store_id integer REFERENCES stores(id),
  is_primary_store boolean DEFAULT false,
  assigned_at timestamptz DEFAULT now(),
  assigned_by uuid REFERENCES user_profiles(id)
);
```

**Use Case:** Track which users have access to which stores

#### **user_hierarchy**
```sql
CREATE TABLE user_hierarchy (
  id uuid PRIMARY KEY,
  user_id uuid UNIQUE REFERENCES user_profiles(id),
  reports_to uuid REFERENCES user_profiles(id),
  level integer NOT NULL,
  created_at timestamptz DEFAULT now()
);
```

**Use Case:** Understand reporting structure (who reports to whom)

#### **permission_changes**
```sql
CREATE TABLE permission_changes (
  id uuid PRIMARY KEY,
  target_user_id uuid REFERENCES user_profiles(id),
  changed_by uuid REFERENCES user_profiles(id),
  action text NOT NULL,
  old_role text,
  new_role text,
  old_permissions jsonb,
  new_permissions jsonb,
  reason text,
  changed_at timestamptz DEFAULT now(),
  ip_address inet,
  user_agent text
);
```

**Use Case:** Audit trail for all permission/role changes

---

## 🔐 Permission System Integration

### **Permission Types**

The system now uses granular permissions instead of just roles:

```typescript
type Permission =
  | 'orders.view' | 'orders.create' | 'orders.update' | 'orders.delete'
  | 'menu.view' | 'menu.create' | 'menu.update' | 'menu.delete'
  | 'analytics.view' | 'analytics.financial'
  | 'settings.view' | 'settings.update'
  | 'users.view' | 'users.create' | 'users.update' | 'users.delete'
  | 'stores.view' | 'stores.update'
  | 'inventory.view' | 'inventory.update'
```

### **Role Hierarchy**

```
Level 4: Super Admin → All permissions, all stores
Level 3: Admin       → Most permissions, multiple stores
Level 2: Manager     → Limited permissions, single store
Level 1: Staff       → View/update orders only, single store
Level 0: Customer    → No business features
```

---

## 📱 Business App Updates Needed

### **1. Update Authentication Context**

#### **Swift Example (iOS):**

```swift
struct UserProfile: Codable {
    let id: String
    let role: String
    let fullName: String
    let phone: String?
    let storeId: Int?

    // NEW RBAC FIELDS:
    let assignedStores: [Int]
    let detailedPermissions: [String: [String: Bool]]
    let isSystemAdmin: Bool
    let createdBy: String?
    let canHireRoles: [String]
    let isActive: Bool
}

class AuthManager {
    func fetchUserProfile(userId: String) async throws -> UserProfile {
        let response = try await supabase
            .from("user_profiles")
            .select("*")
            .eq("id", value: userId)
            .single()
            .execute()

        return try JSONDecoder().decode(UserProfile.self, from: response.data)
    }

    func hasPermission(user: UserProfile, permission: String) -> Bool {
        // Super admins have all permissions
        if user.isSystemAdmin || user.role == "super_admin" {
            return true
        }

        // Parse permission (e.g., "orders.create" → resource: "orders", action: "create")
        let parts = permission.split(separator: ".")
        guard parts.count == 2 else { return false }

        let resource = String(parts[0])
        let action = String(parts[1])

        // Check detailed_permissions
        if let resourcePerms = user.detailedPermissions[resource],
           let hasAction = resourcePerms[action] {
            return hasAction
        }

        // Check for "manage" permission (grants all actions)
        if let resourcePerms = user.detailedPermissions[resource],
           let hasManage = resourcePerms["manage"], hasManage {
            return true
        }

        return false
    }

    func hasStoreAccess(user: UserProfile, storeId: Int) -> Bool {
        // Super admins have access to all stores
        if user.isSystemAdmin || user.role == "super_admin" {
            return true
        }

        // Check assigned_stores array
        return user.assignedStores.contains(storeId)
    }
}
```

#### **Kotlin Example (Android):**

```kotlin
data class UserProfile(
    val id: String,
    val role: String,
    val fullName: String,
    val phone: String?,
    val storeId: Int?,
    // NEW RBAC FIELDS:
    val assignedStores: List<Int>,
    val detailedPermissions: Map<String, Map<String, Boolean>>,
    val isSystemAdmin: Boolean,
    val createdBy: String?,
    val canHireRoles: List<String>,
    val isActive: Boolean
)

class PermissionManager {
    fun hasPermission(user: UserProfile, permission: String): Boolean {
        // Super admins have all permissions
        if (user.isSystemAdmin || user.role == "super_admin") {
            return true
        }

        // Parse permission
        val parts = permission.split(".")
        if (parts.size != 2) return false

        val resource = parts[0]
        val action = parts[1]

        // Check detailed_permissions
        val resourcePerms = user.detailedPermissions[resource] ?: return false

        // Check specific action
        if (resourcePerms[action] == true) return true

        // Check for manage permission
        if (resourcePerms["manage"] == true) return true

        return false
    }

    fun hasStoreAccess(user: UserProfile, storeId: Int): Boolean {
        if (user.isSystemAdmin || user.role == "super_admin") {
            return true
        }

        return user.assignedStores.contains(storeId)
    }
}
```

---

### **2. Update Supabase Queries**

#### **Fetching Orders (with store filtering):**

```swift
// OLD (broken with new RLS):
let orders = try await supabase
    .from("orders")
    .select("*")
    .execute()

// NEW (with store filtering):
let orders = try await supabase
    .from("orders")
    .select("*")
    .in("store_id", values: user.assignedStores)  // Only accessible stores
    .execute()
```

```kotlin
// OLD:
val orders = supabase
    .from("orders")
    .select()
    .execute()

// NEW:
val orders = supabase
    .from("orders")
    .select()
    .`in`("store_id", user.assignedStores)  // Only accessible stores
    .execute()
```

#### **Updating User Profiles:**

When the business app needs to update a user:

```swift
// Check permission first
guard authManager.hasPermission(user: currentUser, permission: "users.update") else {
    throw PermissionError.unauthorized
}

// Update user
try await supabase
    .from("user_profiles")
    .update(["full_name": newName])
    .eq("id", value: targetUserId)
    .execute()
```

---

### **3. UI Permission Gating**

Show/hide UI elements based on permissions:

#### **Swift (SwiftUI):**

```swift
struct OrderManagementView: View {
    @EnvironmentObject var auth: AuthManager

    var body: some View {
        VStack {
            // Show create button only if user has permission
            if auth.hasPermission(user: auth.currentUser, permission: "orders.create") {
                Button("Create Order") {
                    // Create order
                }
            }

            // Show delete button only to admins
            if auth.currentUser.role == "admin" || auth.currentUser.role == "super_admin" {
                Button("Delete Order", role: .destructive) {
                    // Delete order
                }
            }
        }
    }
}
```

#### **Kotlin (Jetpack Compose):**

```kotlin
@Composable
fun OrderManagementScreen(
    permissionManager: PermissionManager,
    currentUser: UserProfile
) {
    Column {
        // Show create button only if user has permission
        if (permissionManager.hasPermission(currentUser, "orders.create")) {
            Button(onClick = { /* Create order */ }) {
                Text("Create Order")
            }
        }

        // Show delete button only to admins
        if (currentUser.role in listOf("admin", "super_admin")) {
            Button(
                onClick = { /* Delete order */ },
                colors = ButtonDefaults.buttonColors(
                    containerColor = MaterialTheme.colorScheme.error
                )
            ) {
                Text("Delete Order")
            }
        }
    }
}
```

---

## 🔄 Migration Steps

### **Step 1: Update Data Models**

1. Update `UserProfile` model to include new RBAC fields
2. Create models for `StoreAssignment`, `UserHierarchy`, `PermissionChange`
3. Update any API response parsers

### **Step 2: Update Authentication**

1. Modify login flow to fetch complete user profile
2. Store `assignedStores`, `detailedPermissions`, `canHireRoles` locally
3. Implement `hasPermission()` and `hasStoreAccess()` helpers

### **Step 3: Update Data Fetching**

1. Add store filtering to all queries (orders, menu, analytics)
2. Respect RLS policies by filtering client-side as well
3. Handle permission errors gracefully

### **Step 4: Update UI**

1. Add permission checks before showing admin features
2. Hide create/edit/delete buttons based on permissions
3. Show appropriate error messages when permission denied

### **Step 5: Test All Roles**

Test the app with each role:
- ✅ Super Admin (all features visible)
- ✅ Admin (multi-store access)
- ✅ Manager (single store, limited features)
- ✅ Staff (view/update orders only)

---

## 📋 Checklist

Use this checklist to track your sync progress:

### **Data Models:**
- [ ] Updated `UserProfile` with RBAC fields
- [ ] Created `StoreAssignment` model
- [ ] Created `UserHierarchy` model
- [ ] Created `PermissionChange` model

### **Authentication:**
- [ ] Updated login to fetch complete profile
- [ ] Implemented `hasPermission()` helper
- [ ] Implemented `hasStoreAccess()` helper
- [ ] Implemented `canHireRole()` helper
- [ ] Store RBAC data locally

### **Data Fetching:**
- [ ] Added store filtering to orders
- [ ] Added store filtering to menu queries
- [ ] Added store filtering to analytics
- [ ] Handle RLS permission errors

### **UI Updates:**
- [ ] Permission gates for create buttons
- [ ] Permission gates for edit buttons
- [ ] Permission gates for delete buttons
- [ ] Permission gates for admin features
- [ ] Show appropriate error messages

### **Testing:**
- [ ] Test Super Admin role
- [ ] Test Admin role (multi-store)
- [ ] Test Manager role (single store)
- [ ] Test Staff role (limited)
- [ ] Test permission errors
- [ ] Test store access restrictions

---

## 🚨 Common Issues & Solutions

### **Issue 1: User can't see any orders**

**Cause:** `assigned_stores` is empty or user doesn't have `orders.view` permission

**Solution:**
```swift
// Check assigned stores
print("Assigned stores: \(user.assignedStores)")

// Check permission
let canView = hasPermission(user: user, permission: "orders.view")
print("Can view orders: \(canView)")

// If both are true but still no orders, check RLS policies in Supabase
```

---

### **Issue 2: Super admin can't access all stores**

**Cause:** Not checking `is_system_admin` flag first

**Solution:**
```swift
func getAccessibleStores(user: UserProfile) -> [Int] {
    // Super admins get all stores
    if user.isSystemAdmin || user.role == "super_admin" {
        return Array(1...29)  // All store IDs
    }

    return user.assignedStores
}
```

---

### **Issue 3: Permission checks not working**

**Cause:** `detailed_permissions` not loaded or malformed

**Solution:**
```swift
// Debug detailed_permissions structure
print("Detailed permissions: \(user.detailedPermissions)")

// Expected structure:
// {
//   "orders": {"view": true, "create": true, "update": true},
//   "menu": {"view": true, "update": true}
// }

// Check if JSON is parsing correctly
```

---

## 🔗 Helpful Resources

### **Web Platform Reference:**
- `src/lib/permissions.ts` - Permission checking logic
- `src/hooks/usePermissions.ts` - React hooks (adapt for mobile)
- `src/components/PermissionGate.tsx` - UI gating examples
- `PHASE_2_COMPLETE.md` - Full Phase 2 documentation

### **Database Reference:**
- `supabase/migrations/029_update_user_profiles_rbac.sql` - Updated user_profiles
- `supabase/migrations/030_create_store_assignments.sql` - Store assignments
- `supabase/migrations/031_create_user_hierarchy.sql` - User hierarchy
- `supabase/migrations/033_comprehensive_rls_policies.sql` - RLS policies

### **Testing Users:**
See `PHASE_2_TESTING_GUIDE.md` for SQL to create test users

---

## ✅ Verification

Once you've synced the business app, verify:

1. **Login works** and fetches complete user profile
2. **Super admin** can see all 29 stores
3. **Admin** can see only assigned stores
4. **Manager** can see single store
5. **Staff** can view/update orders but not delete
6. **Permission errors** handled gracefully
7. **UI hides** features user doesn't have access to

---

## 📞 Need Help?

If you encounter issues:
1. Check the web platform implementation for reference
2. Review RLS policies in Supabase Dashboard
3. Test queries directly in Supabase SQL Editor
4. Check browser console for web platform errors (same backend)

---

**📌 Keep this guide handy while syncing the business app!**

---

*Generated by Claude Code on November 20, 2025*
*Business App Sync Guide for RBAC Phase 2-3*
