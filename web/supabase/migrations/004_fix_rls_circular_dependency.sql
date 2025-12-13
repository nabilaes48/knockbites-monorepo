-- ============================================
-- FIX RLS CIRCULAR DEPENDENCY
-- ============================================
-- The helper functions (user_role, user_store_id, has_permission)
-- were causing circular dependencies when RLS policies called them.
--
-- Solution: Recreate these functions to bypass RLS using SECURITY DEFINER
-- and ensure they don't trigger RLS checks when querying user_profiles.

-- Drop existing functions
DROP FUNCTION IF EXISTS public.user_role();
DROP FUNCTION IF EXISTS public.user_store_id();
DROP FUNCTION IF EXISTS public.has_permission(TEXT);

-- Recreate user_role function with proper RLS bypass
CREATE OR REPLACE FUNCTION public.user_role()
RETURNS TEXT AS $$
BEGIN
  -- SECURITY DEFINER allows this function to bypass RLS
  -- This prevents circular dependency when RLS policies call this function
  RETURN (
    SELECT role::TEXT
    FROM public.user_profiles
    WHERE id = auth.uid()
    LIMIT 1
  );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- Recreate user_store_id function with proper RLS bypass
CREATE OR REPLACE FUNCTION public.user_store_id()
RETURNS INTEGER AS $$
BEGIN
  RETURN (
    SELECT store_id
    FROM public.user_profiles
    WHERE id = auth.uid()
    LIMIT 1
  );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- Recreate has_permission function with proper RLS bypass
CREATE OR REPLACE FUNCTION public.has_permission(permission_name TEXT)
RETURNS BOOLEAN AS $$
DECLARE
  user_permissions TEXT[];
  user_role_value TEXT;
BEGIN
  -- Get user's role and permissions
  SELECT role, permissions
  INTO user_role_value, user_permissions
  FROM public.user_profiles
  WHERE id = auth.uid()
  LIMIT 1;

  -- Super admin and admin have all permissions
  IF user_role_value IN ('super_admin', 'admin') THEN
    RETURN TRUE;
  END IF;

  -- Check if permission exists in user's permissions array
  RETURN permission_name = ANY(user_permissions);
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- Grant execute permissions to authenticated users
GRANT EXECUTE ON FUNCTION public.user_role() TO authenticated;
GRANT EXECUTE ON FUNCTION public.user_store_id() TO authenticated;
GRANT EXECUTE ON FUNCTION public.has_permission(TEXT) TO authenticated;
