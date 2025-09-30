-- Quick fix for profiles table RLS issues
-- Run this in your Supabase SQL Editor

-- 1. First, let's add missing columns to profiles table
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS email text,
ADD COLUMN IF NOT EXISTS is_premium boolean DEFAULT false,
ADD COLUMN IF NOT EXISTS premium_until timestamp with time zone,
ADD COLUMN IF NOT EXISTS updated_at timestamp with time zone DEFAULT now();

-- 2. Drop all existing policies to start fresh
DROP POLICY IF EXISTS "Users can view all profiles except their own" ON public.profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;
DROP POLICY IF EXISTS profiles_read_active ON public.profiles;
DROP POLICY IF EXISTS profiles_insert_own ON public.profiles;
DROP POLICY IF EXISTS profiles_update_own ON public.profiles;
DROP POLICY IF EXISTS profiles_read_own ON public.profiles;

-- 3. Create simple, working policies
CREATE POLICY "Allow users to read their own profile" ON public.profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Allow users to insert their own profile" ON public.profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Allow users to update their own profile" ON public.profiles
  FOR UPDATE USING (auth.uid() = id);

-- 4. Allow reading other active profiles
CREATE POLICY "Allow reading active profiles" ON public.profiles
  FOR SELECT USING (is_active = true);

-- 5. Grant permissions
GRANT ALL ON public.profiles TO authenticated;
GRANT ALL ON public.profiles TO service_role;

SELECT 'Profiles RLS fixed successfully!' as result;
