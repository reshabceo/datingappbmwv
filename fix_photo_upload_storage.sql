-- Fix photo upload storage RLS policies
-- This fixes the "new row violates row-level security policy" error

-- Enable RLS on storage.objects table
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Drop existing policies that might be conflicting
DROP POLICY IF EXISTS "Allow authenticated users to upload chat photos" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated users to upload disappearing photos" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated users to view chat photos" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated users to view disappearing photos" ON storage.objects;

-- Create new, more permissive policies for photo uploads
CREATE POLICY "Users can upload chat photos" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'chat-photos' 
  AND auth.role() = 'authenticated'
);

CREATE POLICY "Users can upload disappearing photos" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'disappearing-photos' 
  AND auth.role() = 'authenticated'
);

CREATE POLICY "Users can view chat photos" ON storage.objects
FOR SELECT USING (
  bucket_id = 'chat-photos' 
  AND auth.role() = 'authenticated'
);

CREATE POLICY "Users can view disappearing photos" ON storage.objects
FOR SELECT USING (
  bucket_id = 'disappearing-photos' 
  AND auth.role() = 'authenticated'
);

-- Also ensure the buckets exist
INSERT INTO storage.buckets (id, name, public) 
VALUES ('chat-photos', 'chat-photos', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public) 
VALUES ('disappearing-photos', 'disappearing-photos', true)
ON CONFLICT (id) DO NOTHING;
