-- TEMPORARY FIX: Disable RLS completely to test
-- This will allow all operations on the profiles table

-- Disable RLS on profiles table
ALTER TABLE public.profiles DISABLE ROW LEVEL SECURITY;

-- Grant full permissions
GRANT ALL ON public.profiles TO authenticated;
GRANT ALL ON public.profiles TO service_role;
GRANT ALL ON public.profiles TO anon;

-- Test that it works
SELECT 'RLS disabled - profiles table should work now' as status;
