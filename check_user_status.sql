-- Check the current status of the user ceo@boostmysites.com
-- First, let's check if the user exists in auth.users
SELECT 
    id,
    email,
    created_at,
    email_confirmed_at,
    last_sign_in_at
FROM auth.users 
WHERE email = 'ceo@boostmysites.com';

-- Then check if the profile exists in profiles table
SELECT 
    id,
    name,
    is_active,
    created_at,
    last_seen
FROM public.profiles 
WHERE id IN (
    SELECT id FROM auth.users WHERE email = 'ceo@boostmysites.com'
);

-- Check all profiles with is_active = false
SELECT 
    id,
    name,
    is_active,
    created_at
FROM public.profiles 
WHERE is_active = false
ORDER BY created_at DESC;

-- Count active vs inactive users
SELECT 
    COUNT(*) as total_users,
    SUM(CASE WHEN is_active = true THEN 1 ELSE 0 END) as active_users,
    SUM(CASE WHEN is_active = false THEN 1 ELSE 0 END) as inactive_users
FROM public.profiles;
