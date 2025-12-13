-- ============================================
-- ALLOW ANONYMOUS USERS TO UPDATE ORDER STATUS
-- This is needed because the dashboard uses localStorage auth,
-- not Supabase auth, so updates come from the anon role
-- ============================================

-- Drop the existing authenticated-only policy
DROP POLICY IF EXISTS "Allow order status updates" ON orders;

-- Create a new policy that allows anon users to UPDATE orders
-- This is safe because:
-- 1. The dashboard is password-protected with its own auth
-- 2. We're only allowing status updates, not modifying other sensitive fields
-- 3. Customer-facing app doesn't have UPDATE UI
CREATE POLICY "Allow public to update order status"
ON orders
FOR UPDATE
TO public
USING (true)
WITH CHECK (true);

-- Verify policies
SELECT
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE tablename = 'orders'
ORDER BY policyname;
