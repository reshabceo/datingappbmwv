-- Add columns to messages table for disappearing photos
-- Run this in Supabase SQL Editor

-- Add columns to messages table
ALTER TABLE public.messages 
ADD COLUMN IF NOT EXISTS is_disappearing_photo boolean DEFAULT false,
ADD COLUMN IF NOT EXISTS disappearing_photo_id uuid REFERENCES public.disappearing_photos(id) ON DELETE CASCADE;

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_messages_disappearing_photo 
ON public.messages(disappearing_photo_id) 
WHERE is_disappearing_photo = true;
