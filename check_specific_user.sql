-- Check the specific user ceo@boostmysites.com status
-- First, check if the user exists in auth.users
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

-- Check all inactive profiles to see if ceo@boostmysites.com is among them
SELECT 
    id,
    name,
    is_active,
    created_at
FROM public.profiles 
WHERE is_active = false
ORDER BY created_at DESC;
