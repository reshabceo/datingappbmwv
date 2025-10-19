-- Fix BFF Chat Foreign Key Violation Issue
-- Run this in Supabase SQL Editor to enable BFF messaging

-- Step 1: Check current state
SELECT 'BFF Matches Count' as check_type, COUNT(*) as count FROM bff_matches
UNION ALL
SELECT 'Regular Matches Count', COUNT(*) FROM matches
UNION ALL
SELECT 'BFF Matches in Matches Table', COUNT(*) FROM matches WHERE id IN (SELECT id FROM bff_matches);

-- Step 2: Create entries in matches table for BFF matches that don't exist
INSERT INTO matches (id, user_id_1, user_id_2, status, created_at)
SELECT 
    bm.id,
    bm.user_id_1,
    bm.user_id_2,
    'matched',
    bm.created_at
FROM bff_matches bm
WHERE NOT EXISTS (
    SELECT 1 FROM matches m WHERE m.id = bm.id
);

-- Step 3: Create a function to ensure BFF matches exist in matches table
CREATE OR REPLACE FUNCTION ensure_bff_match_exists(bff_match_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  -- Check if match exists in matches table
  IF NOT EXISTS (SELECT 1 FROM matches WHERE id = bff_match_id) THEN
    -- Get BFF match details and insert into matches table
    INSERT INTO matches (id, user_id_1, user_id_2, status, created_at)
    SELECT id, user_id_1, user_id_2, 'matched', created_at
    FROM bff_matches 
    WHERE id = bff_match_id;
  END IF;
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Step 4: Create a function to send BFF messages safely
CREATE OR REPLACE FUNCTION send_bff_message(
  p_match_id UUID,
  p_sender_id UUID,
  p_content TEXT
)
RETURNS BOOLEAN AS $$
BEGIN
  -- Ensure BFF match exists in matches table
  PERFORM ensure_bff_match_exists(p_match_id);
  
  -- Insert message
  INSERT INTO messages (match_id, sender_id, content, message_type)
  VALUES (p_match_id, p_sender_id, p_content, 'text');
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Step 5: Update existing messages to ensure they have valid match references
UPDATE messages 
SET match_id = matches.id
FROM matches
WHERE messages.match_id = matches.id;

-- Step 6: Verify the fix
SELECT 'After Fix - BFF Matches Count' as check_type, COUNT(*) as count FROM bff_matches
UNION ALL
SELECT 'After Fix - Regular Matches Count', COUNT(*) FROM matches
UNION ALL
SELECT 'After Fix - BFF Matches in Matches Table', COUNT(*) FROM matches WHERE id IN (SELECT id FROM bff_matches)
UNION ALL
SELECT 'After Fix - Messages with Valid Matches', COUNT(*) FROM messages WHERE match_id IN (SELECT id FROM matches);

-- Step 7: Test the function
-- SELECT send_bff_message('your-bff-match-id-here', 'your-user-id-here', 'Test message');

-- Step 8: Create RLS policy for BFF messages if needed
CREATE POLICY "Users can send messages in BFF matches"
ON messages
FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM matches m 
    WHERE m.id = messages.match_id 
    AND (m.user_id_1 = auth.uid() OR m.user_id_2 = auth.uid())
  )
);

-- Step 9: Verify RLS policies exist
SELECT schemaname, tablename, policyname 
FROM pg_policies 
WHERE tablename = 'messages' 
ORDER BY policyname;
