-- Check the actual structure of the profiles table
-- This will help us understand what columns exist

-- Get all columns from profiles table
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'profiles' 
    AND table_schema = 'public'
ORDER BY ordinal_position;

-- Also check if there are any other tables with similar names
SELECT 
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_schema = 'public' 
    AND table_name LIKE '%profile%'
ORDER BY table_name;