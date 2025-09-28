-- Fix reactivation update issue
-- The problem is that RLS policies are blocking the update to is_active field

-- Step 1: Check current RLS policies on profiles table
SELECT 
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'profiles'
ORDER BY policyname;

-- Step 2: Drop existing update policies that might be blocking
DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Admin can update all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Admin users can update all profiles" ON public.profiles;

-- Step 3: Create a comprehensive update policy that allows users to update their own profile
CREATE POLICY "Users can update their own profile including is_active"
ON public.profiles
FOR UPDATE
TO public
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- Step 4: Also create a policy for admin users to update any profile
CREATE POLICY "Admin can update any profile"
ON public.profiles
FOR UPDATE
TO public
USING (
    EXISTS (
        SELECT 1 FROM auth.users 
        WHERE auth.users.id = auth.uid() 
        AND auth.users.email = 'admin@datingapp.com'
    )
);

-- Step 5: Test the update manually to make sure it works
UPDATE public.profiles 
SET is_active = true, last_seen = NOW()
WHERE id = '63b22ccf-d6ad-4d08-b741-cc47156c2085';

-- Step 6: Verify the update worked
SELECT 
    id,
    name,
    is_active,
    created_at,
    last_seen
FROM public.profiles 
WHERE id = '63b22ccf-d6ad-4d08-b741-cc47156c2085';

-- Step 7: Check the final policies
SELECT 
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'profiles'
ORDER BY policyname;
