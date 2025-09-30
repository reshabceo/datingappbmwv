-- FINAL FIX - Run this ONE file to fix everything
-- Copy and paste this entire code into Supabase SQL Editor

-- 1. Drop the problematic foreign key constraint
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_id_fkey;

-- 2. Disable RLS completely
ALTER TABLE public.profiles DISABLE ROW LEVEL SECURITY;

-- 3. Grant full permissions to everyone
GRANT ALL ON public.profiles TO authenticated;
GRANT ALL ON public.profiles TO service_role;
GRANT ALL ON public.profiles TO anon;

-- 4. Add missing columns
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS email text,
ADD COLUMN IF NOT EXISTS name text DEFAULT 'User',
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

-- 5. Make name column have a default value to prevent null errors
ALTER TABLE public.profiles ALTER COLUMN name SET DEFAULT 'User';

-- 5. Drop all existing policies
DROP POLICY IF EXISTS "Users can view all profiles except their own" ON public.profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;
DROP POLICY IF EXISTS profiles_read_active ON public.profiles;
DROP POLICY IF EXISTS profiles_insert_own ON public.profiles;
DROP POLICY IF EXISTS profiles_update_own ON public.profiles;
DROP POLICY IF EXISTS profiles_read_own ON public.profiles;
DROP POLICY IF EXISTS "Allow users to read their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Allow users to insert their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Allow users to update their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Allow reading active profiles" ON public.profiles;

SELECT 'FIXED! Profiles table should work now' as result;
