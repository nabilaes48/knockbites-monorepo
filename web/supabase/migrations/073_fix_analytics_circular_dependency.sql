-- =====================================================
-- Migration 073: Fix Analytics Circular Dependency
-- Version: 1.0
-- Date: 2025-12-15
-- Purpose: Fix circular dependency between get_business_insights
--          and get_business_insights_secure functions
-- =====================================================

-- The problem:
-- Migration 048 created get_business_insights_secure that calls get_business_insights
-- Migration 058 recreated get_business_insights to call get_business_insights_secure
-- This creates infinite recursion and breaks analytics

-- The fix:
-- Make get_business_insights_secure contain the actual implementation
-- Then get_business_insights can safely wrap it

-- =====================================================
-- STEP 1: Drop functions to clean slate
-- =====================================================

DROP FUNCTION IF EXISTS public.get_business_insights(BIGINT);
DROP FUNCTION IF EXISTS public.get_business_insights_secure(BIGINT);

-- =====================================================
-- STEP 1.5: Ensure can_access_analytics exists
-- This function was defined in migration 048 but may be missing
-- =====================================================

CREATE OR REPLACE FUNCTION public.can_access_analytics(p_store_id BIGINT DEFAULT NULL)
RETURNS BOOLEAN AS $$
DECLARE
    v_role TEXT;
    v_user_store_id BIGINT;
    v_assigned_stores BIGINT[];
BEGIN
    -- Get user info
    SELECT role, store_id, assigned_stores
    INTO v_role, v_user_store_id, v_assigned_stores
    FROM user_profiles
    WHERE id = auth.uid();

    -- No profile = no access
    IF v_role IS NULL THEN
        RETURN FALSE;
    END IF;

    -- Customers cannot access analytics
    IF v_role = 'customer' THEN
        RETURN FALSE;
    END IF;

    -- Super admin can access all
    IF v_role = 'super_admin' THEN
        RETURN TRUE;
    END IF;

    -- Staff must have analytics permission
    IF v_role = 'staff' THEN
        IF NOT (
            SELECT permissions @> '["analytics"]'::jsonb
            FROM user_profiles WHERE id = auth.uid()
        ) THEN
            RETURN FALSE;
        END IF;
    END IF;

    -- If no specific store requested, allow general access
    IF p_store_id IS NULL THEN
        RETURN TRUE;
    END IF;

    -- Check store access
    RETURN p_store_id = v_user_store_id
        OR p_store_id = ANY(v_assigned_stores);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

GRANT EXECUTE ON FUNCTION public.can_access_analytics(BIGINT) TO authenticated;

-- =====================================================
-- STEP 2: Create get_business_insights_secure with actual implementation
-- =====================================================

CREATE OR REPLACE FUNCTION public.get_business_insights_secure(p_store_id BIGINT)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_result JSON;
BEGIN
  -- Check access first
  IF NOT public.can_access_analytics(p_store_id) THEN
    RAISE EXCEPTION 'Access denied to store analytics';
  END IF;

  -- Build the insights JSON (same logic as original get_business_insights)
  SELECT json_build_object(
    'peak_hour', (
      SELECT hour
      FROM analytics_peak_hours
      WHERE store_id = p_store_id
      ORDER BY order_count DESC
      LIMIT 1
    ),
    'busiest_day', (
      SELECT TRIM(day_name)
      FROM analytics_day_of_week
      WHERE store_id = p_store_id
      ORDER BY order_count DESC
      LIMIT 1
    ),
    'top_category', (
      SELECT category
      FROM analytics_category_distribution
      WHERE category IS NOT NULL
      ORDER BY order_count DESC
      LIMIT 1
    ),
    'customer_retention', (
      SELECT repeat_rate
      FROM analytics_customer_insights
      WHERE store_id = p_store_id
    ),
    'avg_wait_time', (
      SELECT ROUND(AVG(avg_processing_minutes), 1)
      FROM analytics_order_funnel
      WHERE store_id = p_store_id
      AND status IN ('preparing', 'ready')
    )
  ) INTO v_result;

  RETURN v_result;
END;
$$;

COMMENT ON FUNCTION public.get_business_insights_secure(BIGINT) IS
'Secure version of get_business_insights with access control. Returns JSON with peak_hour, busiest_day, top_category, customer_retention, avg_wait_time.';

-- =====================================================
-- STEP 3: Create get_business_insights wrapper
-- =====================================================

CREATE OR REPLACE FUNCTION public.get_business_insights(p_store_id BIGINT)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Delegate to secure version which validates access and returns data
  RETURN public.get_business_insights_secure(p_store_id);
END;
$$;

COMMENT ON FUNCTION public.get_business_insights(BIGINT) IS
'Returns business insights for a store. Delegates to get_business_insights_secure for access control.';

-- =====================================================
-- STEP 4: Grant permissions
-- =====================================================

GRANT EXECUTE ON FUNCTION public.get_business_insights_secure(BIGINT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_business_insights(BIGINT) TO authenticated;

-- =====================================================
-- SUCCESS! Circular dependency fixed.
--
-- Changes:
-- - get_business_insights_secure now contains actual implementation
-- - get_business_insights safely wraps the secure version
-- - Both return JSON as frontend expects
-- - Access control is enforced via can_access_analytics()
-- =====================================================
