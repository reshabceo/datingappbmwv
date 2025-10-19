-- Fix the get_profiles_with_super_likes function to match actual table structure
DROP FUNCTION IF EXISTS get_profiles_with_super_likes(UUID);

CREATE OR REPLACE FUNCTION get_profiles_with_super_likes(p_user_id UUID)
RETURNS TABLE (
  id UUID,
  name TEXT,
  age INTEGER,
  photos JSONB,
  location TEXT,
  description TEXT,
  hobbies JSONB,
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
    p.photos,
    p.location,
    p.description,
    p.hobbies,
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
