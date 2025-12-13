# 📱 Customer App Sync Guide

**Date Created:** November 20, 2025
**Purpose:** Ensure the customer iOS/Android app works correctly with Phase 1-3 backend changes
**Target:** Customer-facing mobile app (ordering, tracking, account management)

---

## 🎯 Overview

The customer app is **mostly unaffected** by the RBAC changes since those are business-user focused. However, there are a few updates needed to ensure compatibility with the new database structure.

---

## 📊 What Changed (For Customers)

### **Changes that DON'T affect customers:**
- ✅ RBAC roles (Super Admin, Admin, Manager, Staff) - **Not applicable**
- ✅ Permission system - **Customers don't need this**
- ✅ Multi-store admin assignment - **Not relevant**
- ✅ User hierarchy - **Business-only**

### **Changes that DO affect customers:**
- ⚠️ `user_profiles` table has new columns (need to handle gracefully)
- ⚠️ RLS policies updated (still allow customer actions)
- ✅ Guest checkout still works (no changes needed)
- ✅ Order creation/tracking still works (no changes needed)

---

## 🗄️ Database Compatibility

### **1. Updated user_profiles Table**

The `user_profiles` table now has additional fields, but customer profiles use default values:

```sql
-- Customer profile fields (unchanged):
id uuid
role text DEFAULT 'customer'
full_name text
phone text
email text (from auth.users)
avatar_url text
created_at timestamptz
updated_at timestamptz

-- NEW fields (customers get defaults):
assigned_stores integer[] DEFAULT '{}'           -- Empty for customers
detailed_permissions jsonb DEFAULT '{}'::jsonb   -- Empty for customers
is_system_admin boolean DEFAULT false            -- Always false
created_by uuid DEFAULT NULL                     -- NULL for self-signup
can_hire_roles text[] DEFAULT '{}'               -- Empty for customers
is_active boolean DEFAULT true                   -- Active by default
store_id integer DEFAULT NULL                    -- No store assignment
```

**Action Required:**
- ✅ **NO CHANGES NEEDED** - Customers get safe defaults
- ✅ Your existing queries will work as-is
- ✅ New fields are nullable or have defaults

---

### **2. RLS Policies (Still Allow Customer Actions)**

The RLS policies were updated but **still allow** all customer actions:

#### **Anonymous/Guest Checkout (Still Enabled):**
```sql
-- Customers can create orders without login ✅
-- Customers can view menu items ✅
-- Customers can track their orders ✅
```

#### **Authenticated Customers:**
```sql
-- Customers can view their own profile ✅
-- Customers can update their own profile ✅
-- Customers can view their own orders ✅
-- Customers can create orders ✅
```

**Action Required:**
- ✅ **NO CHANGES NEEDED** - All customer permissions preserved

---

## 📱 Customer App Updates (Optional)

### **1. User Profile Model (Optional Enhancement)**

If you want to be future-proof, update your user profile model to include the new fields (but set defaults):

#### **Swift (iOS):**

```swift
struct CustomerProfile: Codable {
    let id: String
    let role: String  // Always "customer"
    let fullName: String
    let phone: String?
    let email: String
    let avatarUrl: String?
    let createdAt: Date
    let updatedAt: Date

    // NEW FIELDS (optional, with defaults):
    let assignedStores: [Int]  // Default: []
    let detailedPermissions: [String: Any]  // Default: {}
    let isSystemAdmin: Bool  // Default: false
    let isActive: Bool  // Default: true

    enum CodingKeys: String, CodingKey {
        case id, role
        case fullName = "full_name"
        case phone
        case email
        case avatarUrl = "avatar_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case assignedStores = "assigned_stores"
        case detailedPermissions = "detailed_permissions"
        case isSystemAdmin = "is_system_admin"
        case isActive = "is_active"
    }

    // Handle missing fields gracefully
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        role = try container.decode(String.self, forKey: .role)
        fullName = try container.decode(String.self, forKey: .fullName)
        phone = try? container.decode(String.self, forKey: .phone)
        email = try container.decode(String.self, forKey: .email)
        avatarUrl = try? container.decode(String.self, forKey: .avatarUrl)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)

        // New fields with defaults if missing
        assignedStores = (try? container.decode([Int].self, forKey: .assignedStores)) ?? []
        detailedPermissions = (try? container.decode([String: Any].self, forKey: .detailedPermissions)) ?? [:]
        isSystemAdmin = (try? container.decode(Bool.self, forKey: .isSystemAdmin)) ?? false
        isActive = (try? container.decode(Bool.self, forKey: .isActive)) ?? true
    }
}
```

#### **Kotlin (Android):**

```kotlin
@Serializable
data class CustomerProfile(
    val id: String,
    val role: String = "customer",
    @SerialName("full_name") val fullName: String,
    val phone: String? = null,
    val email: String,
    @SerialName("avatar_url") val avatarUrl: String? = null,
    @SerialName("created_at") val createdAt: String,
    @SerialName("updated_at") val updatedAt: String,

    // NEW FIELDS (with defaults):
    @SerialName("assigned_stores") val assignedStores: List<Int> = emptyList(),
    @SerialName("detailed_permissions") val detailedPermissions: Map<String, Any> = emptyMap(),
    @SerialName("is_system_admin") val isSystemAdmin: Boolean = false,
    @SerialName("is_active") val isActive: Boolean = true
)
```

**Benefits:**
- ✅ Future-proof against schema changes
- ✅ No breaking changes if new fields added
- ✅ Safe defaults for all customer accounts

---

### **2. Guest Checkout (No Changes)**

Guest checkout still works exactly as before:

```swift
// Swift - Create guest order
let order = try await supabase
    .from("orders")
    .insert([
        "customer_name": "John Doe",
        "customer_email": "john@example.com",
        "customer_phone": "555-0100",
        "store_id": 1,
        "status": "pending",
        "total": 29.99,
        "order_items": orderItems
    ])
    .execute()
```

```kotlin
// Kotlin - Create guest order
val order = supabase
    .from("orders")
    .insert(mapOf(
        "customer_name" to "John Doe",
        "customer_email" to "john@example.com",
        "customer_phone" to "555-0100",
        "store_id" to 1,
        "status" to "pending",
        "total" to 29.99,
        "order_items" to orderItems
    ))
    .execute()
```

---

### **3. Customer Authentication (No Changes)**

Login and signup work exactly as before:

```swift
// Swift - Sign up
let authResponse = try await supabase.auth.signUp(
    email: email,
    password: password,
    data: [
        "full_name": fullName,
        "phone": phone
    ]
)

// Swift - Sign in
let authResponse = try await supabase.auth.signIn(
    email: email,
    password: password
)
```

```kotlin
// Kotlin - Sign up
val authResponse = supabase.auth.signUpWith(Email) {
    this.email = email
    this.password = password
    data = mapOf(
        "full_name" to fullName,
        "phone" to phone
    )
}

// Kotlin - Sign in
val authResponse = supabase.auth.signInWith(Email) {
    this.email = email
    this.password = password
}
```

---

## 🔄 Migration Steps (Minimal)

### **Step 1: Test Existing App** ✅

1. Launch the customer app (don't change anything)
2. Test guest checkout
3. Test customer signup
4. Test customer login
5. Test order creation
6. Test order tracking

**Expected Result:** Everything should work without changes

---

### **Step 2: Update Models (Optional)** ⚙️

If you want to be future-proof:

1. Add new RBAC fields to `CustomerProfile` model
2. Set safe defaults for all new fields
3. Handle missing fields gracefully in JSON parsing

---

### **Step 3: Test Again** ✅

1. Test signup creates profile with defaults
2. Test login fetches profile correctly
3. Test guest checkout still works
4. Verify no crashes from new fields

---

## 📋 Minimal Checklist

Since customer app changes are minimal, here's a short checklist:

### **Testing (Required):**
- [ ] Test guest checkout (no login)
- [ ] Test customer signup
- [ ] Test customer login
- [ ] Test order creation (logged in)
- [ ] Test order tracking
- [ ] Test profile viewing/editing

### **Code Updates (Optional):**
- [ ] Update `CustomerProfile` model with new fields
- [ ] Add safe defaults for new fields
- [ ] Handle missing fields in JSON parsing

---

## 🚨 Common Issues & Solutions

### **Issue 1: JSON parsing fails on new fields**

**Cause:** New fields not in your model

**Solution:**
```swift
// Make new fields optional or provide defaults
let assignedStores = (try? container.decode([Int].self, forKey: .assignedStores)) ?? []
```

---

### **Issue 2: Profile creation fails**

**Cause:** Trigger automatically creates profile, but your app tries to create it too

**Solution:**
```swift
// Wait for trigger to create profile (give it 1-2 seconds)
try await Task.sleep(nanoseconds: 1_000_000_000)  // 1 second

// Then fetch profile
let profile = try await fetchProfile(userId: authUser.id)
```

---

### **Issue 3: Guest checkout not working**

**Cause:** Not likely related to RBAC changes, check RLS policies

**Solution:**
```sql
-- Verify this policy exists in Supabase:
SELECT * FROM pg_policies WHERE tablename = 'orders' AND policyname = 'Allow public to insert orders';
```

If missing, run migration `020_simplify_order_policies.sql`

---

## ✅ Verification

Test these scenarios to verify customer app still works:

### **Guest User (No Login):**
- [ ] Can view menu
- [ ] Can select items
- [ ] Can add to cart
- [ ] Can checkout
- [ ] Can track order

### **Registered Customer:**
- [ ] Can sign up
- [ ] Can sign in
- [ ] Can view profile
- [ ] Can edit profile
- [ ] Can place orders
- [ ] Can view order history
- [ ] Can track active orders

---

## 🔗 Differences from Business App

| Feature | Customer App | Business App |
|---------|-------------|--------------|
| **RBAC Fields** | Not used (defaults) | Required |
| **Permissions** | Not checked | Must check |
| **Store Access** | Any store | Restricted |
| **Role Checking** | Always "customer" | Multiple roles |
| **Multi-Store** | Not applicable | Admin feature |
| **Audit Logs** | Not tracked | Tracked |

---

## 📞 When to Update Customer App

You **DON'T need to update** the customer app if:
- ✅ Guest checkout works
- ✅ Customer signup/login works
- ✅ Orders can be created
- ✅ Orders can be tracked

You **SHOULD update** the customer app if:
- ❌ JSON parsing errors on profile fetch
- ❌ Guest checkout broken
- ❌ Signup/login fails
- ❌ Can't create orders

---

## 🎯 Summary

**Customer App Changes: MINIMAL** ✨

The RBAC system is designed for business users (Super Admin, Admin, Manager, Staff). Customers are **not affected** by these changes:

- ✅ All customer features work as before
- ✅ Guest checkout still enabled
- ✅ Order creation still works
- ✅ No permission checks needed
- ✅ Optional: Update models for future-proofing

**Recommendation:** Test the existing app first. Only update models if you encounter JSON parsing errors.

---

**📌 Customer app should work with zero changes!**

---

*Generated by Claude Code on November 20, 2025*
*Customer App Sync Guide for RBAC Phase 2-3*
