# 🏢 Cameron's Connect - Role-Based Access Control (RBAC) Scalability Plan
**Date:** November 19, 2025
**Status:** 📋 Planning Phase - Comprehensive RBAC System

---

## 🎯 Vision: Scalable Multi-Store Management System

Build a hierarchical management system where each role has specific capabilities and cannot exceed their authority level.

---

## 📊 Current State vs. Proposed State

### **Current (Limited):**
```
Super Admin
├── Permissions: ["orders", "menu", "analytics", "settings"]
├── Can manage: 1 store
└── No hierarchy enforcement
```

### **Proposed (Scalable):**
```
Super Admin (Corporate HQ)
├── Can create/manage: Admins (unlimited)
├── Can manage: All 29 stores
├── Full system access
│
Admin (Store Owner/Multi-Store Manager)
├── Can create/manage: Managers (unlimited)
├── Can manage: Multiple stores (assigned)
├── Cannot create other Admins
│
Manager (Store Manager)
├── Can hire: Staff (for their store only)
├── Can manage: 1 store
├── Cannot create Managers
│
Staff (Employee)
├── Can view: Orders for their store
├── Can manage: Basic operations
├── Cannot hire anyone
```

---

## 🔐 Comprehensive Permission System

### **1. Super Admin Permissions**

**Access Level:** Corporate / System-Wide

```json
{
  "role": "super_admin",
  "permissions": {
    // User Management
    "users": {
      "create_admin": true,
      "create_manager": true,
      "create_staff": true,
      "edit_admin": true,
      "edit_manager": true,
      "edit_staff": true,
      "delete_admin": true,
      "delete_manager": true,
      "delete_staff": true,
      "promote_to_admin": true,
      "demote_admin": true,
      "view_all_users": true
    },

    // Store Management
    "stores": {
      "create_store": true,
      "edit_store": true,
      "delete_store": true,
      "assign_admin_to_stores": true,
      "view_all_stores": true,
      "manage_all_stores": true
    },

    // Operations
    "orders": {
      "view_all_stores": true,
      "manage_all_stores": true,
      "override_status": true,
      "refund": true,
      "void": true
    },

    "menu": {
      "create_items_all_stores": true,
      "edit_items_all_stores": true,
      "delete_items_all_stores": true,
      "manage_categories": true,
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
      "integration_settings": true,
      "billing_settings": true
    }
  },

  "restrictions": {
    "store_limit": null,  // Unlimited
    "admin_creation_limit": null,  // Unlimited
    "cannot_be_demoted_by": ["admin", "manager", "staff"]
  }
}
```

---

### **2. Admin Permissions**

**Access Level:** Multi-Store Owner / Regional Manager

```json
{
  "role": "admin",
  "permissions": {
    // User Management
    "users": {
      "create_admin": false,  // ❌ Cannot create other Admins
      "create_manager": true,  // ✅ Can hire Managers
      "create_staff": true,    // ✅ Can hire Staff
      "edit_manager": true,    // ✅ For their stores only
      "edit_staff": true,      // ✅ For their stores only
      "delete_manager": true,  // ✅ For their stores only
      "delete_staff": true,    // ✅ For their stores only
      "promote_to_manager": true,  // ✅ Staff → Manager
      "demote_manager": true,      // ✅ Manager → Staff
      "view_users": "assigned_stores_only"
    },

    // Store Management
    "stores": {
      "create_store": false,  // ❌ Only Super Admin can create stores
      "edit_store": "assigned_only",  // ✅ Only their assigned stores
      "delete_store": false,  // ❌ Only Super Admin
      "assign_manager_to_store": true,  // ✅ Within their stores
      "view_stores": "assigned_only",
      "request_new_store": true  // ✅ Can request Super Admin to assign more
    },

    // Operations
    "orders": {
      "view": "assigned_stores_only",
      "manage": "assigned_stores_only",
      "refund": "assigned_stores_only",
      "void": false  // ❌ Only Super Admin
    },

    "menu": {
      "create_items": "assigned_stores_only",
      "edit_items": "assigned_stores_only",
      "delete_items": "assigned_stores_only",
      "manage_categories": "assigned_stores_only",
      "set_pricing": "assigned_stores_only"
    },

    "analytics": {
      "view": "assigned_stores_only",
      "compare_stores": "assigned_stores_only",  // Only their stores
      "export_reports": true,
      "financial_reports": "assigned_stores_only"
    },

    "settings": {
      "store_settings": "assigned_stores_only",
      "staff_settings": "assigned_stores_only",
      "system_settings": false  // ❌ Only Super Admin
    }
  },

  "restrictions": {
    "store_limit": null,  // Unlimited (assigned by Super Admin)
    "manager_creation_limit": null,  // Unlimited for their stores
    "staff_creation_limit": null,  // Unlimited for their stores
    "cannot_create": ["admin", "super_admin"],
    "can_be_demoted_by": ["super_admin"]
  }
}
```

---

### **3. Manager Permissions**

**Access Level:** Single Store Manager

```json
{
  "role": "manager",
  "permissions": {
    // User Management
    "users": {
      "create_admin": false,    // ❌ Cannot create Admins
      "create_manager": false,  // ❌ Cannot create Managers
      "create_staff": true,     // ✅ Can hire Staff for their store
      "edit_staff": "own_store_only",
      "delete_staff": "own_store_only",
      "promote_staff": false,  // ❌ Cannot promote to Manager
      "view_users": "own_store_only"
    },

    // Store Management
    "stores": {
      "create_store": false,
      "edit_store": "own_store_only",  // ✅ Limited settings only
      "delete_store": false,
      "view_stores": "own_store_only"
    },

    // Operations
    "orders": {
      "view": "own_store_only",
      "manage": "own_store_only",
      "accept_reject": true,
      "update_status": true,
      "refund": "limited",  // Up to $50 without approval
      "void": false
    },

    "menu": {
      "create_items": false,  // ❌ Only Admin/Super Admin
      "edit_items": "own_store_only",  // ✅ Can mark out of stock, etc.
      "delete_items": false,  // ❌ Only Admin/Super Admin
      "manage_availability": true,  // ✅ Can enable/disable items
      "set_pricing": false  // ❌ Only Admin/Super Admin
    },

    "analytics": {
      "view": "own_store_only",
      "compare_stores": false,
      "export_reports": "own_store_only",
      "financial_reports": false  // ❌ Only Admin/Super Admin
    },

    "settings": {
      "store_hours": "own_store_only",
      "staff_schedules": "own_store_only",
      "notifications": "own_store_only"
    }
  },

  "restrictions": {
    "store_limit": 1,  // Can only manage 1 store
    "staff_creation_limit": null,  // Unlimited for their store
    "cannot_create": ["manager", "admin", "super_admin"],
    "can_be_demoted_by": ["admin", "super_admin"]
  }
}
```

---

### **4. Staff Permissions**

**Access Level:** Employee / Store Worker

```json
{
  "role": "staff",
  "permissions": {
    // User Management
    "users": {
      "create": false,  // ❌ Cannot hire anyone
      "edit": false,
      "delete": false,
      "view_users": "own_store_only"  // Can see coworkers
    },

    // Store Management
    "stores": {
      "view_stores": "own_store_only"
    },

    // Operations
    "orders": {
      "view": "own_store_only",
      "accept_reject": true,  // ✅ Can accept/reject orders
      "update_status": true,  // ✅ Can update to preparing/ready
      "manage": "limited",
      "refund": false,
      "void": false
    },

    "menu": {
      "view": "own_store_only",
      "mark_unavailable": true,  // ✅ Can mark items out of stock
      "edit": false,
      "delete": false,
      "set_pricing": false
    },

    "analytics": {
      "view": "basic_metrics_only",  // Order counts, not revenue
      "export_reports": false
    },

    "settings": {
      "profile_settings": "own_only"  // Can update their own profile
    }
  },

  "restrictions": {
    "store_limit": 1,
    "cannot_create_users": true,
    "can_be_promoted_by": ["manager", "admin", "super_admin"]
  }
}
```

---

## 🗄️ Database Schema Updates

### **1. Update user_profiles Table**

```sql
-- Update user_profiles with comprehensive permissions
ALTER TABLE user_profiles
ADD COLUMN IF NOT EXISTS assigned_stores INT[] DEFAULT ARRAY[]::INT[];  -- Multiple stores for Admin

ALTER TABLE user_profiles
ADD COLUMN IF NOT EXISTS permissions JSONB DEFAULT '{}'::jsonb;  -- Detailed permissions

ALTER TABLE user_profiles
ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES auth.users(id);  -- Track who created this user

ALTER TABLE user_profiles
ADD COLUMN IF NOT EXISTS can_hire_roles VARCHAR[] DEFAULT ARRAY[]::VARCHAR[];  -- Which roles they can hire

-- Add constraints
ALTER TABLE user_profiles
ADD CONSTRAINT valid_role CHECK (role IN ('super_admin', 'admin', 'manager', 'staff'));

-- Create index for faster queries
CREATE INDEX idx_user_profiles_assigned_stores ON user_profiles USING GIN(assigned_stores);
CREATE INDEX idx_user_profiles_created_by ON user_profiles(created_by);
```

---

### **2. Create store_assignments Table**

```sql
-- Track which users are assigned to which stores
CREATE TABLE store_assignments (
    id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    store_id INT NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    role VARCHAR(50) NOT NULL,  -- Role at this store (for multi-store admins)
    assigned_by UUID REFERENCES auth.users(id),
    assigned_at TIMESTAMP DEFAULT NOW(),
    is_primary_store BOOLEAN DEFAULT FALSE,  -- Primary store for user
    UNIQUE(user_id, store_id)
);

CREATE INDEX idx_store_assignments_user ON store_assignments(user_id);
CREATE INDEX idx_store_assignments_store ON store_assignments(store_id);
CREATE INDEX idx_store_assignments_assigned_by ON store_assignments(assigned_by);
```

---

### **3. Create user_hierarchy Table**

```sql
-- Track who reports to whom
CREATE TABLE user_hierarchy (
    id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    manager_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,  -- Who manages this user
    created_by UUID REFERENCES auth.users(id),  -- Who created this user
    created_at TIMESTAMP DEFAULT NOW(),
    level INT NOT NULL,  -- 4=super_admin, 3=admin, 2=manager, 1=staff
    UNIQUE(user_id)
);

CREATE INDEX idx_user_hierarchy_manager ON user_hierarchy(manager_id);
CREATE INDEX idx_user_hierarchy_level ON user_hierarchy(level);
```

---

### **4. Create permission_changes Table (Audit Trail)**

```sql
-- Track all permission changes for security/compliance
CREATE TABLE permission_changes (
    id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id),
    changed_by UUID NOT NULL REFERENCES auth.users(id),
    change_type VARCHAR(50) NOT NULL,  -- 'role_change', 'promotion', 'demotion', 'permission_grant', 'permission_revoke'
    old_role VARCHAR(50),
    new_role VARCHAR(50),
    old_permissions JSONB,
    new_permissions JSONB,
    reason TEXT,
    changed_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_permission_changes_user ON permission_changes(user_id);
CREATE INDEX idx_permission_changes_changed_by ON permission_changes(changed_by);
CREATE INDEX idx_permission_changes_date ON permission_changes(changed_at);
```

---

## 🎨 UI/UX Changes

### **1. Super Admin Dashboard**

**New Features:**
- ✅ **Admin Management Panel**
  - Create new Admins
  - Assign stores to Admins (multi-select)
  - View all Admins across system
  - Demote/Remove Admins

- ✅ **System Overview**
  - Total stores: 29
  - Total admins: 5
  - Total managers: 12
  - Total staff: 48
  - Active users vs inactive

- ✅ **Store Assignment Interface**
  - Drag & drop stores to Admins
  - Visual store map with Admin assignments
  - Reassign stores between Admins

---

### **2. Admin Dashboard**

**New Features:**
- ✅ **My Stores Panel**
  - List of assigned stores
  - Quick switch between stores
  - Store performance metrics

- ✅ **Manager Management**
  - Hire new Managers for their stores
  - Assign Manager to specific store
  - View Manager performance

- ✅ **Staff Overview (All Stores)**
  - See all staff across their stores
  - Transfer staff between their stores
  - View cross-store statistics

- ✅ **Request More Stores**
  - Button to request Super Admin assign more stores
  - Shows pending requests

---

### **3. Manager Dashboard**

**New Features:**
- ✅ **My Store Info**
  - Single store focus
  - Store metrics and performance
  - Staff roster

- ✅ **Hire Staff Button**
  - Can only hire Staff (not Managers)
  - Staff automatically assigned to their store

- ✅ **Limited Analytics**
  - Order metrics for their store
  - Cannot see financial data
  - Cannot compare to other stores

---

### **4. Staff Dashboard**

**New Features:**
- ✅ **Order Management**
  - Accept/Reject orders
  - Update order status
  - View order history

- ✅ **Basic Metrics**
  - Orders processed today
  - Average prep time
  - Their own performance stats

- ❌ **Restricted Access**
  - Cannot see financial data
  - Cannot access other stores
  - Cannot hire anyone

---

## 🚀 Implementation Phases

### **Phase 1: Database Foundation (Week 1)**

**Tasks:**
1. Update `user_profiles` table with new columns
2. Create `store_assignments` table
3. Create `user_hierarchy` table
4. Create `permission_changes` table
5. Write migration scripts
6. Add indexes for performance
7. Set up Row Level Security (RLS) policies

**Deliverables:**
- Migration files (029-033)
- RLS policies for new tables
- Database documentation

---

### **Phase 2: Permission System Backend (Week 2)**

**Tasks:**
1. Create permission helper functions
2. Build `canUserPerformAction()` utility
3. Implement role validation middleware
4. Create store assignment logic
5. Build hierarchy enforcement

**Code Example:**
```typescript
// src/lib/permissions.ts
export const canUserPerformAction = (
  userRole: string,
  action: string,
  targetRole?: string,
  storeId?: number
): boolean => {
  const permissions = ROLE_PERMISSIONS[userRole];

  // Check if action is allowed
  if (!permissions[action]) return false;

  // Check if user can act on target role
  if (targetRole && !canManageRole(userRole, targetRole)) {
    return false;
  }

  // Check store access
  if (storeId && !hasStoreAccess(userId, storeId)) {
    return false;
  }

  return true;
};
```

**Deliverables:**
- Permission utility library
- Role validation functions
- Store access checker
- Unit tests

---

### **Phase 3: Super Admin Features (Week 3)**

**Tasks:**
1. Build Admin Management UI
2. Create store assignment interface
3. Add system-wide analytics
4. Implement Admin creation workflow
5. Add audit logging UI

**New Components:**
- `AdminManagement.tsx` - Manage all Admins
- `StoreAssignment.tsx` - Assign stores to Admins
- `SystemAnalytics.tsx` - System-wide metrics
- `AuditLog.tsx` - View all permission changes

**Deliverables:**
- Super Admin dashboard
- Admin management panel
- Store assignment UI

---

### **Phase 4: Admin Features (Week 4)**

**Tasks:**
1. Build multi-store switcher
2. Create Manager hiring workflow
3. Add store request system
4. Implement cross-store staff view
5. Add multi-store analytics

**New Components:**
- `StoreSwitcher.tsx` - Switch between assigned stores
- `ManagerHiring.tsx` - Hire Managers for stores
- `StoreRequest.tsx` - Request more stores
- `CrossStoreAnalytics.tsx` - Analytics across their stores

**Deliverables:**
- Admin dashboard enhancements
- Manager creation workflow
- Multi-store management UI

---

### **Phase 5: Manager & Staff Features (Week 5)**

**Tasks:**
1. Build staff hiring workflow for Managers
2. Add store-specific restrictions
3. Implement limited analytics views
4. Add order management for Staff
5. Create performance tracking

**New Components:**
- `StaffHiring.tsx` - Manager hires staff
- `StoreMetrics.tsx` - Store-specific metrics
- `OrderQueue.tsx` - Staff order management

**Deliverables:**
- Manager dashboard
- Staff dashboard
- Limited permission enforcement

---

### **Phase 6: Testing & Security (Week 6)**

**Tasks:**
1. End-to-end permission testing
2. Security audit
3. Performance testing with 1000+ users
4. Load testing
5. Bug fixes and optimization

**Test Cases:**
- ✅ Super Admin can create Admin
- ✅ Admin cannot create another Admin
- ✅ Admin can create Manager
- ✅ Manager can create Staff
- ✅ Manager cannot create Manager
- ✅ Staff cannot create anyone
- ✅ Admin sees only their stores
- ✅ Manager sees only their store
- ✅ RLS policies enforce restrictions

**Deliverables:**
- Test suite
- Security audit report
- Performance optimization
- Production-ready system

---

## 🔒 Security Considerations

### **1. Row Level Security (RLS)**

```sql
-- Super Admin: See everything
CREATE POLICY "Super admins can see all users"
ON user_profiles FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM user_profiles up
    WHERE up.id = auth.uid()
    AND up.role = 'super_admin'
  )
);

-- Admin: See users in their stores only
CREATE POLICY "Admins can see users in their stores"
ON user_profiles FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM user_profiles up
    WHERE up.id = auth.uid()
    AND up.role = 'admin'
    AND up.assigned_stores && ARRAY[user_profiles.store_id]
  )
);

-- Manager: See users in their store only
CREATE POLICY "Managers can see users in their store"
ON user_profiles FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM user_profiles up
    WHERE up.id = auth.uid()
    AND up.role = 'manager'
    AND up.store_id = user_profiles.store_id
  )
);

-- Staff: See only users in their store
CREATE POLICY "Staff can see users in their store"
ON user_profiles FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM user_profiles up
    WHERE up.id = auth.uid()
    AND up.role = 'staff'
    AND up.store_id = user_profiles.store_id
  )
);
```

---

### **2. Permission Enforcement**

Every action must check:
1. **User's role** - What role are they?
2. **Target role** - Are they allowed to act on this role?
3. **Store access** - Do they have access to this store?
4. **Action permission** - Is this action in their permissions?

```typescript
// Middleware example
const requirePermission = (action: string) => {
  return async (req, res, next) => {
    const user = await getCurrentUser(req);
    const hasPermission = canUserPerformAction(
      user.role,
      action,
      req.body.targetRole,
      req.body.storeId
    );

    if (!hasPermission) {
      return res.status(403).json({
        error: "Forbidden",
        message: "You don't have permission to perform this action"
      });
    }

    next();
  };
};

// Usage
app.post('/api/users/create',
  requirePermission('create_user'),
  createUserHandler
);
```

---

### **3. Audit Logging**

Log every permission-related action:
- User creation/deletion
- Role changes
- Permission grants/revokes
- Store assignments
- Failed permission attempts

```typescript
const logPermissionChange = async (change: PermissionChange) => {
  await supabase.from('permission_changes').insert({
    user_id: change.userId,
    changed_by: change.changedBy,
    change_type: change.type,
    old_role: change.oldRole,
    new_role: change.newRole,
    reason: change.reason,
  });
};
```

---

## 📊 Example Scenarios

### **Scenario 1: Super Admin Creates New Admin for 3 Stores**

```
1. Super Admin logs in
2. Goes to Admin Management
3. Clicks "Create New Admin"
4. Fills form:
   - Name: "John Smith"
   - Email: "john@camerons.com"
   - Assigned Stores: [Store 1, Store 5, Store 12]
5. Clicks "Create Admin"
6. System:
   - Creates user in auth.users
   - Creates profile in user_profiles (role: 'admin')
   - Creates 3 records in store_assignments
   - Creates record in user_hierarchy
   - Logs action in permission_changes
   - Sends welcome email to John
7. John receives email with login credentials
8. John logs in and sees dashboard for 3 stores
```

---

### **Scenario 2: Admin Hires Manager for Store 5**

```
1. Admin (John) logs in
2. Sees "My Stores" panel with Store 1, 5, 12
3. Selects Store 5
4. Goes to Staff Management
5. Clicks "Hire Manager"
6. Fills form:
   - Name: "Sarah Manager"
   - Email: "sarah@camerons.com"
   - Store: Store 5 (auto-filled)
7. Clicks "Hire Manager"
8. System:
   - Validates: John has access to Store 5 ✅
   - Validates: John can create Manager ✅
   - Creates user
   - Assigns to Store 5
   - Sets manager_id to John's ID in user_hierarchy
   - Logs action
9. Sarah receives credentials
10. Sarah can only access Store 5
```

---

### **Scenario 3: Manager Tries to Hire Another Manager (Blocked)**

```
1. Manager (Sarah) logs in
2. Goes to Staff Management
3. Clicks "Hire Staff"
4. UI shows ONLY "Staff" role option
   (Manager and Admin options are HIDDEN)
5. Sarah cannot hire Managers
   (Prevented by UI and backend validation)
```

---

### **Scenario 4: Admin Requests More Stores**

```
1. Admin (John) has Store 1, 5, 12
2. Wants to manage Store 20
3. Clicks "Request More Stores"
4. Selects Store 20 from dropdown
5. Adds reason: "Expanding operations to this region"
6. Submits request
7. System:
   - Creates store_request record
   - Notifies Super Admin
8. Super Admin reviews request
9. Super Admin approves
10. Store 20 is added to John's assigned_stores
11. John receives notification
12. John now sees Store 20 in his dashboard
```

---

## 🎯 Benefits of This System

### **1. Scalability**
- ✅ Can grow from 1 to 1000+ stores
- ✅ Each Admin can manage multiple stores
- ✅ Clear hierarchy prevents chaos
- ✅ Automated permission enforcement

### **2. Security**
- ✅ Principle of least privilege
- ✅ No one can exceed their authority
- ✅ Complete audit trail
- ✅ RLS policies at database level

### **3. Flexibility**
- ✅ Super Admin can reorganize anytime
- ✅ Admins can request more stores
- ✅ Managers can be promoted
- ✅ Staff can grow within system

### **4. Accountability**
- ✅ Every action is logged
- ✅ Know who created each user
- ✅ Track all permission changes
- ✅ Performance metrics per role

---

## 📈 Rollout Strategy

### **Phase 1: Highland Mills Only (Current)**
- 1 Super Admin
- 0 Admins (Super Admin manages directly)
- 1-2 Managers
- 3-5 Staff

### **Phase 2: Expand to 5 Stores**
- 1 Super Admin
- 1 Admin (manages 5 stores)
- 5 Managers (1 per store)
- 15-20 Staff

### **Phase 3: Full Rollout (All 29 Stores)**
- 1 Super Admin (Corporate)
- 3-4 Admins (Regional managers, 7-10 stores each)
- 29 Managers (1 per store)
- 100+ Staff

---

## 🚀 Next Steps

**Do you want me to:**
1. ✅ Start implementing Phase 1 (Database Foundation)?
2. ✅ Create the migration files?
3. ✅ Build the permission system?
4. ✅ Update the UI components?

Let me know which phase you'd like to start with, and I'll begin implementation!

---

**Generated with Claude Code**
**Date:** November 19, 2025
