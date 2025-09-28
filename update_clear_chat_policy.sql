-- Update RLS policies to allow clearing all messages in a match
-- Run this in Supabase SQL Editor

-- Drop the existing restrictive policies
DROP POLICY IF EXISTS "Users can delete their own messages" ON messages;
DROP POLICY IF EXISTS "Users can delete their own disappearing photos" ON disappearing_photos;

-- Create new policies that allow clearing all messages in a match
CREATE POLICY "Users can clear all messages in their matches" ON messages
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM matches 
      WHERE matches.id = messages.match_id 
      AND (matches.user_id_1 = auth.uid() OR matches.user_id_2 = auth.uid())
    )
  );

CREATE POLICY "Users can clear all disappearing photos in their matches" ON disappearing_photos
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM matches 
      WHERE matches.id = disappearing_photos.match_id 
      AND (matches.user_id_1 = auth.uid() OR matches.user_id_2 = auth.uid())
    )
  );

-- Verify the policies were updated
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename IN ('messages', 'disappearing_photos')
AND policyname LIKE '%clear%'
ORDER BY tablename, policyname;
