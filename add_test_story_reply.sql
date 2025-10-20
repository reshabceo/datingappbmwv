-- Add a test story reply message to test the story preview feature
-- This will create a message that replies to one of the existing stories

-- First, let's get the story ID from one of the existing stories
-- We'll use Alex's first story (the workout one)

-- Insert a story reply message
INSERT INTO messages (
    match_id,
    sender_id,
    content,
    is_story_reply,
    story_id,
    story_user_name,
    created_at
) VALUES (
    'test-match-id', -- Replace with actual match ID
    'c1ffb3e0-0e25-4176-9736-0db8522fd357', -- Current user ID
    'hey',
    true,
    (SELECT id FROM stories WHERE user_id = '22222222-2222-2222-2222-222222222222' ORDER BY created_at DESC LIMIT 1),
    'Alex',
    NOW()
);

-- Verify the story reply message was created
SELECT 
    m.id,
    m.content,
    m.is_story_reply,
    m.story_id,
    m.story_user_name,
    s.media_url,
    s.content as story_content,
    s.created_at as story_created_at
FROM messages m
LEFT JOIN stories s ON m.story_id = s.id
WHERE m.is_story_reply = true
ORDER BY m.created_at DESC
LIMIT 5;
