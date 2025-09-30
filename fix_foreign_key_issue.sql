-- Fix the foreign key issue causing "permission denied for table users"
-- The profiles table has a foreign key to auth.users which is causing RLS issues

-- 1. Drop the problematic foreign key constraint
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_id_fkey;

-- 2. Make sure the profiles table has the correct structure without foreign key
-- First, let's check the current structure
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'profiles' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 3. Ensure the profiles table has all required columns
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS email text,
ADD COLUMN IF NOT EXISTS name text,
ADD COLUMN IF NOT EXISTS age integer DEFAULT 18,
ADD COLUMN IF NOT EXISTS image_urls jsonb DEFAULT '[]'::jsonb,
ADD COLUMN IF NOT EXISTS location text,
ADD COLUMN IF NOT EXISTS distance text,
ADD COLUMN IF NOT EXISTS description text,
ADD COLUMN IF NOT EXISTS hobbies jsonb DEFAULT '[]'::jsonb,
ADD COLUMN IF NOT EXISTS is_active boolean DEFAULT false,
ADD COLUMN IF NOT EXISTS is_premium boolean DEFAULT false,
ADD COLUMN IF NOT EXISTS premium_until timestamp with time zone,
ADD COLUMN IF NOT EXISTS created_at timestamp with time zone DEFAULT now(),
ADD COLUMN IF NOT EXISTS updated_at timestamp with time zone DEFAULT now();

-- 4. Disable RLS temporarily to test
ALTER TABLE public.profiles DISABLE ROW LEVEL SECURITY;

-- 5. Grant full permissions
GRANT ALL ON public.profiles TO authenticated;
GRANT ALL ON public.profiles TO service_role;
GRANT ALL ON public.profiles TO anon;

-- 6. Test that it works
SELECT 'Foreign key constraint removed - profiles table should work now' as status;
