-- =====================================================
-- Migration 040: Fix Orders Policies - Remove auth.users Access
-- Version: 1.0
-- Date: 2025-11-20
-- Purpose: Fix orders policies that query auth.users (causing permission denied)
-- =====================================================

-- =====================================================
-- STEP 1: Create helper function to get current user email
-- =====================================================

CREATE OR REPLACE FUNCTION public.get_current_user_email()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    user_email TEXT;
BEGIN
    SELECT email INTO user_email
    FROM auth.users
    WHERE id = auth.uid();

    RETURN user_email;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_current_user_email() TO authenticated;

-- =====================================================
-- STEP 2: Drop old policies that query auth.users
-- =====================================================

DROP POLICY IF EXISTS "Customers can view own orders" ON orders;
DROP POLICY IF EXISTS "rbac_customers_view_own_orders" ON orders;

-- =====================================================
-- STEP 3: Create fixed policies using helper function
-- =====================================================

-- Customers can view their own orders (by user_id or email)
CREATE POLICY "customers_view_own_orders"
ON orders FOR SELECT
TO authenticated
USING (
    public.get_current_user_role() = 'customer'
    AND (
        user_id = auth.uid()
        OR customer_email = public.get_current_user_email()
    )
);

-- Legacy policy for customers who ordered before login (match by email/phone)
CREATE POLICY "customers_view_orders_by_email"
ON orders FOR SELECT
TO authenticated
USING (
    customer_email = public.get_current_user_email()
);

-- =====================================================
-- SUCCESS! Fixed orders policies.
--
-- Changes:
-- ✅ Created get_current_user_email() with SECURITY DEFINER
-- ✅ Removed direct queries to auth.users from policies
-- ✅ Customers can still view their orders by user_id or email
-- ✅ No more "permission denied for table users" error
-- =====================================================
