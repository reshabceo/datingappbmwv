-- Debug admin panel permissions
-- Check if RLS is enabled on profiles table
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE tablename = 'profiles';

-- Check current RLS policies on profiles table
SELECT 
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'profiles';

-- Test admin user access to profiles
-- First, let's see what the current user can access
SELECT 
    COUNT(*) as total_profiles_visible,
    COUNT(CASE WHEN is_active = true THEN 1 END) as active_profiles_visible,
    COUNT(CASE WHEN is_active = false THEN 1 END) as inactive_profiles_visible
FROM public.profiles;

-- Check if there are any RLS policies that might be filtering results
SELECT 
    id,
    name,
    is_active,
    created_at
FROM public.profiles 
ORDER BY created_at DESC
LIMIT 10;
