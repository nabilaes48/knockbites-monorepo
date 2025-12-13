-- Check what the trigger functions do
SELECT
    routine_name,
    routine_definition
FROM information_schema.routines
WHERE routine_name IN (
    'auto_log_role_change',
    'auto_log_user_creation',
    'update_updated_at'
)
AND routine_schema = 'public';
