-- Fix Reactivation Loop: Clean RLS Policies for Profiles Table
-- This script removes all conflicting policies and creates a clean, minimal set

-- Step 1: Drop ALL existing policies on profiles table
DROP POLICY IF EXISTS "Admin can update any profile" ON public.profiles;
DROP POLICY IF EXISTS "Allow authenticated users to read profiles" ON public.profiles;
DROP POLICY IF EXISTS "Users can always read their own profile regardless of status" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update their own profile including is_active" ON public.profiles;
DROP POLICY IF EXISTS "Users can view their own profile" ON public.profiles;
DROP POLICY IF EXISTS "profiles_insert_own" ON public.profiles;
DROP POLICY IF EXISTS "profiles_read_active" ON public.profiles;
DROP POLICY IF EXISTS "profiles_read_active_others" ON public.profiles;
DROP POLICY IF EXISTS "profiles_read_self" ON public.profiles;
DROP POLICY IF EXISTS "profiles_update_own" ON public.profiles;

-- Step 2: Create clean, minimal policy set
-- Policy 1: Users can read their own profile (regardless of is_active status)
CREATE POLICY "profiles_self_read"
ON public.profiles
FOR SELECT
TO public
USING (auth.uid() = id);

-- Policy 2: Users can read other profiles only if they are active
CREATE POLICY "profiles_others_read_active"
ON public.profiles
FOR SELECT
TO public
USING (is_active = true AND auth.uid() != id);

-- Policy 3: Users can insert their own profile
CREATE POLICY "profiles_self_insert"
ON public.profiles
FOR INSERT
TO public
WITH CHECK (auth.uid() = id);

-- Policy 4: Users can update their own profile (including is_active)
CREATE POLICY "profiles_self_update"
ON public.profiles
FOR UPDATE
TO public
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- Policy 5: Admin can update any profile
CREATE POLICY "profiles_admin_update"
ON public.profiles
FOR UPDATE
TO public
USING (
  EXISTS (
    SELECT 1 FROM auth.users
    WHERE users.id = auth.uid() 
    AND users.email = 'admin@datingapp.com'
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM auth.users
    WHERE users.id = auth.uid() 
    AND users.email = 'admin@datingapp.com'
  )
);

-- Step 3: Verify the policies are working correctly
-- Test query to check if user can read their own profile regardless of is_active
SELECT 
  'Policy Test' as test_type,
  id,
  name,
  is_active,
  CASE 
    WHEN auth.uid() = id THEN 'Can read own profile'
    ELSE 'Cannot read own profile'
  END as access_status
FROM public.profiles 
WHERE auth.uid() = id
LIMIT 1;

-- Step 4: Check current user status
SELECT 
  'Current User Status' as info,
  id,
  name,
  is_active,
  created_at,
  last_seen
FROM public.profiles 
WHERE auth.uid() = id;
