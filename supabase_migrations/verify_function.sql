-- Quick verification script to check if the add_brand_to_enum function exists
-- Run this in Supabase SQL Editor to verify the function was created successfully

-- Check if the function exists
SELECT 
    p.proname AS function_name,
    pg_get_function_arguments(p.oid) AS arguments,
    pg_get_function_result(p.oid) AS return_type,
    CASE 
        WHEN p.prosecdef THEN 'SECURITY DEFINER'
        ELSE 'SECURITY INVOKER'
    END AS security_type
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
  AND p.proname = 'add_brand_to_enum';

-- Check the function permissions
SELECT 
    p.proname AS function_name,
    r.rolname AS grantee,
    has_function_privilege(r.rolname, p.oid, 'EXECUTE') AS can_execute
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
CROSS JOIN pg_roles r
WHERE n.nspname = 'public'
  AND p.proname = 'add_brand_to_enum'
  AND r.rolname IN ('authenticated', 'anon', 'public')
ORDER BY r.rolname;

-- Test the function (this will add 'test_brand' if it doesn't exist)
-- Uncomment the line below to test:
-- SELECT add_brand_to_enum('test_brand');

