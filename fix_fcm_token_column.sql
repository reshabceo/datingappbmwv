-- Fix missing fcm_token column in profiles table
-- This is required for push notifications to work

-- Add fcm_token column to profiles table
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS fcm_token TEXT;

-- Add notification preference columns
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS notification_matches BOOLEAN DEFAULT TRUE,
ADD COLUMN IF NOT EXISTS notification_messages BOOLEAN DEFAULT TRUE,
ADD COLUMN IF NOT EXISTS notification_stories BOOLEAN DEFAULT TRUE,
ADD COLUMN IF NOT EXISTS notification_likes BOOLEAN DEFAULT TRUE,
ADD COLUMN IF NOT EXISTS notification_admin BOOLEAN DEFAULT TRUE,
ADD COLUMN IF NOT EXISTS notification_calls BOOLEAN DEFAULT TRUE;

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_profiles_fcm_token ON public.profiles(fcm_token);

-- Update RLS policies to allow fcm_token updates
DROP POLICY IF EXISTS profiles_update_own ON public.profiles;
CREATE POLICY profiles_update_own ON public.profiles
  FOR UPDATE USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Grant permissions for fcm_token updates
GRANT UPDATE ON public.profiles TO authenticated;

-- Verification
DO $$
BEGIN
  RAISE NOTICE '=== FCM Token Column Fix Applied ===';
  RAISE NOTICE 'Added fcm_token column and notification preferences to profiles table.';
  RAISE NOTICE 'Push notifications should now work properly.';
END;
$$;
