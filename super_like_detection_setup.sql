-- Super Like Detection Setup
-- This adds functionality to detect who super liked you

-- Step 1: Create a function to get profiles with super like status
CREATE OR REPLACE FUNCTION get_profiles_with_super_likes(p_user_id UUID)
RETURNS TABLE (
  id UUID,
  name TEXT,
  age INT,
  image_urls JSONB,
  photos JSONB,
  location TEXT,
  bio TEXT,
  description TEXT,
  interests JSONB,
  hobbies JSONB,
  gender TEXT,
  latitude DECIMAL,
  longitude DECIMAL,
  is_super_liked BOOLEAN
)
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.id,
    p.name,
    p.age,
    p.image_urls,
    p.photos,
    p.location,
    p.bio,
    p.description,
    p.interests,
    p.hobbies,
    p.gender,
    p.latitude,
    p.longitude,
    -- Check if this profile super liked the current user
    EXISTS(
      SELECT 1 
      FROM swipes s 
      WHERE s.swiper_id = p.id 
        AND s.swiped_id = p_user_id 
        AND s.action = 'super_like'
    ) as is_super_liked
  FROM profiles p
  WHERE p.id != p_user_id
    AND p.is_active = true
    -- Exclude profiles the user has already swiped on
    AND NOT EXISTS (
      SELECT 1 
      FROM swipes s2 
      WHERE s2.swiper_id = p_user_id 
        AND s2.swiped_id = p.id
    )
  ORDER BY 
    -- Show super likes first
    EXISTS(
      SELECT 1 
      FROM swipes s 
      WHERE s.swiper_id = p.id 
        AND s.swiped_id = p_user_id 
        AND s.action = 'super_like'
    ) DESC,
    p.created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- Step 2: Grant execute permission
GRANT EXECUTE ON FUNCTION get_profiles_with_super_likes(UUID) TO authenticated;

-- Step 3: Test the function (replace with your actual user ID)
-- SELECT * FROM get_profiles_with_super_likes((SELECT id FROM auth.users WHERE email = 'reshab.retheesh@gmail.com'));

-- Step 4: Verify function was created
SELECT 
  routine_name,
  routine_type,
  security_type
FROM information_schema.routines 
WHERE routine_name = 'get_profiles_with_super_likes';

-- Success message
DO $$
BEGIN
  RAISE NOTICE '✅ Super like detection setup complete!';
  RAISE NOTICE '📊 Created function: get_profiles_with_super_likes()';
  RAISE NOTICE '⭐ Super liked profiles will now be shown first with glow effect!';
END $$;

