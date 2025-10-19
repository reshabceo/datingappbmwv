-- Add a real story for Emma so you can test story messaging
-- This will create an actual story in the database that you can reply to

-- 1. Get Emma's user ID
DO $$
DECLARE
  emma_user_id UUID;
  story_id UUID;
BEGIN
  -- Find Emma's ID from profiles
  SELECT id INTO emma_user_id 
  FROM profiles 
  WHERE name ILIKE '%emma%' 
  LIMIT 1;

  IF emma_user_id IS NULL THEN
    RAISE NOTICE 'Emma not found in profiles table';
  ELSE
    RAISE NOTICE 'Found Emma with ID: %', emma_user_id;
    
    -- Generate a new story ID
    story_id := gen_random_uuid();
    
    -- Insert a story for Emma
    -- Note: Stories expire after 24 hours by default
    INSERT INTO stories (id, user_id, media_url, created_at, expires_at)
    VALUES (
      story_id,
      emma_user_id,
      'https://picsum.photos/400/600?random=100', -- Placeholder image
      NOW(),
      NOW() + INTERVAL '24 hours'
    );
    
    RAISE NOTICE 'Created story with ID: %', story_id;
    
    -- Verify the story was created
    RAISE NOTICE 'Story created successfully!';
  END IF;
END $$;

-- 2. Verify Emma's story exists
SELECT 
  s.id as story_id,
  p.name as user_name,
  s.media_url,
  s.created_at,
  s.expires_at,
  CASE 
    WHEN s.expires_at > NOW() THEN 'Active'
    ELSE 'Expired'
  END as status
FROM stories s
JOIN profiles p ON p.id = s.user_id
WHERE p.name ILIKE '%emma%'
ORDER BY s.created_at DESC;

