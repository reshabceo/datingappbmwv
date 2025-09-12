// Test script to verify storage upload
// This can be run in your Supabase SQL Editor to test storage

-- First, let's check if the bucket exists and is accessible
SELECT * FROM storage.buckets WHERE id = 'profile-photos';

-- Check current storage policies
SELECT * FROM pg_policies WHERE tablename = 'objects' AND schemaname = 'storage';

-- Simple test: Try to disable RLS temporarily
-- ALTER TABLE storage.objects DISABLE ROW LEVEL SECURITY;

-- Alternative: Create a very simple policy that allows all authenticated users
-- DROP POLICY IF EXISTS "Users can upload profile photos" ON storage.objects;
-- CREATE POLICY "Allow all authenticated uploads" ON storage.objects
--   FOR ALL TO authenticated
--   USING (bucket_id = 'profile-photos');

-- Test upload with a simple path structure
-- This should work if policies are correct
