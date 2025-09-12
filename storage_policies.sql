-- Storage bucket policies for profile photos
-- This script sets up the necessary permissions for the profile-photos bucket

-- First, create the storage bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('profile-photos', 'profile-photos', true)
ON CONFLICT (id) DO NOTHING;

-- Enable RLS on the storage.objects table
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Policy 1: Allow authenticated users to upload files to their own folder
CREATE POLICY "Users can upload their own profile photos"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'profile-photos' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Policy 2: Allow authenticated users to view profile photos
CREATE POLICY "Users can view profile photos"
ON storage.objects
FOR SELECT
TO authenticated
USING (bucket_id = 'profile-photos');

-- Policy 3: Allow users to update their own profile photos
CREATE POLICY "Users can update their own profile photos"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'profile-photos' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Policy 4: Allow users to delete their own profile photos
CREATE POLICY "Users can delete their own profile photos"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'profile-photos' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Alternative: If you want to allow public access to profile photos (for viewing)
-- Uncomment the following policy and comment out the SELECT policy above
/*
CREATE POLICY "Profile photos are publicly viewable"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'profile-photos');
*/
