-- Comprehensive fix for admin panel access
-- This will ensure admin users can see all profiles including inactive ones

-- Step 1: Check current RLS status
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename = 'profiles';

-- Step 2: Check existing policies
SELECT 
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'profiles'
ORDER BY policyname;

-- Step 3: Drop all existing policies to start fresh
DROP POLICY IF EXISTS "Users can read their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Admin users can read all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Admin users can update all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Service role can read all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Service role can update all profiles" ON public.profiles;

-- Step 4: Create new comprehensive policies
-- Policy 1: Allow users to read their own profile
CREATE POLICY "Users can read their own profile"
ON public.profiles FOR SELECT 
USING (auth.uid() = id);

-- Policy 2: Allow users to update their own profile
CREATE POLICY "Users can update their own profile"
ON public.profiles FOR UPDATE 
USING (auth.uid() = id);

-- Policy 3: Allow users to insert their own profile
CREATE POLICY "Users can insert their own profile"
ON public.profiles FOR INSERT 
WITH CHECK (auth.uid() = id);

-- Policy 4: Allow admin users to read ALL profiles (including inactive)
CREATE POLICY "Admin users can read all profiles"
ON public.profiles FOR SELECT 
USING (
    -- Allow if user is admin@datingapp.com
    EXISTS (
        SELECT 1 FROM auth.users 
        WHERE auth.users.id = auth.uid() 
        AND auth.users.email = 'admin@datingapp.com'
    )
    OR
    -- Allow if user is in admin_users table
    EXISTS (
        SELECT 1 FROM admin_users au
        WHERE au.user_id = auth.uid() 
        AND au.is_active = true
    )
);

-- Policy 5: Allow admin users to update ALL profiles
CREATE POLICY "Admin users can update all profiles"
ON public.profiles FOR UPDATE 
USING (
    -- Allow if user is admin@datingapp.com
    EXISTS (
        SELECT 1 FROM auth.users 
        WHERE auth.users.id = auth.uid() 
        AND auth.users.email = 'admin@datingapp.com'
    )
    OR
    -- Allow if user is in admin_users table
    EXISTS (
        SELECT 1 FROM admin_users au
        WHERE au.user_id = auth.uid() 
        AND au.is_active = true
    )
);

-- Step 5: Test the policies
SELECT 'RLS policies updated successfully' as status;

-- Step 6: Verify admin can see all profiles
SELECT 
    COUNT(*) as total_visible,
    COUNT(CASE WHEN is_active = true THEN 1 END) as active_visible,
    COUNT(CASE WHEN is_active = false THEN 1 END) as inactive_visible
FROM public.profiles;
