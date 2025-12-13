-- Find all policies that query auth.users
SELECT
    schemaname,
    tablename,
    policyname,
    qual AS using_clause
FROM pg_policies
WHERE (
    qual LIKE '%FROM auth.users%'
    OR qual LIKE '%FROM auth\.users%'
    OR qual LIKE '%JOIN auth.users%'
    OR qual LIKE '%SELECT email FROM auth.users%'
)
ORDER BY tablename, policyname;
