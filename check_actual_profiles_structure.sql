-- Check the ACTUAL structure of the profiles table
-- This will show us exactly what columns exist so we can build the function correctly

-- 1. Get all columns in the profiles table
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'profiles'
ORDER BY ordinal_position;

-- 2. Get a sample row to see what data looks like
SELECT * FROM profiles LIMIT 1;

-- 3. Check if bff_enabled column exists
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' 
                AND table_name = 'profiles' 
                AND column_name = 'bff_enabled'
        ) THEN 'bff_enabled column EXISTS'
        ELSE 'bff_enabled column DOES NOT EXIST'
    END as bff_enabled_status;

-- 4. Check what columns are actually used in the app
-- Look for any existing functions that work with profiles
SELECT 
    routine_name,
    routine_definition
FROM information_schema.routines 
WHERE routine_schema = 'public' 
    AND routine_name LIKE '%profile%'
    AND routine_type = 'FUNCTION'
LIMIT 3;
