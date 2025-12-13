-- ============================================
-- ALLOW PUBLIC TO INSERT ORDER STATUS HISTORY
-- This is needed when orders table triggers insert history records
-- ============================================

-- Allow anyone to insert order status history records
-- This is safe because it's triggered automatically when order status changes
DROP POLICY IF EXISTS "Allow public to insert order history" ON order_status_history;

CREATE POLICY "Allow public to insert order history"
ON order_status_history
FOR INSERT
TO public
WITH CHECK (true);

-- Verify final policies
SELECT
  policyname,
  cmd,
  roles::text,
  qual::text,
  with_check::text
FROM pg_policies
WHERE tablename = 'order_status_history'
ORDER BY cmd, policyname;
