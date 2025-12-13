# 🚨 Fix Login Issue - Infinite Recursion in RLS Policies

**Issue:** Cannot login to business dashboard - "infinite recursion detected in policy for relation 'user_profiles'"

**Cause:** The RLS policies on `user_profiles` table query the same table they're protecting, creating circular dependencies.

**Solution:** Run migrations 037, 038, AND 039 to fix ALL policies across ALL tables (20+ policies updated to eliminate all recursion).

---

## ⚡ Quick Fix (5 minutes)

### **Step 1: Open Supabase Dashboard**

1. Go to [Supabase Dashboard](https://app.supabase.com)
2. Select your project: **camerons-connect**
3. Navigate to: **SQL Editor** (left sidebar)

---

### **Step 2: Run the Fix Migrations**

**Migration 037** (if not already run):
1. Click "**New query**" button
2. Copy the entire content of: `supabase/migrations/037_comprehensive_policy_migration.sql`
3. Paste into the SQL Editor
4. Click "**Run**" button

**Expected Result:** `Success. No rows returned`

**Migration 038** (fixes permission_changes recursion):
1. Click "**New query**" button
2. Copy the entire content of: `supabase/migrations/038_fix_permission_changes_policies.sql`
3. Paste into the SQL Editor
4. Click "**Run**" button

**Expected Result:** `Success. No rows returned`

**Migration 039** (CRITICAL - fixes ALL remaining recursion):
1. Click "**New query**" button
2. Copy the entire content of: `supabase/migrations/039_fix_all_remaining_recursive_policies.sql`
3. Paste into the SQL Editor
4. Click "**Run**" button

**Expected Result:** `Success. No rows returned`

---

### **Step 3: Verify the Fix**

Run this verification query:

```sql
-- Check if helper functions were created
SELECT routine_name
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name IN (
    'get_current_user_role',
    'is_current_user_system_admin',
    'get_current_user_assigned_stores',
    'get_current_user_store_id'
  );
```

**Expected Result:** Should show 4 functions

---

### **Step 4: Test Login**

1. Go back to your login page: `http://localhost:8080/dashboard/login`
2. Try logging in with your credentials
3. Should work without errors! ✅

---

## 🔧 What the Fix Does

### **Created Helper Functions (in PUBLIC schema):**

1. **`public.get_current_user_role()`**
   - Returns current user's role
   - Uses SECURITY DEFINER to bypass RLS
   - Prevents infinite recursion

2. **`public.is_current_user_system_admin()`**
   - Returns TRUE if user is system admin
   - Bypasses RLS for checking
   - Safe from recursion

3. **`public.get_current_user_assigned_stores()`**
   - Returns array of user's assigned stores
   - Bypasses RLS
   - Used for store filtering

4. **`public.get_current_user_store_id()`**
   - Returns user's primary store_id
   - Bypasses RLS
   - Used for single-store role filtering

### **Fixed Policies:**

**Before (caused recursion):**
```sql
CREATE POLICY "rbac_super_admin_view_all_users"
ON user_profiles FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM user_profiles up  -- ❌ Queries same table!
        WHERE up.id = auth.uid()
        AND up.is_system_admin = TRUE
    )
);
```

**After (no recursion):**
```sql
CREATE POLICY "super_admin_view_all"
ON user_profiles FOR SELECT
USING (
    public.is_current_user_system_admin() = TRUE  -- ✅ Uses helper function
);
```

---

## 🧪 Testing After Fix

### **Test Business Login:**
```
1. Navigate to /dashboard/login
2. Enter credentials:
   - Email: [your admin email]
   - Password: [your password]
3. Should redirect to /dashboard
4. Should see your profile loaded
5. No console errors
```

### **Test Different Roles:**
```
✅ Super Admin - Can see all users
✅ Admin - Can see users in assigned stores
✅ Manager - Can see users in their store
✅ Staff - Can see coworkers
✅ Customer - Can see own profile only
```

---

## 🚨 If You Still Have Issues

### **Issue: Permission denied for schema auth**
**Solution:** Use migration 037 (uses PUBLIC schema, not AUTH schema)

### **Issue: Still getting infinite recursion after migration 035/036**
**Solution:** Old `user_role()` function was used across 12+ tables. Migration 037 updates ALL policies across ALL tables.

### **Issue: Cannot drop function user_role() because other objects depend on it**
**Solution:** Run migration 037 which updates all dependent policies first, then drops old functions.

### **Issue: Functions not found**
**Solution:** Make sure you ran the full migration 037

### **Issue: Permission denied**
**Solution:** Verify you're logged into Supabase with owner/admin access

### **Issue: Still getting errors**
**Solution:** Check browser console for specific errors and let me know

---

## 📝 What Caused This

The RBAC migrations (Phase 1-3) created comprehensive RLS policies that were too complex and created circular dependencies:

1. User tries to login
2. Frontend fetches user profile from `user_profiles`
3. RLS policy checks if user is admin by querying `user_profiles`
4. This triggers the same RLS policy again (infinite recursion)
5. Supabase detects the loop and throws error

**The fix:** Use `SECURITY DEFINER` functions that bypass RLS for these helper queries.

---

## ✅ Success Criteria

Login is fixed when:
- ✅ No "infinite recursion" errors
- ✅ Business login works (/dashboard/login)
- ✅ Profile loads correctly
- ✅ Dashboard displays
- ✅ No 500 errors in Network tab

---

**Run the migration now and you should be able to login!** 🚀

---

*Created: November 20, 2025*
*Migrations: 037, 038, 039*
*Note: Updates ALL policies across ALL tables (20+ policies, 12+ tables) + uses PUBLIC schema (no special permissions required)*
