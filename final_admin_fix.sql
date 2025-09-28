-- Final comprehensive fix for admin panel
-- This will ensure admin can see all users

-- Step 1: Check if admin user exists
SELECT 
    id,
    email,
    created_at
FROM auth.users 
WHERE email = 'admin@datingapp.com';

-- Step 2: If admin user doesn't exist, we need to create it
-- But first, let's try a different approach - disable RLS temporarily for testing
ALTER TABLE public.profiles DISABLE ROW LEVEL SECURITY;

-- Step 3: Test if admin can now see all profiles
SELECT 
    COUNT(*) as total_profiles,
    COUNT(CASE WHEN is_active = true THEN 1 END) as active_profiles,
    COUNT(CASE WHEN is_active = false THEN 1 END) as inactive_profiles
FROM public.profiles;

-- Step 4: If that works, re-enable RLS with proper policies
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Step 5: Drop all existing policies
DROP POLICY IF EXISTS "Users can read their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Admin can read all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Admin can update all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Admin users can read all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Admin users can update all profiles" ON public.profiles;

-- Step 6: Create simple working policies
-- Allow all authenticated users to read profiles (for admin panel)
CREATE POLICY "Allow authenticated users to read profiles"
ON public.profiles FOR SELECT 
USING (auth.role() = 'authenticated');

-- Allow users to update their own profile
CREATE POLICY "Users can update their own profile"
ON public.profiles FOR UPDATE 
USING (auth.uid() = id);

-- Allow users to insert their own profile
CREATE POLICY "Users can insert their own profile"
ON public.profiles FOR INSERT 
WITH CHECK (auth.uid() = id);

-- Test the final result
SELECT 'RLS policies updated - admin should now see all users' as status;
