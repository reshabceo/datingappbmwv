-- Disappearing Photos Schema
-- This script creates the necessary tables and policies for Snapchat-like disappearing photos

-- Create disappearing_photos table
CREATE TABLE IF NOT EXISTS disappearing_photos (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  match_id UUID NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
  photo_url TEXT NOT NULL,
  sender_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  view_duration INTEGER DEFAULT 10, -- seconds
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
  is_viewed BOOLEAN DEFAULT FALSE,
  viewed_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create storage bucket for disappearing photos
INSERT INTO storage.buckets (id, name, public)
VALUES ('disappearing-photos', 'disappearing-photos', false)
ON CONFLICT (id) DO NOTHING;

-- Enable RLS on disappearing_photos table
ALTER TABLE disappearing_photos ENABLE ROW LEVEL SECURITY;

-- Policy 1: Users can insert disappearing photos for their matches
CREATE POLICY "Users can send disappearing photos to their matches"
ON disappearing_photos
FOR INSERT
TO authenticated
WITH CHECK (
  sender_id = auth.uid() AND
  match_id IN (
    SELECT id FROM matches 
    WHERE (user_id_1 = auth.uid() OR user_id_2 = auth.uid()) 
    AND status = 'matched'
  )
);

-- Policy 2: Users can view disappearing photos from their matches
CREATE POLICY "Users can view disappearing photos from their matches"
ON disappearing_photos
FOR SELECT
TO authenticated
USING (
  match_id IN (
    SELECT id FROM matches 
    WHERE (user_id_1 = auth.uid() OR user_id_2 = auth.uid()) 
    AND status = 'matched'
  ) AND
  expires_at > NOW()
);

-- Policy 3: Users can update their own disappearing photos (mark as viewed)
CREATE POLICY "Users can update disappearing photos they can view"
ON disappearing_photos
FOR UPDATE
TO authenticated
USING (
  match_id IN (
    SELECT id FROM matches 
    WHERE (user_id_1 = auth.uid() OR user_id_2 = auth.uid()) 
    AND status = 'matched'
  )
);

-- Policy 4: Users can delete their own disappearing photos
CREATE POLICY "Users can delete their own disappearing photos"
ON disappearing_photos
FOR DELETE
TO authenticated
USING (sender_id = auth.uid());

-- Storage bucket policies for disappearing photos
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Policy 1: Allow authenticated users to upload disappearing photos
CREATE POLICY "Users can upload disappearing photos"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'disappearing-photos' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Policy 2: Allow users to view disappearing photos from their matches
CREATE POLICY "Users can view disappearing photos from matches"
ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id = 'disappearing-photos' 
  AND name IN (
    SELECT photo_url FROM disappearing_photos 
    WHERE match_id IN (
      SELECT id FROM matches 
      WHERE (user_id_1 = auth.uid() OR user_id_2 = auth.uid()) 
      AND status = 'matched'
    )
    AND expires_at > NOW()
  )
);

-- Policy 3: Allow users to delete their own disappearing photos
CREATE POLICY "Users can delete their own disappearing photos"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'disappearing-photos' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Create function to automatically clean up expired photos
CREATE OR REPLACE FUNCTION cleanup_expired_disappearing_photos()
RETURNS void AS $$
BEGIN
  DELETE FROM disappearing_photos 
  WHERE expires_at < NOW();
END;
$$ LANGUAGE plpgsql;

-- Create a scheduled job to clean up expired photos (if pg_cron is available)
-- SELECT cron.schedule('cleanup-expired-photos', '*/5 * * * *', 'SELECT cleanup_expired_disappearing_photos();');

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_disappearing_photos_match_id ON disappearing_photos(match_id);
CREATE INDEX IF NOT EXISTS idx_disappearing_photos_expires_at ON disappearing_photos(expires_at);
CREATE INDEX IF NOT EXISTS idx_disappearing_photos_sender_id ON disappearing_photos(sender_id);
