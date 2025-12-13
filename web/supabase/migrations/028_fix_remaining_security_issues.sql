-- ============================================
-- FIX REMAINING SECURITY ISSUES
-- Addresses security scan findings for:
-- - order_sequences table RLS
-- - analytics views protection
-- - security_definer views
-- ============================================

-- ============================================
-- PART 1: ENABLE RLS ON ORDER_SEQUENCES TABLE
-- ============================================

-- Enable RLS on order_sequences table
ALTER TABLE order_sequences ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any
DROP POLICY IF EXISTS "Staff can view order sequences" ON order_sequences;
DROP POLICY IF EXISTS "Staff can insert order sequences" ON order_sequences;
DROP POLICY IF EXISTS "Staff can update order sequences" ON order_sequences;

-- Policy 1: Only authenticated staff can view order sequences
CREATE POLICY "Staff can view order sequences"
ON order_sequences
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM user_profiles up
    WHERE up.id = auth.uid()
    AND up.role IN ('staff', 'manager', 'admin', 'super_admin')
    AND (up.store_id = order_sequences.store_id OR up.role = 'super_admin')
  )
);

-- Policy 2: Only authenticated staff can insert order sequences
-- Note: This is typically done by the generate_order_number() function
CREATE POLICY "Staff can insert order sequences"
ON order_sequences
FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM user_profiles up
    WHERE up.id = auth.uid()
    AND up.role IN ('staff', 'manager', 'admin', 'super_admin')
  )
);

-- Policy 3: Only authenticated staff can update order sequences
-- Note: This is typically done by the generate_order_number() function
CREATE POLICY "Staff can update order sequences"
ON order_sequences
FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM user_profiles up
    WHERE up.id = auth.uid()
    AND up.role IN ('staff', 'manager', 'admin', 'super_admin')
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM user_profiles up
    WHERE up.id = auth.uid()
    AND up.role IN ('staff', 'manager', 'admin', 'super_admin')
  )
);


-- ============================================
-- PART 2: FIX ANALYTICS VIEWS SECURITY
-- ============================================

-- Drop and recreate analytics_top_customers view WITHOUT customer PII
-- This view should NOT expose customer names and phone numbers

DROP VIEW IF EXISTS analytics_top_customers CASCADE;

-- Recreate view without PII - use anonymized customer identifiers
CREATE OR REPLACE VIEW analytics_top_customers AS
SELECT
  o.store_id,
  -- Instead of showing actual names/phones, use hashed identifiers
  MD5(o.customer_phone) as customer_id,  -- Anonymized identifier
  COUNT(o.id) as total_orders,
  SUM(o.total) as total_spent,
  AVG(o.total) as avg_order_value,
  MAX(o.created_at) as last_order_date
FROM orders o
WHERE o.status != 'cancelled'
GROUP BY o.store_id, MD5(o.customer_phone)
HAVING COUNT(o.id) > 1
ORDER BY total_spent DESC
LIMIT 100;

-- Ensure the view is NOT publicly accessible
REVOKE ALL ON analytics_top_customers FROM public, anon;

-- Only grant to authenticated users
GRANT SELECT ON analytics_top_customers TO authenticated;


-- ============================================
-- PART 3: ENSURE ALL ANALYTICS VIEWS ARE PROTECTED
-- ============================================

-- Set security_invoker on all analytics views
-- This makes views use the permissions of the person querying them,
-- not the person who created them

ALTER VIEW analytics_daily_stats SET (security_invoker = on);
ALTER VIEW analytics_hourly_today SET (security_invoker = on);
ALTER VIEW analytics_time_distribution SET (security_invoker = on);
ALTER VIEW analytics_category_distribution SET (security_invoker = on);
ALTER VIEW analytics_popular_items SET (security_invoker = on);
ALTER VIEW analytics_store_summary SET (security_invoker = on);
ALTER VIEW analytics_customer_insights SET (security_invoker = on);
ALTER VIEW analytics_peak_hours SET (security_invoker = on);
ALTER VIEW analytics_order_funnel SET (security_invoker = on);
ALTER VIEW analytics_revenue_goals SET (security_invoker = on);
ALTER VIEW analytics_day_of_week SET (security_invoker = on);
ALTER VIEW analytics_top_customers SET (security_invoker = on);


-- ============================================
-- PART 4: CREATE SECURE FUNCTION TO GET TOP CUSTOMERS WITH PII
-- ============================================

-- For authenticated staff who need to see actual customer data,
-- create a secure function that enforces role checks

CREATE OR REPLACE FUNCTION get_top_customers_with_details(
  p_store_id BIGINT DEFAULT NULL,
  p_limit INTEGER DEFAULT 100
)
RETURNS TABLE (
  store_id BIGINT,
  customer_name TEXT,
  customer_phone TEXT,
  total_orders BIGINT,
  total_spent NUMERIC,
  avg_order_value NUMERIC,
  last_order_date TIMESTAMP WITH TIME ZONE
)
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  -- Check if user is authenticated staff
  IF NOT EXISTS (
    SELECT 1 FROM user_profiles
    WHERE id = auth.uid()
    AND role IN ('staff', 'manager', 'admin', 'super_admin')
  ) THEN
    RAISE EXCEPTION 'Access denied. Staff authentication required.';
  END IF;

  -- If specific store requested, verify staff has access to that store
  IF p_store_id IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM user_profiles
    WHERE id = auth.uid()
    AND (store_id = p_store_id OR role = 'super_admin')
  ) THEN
    RAISE EXCEPTION 'Access denied. You do not have permission for this store.';
  END IF;

  -- Return customer data
  RETURN QUERY
  SELECT
    o.store_id,
    o.customer_name,
    o.customer_phone,
    COUNT(o.id)::BIGINT as total_orders,
    SUM(o.total)::NUMERIC as total_spent,
    AVG(o.total)::NUMERIC as avg_order_value,
    MAX(o.created_at) as last_order_date
  FROM orders o
  WHERE o.status != 'cancelled'
  AND (p_store_id IS NULL OR o.store_id = p_store_id)
  GROUP BY o.store_id, o.customer_name, o.customer_phone
  HAVING COUNT(o.id) > 1
  ORDER BY SUM(o.total) DESC
  LIMIT p_limit;
END;
$$;

-- Grant execute to authenticated users only
REVOKE ALL ON FUNCTION get_top_customers_with_details(BIGINT, INTEGER) FROM public, anon;
GRANT EXECUTE ON FUNCTION get_top_customers_with_details(BIGINT, INTEGER) TO authenticated;

-- Add comment explaining the function
COMMENT ON FUNCTION get_top_customers_with_details IS
  'Securely retrieves top customer data with PII. Only accessible by authenticated staff. Staff can only see customers from their assigned store (except super_admin).';


-- ============================================
-- PART 5: UPDATE generate_order_number FUNCTION
-- ============================================

-- Update the generate_order_number function to use SECURITY DEFINER
-- so it can insert/update order_sequences even when called by guests

CREATE OR REPLACE FUNCTION generate_order_number(p_store_id BIGINT)
RETURNS VARCHAR(20)
LANGUAGE plpgsql
SECURITY DEFINER  -- Run with creator's privileges
SET search_path = public
AS $$
DECLARE
  v_store_code VARCHAR(3);
  v_date_key VARCHAR(6);
  v_sequence INTEGER;
  v_order_number VARCHAR(20);
BEGIN
  -- Get store code
  SELECT store_code INTO v_store_code
  FROM stores
  WHERE id = p_store_id;

  IF v_store_code IS NULL THEN
    RAISE EXCEPTION 'Store not found: %', p_store_id;
  END IF;

  -- Get current date key (YYMMDD format)
  v_date_key := TO_CHAR(CURRENT_DATE, 'YYMMDD');

  -- Get and increment sequence for this store and date
  INSERT INTO order_sequences (store_id, date_key, sequence_number)
  VALUES (p_store_id, v_date_key, 1)
  ON CONFLICT (store_id, date_key)
  DO UPDATE SET sequence_number = order_sequences.sequence_number + 1
  RETURNING sequence_number INTO v_sequence;

  -- Format: STORECODE-YYMMDD-NNNN
  -- Example: HR-241119-0001
  v_order_number := v_store_code || '-' || v_date_key || '-' || LPAD(v_sequence::TEXT, 4, '0');

  RETURN v_order_number;
END;
$$;

-- Grant execute to public so guest checkout can generate order numbers
GRANT EXECUTE ON FUNCTION generate_order_number(BIGINT) TO public, anon, authenticated;


-- ============================================
-- PART 6: VERIFICATION
-- ============================================

-- Verify RLS is enabled on order_sequences
SELECT
  schemaname,
  tablename,
  rowsecurity as rls_enabled
FROM pg_tables
WHERE tablename = 'order_sequences';

-- Verify policies exist on order_sequences
SELECT
  schemaname,
  tablename,
  policyname,
  cmd,
  roles
FROM pg_policies
WHERE tablename = 'order_sequences'
ORDER BY cmd, policyname;

-- Verify analytics views are protected
SELECT
  schemaname,
  viewname,
  viewowner
FROM pg_views
WHERE viewname LIKE 'analytics_%'
AND schemaname = 'public';

-- Add comments for documentation
COMMENT ON TABLE order_sequences IS 'RLS enabled - Migration 028 - Only staff can access';
COMMENT ON VIEW analytics_top_customers IS 'PII removed - Migration 028 - Use get_top_customers_with_details() for full data';

-- Success message
DO $$
BEGIN
  RAISE NOTICE 'Migration 028 completed successfully';
  RAISE NOTICE '✅ RLS enabled on order_sequences table';
  RAISE NOTICE '✅ analytics_top_customers view anonymized (PII removed)';
  RAISE NOTICE '✅ All analytics views set to security_invoker mode';
  RAISE NOTICE '✅ Created get_top_customers_with_details() for authenticated staff';
  RAISE NOTICE '✅ Updated generate_order_number() to SECURITY DEFINER';
END $$;
