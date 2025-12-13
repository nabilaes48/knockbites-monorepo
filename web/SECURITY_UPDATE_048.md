# Security Update - Migration 048

**Date**: December 2, 2025
**Status**: Ready to apply
**Breaking Changes**: Yes (order updates require auth)

---

## Summary

Migration 048 fixes three critical security vulnerabilities discovered in Phase 2 analysis:

1. **Order UPDATE vulnerability** - Anyone could update any order
2. **Analytics exposure** - Anonymous users could access analytics views
3. **Missing email verification** - Codes generated but not sent

---

## Breaking Changes

### 1. Order Status Updates (AFFECTS iOS BUSINESS APP)

**Before**: Anyone (including anonymous users) could update any order.

**After**: Only authenticated staff can update orders in their assigned store.

**Impact on iOS Business App**:
- Staff MUST be logged in to accept/reject/update orders
- The app already requires login, so this should work as-is
- Verify that `supabase.auth.signIn()` is called before order management

**Verification**:
```swift
// In your order management code, ensure user is authenticated
guard supabase.auth.session != nil else {
    // Show login screen
    return
}

// Now order updates will work
try await supabase
    .from("orders")
    .update(["status": "preparing"])
    .eq("id", orderId)
    .execute()
```

### 2. Analytics Access (AFFECTS iOS BUSINESS APP)

**Before**: Anonymous users could query analytics views.

**After**: Only authenticated users with appropriate roles can access analytics.

**Impact**:
- Staff must be logged in to view analytics
- Customer app should NOT access analytics (as expected)
- Super admins see all stores
- Other roles see only their assigned store

**No code changes needed** - just ensure users are authenticated.

---

## Non-Breaking Changes

### 1. Email Verification Now Sends Emails

The verification code flow now calls an Edge Function to send emails.

**Setup Required**:
1. Deploy Edge Function: `supabase functions deploy send-verification-email`
2. Set environment variables:
   ```bash
   supabase secrets set RESEND_API_KEY=your_resend_key
   # OR
   supabase secrets set SENDGRID_API_KEY=your_sendgrid_key
   ```

### 2. Rate Limiting Added

Verification requests are now rate-limited:
- 5 requests per 15-minute window per email
- Prevents abuse/spam

### 3. Scheduled Cleanup Jobs

New infrastructure for automated cleanup:
- `cleanup_expired_verifications()` - Every 15 minutes
- `aggregate_daily_metrics()` - Daily at midnight

**Setup Options**:
1. Enable pg_cron in Supabase Dashboard
2. Use external cron service with service_role key
3. Use Supabase scheduled Edge Functions

---

## How to Apply

### Step 1: Apply Migration
```bash
# In Supabase SQL Editor, run:
-- Contents of supabase/migrations/048_security_fixes.sql
```

### Step 2: Deploy Edge Functions
```bash
cd /path/to/camerons-connect
supabase functions deploy send-verification-email
supabase functions deploy scheduled-cleanup
```

### Step 3: Set Secrets
```bash
supabase secrets set RESEND_API_KEY=re_xxxxx
# or
supabase secrets set SENDGRID_API_KEY=SG.xxxxx
supabase secrets set FROM_EMAIL=noreply@camerons247deli.com
```

### Step 4: Test

**Web App**:
1. Try to place an order → Should receive email with code
2. Login as staff → Can update order status
3. Logout → Cannot update order status

**iOS Customer App**:
1. Browse menu → Works (public)
2. Place order → Works (with verification)
3. Track order → Works (public)

**iOS Business App**:
1. Login required → Already implemented
2. View orders → Works (authenticated)
3. Update orders → Works (authenticated)
4. View analytics → Works (authenticated)

---

## Rollback

If issues occur, rollback with:

```sql
-- Restore public order updates (NOT RECOMMENDED - security risk)
DROP POLICY IF EXISTS "staff_update_store_orders" ON orders;
DROP POLICY IF EXISTS "customers_cancel_own_orders" ON orders;

CREATE POLICY "Allow public to update order status"
ON orders FOR UPDATE TO public
USING (true) WITH CHECK (true);

-- Restore anon analytics access (NOT RECOMMENDED)
GRANT SELECT ON analytics_daily_stats TO anon;
-- ... repeat for other views
```

---

## Files Changed

### New Files
- `supabase/migrations/048_security_fixes.sql` - Security migration
- `supabase/migrations/049_setup_scheduled_jobs.sql` - Job scheduling
- `supabase/functions/send-verification-email/index.ts` - Email Edge Function
- `supabase/functions/scheduled-cleanup/index.ts` - Cleanup Edge Function

### Modified Files
- `src/components/order/Checkout.tsx` - Now calls Edge Function for email

### Deleted Files
- `src/lib/pocketbase.ts` - Unused
- `pb_data/`, `pb_hooks/`, `pb_migrations/` - Empty directories

### Renamed Files
- `041_separate_customer_and_staff_signups.sql` → `041_SUPERSEDED_...`
- `042_portion_based_customizations.sql` → `042_SUPERSEDED_...`

---

## Security Improvements Summary

| Vulnerability | Severity | Fixed |
|--------------|----------|-------|
| Public order updates | 🔴 Critical | ✅ |
| Analytics exposed to anon | 🟡 Medium | ✅ |
| Missing email sending | 🟡 Medium | ✅ |
| No rate limiting | 🟡 Medium | ✅ |
| Superseded migrations | 🟢 Low | ✅ |
| Dead code | 🟢 Low | ✅ |

---

## Contact

For issues with this update, check:
1. Supabase Dashboard → Logs
2. Edge Function logs
3. Browser console for frontend errors
