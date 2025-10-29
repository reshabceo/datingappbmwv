-- Fix missing notification_calls column in profiles table
-- This column is needed for call-related push notifications

-- Add the missing notification_calls column
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS notification_calls BOOLEAN DEFAULT TRUE;

-- Update existing profiles to have call notifications enabled by default
UPDATE public.profiles 
SET notification_calls = TRUE 
WHERE notification_calls IS NULL;

-- Verification
DO $$
BEGIN
  RAISE NOTICE '=== Notification Calls Column Fix Applied ===';
  RAISE NOTICE 'Added notification_calls column to profiles table.';
  RAISE NOTICE 'Call notifications are now enabled by default for all users.';
END;
$$;
