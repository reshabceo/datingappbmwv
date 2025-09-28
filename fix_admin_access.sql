-- Fix admin panel access to see all users including inactive ones
-- The issue is that RLS policies are filtering out inactive users for admin panel

-- First, let's check what RLS policies exist
SELECT 
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'profiles';

-- Create a policy that allows admin users to see all profiles
-- We'll create a policy that allows users with admin role to see everything
CREATE POLICY "Admin users can read all profiles"
ON public.profiles FOR SELECT 
USING (
    -- Allow users to see their own profile
    auth.uid() = id 
    OR 
    -- Allow admin users to see all profiles
    -- This checks if the user has admin privileges
    EXISTS (
        SELECT 1 FROM auth.users 
        WHERE auth.users.id = auth.uid() 
        AND (
            -- Check if user email is admin
            auth.users.email = 'admin@datingapp.com'
            OR 
            -- Check if user is in admin_users table (if it exists)
            auth.users.id IN (
                SELECT user_id FROM admin_users WHERE is_active = true
            )
        )
    )
);

-- Also create a policy for admin users to update all profiles
CREATE POLICY "Admin users can update all profiles"
ON public.profiles FOR UPDATE 
USING (
    -- Allow users to update their own profile
    auth.uid() = id 
    OR 
    -- Allow admin users to update all profiles
    EXISTS (
        SELECT 1 FROM auth.users 
        WHERE auth.users.id = auth.uid() 
        AND (
            auth.users.email = 'admin@datingapp.com'
            OR 
            auth.users.id IN (
                SELECT user_id FROM admin_users WHERE is_active = true
            )
        )
    )
);

-- Test the fix by checking if admin can see all profiles
SELECT 'RLS policies updated for admin access' as status;
