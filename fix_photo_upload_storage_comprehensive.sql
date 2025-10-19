-- Comprehensive fix for photo upload storage RLS policies
-- This script removes all existing policies and creates new ones

-- First, drop all existing policies for the storage buckets
DROP POLICY IF EXISTS "Allow authenticated users to upload chat photos" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated users to view chat photos" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated users to delete own chat photos" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated users to upload disappearing photos" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated users to view disappearing photos" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated users to delete own disappearing photos" ON storage.objects;

-- Create new, more permissive policies for chat-photos bucket
CREATE POLICY "Allow authenticated users to upload chat photos"
ON storage.objects FOR INSERT 
WITH CHECK (bucket_id = 'chat-photos' AND auth.role() = 'authenticated');

CREATE POLICY "Allow authenticated users to view chat photos"
ON storage.objects FOR SELECT 
USING (bucket_id = 'chat-photos' AND auth.role() = 'authenticated');

CREATE POLICY "Allow authenticated users to delete chat photos"
ON storage.objects FOR DELETE 
USING (bucket_id = 'chat-photos' AND auth.role() = 'authenticated');

-- Create new, more permissive policies for disappearing-photos bucket
CREATE POLICY "Allow authenticated users to upload disappearing photos"
ON storage.objects FOR INSERT 
WITH CHECK (bucket_id = 'disappearing-photos' AND auth.role() = 'authenticated');

CREATE POLICY "Allow authenticated users to view disappearing photos"
ON storage.objects FOR SELECT 
USING (bucket_id = 'disappearing-photos' AND auth.role() = 'authenticated');

CREATE POLICY "Allow authenticated users to delete disappearing photos"
ON storage.objects FOR DELETE 
USING (bucket_id = 'disappearing-photos' AND auth.role() = 'authenticated');

-- Ensure the buckets exist and are public
INSERT INTO storage.buckets (id, name, public) 
VALUES ('chat-photos', 'chat-photos', true)
ON CONFLICT (id) DO UPDATE SET public = true;

INSERT INTO storage.buckets (id, name, public) 
VALUES ('disappearing-photos', 'disappearing-photos', true)
ON CONFLICT (id) DO UPDATE SET public = true;
