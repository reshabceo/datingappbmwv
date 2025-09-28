-- Quick Storage Fix - Run this in Supabase SQL Editor
-- This creates the missing storage buckets

-- Create chat-photos bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('chat-photos', 'chat-photos', true)
ON CONFLICT (id) DO NOTHING;

-- Create disappearing-photos bucket  
INSERT INTO storage.buckets (id, name, public)
VALUES ('disappearing-photos', 'disappearing-photos', true)
ON CONFLICT (id) DO NOTHING;

-- Create basic policies for chat-photos
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

-- Create basic policies for disappearing-photos
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

-- Verify buckets were created
SELECT id, name, public FROM storage.buckets 
WHERE id IN ('chat-photos', 'disappearing-photos');
