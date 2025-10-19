-- Fix Chat Photos Storage Issue
-- Run this in Supabase SQL Editor to enable photo upload in chat

-- Create chat-photos bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('chat-photos', 'chat-photos', true)
ON CONFLICT (id) DO NOTHING;

-- Create disappearing-photos bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('disappearing-photos', 'disappearing-photos', true)
ON CONFLICT (id) DO NOTHING;

-- Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "Allow authenticated users to upload chat photos" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated users to view chat photos" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated users to upload disappearing photos" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated users to view disappearing photos" ON storage.objects;

-- Create policies for chat photos
CREATE POLICY "Allow authenticated users to upload chat photos"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'chat-photos');

CREATE POLICY "Allow authenticated users to view chat photos"
ON storage.objects
FOR SELECT
TO authenticated
USING (bucket_id = 'chat-photos');

CREATE POLICY "Allow authenticated users to update chat photos"
ON storage.objects
FOR UPDATE
TO authenticated
USING (bucket_id = 'chat-photos');

CREATE POLICY "Allow authenticated users to delete chat photos"
ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'chat-photos');

-- Create policies for disappearing photos
CREATE POLICY "Allow authenticated users to upload disappearing photos"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'disappearing-photos');

CREATE POLICY "Allow authenticated users to view disappearing photos"
ON storage.objects
FOR SELECT
TO authenticated
USING (bucket_id = 'disappearing-photos');

CREATE POLICY "Allow authenticated users to update disappearing photos"
ON storage.objects
FOR UPDATE
TO authenticated
USING (bucket_id = 'disappearing-photos');

CREATE POLICY "Allow authenticated users to delete disappearing photos"
ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'disappearing-photos');

-- Verify buckets were created
SELECT id, name, public FROM storage.buckets 
WHERE id IN ('chat-photos', 'disappearing-photos');

-- Verify policies were created
SELECT schemaname, tablename, policyname 
FROM pg_policies 
WHERE tablename = 'objects' 
AND policyname LIKE '%chat%' OR policyname LIKE '%disappearing%';
