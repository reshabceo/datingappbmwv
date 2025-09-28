-- Simple fix for admin panel RLS policies
-- The current policies are too restrictive

-- Drop all existing policies
DROP POLICY IF EXISTS "Users can read their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Admin can read all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Admin users can read all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Admin users can update all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Service role can read all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Service role can update all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Allow authenticated users to read their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Allow authenticated users to update their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Allow authenticated users to insert their own profile" ON public.profiles;

-- Create simple policies that work
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

-- Policy 4: Allow admin@datingapp.com to read ALL profiles
CREATE POLICY "Admin can read all profiles"
ON public.profiles FOR SELECT 
USING (
    EXISTS (
        SELECT 1 FROM auth.users 
        WHERE auth.users.id = auth.uid() 
        AND auth.users.email = 'admin@datingapp.com'
    )
);

-- Policy 5: Allow admin@datingapp.com to update ALL profiles
CREATE POLICY "Admin can update all profiles"
ON public.profiles FOR UPDATE 
USING (
    EXISTS (
        SELECT 1 FROM auth.users 
        WHERE auth.users.id = auth.uid() 
        AND auth.users.email = 'admin@datingapp.com'
    )
);

-- Test the policies
SELECT 'RLS policies updated successfully' as status;
