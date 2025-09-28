-- Complete Database Schema for LoveBug Dating App
-- This script sets up all necessary tables and relationships
-- Run this in Supabase SQL Editor

-- ============================================
-- 1. DISAPPEARING PHOTOS TABLE
-- ============================================

-- Create the 'disappearing_photos' table
CREATE TABLE IF NOT EXISTS public.disappearing_photos (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    match_id uuid REFERENCES public.matches(id) ON DELETE CASCADE,
    sender_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
    photo_url text NOT NULL,
    view_duration integer NOT NULL, -- in seconds
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    viewed_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
    viewed_at timestamp with time zone,
    expires_at timestamp with time zone NOT NULL
);

-- Enable RLS on disappearing_photos
ALTER TABLE public.disappearing_photos ENABLE ROW LEVEL SECURITY;

-- ============================================
-- 2. DISAPPEARING PHOTOS POLICIES
-- ============================================

-- Policy for senders to insert their own disappearing photos
CREATE POLICY "Allow sender to insert disappearing photos"
ON public.disappearing_photos
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = sender_id);

-- Policy for participants of a match to select disappearing photos
CREATE POLICY "Allow match participants to view disappearing photos"
ON public.disappearing_photos
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1
        FROM public.matches
        WHERE (matches.id = disappearing_photos.match_id)
          AND (
                (matches.user_id_1 = auth.uid())
             OR (matches.user_id_2 = auth.uid())
          )
    )
    AND (disappearing_photos.expires_at > now()) -- Only view if not expired
);

-- Policy to allow sender to delete their own disappearing photos
CREATE POLICY "Allow sender to delete own disappearing photos"
ON public.disappearing_photos
FOR DELETE
TO authenticated
USING (auth.uid() = sender_id);

-- Policy to allow marking as viewed (only if not already viewed by current user)
CREATE POLICY "Allow marking photo as viewed by recipient"
ON public.disappearing_photos
FOR UPDATE
TO authenticated
USING (
    EXISTS (
        SELECT 1
        FROM public.matches
        WHERE (matches.id = disappearing_photos.match_id)
          AND (
                (matches.user_id_1 = auth.uid())
             OR (matches.user_id_2 = auth.uid())
          )
    )
    AND (disappearing_photos.viewed_by IS NULL) -- Only if not already viewed
    AND (auth.uid() <> sender_id) -- Recipient only
)
WITH CHECK (
    (auth.uid() = viewed_by)
);

-- ============================================
-- 3. INDEXES FOR PERFORMANCE
-- ============================================

-- Index for faster queries on disappearing photos
CREATE INDEX IF NOT EXISTS idx_disappearing_photos_match_id 
ON public.disappearing_photos(match_id);

CREATE INDEX IF NOT EXISTS idx_disappearing_photos_sender_id 
ON public.disappearing_photos(sender_id);

CREATE INDEX IF NOT EXISTS idx_disappearing_photos_expires_at 
ON public.disappearing_photos(expires_at);

-- ============================================
-- 4. CLEANUP FUNCTION FOR EXPIRED PHOTOS
-- ============================================

-- Function to clean up expired disappearing photos
CREATE OR REPLACE FUNCTION cleanup_expired_disappearing_photos()
RETURNS void AS $$
BEGIN
    -- Delete expired photos that have been viewed
    DELETE FROM public.disappearing_photos 
    WHERE expires_at < now() 
    AND viewed_by IS NOT NULL;
    
    -- Delete photos that have been expired for more than 24 hours (even if not viewed)
    DELETE FROM public.disappearing_photos 
    WHERE expires_at < (now() - interval '24 hours');
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 5. VERIFY SETUP
-- ============================================

-- Check that the table was created
SELECT table_name, column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'disappearing_photos' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Check that policies were created
SELECT schemaname, tablename, policyname, permissive, roles, cmd
FROM pg_policies 
WHERE tablename = 'disappearing_photos' 
AND schemaname = 'public'
ORDER BY policyname;
