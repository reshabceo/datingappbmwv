-- Check what columns actually exist in the profiles table
-- This will show us the real structure

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

-- 2. Check if bff_enabled column exists
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

-- 3. Check if there are any BFF-related columns
SELECT 
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'profiles'
    AND column_name LIKE '%bff%'
ORDER BY column_name;

-- 4. Show a sample row to see what data looks like
SELECT * FROM profiles LIMIT 1;
