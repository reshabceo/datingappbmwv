-- Add DELETE policy for messages table
-- Run this in Supabase SQL Editor

-- Add DELETE policy for messages - users can delete their own messages
CREATE POLICY "Users can delete their own messages" ON messages
  FOR DELETE USING (
    auth.uid() = sender_id AND
    EXISTS (
      SELECT 1 FROM matches 
      WHERE matches.id = messages.match_id 
      AND (matches.user_id_1 = auth.uid() OR matches.user_id_2 = auth.uid())
    )
  );

-- Add DELETE policy for disappearing_photos - users can delete their own disappearing photos
CREATE POLICY "Users can delete their own disappearing photos" ON disappearing_photos
  FOR DELETE USING (
    auth.uid() = sender_id AND
    EXISTS (
      SELECT 1 FROM matches 
      WHERE matches.id = disappearing_photos.match_id 
      AND (matches.user_id_1 = auth.uid() OR matches.user_id_2 = auth.uid())
    )
  );

-- Verify the policies were created
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
AND policyname LIKE '%delete%'
ORDER BY tablename, policyname;
