-- COMPLETE SUPABASE DATA INTEGRITY FIX
-- This script fixes all data inconsistencies and ensures proper BFF/dating separation

-- Step 1: Check current data state
SELECT 'Current Data State Analysis' as analysis_type;

-- Check BFF matches count
SELECT 'BFF Matches' as table_name, COUNT(*) as count FROM bff_matches;

-- Check regular matches count  
SELECT 'Regular Matches' as table_name, COUNT(*) as count FROM matches;

-- Check if BFF matches exist in regular matches table
SELECT 'BFF in Regular Matches' as check_type, COUNT(*) as count 
FROM matches WHERE id IN (SELECT id FROM bff_matches);

-- Check messages count
SELECT 'Messages' as table_name, COUNT(*) as count FROM messages;

-- Step 2: Ensure BFF matches exist in matches table for chat functionality
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

-- Step 3: Fix any orphaned messages (messages without valid match_id)
UPDATE messages 
SET match_id = (
    SELECT m.id FROM matches m 
    WHERE (m.user_id_1 = messages.sender_id OR m.user_id_2 = messages.sender_id)
    AND (m.user_id_1 = (
        SELECT CASE 
            WHEN m.user_id_1 = messages.sender_id THEN m.user_id_2 
            ELSE m.user_id_1 
        END
    ) OR m.user_id_2 = (
        SELECT CASE 
            WHEN m.user_id_1 = messages.sender_id THEN m.user_id_2 
            ELSE m.user_id_1 
        END
    ))
    LIMIT 1
)
WHERE match_id NOT IN (SELECT id FROM matches);

-- Step 4: Create proper indexes for performance
CREATE INDEX IF NOT EXISTS idx_matches_user_id_1 ON matches(user_id_1);
CREATE INDEX IF NOT EXISTS idx_matches_user_id_2 ON matches(user_id_2);
CREATE INDEX IF NOT EXISTS idx_bff_matches_user_id_1 ON bff_matches(user_id_1);
CREATE INDEX IF NOT EXISTS idx_bff_matches_user_id_2 ON bff_matches(user_id_2);
CREATE INDEX IF NOT EXISTS idx_messages_match_id ON messages(match_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON messages(sender_id);

-- Step 5: Verify data integrity after fixes
SELECT 'After Fix - BFF Matches' as table_name, COUNT(*) as count FROM bff_matches;
SELECT 'After Fix - Regular Matches' as table_name, COUNT(*) as count FROM matches;
SELECT 'After Fix - BFF in Regular Matches' as check_type, COUNT(*) as count 
FROM matches WHERE id IN (SELECT id FROM bff_matches);
SELECT 'After Fix - Messages' as table_name, COUNT(*) as count FROM messages;

-- Step 6: Check for any remaining data issues
SELECT 'Data Integrity Check' as check_type,
       CASE 
           WHEN COUNT(*) = 0 THEN 'PASS - No orphaned messages'
           ELSE 'FAIL - ' || COUNT(*) || ' orphaned messages found'
       END as result
FROM messages m 
WHERE m.match_id NOT IN (SELECT id FROM matches);

-- Step 7: Create helper function for chat filtering
CREATE OR REPLACE FUNCTION get_user_matches(p_user_id UUID, p_mode TEXT)
RETURNS TABLE (
    match_id UUID,
    other_user_id UUID,
    other_user_name TEXT,
    other_user_image TEXT,
    last_message TEXT,
    last_message_time TIMESTAMP WITH TIME ZONE,
    unread_count INTEGER
) AS $$
BEGIN
    IF p_mode = 'bff' THEN
        RETURN QUERY
        SELECT 
            m.id as match_id,
            CASE 
                WHEN m.user_id_1 = p_user_id THEN m.user_id_2
                ELSE m.user_id_1
            END as other_user_id,
            CASE 
                WHEN m.user_id_1 = p_user_id THEN p2.name
                ELSE p1.name
            END as other_user_name,
            CASE 
                WHEN m.user_id_1 = p_user_id THEN p2.image_urls->>0
                ELSE p1.image_urls->>0
            END as other_user_image,
            msg.content as last_message,
            msg.created_at as last_message_time,
            COALESCE(unread.unread_count, 0) as unread_count
        FROM matches m
        JOIN bff_matches bm ON m.id = bm.id
        LEFT JOIN profiles p1 ON m.user_id_1 = p1.id
        LEFT JOIN profiles p2 ON m.user_id_2 = p2.id
        LEFT JOIN LATERAL (
            SELECT content, created_at
            FROM messages 
            WHERE match_id = m.id 
            ORDER BY created_at DESC 
            LIMIT 1
        ) msg ON true
        LEFT JOIN LATERAL (
            SELECT COUNT(*) as unread_count
            FROM messages 
            WHERE match_id = m.id 
            AND sender_id != p_user_id 
            AND is_read = false
        ) unread ON true
        WHERE (m.user_id_1 = p_user_id OR m.user_id_2 = p_user_id)
        ORDER BY COALESCE(msg.created_at, m.created_at) DESC;
    ELSE
        RETURN QUERY
        SELECT 
            m.id as match_id,
            CASE 
                WHEN m.user_id_1 = p_user_id THEN m.user_id_2
                ELSE m.user_id_1
            END as other_user_id,
            CASE 
                WHEN m.user_id_1 = p_user_id THEN p2.name
                ELSE p1.name
            END as other_user_name,
            CASE 
                WHEN m.user_id_1 = p_user_id THEN p2.image_urls->>0
                ELSE p1.image_urls->>0
            END as other_user_image,
            msg.content as last_message,
            msg.created_at as last_message_time,
            COALESCE(unread.unread_count, 0) as unread_count
        FROM matches m
        LEFT JOIN bff_matches bm ON m.id = bm.id
        LEFT JOIN profiles p1 ON m.user_id_1 = p1.id
        LEFT JOIN profiles p2 ON m.user_id_2 = p2.id
        LEFT JOIN LATERAL (
            SELECT content, created_at
            FROM messages 
            WHERE match_id = m.id 
            ORDER BY created_at DESC 
            LIMIT 1
        ) msg ON true
        LEFT JOIN LATERAL (
            SELECT COUNT(*) as unread_count
            FROM messages 
            WHERE match_id = m.id 
            AND sender_id != p_user_id 
            AND is_read = false
        ) unread ON true
        WHERE (m.user_id_1 = p_user_id OR m.user_id_2 = p_user_id)
        AND bm.id IS NULL  -- Exclude BFF matches
        ORDER BY COALESCE(msg.created_at, m.created_at) DESC;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 8: Test the function (replace with actual user ID)
-- First, get your user ID:
SELECT 'Current user IDs in the system:' as info;
SELECT id, name FROM profiles LIMIT 5;

-- Then test the function with a real user ID (replace 'ACTUAL_USER_ID' with a real UUID from above)
-- SELECT 'Testing chat function for dating mode' as test_type;
-- SELECT * FROM get_user_matches('ACTUAL_USER_ID', 'dating') LIMIT 5;

-- SELECT 'Testing chat function for BFF mode' as test_type;  
-- SELECT * FROM get_user_matches('ACTUAL_USER_ID', 'bff') LIMIT 5;

-- Step 9: Final verification
SELECT 'FINAL VERIFICATION' as status;
SELECT 'BFF matches in regular matches table' as check_type, COUNT(*) as count 
FROM matches WHERE id IN (SELECT id FROM bff_matches);
SELECT 'Total matches' as check_type, COUNT(*) as count FROM matches;
SELECT 'Total BFF matches' as check_type, COUNT(*) as count FROM bff_matches;
SELECT 'Total messages' as check_type, COUNT(*) as count FROM messages;
