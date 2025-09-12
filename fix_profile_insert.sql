-- Fix: Add INSERT policy for profiles table
-- Users should be able to insert their own profile

-- Policy to allow users to create their own profile
CREATE POLICY profiles_insert_own ON public.profiles
  FOR INSERT 
  WITH CHECK (auth.uid() = id);

-- Policy to allow users to update their own profile  
CREATE POLICY profiles_update_own ON public.profiles
  FOR UPDATE 
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Policy to allow users to read their own profile (even if not active)
CREATE POLICY profiles_read_own ON public.profiles
  FOR SELECT 
  USING (auth.uid() = id);






