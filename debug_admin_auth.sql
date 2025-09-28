-- Debug admin authentication and RLS policies
-- Check if admin user exists in auth.users
SELECT 
    id,
    email,
    created_at,
    email_confirmed_at,
    last_sign_in_at
FROM auth.users 
WHERE email = 'admin@datingapp.com';

-- Check current RLS policies on profiles table
SELECT 
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'profiles'
ORDER BY policyname;

-- Test if admin can see profiles (this should work if RLS is correct)
SELECT 
    COUNT(*) as total_profiles_visible_to_admin,
    COUNT(CASE WHEN is_active = true THEN 1 END) as active_profiles_visible,
    COUNT(CASE WHEN is_active = false THEN 1 END) as inactive_profiles_visible
FROM public.profiles;

-- Check if there are any RLS policies that might be blocking access
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename = 'profiles';
