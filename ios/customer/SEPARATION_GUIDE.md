# 🎯 Customer vs Business App Separation Guide
**Date:** November 19, 2025
**Status:** ✅ Complete & Ready

---

## 📊 Architecture Overview

Your Cameron's Connect platform has **TWO separate user systems**:

### 1. **Customer App** (iOS + Website Customer Login)
- **Database Table:** `customers`
- **Purpose:** Customer ordering, favorites, dietary preferences, saved addresses
- **Access:** Public customer sign-ups, guest checkout
- **Apps:** iOS customer app, Website customer portal

### 2. **Business Dashboard** (Website Admin Section)
- **Database Table:** `user_profiles`
- **Purpose:** Business operations, staff management, order management, analytics
- **Access:** Staff/admin login only (requires role assignment)
- **Apps:** Web dashboard at `/admin` or `/dashboard`

---

## 🗄️ Database Structure

### Tables Used by **CUSTOMERS**:
```sql
customers                    -- Customer account data
├── id                      -- Auto-generated UUID
├── auth_user_id            -- Links to auth.users (Supabase Auth)
├── email
├── full_name
├── phone_number
├── dietary_preferences     -- JSONB: ["vegetarian", "gluten_free"]
├── allergens               -- JSONB: ["dairy", "nuts"]
├── spicy_tolerance         -- VARCHAR: "mild", "medium", "hot", "extra_hot"
├── default_store_id        -- INT: Links to stores table
├── preferred_order_type    -- VARCHAR: "pickup", "delivery", "dine_in"
├── email_notifications     -- BOOLEAN
├── push_notifications      -- BOOLEAN
├── sms_notifications       -- BOOLEAN
├── marketing_emails        -- BOOLEAN
├── created_at
└── updated_at

customer_favorites           -- Customer favorite menu items
├── id
├── customer_id             -- UUID: Links to customers.auth_user_id
├── menu_item_id            -- INT: Links to menu_items
└── created_at

customer_addresses           -- Customer delivery addresses
├── id
├── customer_id             -- UUID: Links to customers.auth_user_id
├── label                   -- "Home", "Work", etc.
├── street_address
├── apartment
├── city
├── state
├── zip_code
├── phone_number
├── delivery_instructions
├── is_default              -- BOOLEAN: One default per customer
├── created_at
└── updated_at
```

### Tables Used by **BUSINESS USERS**:
```sql
user_profiles                -- Business/staff accounts
├── id                      -- UUID from auth.users
├── role                    -- "super_admin", "admin", "manager", "staff"
├── full_name
├── phone
├── store_id                -- INT: Assigned store
├── permissions             -- JSONB: ["orders", "menu", "analytics", "settings"]
├── is_active
├── avatar_url
├── created_at
└── updated_at
```

### Shared Tables (Both Systems Use):
```sql
stores                       -- Store locations
menu_items                   -- Menu catalog
menu_categories              -- Menu organization
orders                       -- All orders (customer + business)
order_items                  -- Order details
```

---

## 🚀 Migration Status

### ✅ Completed Migrations:

1. **002_ADD_CUSTOMER_COLUMNS.sql** (Already run)
   - Added dietary preference columns to `user_profiles` table
   - Created `user_favorites` and `user_addresses` tables
   - **Note:** This was for the business table, not customer table

2. **003_CUSTOMERS_TABLE_FINAL.sql** (RUN THIS NOW!)
   - ✅ Adds dietary preference columns to `customers` table
   - ✅ Creates `customer_favorites` table
   - ✅ Creates `customer_addresses` table
   - ✅ Sets up Row Level Security (RLS)
   - ✅ Creates helper functions

**ACTION REQUIRED:**
Run `database-migrations/003_CUSTOMERS_TABLE_FINAL.sql` in Supabase SQL Editor

---

## 📱 iOS Customer App - Cursor Instructions

### Copy/Paste This to Cursor:

```
The iOS customer app uses the "customers" table for customer data, NOT "user_profiles".

Database Schema:
- customers: Customer accounts with dietary preferences
- customer_favorites: Customer favorite menu items (column: customer_id)
- customer_addresses: Customer delivery addresses (column: customer_id)

Key Points:
1. All customer queries use auth_user_id from customers table
2. Favorites table uses customer_id column (not user_id)
3. Addresses table uses customer_id column (not user_id)
4. user_profiles table is for business/staff accounts only

The iOS app code in SupabaseManager.swift already uses the correct tables:
- .from("customers") for profile data
- .from("customer_favorites") for favorites
- .from("customer_addresses") for addresses

All queries use .eq("customer_id", value: userId) or .eq("auth_user_id", value: userId)

Migration to run: database-migrations/003_CUSTOMERS_TABLE_FINAL.sql
```

---

## 🌐 Web Business Dashboard - Cursor Instructions

### Copy/Paste This to Cursor:

```
The business dashboard uses the "user_profiles" table for staff/admin accounts, NOT "customers".

Database Schema:
- user_profiles: Business user accounts with roles and permissions
- user_favorites: (Optional) Staff favorites - separate from customer favorites
- user_addresses: (Optional) Staff addresses - separate from customer addresses

User Roles in user_profiles:
- super_admin: Full access to all stores
- admin: Full access to assigned store
- manager: Order/menu/analytics access for assigned store
- staff: Limited access based on permissions array

Key Points:
1. Business users have role-based access control (RBAC)
2. user_profiles.id links to auth.users(id)
3. user_profiles.store_id assigns staff to specific store
4. user_profiles.permissions is JSONB array: ["orders", "menu", "analytics", "settings"]
5. Customer accounts are in the separate "customers" table

Authentication Flow:
- /login → Customer login (saves to customers table)
- /admin/login or /dashboard/login → Staff login (uses user_profiles table)

Current user_profiles records:
- super_admin (role: 'super_admin')
- customer (role: 'customer') - This should be moved to customers table eventually

Migration already run: 002_ADD_CUSTOMER_COLUMNS.sql
```

---

## 🔐 Authentication & Security

### Customer Authentication (iOS + Website):
```typescript
// Customer sign up
const { data, error } = await supabase.auth.signUp({
  email: 'customer@example.com',
  password: 'password123',
  options: {
    data: {
      user_type: 'customer' // Tag for later processing
    }
  }
})

// After sign up, create customer profile
await supabase.from('customers').insert({
  auth_user_id: data.user.id,
  email: data.user.email,
  full_name: 'John Doe'
})
```

### Business Authentication (Website Dashboard):
```typescript
// Admin/staff sign in
const { data, error } = await supabase.auth.signInWithPassword({
  email: 'admin@camerons.com',
  password: 'securepassword'
})

// Check user_profiles for role
const { data: profile } = await supabase
  .from('user_profiles')
  .select('role, permissions, store_id')
  .eq('id', data.user.id)
  .single()

// Redirect based on role
if (profile.role === 'super_admin') {
  // Access to all stores
} else if (profile.role === 'admin') {
  // Access to assigned store
}
```

---

## 🧪 Testing Checklist

### Test Customer App (iOS):

1. ✅ **Run Migration First:**
   - Execute `003_CUSTOMERS_TABLE_FINAL.sql` in Supabase SQL Editor
   - Verify tables created: `customer_favorites`, `customer_addresses`
   - Verify columns added to `customers` table

2. ✅ **Sign Up New Customer:**
   - Create account in iOS app
   - Verify record created in `customers` table
   - Check `auth_user_id` matches auth.users

3. ✅ **Test Dietary Preferences:**
   - Open Profile → Dietary Preferences
   - Select preferences (Vegetarian, Gluten-free, etc.)
   - Verify saved to `customers.dietary_preferences`
   - Close app and reopen → preferences should persist

4. ✅ **Test Favorites:**
   - Browse menu
   - Tap heart icon on items
   - Check Favorites tab
   - Verify records in `customer_favorites` table with correct `customer_id`

5. ✅ **Test Addresses:**
   - Open Profile → Addresses
   - Add new address
   - Set as default
   - Verify record in `customer_addresses` table with correct `customer_id`

### Test Business Dashboard (Website):

1. ✅ **Admin Login:**
   - Navigate to `/admin/login`
   - Sign in with admin credentials
   - Verify pulls from `user_profiles` table

2. ✅ **Role-Based Access:**
   - Test super_admin → sees all stores
   - Test admin → sees assigned store only
   - Test manager → sees limited dashboard tabs

3. ✅ **Order Management:**
   - View orders from customers table
   - Accept/reject orders
   - Verify order status updates

---

## 📝 Common Queries

### Get Customer Profile:
```typescript
const { data } = await supabase
  .from('customers')
  .select('*')
  .eq('auth_user_id', userId)
  .single()
```

### Get Customer Favorites:
```typescript
const { data } = await supabase
  .from('customer_favorites')
  .select('*')
  .eq('customer_id', userId)
```

### Get Customer Addresses:
```typescript
const { data } = await supabase
  .from('customer_addresses')
  .select('*')
  .eq('customer_id', userId)
  .order('created_at', { ascending: false })
```

### Get Business User Profile:
```typescript
const { data } = await supabase
  .from('user_profiles')
  .select('role, permissions, store_id')
  .eq('id', userId)
  .single()
```

---

## 🎨 Website Implementation Plan

### Customer Portal (`/` or `/customer`):
```
Pages:
- /login → Customer login
- /signup → Customer registration
- /menu → Browse menu
- /order → Place order
- /profile → Manage profile, favorites, addresses
- /orders → View order history
```

### Business Dashboard (`/admin` or `/dashboard`):
```
Pages:
- /admin/login → Staff/admin login
- /admin/dashboard → Overview
- /admin/orders → Order management
- /admin/menu → Menu management
- /admin/analytics → Sales analytics
- /admin/staff → Staff management (admin+ only)
- /admin/settings → Store settings
```

### Login Page Pattern:
```tsx
// Default customer login
<LoginForm onSubmit={customerLogin} />

// Small link at bottom
<a href="/admin/login">Staff Login →</a>
```

---

## ⚠️ Important Notes

1. **Never Mix Tables:**
   - Customer app queries → `customers`, `customer_favorites`, `customer_addresses`
   - Business app queries → `user_profiles`
   - Shared queries → `orders`, `menu_items`, `stores`

2. **Column Names Matter:**
   - Customer tables use `customer_id` (UUID)
   - Business tables use `user_id` or `id` (UUID)
   - Both link to `auth.users(id)`

3. **RLS Policies:**
   - Customers can only see their own data
   - Staff can see data for their assigned store
   - Super admins can see all data

4. **Migration Order:**
   - ✅ 002_ADD_CUSTOMER_COLUMNS.sql (Already run - added to user_profiles)
   - ⏳ 003_CUSTOMERS_TABLE_FINAL.sql (Run this now - adds to customers)

---

## 🚀 Next Steps

1. ✅ Run migration: `003_CUSTOMERS_TABLE_FINAL.sql`
2. ✅ Test iOS app with new database structure
3. ⏳ Implement website customer portal with `/login`
4. ⏳ Implement website business dashboard with `/admin/login`
5. ⏳ Add login type toggle on website
6. ⏳ Test complete customer → business workflow

---

## 📞 Support

If you need to tell Cursor AI about this architecture:

**For iOS Customer App:**
"Use customers table for customer data. Favorites and addresses use customer_id column. Migration: 003_CUSTOMERS_TABLE_FINAL.sql"

**For Website Business Dashboard:**
"Use user_profiles table for staff/admin data. Customers are in separate customers table. Check role and permissions fields for access control."

---

**Built with ❤️ for Cameron's Connect**
Clean separation = Better security + Easier maintenance
