-- ============================================
-- SIMPLIFY ORDER POLICIES
-- Remove all the complex role-based UPDATE policies
-- and keep only the simple public UPDATE policy
-- ============================================

-- Drop all existing UPDATE policies that might conflict
DROP POLICY IF EXISTS "Staff can cancel orders" ON orders;
DROP POLICY IF EXISTS "Staff can update store orders" ON orders;
DROP POLICY IF EXISTS "Allow order status updates" ON orders;

-- Keep only the simple public UPDATE policy
-- (This was created in migration 019, just ensuring it exists)
DROP POLICY IF EXISTS "Allow public to update order status" ON orders;

CREATE POLICY "Allow public to update order status"
ON orders
FOR UPDATE
TO public
USING (true)
WITH CHECK (true);

-- Verify final policies
SELECT
  policyname,
  cmd,
  roles::text,
  qual::text,
  with_check::text
FROM pg_policies
WHERE tablename = 'orders'
ORDER BY cmd, policyname;
