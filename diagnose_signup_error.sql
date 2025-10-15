-- Diagnose signup error - Run this in Supabase SQL Editor
-- This will check the current database structure and identify issues

-- 1. Check if profiles table exists and its structure
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'profiles' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. Check if auth.users table exists
SELECT COUNT(*) as auth_users_count FROM auth.users LIMIT 1;

-- 3. Check profiles table constraints
SELECT 
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
LEFT JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.table_name = 'profiles' 
AND tc.table_schema = 'public';

-- 4. Check RLS policies on profiles table
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'profiles';

-- 5. Check if there are any triggers on profiles table
SELECT 
    trigger_name,
    event_manipulation,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'profiles';

-- 6. Test if we can insert into profiles table manually
-- (This will help identify the exact error)
-- DO NOT RUN THIS - Just for reference
-- INSERT INTO profiles (email, name, age) VALUES ('test@example.com', 'Test User', 25);
