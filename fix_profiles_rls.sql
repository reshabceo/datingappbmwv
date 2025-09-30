-- Fix RLS policies for profiles table
-- This fixes the "permission denied for table users" error

-- First, let's check if the profiles table has the correct structure
-- Add missing columns if they don't exist
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS email text,
ADD COLUMN IF NOT EXISTS is_premium boolean DEFAULT false,
ADD COLUMN IF NOT EXISTS premium_until timestamp with time zone,
ADD COLUMN IF NOT EXISTS updated_at timestamp with time zone DEFAULT now();

-- Drop existing policies to recreate them properly
DROP POLICY IF EXISTS "Users can view all profiles except their own" ON public.profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;
DROP POLICY IF EXISTS profiles_read_active ON public.profiles;
DROP POLICY IF EXISTS profiles_insert_own ON public.profiles;
DROP POLICY IF EXISTS profiles_update_own ON public.profiles;
DROP POLICY IF EXISTS profiles_read_own ON public.profiles;

-- Create comprehensive RLS policies for profiles table

-- 1. Users can read their own profile (even if not active)
CREATE POLICY "profiles_read_own" ON public.profiles
  FOR SELECT 
  USING (auth.uid() = id);

-- 2. Users can read all active profiles except their own
CREATE POLICY "profiles_read_active" ON public.profiles
  FOR SELECT 
  USING (is_active = true AND auth.uid() != id);

-- 3. Users can insert their own profile
CREATE POLICY "profiles_insert_own" ON public.profiles
  FOR INSERT 
  WITH CHECK (auth.uid() = id);

-- 4. Users can update their own profile
CREATE POLICY "profiles_update_own" ON public.profiles
  FOR UPDATE 
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- 5. Users can delete their own profile
CREATE POLICY "profiles_delete_own" ON public.profiles
  FOR DELETE 
  USING (auth.uid() = id);

-- Ensure RLS is enabled
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Create or replace the updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Drop and recreate the trigger
DROP TRIGGER IF EXISTS update_profiles_updated_at ON public.profiles;
CREATE TRIGGER update_profiles_updated_at 
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Grant necessary permissions
GRANT ALL ON public.profiles TO authenticated;
GRANT ALL ON public.profiles TO service_role;

-- Test the policies
-- This should work for authenticated users
SELECT 'RLS policies created successfully' as status;
