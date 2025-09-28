-- Storage bucket policies for chat photos
-- This script sets up the necessary permissions for the chat-photos bucket

-- First, create the storage bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('chat-photos', 'chat-photos', true)
ON CONFLICT (id) DO NOTHING;

-- Create policies for the chat-photos bucket
-- Note: These policies are created on the storage.objects table but target the specific bucket

-- Policy 1: Allow authenticated users to upload chat photos
CREATE POLICY "Users can upload chat photos"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'chat-photos');

-- Policy 2: Allow authenticated users to view chat photos  
CREATE POLICY "Users can view chat photos"
ON storage.objects
FOR SELECT
TO authenticated
USING (bucket_id = 'chat-photos');

-- Policy 3: Allow users to update chat photos
CREATE POLICY "Users can update chat photos"
ON storage.objects
FOR UPDATE
TO authenticated
USING (bucket_id = 'chat-photos');

-- Policy 4: Allow users to delete chat photos
CREATE POLICY "Users can delete chat photos"
ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'chat-photos');
