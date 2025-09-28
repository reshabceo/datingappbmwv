-- Fix for existing policies - Run this in Supabase SQL Editor
-- This handles the case where policies already exist

-- First, drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "Allow authenticated users to upload chat photos" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated users to view chat photos" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated users to upload disappearing photos" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated users to view disappearing photos" ON storage.objects;

-- Create chat-photos bucket (if not exists)
INSERT INTO storage.buckets (id, name, public)
VALUES ('chat-photos', 'chat-photos', true)
ON CONFLICT (id) DO NOTHING;

-- Create disappearing-photos bucket (if not exists)
INSERT INTO storage.buckets (id, name, public)
VALUES ('disappearing-photos', 'disappearing-photos', true)
ON CONFLICT (id) DO NOTHING;

-- Now create the policies
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

-- Verify everything was created
SELECT id, name, public FROM storage.buckets 
WHERE id IN ('chat-photos', 'disappearing-photos');
