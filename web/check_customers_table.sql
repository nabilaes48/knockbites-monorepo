-- Check if customers table exists and its structure
SELECT
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'customers'
ORDER BY ordinal_position;

-- Check existing policies on customers
SELECT policyname, qual
FROM pg_policies
WHERE tablename = 'customers';
