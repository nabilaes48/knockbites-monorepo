-- =====================================================
-- Migration 070: CRITICAL SECURITY HOTFIX
-- Version: 1.0
-- Date: 2025-01-XX
--
-- MUST BE DEPLOYED BEFORE ANY PRODUCTION TRAFFIC
-- This migration fixes critical RLS vulnerabilities
-- =====================================================

BEGIN;

-- =====================================================
-- 1. Add tracking token for secure anonymous order access
-- =====================================================

ALTER TABLE orders
ADD COLUMN IF NOT EXISTS tracking_token UUID DEFAULT gen_random_uuid();

-- Ensure existing orders have tokens
UPDATE orders
SET tracking_token = gen_random_uuid()
WHERE tracking_token IS NULL;

-- Make column NOT NULL going forward
ALTER TABLE orders
ALTER COLUMN tracking_token SET NOT NULL;

-- Index for fast token lookups
CREATE INDEX IF NOT EXISTS idx_orders_tracking_token
ON orders(tracking_token);

-- =====================================================
-- 2. Fix CRITICAL: orders UPDATE policy
--    OLD: Anyone (anon/auth) can update ANY order
--    NEW: Only authenticated staff can update their store's orders
-- =====================================================

DROP POLICY IF EXISTS "orders_update_status" ON orders;

CREATE POLICY "orders_update_staff_only"
ON orders FOR UPDATE
TO authenticated
USING (
  -- Must be staff role or higher
  public.get_current_user_role() IN ('super_admin', 'admin', 'manager', 'staff')
  AND (
    -- Super admin can update any order
    public.is_current_user_system_admin()
    OR
    -- Others can only update orders from their assigned stores
    store_id = ANY(public.get_current_user_assigned_stores())
  )
)
WITH CHECK (
  -- Same conditions for what values can be set
  public.get_current_user_role() IN ('super_admin', 'admin', 'manager', 'staff')
  AND (
    public.is_current_user_system_admin()
    OR store_id = ANY(public.get_current_user_assigned_stores())
  )
);

-- =====================================================
-- 3. Fix CRITICAL: orders SELECT for anonymous
--    OLD: Anonymous can view ALL orders (USING true)
--    NEW: Anonymous can only view orders with valid tracking token
-- =====================================================

DROP POLICY IF EXISTS "orders_select_anon" ON orders;

-- Create function to get tracking token from request
CREATE OR REPLACE FUNCTION public.get_request_tracking_token()
RETURNS UUID
LANGUAGE sql
STABLE
AS $$
  SELECT NULLIF(
    COALESCE(
      -- Try header first
      current_setting('request.headers', true)::json->>'x-tracking-token',
      -- Then try query parameter (passed via PostgREST)
      current_setting('request.query.token', true)
    ),
    ''
  )::UUID
$$;

-- Anonymous can ONLY view orders they have the tracking token for
CREATE POLICY "orders_select_by_token_anon"
ON orders FOR SELECT
TO anon
USING (
  -- Must provide valid tracking token
  tracking_token = public.get_request_tracking_token()
);

-- =====================================================
-- 4. Fix order_items SELECT to follow order access
-- =====================================================

DROP POLICY IF EXISTS "order_items_public_read" ON order_items;

CREATE POLICY "order_items_select_with_order"
ON order_items FOR SELECT
TO anon, authenticated
USING (
  EXISTS (
    SELECT 1 FROM orders o
    WHERE o.id = order_items.order_id
    AND (
      -- Anonymous: must have valid tracking token for this order
      (
        (SELECT auth.role()) = 'anon'
        AND o.tracking_token = public.get_request_tracking_token()
      )
      OR
      -- Authenticated customer: owns the order
      (
        (SELECT auth.role()) = 'authenticated'
        AND (
          o.customer_id = (SELECT auth.uid())
          OR o.customer_email = (SELECT email FROM auth.users WHERE id = (SELECT auth.uid()))
        )
      )
      OR
      -- Staff: can view orders from their stores
      (
        (SELECT auth.role()) = 'authenticated'
        AND public.get_current_user_role() IN ('super_admin', 'admin', 'manager', 'staff')
        AND (
          public.is_current_user_system_admin()
          OR o.store_id = ANY(public.get_current_user_assigned_stores())
        )
      )
    )
  )
);

-- =====================================================
-- 5. Fix order_items INSERT - must be during active checkout
-- =====================================================

DROP POLICY IF EXISTS "order_items_insert_public" ON order_items;

CREATE POLICY "order_items_insert_with_valid_order"
ON order_items FOR INSERT
TO anon, authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM orders o
    WHERE o.id = order_id
    -- Order must be recent (within checkout window)
    AND o.created_at > NOW() - INTERVAL '10 minutes'
    -- Order must still be pending
    AND o.status = 'pending'
  )
);

-- =====================================================
-- 6. Ensure orders INSERT still works for guest checkout
--    (This should already be permissive, just verifying)
-- =====================================================

DROP POLICY IF EXISTS "orders_insert_public" ON orders;

CREATE POLICY "orders_insert_public"
ON orders FOR INSERT
TO anon, authenticated
WITH CHECK (
  -- Anyone can create orders (guest checkout)
  -- But server-side validation ensures proper pricing
  true
);

-- =====================================================
-- 7. Add audit logging for sensitive operations
-- =====================================================

CREATE TABLE IF NOT EXISTS security_audit_log (
  id BIGSERIAL PRIMARY KEY,
  event_type TEXT NOT NULL,
  user_id UUID,
  user_role TEXT,
  target_table TEXT,
  target_id TEXT,
  old_values JSONB,
  new_values JSONB,
  ip_address TEXT,
  user_agent TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for querying audit logs
CREATE INDEX IF NOT EXISTS idx_audit_log_created
ON security_audit_log(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_audit_log_user
ON security_audit_log(user_id, created_at DESC);

-- Function to log order status changes
CREATE OR REPLACE FUNCTION log_order_status_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF OLD.status IS DISTINCT FROM NEW.status THEN
    INSERT INTO security_audit_log (
      event_type,
      user_id,
      user_role,
      target_table,
      target_id,
      old_values,
      new_values
    ) VALUES (
      'order_status_change',
      auth.uid(),
      public.get_current_user_role(),
      'orders',
      NEW.id::TEXT,
      jsonb_build_object('status', OLD.status),
      jsonb_build_object('status', NEW.status)
    );
  END IF;
  RETURN NEW;
END;
$$;

-- Attach trigger
DROP TRIGGER IF EXISTS tr_log_order_status ON orders;
CREATE TRIGGER tr_log_order_status
AFTER UPDATE ON orders
FOR EACH ROW
EXECUTE FUNCTION log_order_status_change();

-- =====================================================
-- 8. Add rate limiting table for future use
-- =====================================================

CREATE TABLE IF NOT EXISTS rate_limit_log (
  id BIGSERIAL PRIMARY KEY,
  identifier TEXT NOT NULL, -- IP address or user ID
  endpoint TEXT NOT NULL,
  request_count INT DEFAULT 1,
  window_start TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_rate_limit_lookup
ON rate_limit_log(identifier, endpoint, window_start DESC);

COMMIT;

-- =====================================================
-- VERIFICATION QUERIES
-- Run these after migration to confirm security fixes
-- =====================================================

-- Test 1: Verify anon cannot select all orders
-- Expected: Returns 0 rows (no token provided)
-- SELECT * FROM orders LIMIT 5;

-- Test 2: Verify anon cannot update orders
-- Expected: ERROR: permission denied
-- UPDATE orders SET status = 'cancelled' WHERE id = 1;

-- Test 3: Verify staff can only see their store orders
-- (Run as authenticated staff user)
-- SELECT COUNT(*) FROM orders; -- Should only count their store

-- =====================================================
-- SUCCESS! Migration 070 complete.
--
-- Changes:
-- 1. Added tracking_token column to orders
-- 2. Fixed orders UPDATE - staff only, store restricted
-- 3. Fixed orders SELECT for anon - token required
-- 4. Fixed order_items SELECT - follows order access
-- 5. Fixed order_items INSERT - checkout window only
-- 6. Added security audit logging
-- 7. Added rate limit infrastructure
--
-- NEXT STEPS:
-- 1. Deploy secure-checkout Edge Function
-- 2. Update frontend to use tracking tokens in URLs
-- 3. Update iOS apps to use new order tracking flow
-- =====================================================
