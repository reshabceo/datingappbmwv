-- Fix RLS policies for profiles table to ensure users can access their own profiles
-- This should fix the profile fetching issue after reactivation

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;

-- Create comprehensive RLS policies for profiles table
CREATE POLICY "Users can view their own profile" ON public.profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profile" ON public.profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Fix user_events table RLS policy (causing the error in logs)
DROP POLICY IF EXISTS "Users can insert their own events" ON public.user_events;

CREATE POLICY "Users can insert their own events" ON public.user_events
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Ensure profiles table has RLS enabled
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Ensure user_events table has RLS enabled
ALTER TABLE public.user_events ENABLE ROW LEVEL SECURITY;

-- Test query to verify policies work
-- This should return the current user's profile if they're authenticated
SELECT * FROM public.profiles WHERE id = auth.uid();
