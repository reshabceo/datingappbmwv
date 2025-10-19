-- Fix BFF Profile Filtering Issue
-- The problem: get_bff_profiles looks in bff_interactions but handle_bff_swipe records in bff_swipes

-- Drop the existing function first
DROP FUNCTION IF EXISTS public.get_bff_profiles(UUID);

-- Create the updated get_bff_profiles function to check the correct table
CREATE OR REPLACE FUNCTION public.get_bff_profiles(
  p_user_id UUID
)
RETURNS TABLE(
  id UUID,
  name TEXT,
  age INTEGER,
  photos JSONB,
  location TEXT,
  description TEXT,
  hobbies JSONB,
  created_at TIMESTAMP WITH TIME ZONE
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT
    p.id, p.name, p.age, p.photos, p.location, p.description, p.hobbies, p.created_at
  FROM profiles p
  WHERE p.id != p_user_id
    AND p.mode_preferences->>'bff' = 'true'
    -- Check BOTH tables for interactions
    AND p.id NOT IN (
      SELECT target_user_id 
      FROM bff_interactions 
      WHERE user_id = p_user_id
    )
    AND p.id NOT IN (
      SELECT swiped_id 
      FROM bff_swipes 
      WHERE swiper_id = p_user_id
    )
    -- Also exclude existing matches
    AND p.id NOT IN (
      SELECT CASE 
        WHEN user_id_1 = p_user_id THEN user_id_2 
        ELSE user_id_1 
      END 
      FROM bff_matches 
      WHERE (user_id_1 = p_user_id OR user_id_2 = p_user_id) 
        AND status IN ('matched', 'active')
    )
  ORDER BY p.created_at DESC
  LIMIT 20;
END;
$$;

-- Test the function to see what profiles are available
SELECT 
    'Available BFF profiles after fix' as test_name,
    COUNT(*) as count
FROM get_bff_profiles('7ffe44fe-9c0f-4783-aec2-a6172a6e008b');

-- Show which profiles are available
SELECT 
    id,
    name,
    age,
    created_at
FROM get_bff_profiles('7ffe44fe-9c0f-4783-aec2-a6172a6e008b')
ORDER BY id DESC
LIMIT 10;
