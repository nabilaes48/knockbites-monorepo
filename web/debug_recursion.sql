-- Debug queries to check for remaining recursion issues

-- 1. Check if there are any triggers on user_profiles
SELECT
    trigger_name,
    event_manipulation,
    action_statement
FROM information_schema.triggers
WHERE event_object_table = 'user_profiles';

-- 2. Check if there are any views that reference user_profiles
SELECT
    table_name,
    view_definition
FROM information_schema.views
WHERE view_definition LIKE '%user_profiles%';

-- 3. Test the helper functions directly
SELECT public.get_current_user_role();
SELECT public.is_current_user_system_admin();
SELECT public.get_current_user_assigned_stores();
SELECT public.get_current_user_store_id();

-- 4. Try to select your own profile (this should work)
SELECT * FROM user_profiles WHERE id = auth.uid();

-- 5. Check if there are any recursive CTEs or subqueries in policies
SELECT
    schemaname,
    tablename,
    policyname,
    qual
FROM pg_policies
WHERE tablename = 'user_profiles'
  AND qual LIKE '%user_profiles%';
