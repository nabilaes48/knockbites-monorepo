-- Find all policies across all tables that query user_profiles
SELECT
    schemaname,
    tablename,
    policyname,
    qual AS using_clause,
    with_check
FROM pg_policies
WHERE (
    qual LIKE '%FROM user_profiles%'
    OR qual LIKE '%FROM public.user_profiles%'
    OR with_check LIKE '%FROM user_profiles%'
    OR with_check LIKE '%FROM public.user_profiles%'
)
AND tablename != 'user_profiles'  -- Exclude user_profiles itself
ORDER BY tablename, policyname;
