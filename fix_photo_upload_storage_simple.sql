-- Simple fix for photo upload storage issues
-- This approach works without requiring admin privileges

-- First, let's check if the buckets exist and create them if needed
-- (This should work with your current permissions)

-- Create chat-photos bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public) 
VALUES ('chat-photos', 'chat-photos', true)
ON CONFLICT (id) DO NOTHING;

-- Create disappearing-photos bucket if it doesn't exist  
INSERT INTO storage.buckets (id, name, public) 
VALUES ('disappearing-photos', 'disappearing-photos', true)
ON CONFLICT (id) DO NOTHING;

-- Check if buckets were created successfully
SELECT 'Buckets created successfully' as status;
SELECT id, name, public FROM storage.buckets WHERE id IN ('chat-photos', 'disappearing-photos');
