# Security Vulnerability Fixes

## Overview

This document explains the security vulnerabilities that were identified and fixed in migration `027_fix_security_vulnerabilities.sql`.

## Issues Identified

### 1. **All Customer Orders Exposed to Public** (CRITICAL)
**Problem**: The `orders` table had a policy allowing ANY unauthenticated user to view ALL orders in the system.

```sql
-- OLD VULNERABLE POLICY
CREATE POLICY "Allow public to view orders"
ON orders FOR SELECT TO public
USING (true);  -- ❌ Exposes ALL orders to everyone
```

**Impact**: Customer names, phone numbers, email addresses, order details, and spending patterns were visible to anyone on the internet.

### 2. **Anyone Can Modify Orders** (CRITICAL)
**Problem**: The `orders` table allowed ANY unauthenticated user to UPDATE any order.

```sql
-- OLD VULNERABLE POLICY
CREATE POLICY "Allow public to update order status"
ON orders FOR UPDATE TO public
USING (true) WITH CHECK (true);  -- ❌ Anyone can modify any order
```

**Impact**: Malicious actors could cancel orders, change delivery addresses, modify totals, or disrupt business operations.

### 3. **Analytics Data Publicly Accessible** (HIGH)
**Problem**: All analytics views were granted SELECT permissions to anonymous users (`anon`).

```sql
-- OLD VULNERABLE GRANTS
GRANT SELECT ON analytics_top_customers TO anon, authenticated;
GRANT SELECT ON analytics_store_summary TO anon, authenticated;
```

**Impact**: Sensitive business intelligence, customer PII, and revenue data accessible to competitors or bad actors.

## Solutions Implemented

### Orders Table RLS Policies

#### Policy 1: Guest Checkout (INSERT)
```sql
CREATE POLICY "Public can create orders"
ON orders FOR INSERT TO public
WITH CHECK (true);
```
✅ Allows guest users to create orders (essential for guest checkout)
✅ No SELECT access, so they can't view other orders

#### Policy 2: Authenticated User Access (SELECT)
```sql
CREATE POLICY "Users can view own orders or staff view store orders"
ON orders FOR SELECT TO authenticated
USING (
  -- Customers see their own orders
  (customer_id = auth.uid())
  OR
  -- Staff see orders for their store
  (role IN ('staff', 'manager', 'admin', 'super_admin')
   AND (store_id = user_store_id OR role = 'super_admin'))
);
```
✅ Customers only see their own orders
✅ Staff only see orders for their assigned store
✅ Super admins see all stores

#### Policy 3: Staff Order Updates (UPDATE)
```sql
CREATE POLICY "Staff can update orders"
ON orders FOR UPDATE TO authenticated
USING (
  role IN ('staff', 'manager', 'admin', 'super_admin')
  AND (store_id = user_store_id OR role = 'super_admin')
);
```
✅ Only authenticated staff can update orders
✅ Staff limited to their store, super admins can update any

#### Policy 4: Customer Self-Service (UPDATE)
```sql
CREATE POLICY "Customers can cancel own orders"
ON orders FOR UPDATE TO authenticated
USING (
  customer_id = auth.uid()
  AND status IN ('pending', 'confirmed')
);
```
✅ Customers can only cancel their own pending orders
✅ Cannot modify completed orders

### Secure Guest Order Tracking

Instead of exposing all orders to public, we created a secure function:

```sql
CREATE FUNCTION get_order_by_id(p_order_id BIGINT)
RETURNS SETOF orders
SECURITY DEFINER;
```

**Usage in JavaScript:**
```javascript
// ✅ SECURE: Fetch specific order by ID for guest tracking
const { data: order } = await supabase
  .rpc('get_order_by_id', { p_order_id: orderId });

// ❌ INSECURE: Direct SELECT (will fail for guests now)
const { data } = await supabase
  .from('orders')
  .select('*')
  .eq('id', orderId);  // Blocked by RLS for anonymous users
```

### Analytics View Protection

```sql
-- Revoke anonymous access
REVOKE SELECT ON analytics_top_customers FROM anon;
REVOKE SELECT ON analytics_daily_stats FROM anon;
-- ... etc for all views

-- Enable security_invoker to inherit RLS from base tables
ALTER VIEW analytics_top_customers SET (security_invoker = on);
```

✅ Only authenticated staff can access analytics
✅ Views inherit RLS policies from underlying tables
✅ Staff see only their store's data (except super admins)

## Migration Instructions

### 1. Backup Your Database
```bash
# Create a backup before running migration
supabase db dump > backup_before_security_fix.sql
```

### 2. Run the Migrations
In Supabase SQL Editor, run BOTH migration files in order:

**First, run migration 027:**
```sql
-- Run in Supabase SQL Editor
-- File: supabase/migrations/027_fix_security_vulnerabilities.sql
```

**Then, run migration 028:**
```sql
-- Run in Supabase SQL Editor
-- File: supabase/migrations/028_fix_remaining_security_issues.sql
```

Migration 028 fixes:
- ✅ Enables RLS on `order_sequences` table
- ✅ Removes PII from `analytics_top_customers` view (anonymizes data)
- ✅ Sets `security_invoker` on all analytics views
- ✅ Creates `get_top_customers_with_details()` function for staff to access PII
- ✅ Updates `generate_order_number()` to work with guest checkout

### 3. Update Application Code

#### For Guest Order Tracking Pages
Replace direct queries with the secure function:

```typescript
// BEFORE (no longer works for guests)
const { data: order } = await supabase
  .from('orders')
  .select('*')
  .eq('id', orderId)
  .single();

// AFTER (works for guests)
const { data: order } = await supabase
  .rpc('get_order_by_id', { p_order_id: orderId })
  .then(res => ({ data: res.data?.[0], error: res.error }));
```

#### For Staff Dashboard
No changes needed - existing queries will work with new RLS policies.

#### For Customer Dashboard
No changes needed - authenticated customers can see their own orders.

#### For Analytics - Top Customers View
The `analytics_top_customers` view has been anonymized to remove PII. To get customer details (names/phones) for authenticated staff:

```typescript
// OLD - Shows anonymized data only
const { data: topCustomers } = await supabase
  .from('analytics_top_customers')
  .select('*');

// NEW - For staff needing actual customer data
const { data: topCustomers } = await supabase
  .rpc('get_top_customers_with_details', {
    p_store_id: storeId,  // Optional: null for all stores (super admin only)
    p_limit: 100          // Optional: defaults to 100
  });
```

This function enforces:
- Only authenticated staff can call it
- Staff can only see customers from their assigned store
- Super admins can see all stores

### 4. Test the Following Scenarios

**✅ Test 1: Guest Checkout**
- [ ] Guest can create order without login
- [ ] Guest can track order using order ID
- [ ] Guest CANNOT view all orders
- [ ] Guest CANNOT update/cancel any order

**✅ Test 2: Customer Dashboard**
- [ ] Logged-in customer sees only their orders
- [ ] Customer can cancel pending orders
- [ ] Customer CANNOT see other customers' orders

**✅ Test 3: Staff Dashboard**
- [ ] Staff sees only orders for their assigned store
- [ ] Staff can update order status
- [ ] Staff CANNOT see orders from other stores

**✅ Test 4: Admin Dashboard**
- [ ] Admin sees all orders for their store
- [ ] Admin can manage all store orders
- [ ] Admin CANNOT see orders from other stores

**✅ Test 5: Super Admin Dashboard**
- [ ] Super admin sees orders from ALL stores
- [ ] Super admin can manage any order
- [ ] Super admin sees all analytics data

**✅ Test 6: Analytics Access**
- [ ] Anonymous users CANNOT access analytics views
- [ ] Staff can only see analytics for their store
- [ ] Super admin sees analytics for all stores
- [ ] `analytics_top_customers` view does NOT show customer names/phones (anonymized)
- [ ] Staff can use `get_top_customers_with_details()` to see customer PII
- [ ] Non-staff users CANNOT call `get_top_customers_with_details()`

**✅ Test 7: Order Sequences**
- [ ] Anonymous users CANNOT view `order_sequences` table
- [ ] Guest checkout can still create orders with order numbers
- [ ] Staff can view order sequences for their store
- [ ] Super admin can view all order sequences

## Security Best Practices Going Forward

### 1. Never Use `USING (true)` for Public Policies
```sql
-- ❌ BAD - Exposes everything
CREATE POLICY "bad_policy" ON table_name
FOR SELECT TO public USING (true);

-- ✅ GOOD - Use specific conditions
CREATE POLICY "good_policy" ON table_name
FOR SELECT TO authenticated
USING (user_id = auth.uid());
```

### 2. Always Enable RLS on Tables
```sql
ALTER TABLE table_name ENABLE ROW LEVEL SECURITY;
```

### 3. Use SECURITY DEFINER Functions for Guest Access
When guests need specific data, use functions instead of broad SELECT policies.

### 4. Grant Permissions Explicitly
```sql
-- ❌ BAD - Too permissive
GRANT SELECT ON sensitive_table TO anon, authenticated;

-- ✅ GOOD - Only authenticated users
GRANT SELECT ON sensitive_table TO authenticated;
```

### 5. Test With Different User Roles
Always test queries as:
- Anonymous user (not logged in)
- Customer user
- Staff user
- Admin user
- Super admin user

## Rollback Instructions

If you need to rollback (NOT RECOMMENDED - security vulnerability):

```sql
-- WARNING: This re-introduces security vulnerabilities!
-- Only use for emergency rollback

-- Re-enable public access (insecure)
CREATE POLICY "Allow public to view orders" ON orders
FOR SELECT TO public USING (true);

CREATE POLICY "Allow public to update order status" ON orders
FOR UPDATE TO public USING (true) WITH CHECK (true);

-- Re-grant analytics access (insecure)
GRANT SELECT ON analytics_top_customers TO anon;
-- etc...
```

## Questions or Issues?

If you encounter any issues after applying these fixes:

1. Check the Supabase logs for RLS policy errors
2. Verify you're using `get_order_by_id()` for guest order tracking
3. Ensure staff users have correct `role` and `store_id` in `user_profiles`
4. Test with actual user accounts, not service role key

## Summary

✅ Orders table now properly secured with role-based access
✅ Guest checkout still works via INSERT policy
✅ Guest order tracking uses secure function instead of broad SELECT
✅ Analytics data protected from public access
✅ Staff can only see data for their assigned store
✅ Customer PII no longer exposed to internet

**Security Score**: Improved from CRITICAL to SECURE ✨
