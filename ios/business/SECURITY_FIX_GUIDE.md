# Security Vulnerability Fix Guide
**Critical Security Issues - Immediate Action Required**

## Overview
Your Lovable.dev security scan identified 5 critical errors related to Row Level Security (RLS) policies in your Supabase database. These issues expose sensitive customer data and business analytics to unauthorized access.

## Issues Found

### 🔴 ERROR 1: RLS Disabled in Public
**Table:** `order_sequences`
- **Risk:** Internal business order numbering sequences are publicly visible
- **Impact:** Competitors can track your order volume and growth

### 🔴 ERROR 2: Internal Business Data Exposed
**Table:** `order_sequences`
- **Risk:** RLS completely disabled
- **Impact:** Anyone can read/modify order sequence data

### 🔴 ERROR 3: Customer Phone Numbers and Names Exposed
**Table:** `customers`
- **Risk:** Customer PII visible to public internet
- **Impact:** Privacy violation, potential GDPR/CCPA issues

### 🔴 ERROR 4: Business Analytics Exposed to Competitors
**Tables:** 11 analytics views with no RLS
- `analytics_category_distribution`
- `analytics_customer_insights`
- `analytics_daily_stats`
- `analytics_day_of_week`
- `analytics_hourly_today`
- `analytics_order_funnel`
- `analytics_peak_hours`
- `analytics_popular_items`
- `analytics_revenue_goals`
- `analytics_store_summary`
- `analytics_time_distribution`

**Risk:** Revenue, sales patterns, customer behavior visible to anyone
**Impact:** Competitive disadvantage, business intelligence theft

### 🔴 ERROR 5: Security Definer View
**Risk:** Elevated privilege functions may bypass RLS
**Impact:** Unauthorized data access through views

---

## ✅ Solution: Apply Migration 025

I've created a comprehensive SQL migration that fixes all these issues.

### Step 1: Review the Migration

The migration file is located at:
```
database/migrations/025_fix_security_rls_policies.sql
```

### Step 2: Apply to Supabase

**Option A: Via Supabase Dashboard (Recommended)**

1. Open your Supabase Dashboard
   - Go to: https://app.supabase.com/project/jwcuebbhkwwilqfblecq

2. Navigate to SQL Editor
   - Click "SQL Editor" in left sidebar

3. Copy Migration Content
   ```bash
   # In your terminal:
   cat database/migrations/025_fix_security_rls_policies.sql | pbcopy
   ```

4. Paste and Execute
   - Paste the SQL in the editor
   - Click "Run" button

5. Verify Success
   - Check for "Success" message
   - No error messages should appear

**Option B: Via Supabase CLI**

```bash
# Install Supabase CLI if not already installed
brew install supabase/tap/supabase

# Login
supabase login

# Link to your project
supabase link --project-ref jwcuebbhkwwilqfblecq

# Apply migration
supabase db push database/migrations/025_fix_security_rls_policies.sql
```

---

## What This Migration Does

### 1. **Enables RLS on All Tables**
Every table now requires authentication to access

### 2. **Protects Customer Data**
- ✅ Customers can only see their own data
- ✅ Staff can see customers in their store
- ✅ Admins can see all customers

### 3. **Secures Order Data**
- ✅ Customers see only their orders
- ✅ Staff see orders for their store only
- ✅ Admins see all orders

### 4. **Restricts Analytics**
- ✅ Only authenticated staff can access analytics
- ✅ Public users cannot see business metrics
- ✅ Store-level isolation (staff see only their store's data)

### 5. **Protects Business Operations**
- ✅ Order sequences hidden from public
- ✅ Menu management restricted to staff
- ✅ Store configuration restricted to admins

### 6. **Marketing Data Security**
- ✅ Active coupons are public (as intended)
- ✅ Campaign management restricted to managers
- ✅ Customer loyalty data private to each customer

---

## Post-Migration Verification

### Test 1: Public Access Should Fail
Open browser in incognito mode and try:
```
https://jwcuebbhkwwilqfblecq.supabase.co/rest/v1/customers?select=*
```
**Expected:** `401 Unauthorized` or empty result

### Test 2: Staff Can Access Their Data
Login as staff user and verify:
- Can view orders for their store ✅
- Cannot view orders for other stores ❌
- Can update order status ✅

### Test 3: Customer Privacy
Login as customer and verify:
- Can view own orders ✅
- Cannot view other customers' orders ❌
- Cannot see analytics data ❌

### Test 4: Run Lovable Security Scan Again
1. Go back to Lovable.dev
2. Run security scan
3. Verify all 5 errors are resolved ✅

---

## Policy Summary

| Table | Public Read | Customer Read | Staff Read | Staff Write | Admin |
|-------|-------------|---------------|------------|-------------|-------|
| **customers** | ❌ | Own data only | Store only | Store only | Full |
| **orders** | ❌ | Own orders | Store orders | Can update | Full |
| **order_items** | ❌ | Own items | Store items | View only | Full |
| **order_sequences** | ❌ | ❌ | View only | Auto-update | Full |
| **menu_items** | ✅ (available) | ✅ | ✅ | Manage | Full |
| **stores** | ✅ | ✅ | ✅ | ❌ | Full |
| **staff** | ❌ | ❌ | Own + team | ❌ | Full |
| **analytics_*** | ❌ | ❌ | Store data | ❌ | Full |
| **coupons** | ✅ (active) | ✅ (active) | ✅ | Manage | Full |
| **loyalty_transactions** | ❌ | Own data | View all | Manage | Full |
| **notification_logs** | ❌ | Own notifs | View all | Manage | Full |

---

## Emergency Rollback

If something breaks after applying the migration:

### Option 1: Disable RLS Temporarily (Not Recommended)
```sql
-- EMERGENCY ONLY - DO NOT USE IN PRODUCTION
ALTER TABLE orders DISABLE ROW LEVEL SECURITY;
ALTER TABLE customers DISABLE ROW LEVEL SECURITY;
-- Repeat for other tables...
```

### Option 2: Drop Problematic Policies
```sql
-- Remove a specific policy if it's causing issues
DROP POLICY "policy_name" ON table_name;
```

### Option 3: Contact Support
If you're stuck:
1. Take screenshot of error messages
2. Share with your database administrator
3. Check Supabase logs for details

---

## Next Steps

1. ✅ **Apply migration 025** (critical - do this now)
2. ✅ **Test your iOS app** (ensure staff can still access data)
3. ✅ **Re-run Lovable security scan** (verify all errors are fixed)
4. ✅ **Update `.env.local`** (if you have a customer web app)
5. ✅ **Review API keys** (ensure service role key is secured)
6. ✅ **Enable database backups** (in Supabase dashboard)

---

## Additional Security Recommendations

### 1. Enable Supabase Audit Logs
- Go to Supabase Dashboard → Logs
- Enable audit logging for all tables
- Monitor for suspicious access patterns

### 2. Rotate API Keys
If your anon key was exposed:
```bash
# Generate new anon key in Supabase Dashboard
# Settings → API → Reset anon key
```

### 3. Enable 2FA for Supabase Account
- Supabase Dashboard → Account Settings
- Enable Two-Factor Authentication

### 4. Review Service Role Key Usage
- Never use service role key in frontend code
- Only use in backend/server environments
- Rotate if potentially compromised

### 5. Set Up Alerts
- Configure Supabase alerts for:
  - Failed authentication attempts
  - RLS policy violations
  - Unusual query patterns

---

## Questions?

If you encounter any issues:
1. Check Supabase Dashboard → Logs for error details
2. Verify you're logged in as an admin when testing
3. Ensure `staff` table has your user's `user_id` correctly linked
4. Test policies one table at a time

**Status:** 🔴 **CRITICAL - Apply migration immediately**

Once applied: ✅ **All security issues resolved**
