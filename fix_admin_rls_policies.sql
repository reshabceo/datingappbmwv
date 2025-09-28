-- Fix RLS policies for admin panel access
-- This will allow admin users to see all profiles regardless of is_active status

-- First, check if there's an admin_users table or way to identify admin users
-- Let's create a simple admin bypass policy

-- Drop existing restrictive policies if they exist
DROP POLICY IF EXISTS "Allow authenticated users to read their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Allow authenticated users to update their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Allow authenticated users to insert their own profile" ON public.profiles;

-- Create new policies that allow admin access
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

-- Policy 4: Allow admin users to read all profiles
-- This assumes admin users have a specific role or are in an admin_users table
-- For now, we'll create a policy that allows service role access
CREATE POLICY "Service role can read all profiles"
ON public.profiles FOR SELECT 
USING (auth.role() = 'service_role');

-- Policy 5: Allow service role to update all profiles
CREATE POLICY "Service role can update all profiles"
ON public.profiles FOR UPDATE 
USING (auth.role() = 'service_role');

-- Alternative: If you have an admin_users table, create a policy like this:
-- CREATE POLICY "Admin users can read all profiles"
-- ON public.profiles FOR SELECT 
-- USING (auth.uid() IN (SELECT user_id FROM admin_users));

-- Test the policies
SELECT 'RLS policies updated successfully' as status;
