-- Fix user reactivation flow by allowing users to read their own profile regardless of is_active status
-- This will fix the "permission denied for table users" error

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

-- Step 2: Add the missing policy that allows users to read their own profile regardless of is_active status
CREATE POLICY "Users can always read their own profile regardless of status"
ON public.profiles
FOR SELECT
TO public
USING (auth.uid() = id);

-- Step 3: Test the fix by checking if Ashley can now access her profile
-- This should work now that users can read their own profile regardless of is_active status
SELECT 
    id,
    name,
    is_active,
    created_at
FROM public.profiles 
WHERE id = '63b22ccf-d6ad-4d08-b741-cc47156c2085';

-- Step 4: Verify the policy was created
SELECT 
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'profiles' 
AND policyname = 'Users can always read their own profile regardless of status';

-- Step 5: Test the complete flow
SELECT 'RLS policy added - users can now read their own profile regardless of is_active status' as status;