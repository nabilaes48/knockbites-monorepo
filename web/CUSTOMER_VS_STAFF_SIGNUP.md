# Customer vs Staff Signup - Architecture

**Date:** November 20, 2025
**Purpose:** Clarify the separation between customer and business user authentication

---

## 🏗️ Architecture Overview

Cameron's Connect uses **two separate tables** for authentication:

| User Type | Table | Signup Method | Created By |
|-----------|-------|---------------|------------|
| **Customers** | `customers` | Public signup at `/signup` | Self-registration |
| **Business Users** | `user_profiles` | Admin creates OR staff request | Super Admin / Admin |

---

## 👥 Customer Signups

### **URL:** `http://localhost:8080/signup`

### **Process:**
1. Customer fills out signup form (name, email, phone, password)
2. Account created in `auth.users` (Supabase Auth)
3. Trigger `handle_new_user()` automatically creates record in `customers` table
4. Customer can sign in at `/signin`
5. Customer redirected to `/customer/dashboard`

### **Database Flow:**
```
/signup → auth.users → (trigger) → customers table
```

### **Customers Table:**
```sql
customers (
  id uuid PRIMARY KEY,          -- Links to auth.users
  full_name text,
  email text,
  phone text,
  avatar_url text,
  created_at timestamp,
  updated_at timestamp
)
```

### **What Customers Can Do:**
- ✅ Browse menu
- ✅ Place orders (guest or logged in)
- ✅ Track orders
- ✅ View order history
- ✅ Earn rewards
- ❌ Cannot access business dashboard
- ❌ Cannot manage stores/staff

---

## 👔 Business User Signups (Staff, Manager, Admin, Super Admin)

### **Method 1: Admin Creates User (Preferred)**

**URL:** `http://localhost:8080/super-admin` (Super Admin Dashboard)

1. Super Admin logs into `/dashboard/login`
2. Navigates to Super Admin Dashboard
3. Goes to "Users" tab
4. Clicks "Create User"
5. Fills out form (email, password, role, store assignment)
6. User created in `auth.users` AND `user_profiles` table
7. New staff member can sign in at `/dashboard/login`

**Database Flow:**
```
Super Admin → Create User Modal → auth.users + user_profiles
```

---

### **Method 2: Staff Access Request (Self-Service)**

**URL:** `http://localhost:8080/request-staff-access`

1. Potential staff member goes to link (or clicks "Staff? Sign in here →" from `/signin`)
2. Fills out staff access request form
3. Request submitted (TODO: Implement request approval system)
4. Admin reviews and approves
5. Admin manually creates account in Super Admin Dashboard

**Current Status:** Request form exists but approval workflow not yet implemented

---

## 🗂️ User Profiles Table

Only business users exist here:

```sql
user_profiles (
  id uuid PRIMARY KEY,          -- Links to auth.users
  role text,                    -- 'super_admin', 'admin', 'manager', 'staff'
  full_name text,
  phone text,
  store_id integer,             -- Primary store assignment
  assigned_stores integer[],    -- Multi-store access (for admins)
  permissions jsonb,
  detailed_permissions jsonb,
  is_system_admin boolean,
  is_active boolean,
  created_by uuid,              -- Who created this user
  can_hire_roles text[],
  avatar_url text,
  created_at timestamp,
  updated_at timestamp
)
```

---

## 🚦 Login Pages

### **Customer Login:** `/signin`
- Uses `customers` table
- Redirects to `/customer/dashboard`
- Orange "Sign In" button
- Link: "Don't have an account? Sign up"

### **Business Login:** `/dashboard/login`
- Uses `user_profiles` table
- Redirects to `/dashboard`
- Shows role badge (Super Admin, Admin, Manager, Staff)
- Link: "Need Staff Access? Request access"

---

## 🔒 RLS Policies

### **Customers Table:**
- ✅ Customers can view/update own profile
- ✅ Public can insert on signup (via trigger)
- ✅ Staff can view all customers

### **User Profiles Table:**
- ✅ Users can view own profile
- ✅ Super Admin can view/create/update/delete all
- ✅ Admin can view/create/update users in their stores
- ✅ Manager can view/create staff in their store
- ❌ Customers cannot access this table

---

## 🔧 Migration 041

**Run this migration** to separate customer and staff signups:

```sql
-- In Supabase SQL Editor:
-- Copy and paste: supabase/migrations/041_separate_customer_and_staff_signups.sql
```

**What it does:**
1. Creates `customers` table
2. Updates trigger to insert customers by default
3. Migrates existing customer-role users from user_profiles to customers
4. Adds RLS policies for customers table

---

## ✅ Testing the Separation

### **Test Customer Flow:**
1. Open incognito window
2. Go to `/signup`
3. Create customer account
4. Sign in at `/signin`
5. Check you can place orders
6. Verify you CANNOT access `/dashboard`

### **Test Staff Flow:**
1. Log in as Super Admin at `/dashboard/login`
2. Go to `/super-admin`
3. Create a new Staff user
4. Log out
5. Log in as new staff member
6. Verify you can access `/dashboard`
7. Verify you CANNOT access `/super-admin`

---

## 📌 Key Differences

| Feature | Customer | Business User |
|---------|----------|---------------|
| **Signup URL** | `/signup` | Created by admin |
| **Login URL** | `/signin` | `/dashboard/login` |
| **Database Table** | `customers` | `user_profiles` |
| **Dashboard** | `/customer/dashboard` | `/dashboard` |
| **Can Place Orders** | ✅ Yes | ✅ Yes (but also manage) |
| **Can Manage Orders** | ❌ No | ✅ Yes |
| **Can Manage Staff** | ❌ No | ✅ Yes (role-dependent) |
| **Multi-Store Access** | N/A | ✅ Yes (admins only) |
| **RBAC Roles** | N/A | staff/manager/admin/super_admin |

---

## 🎯 Summary

**Customers = `customers` table**
- Self-registration at `/signup`
- Consumer-facing features only

**Business Users = `user_profiles` table**
- Created by Super Admin/Admin
- Full access to business dashboard with RBAC

**This separation ensures:**
- ✅ Clean data architecture
- ✅ Proper security boundaries
- ✅ Role-based access control
- ✅ No permission conflicts

---

*Generated on November 20, 2025*
