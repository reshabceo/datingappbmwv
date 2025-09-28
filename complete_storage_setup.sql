-- Complete Storage Setup for LoveBug Dating App
-- This script sets up all necessary storage buckets and policies
-- Run this in Supabase SQL Editor

-- ============================================
-- 1. CREATE ALL STORAGE BUCKETS
-- ============================================

-- Profile photos bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('profile-photos', 'profile-photos', true)
ON CONFLICT (id) DO NOTHING;

-- Chat photos bucket  
INSERT INTO storage.buckets (id, name, public)
VALUES ('chat-photos', 'chat-photos', true)
ON CONFLICT (id) DO NOTHING;

-- Disappearing photos bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('disappearing-photos', 'disappearing-photos', true)
ON CONFLICT (id) DO NOTHING;

-- Stories bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('stories', 'stories', true)
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- 2. DROP EXISTING POLICIES (if any)
-- ============================================

-- Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "Users can upload their own profile photos" ON storage.objects;
DROP POLICY IF EXISTS "Users can view profile photos" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own profile photos" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own profile photos" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload chat photos" ON storage.objects;
DROP POLICY IF EXISTS "Users can view chat photos" ON storage.objects;
DROP POLICY IF EXISTS "Users can update chat photos" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete chat photos" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated users to upload disappearing photos" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated users to view disappearing photos" ON storage.objects;

-- ============================================
-- 3. CREATE COMPREHENSIVE STORAGE POLICIES
-- ============================================

-- PROFILE PHOTOS POLICIES
CREATE POLICY "Profile photos - Upload"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'profile-photos' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Profile photos - View"
ON storage.objects
FOR SELECT
TO authenticated
USING (bucket_id = 'profile-photos');

CREATE POLICY "Profile photos - Update"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'profile-photos' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Profile photos - Delete"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'profile-photos' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- CHAT PHOTOS POLICIES
CREATE POLICY "Chat photos - Upload"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'chat-photos');

CREATE POLICY "Chat photos - View"
ON storage.objects
FOR SELECT
TO authenticated
USING (bucket_id = 'chat-photos');

CREATE POLICY "Chat photos - Update"
ON storage.objects
FOR UPDATE
TO authenticated
USING (bucket_id = 'chat-photos');

CREATE POLICY "Chat photos - Delete"
ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'chat-photos');

-- DISAPPEARING PHOTOS POLICIES
CREATE POLICY "Disappearing photos - Upload"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'disappearing-photos'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Disappearing photos - View"
ON storage.objects
FOR SELECT
TO authenticated
USING (bucket_id = 'disappearing-photos');

CREATE POLICY "Disappearing photos - Update"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'disappearing-photos'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Disappearing photos - Delete"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'disappearing-photos'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- STORIES POLICIES
CREATE POLICY "Stories - Upload"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'stories'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Stories - View"
ON storage.objects
FOR SELECT
TO authenticated
USING (bucket_id = 'stories');

CREATE POLICY "Stories - Update"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'stories'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Stories - Delete"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'stories'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- ============================================
-- 4. VERIFY SETUP
-- ============================================

-- Check that all buckets were created
SELECT id, name, public FROM storage.buckets 
WHERE id IN ('profile-photos', 'chat-photos', 'disappearing-photos', 'stories');

-- Check that policies were created
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'objects' 
AND schemaname = 'storage'
ORDER BY policyname;
