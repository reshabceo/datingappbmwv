-- Get Potential Matches Count and Last Liker Details
-- This function returns the count of users who liked the current user (not matched yet)
-- and the details of the most recent liker

DROP FUNCTION IF EXISTS get_potential_matches(UUID);

CREATE OR REPLACE FUNCTION get_potential_matches(p_user_id UUID)
RETURNS TABLE (
  total_count INTEGER,
  last_liker_id UUID,
  last_liker_name TEXT,
  last_liker_photo TEXT,
  last_liked_at TIMESTAMP WITH TIME ZONE
) 
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_total_count INTEGER := 0;
  v_last_liker_id UUID;
  v_last_liker_name TEXT;
  v_last_liker_photo TEXT;
  v_last_liked_at TIMESTAMP WITH TIME ZONE;
BEGIN
  -- Count total likes (not matched)
  SELECT COUNT(*)::INTEGER
  INTO v_total_count
  FROM swipes s
  WHERE s.swiped_id = p_user_id 
    AND s.action IN ('like', 'super_like')
    -- Only count likes if they haven't matched yet
    AND NOT EXISTS (
      SELECT 1 FROM matches m 
      WHERE (m.user_id_1 = p_user_id AND m.user_id_2 = s.swiper_id)
         OR (m.user_id_2 = p_user_id AND m.user_id_1 = s.swiper_id)
    );
  
  -- Get last liker details
  SELECT 
    s.swiper_id,
    COALESCE(p.name, 'User')::TEXT,
    CASE 
      WHEN p.image_urls IS NOT NULL AND jsonb_array_length(p.image_urls) > 0 
      THEN (p.image_urls->>0)::TEXT 
      ELSE ''::TEXT 
    END,
    s.created_at
  INTO 
    v_last_liker_id,
    v_last_liker_name,
    v_last_liker_photo,
    v_last_liked_at
  FROM swipes s
  LEFT JOIN profiles p ON p.id = s.swiper_id
  WHERE s.swiped_id = p_user_id 
    AND s.action IN ('like', 'super_like')
    -- Only get last liker if they haven't matched yet
    AND NOT EXISTS (
      SELECT 1 FROM matches m 
      WHERE (m.user_id_1 = p_user_id AND m.user_id_2 = s.swiper_id)
         OR (m.user_id_2 = p_user_id AND m.user_id_1 = s.swiper_id)
    )
  ORDER BY s.created_at DESC
  LIMIT 1;
  
  -- Return results
  RETURN QUERY SELECT 
    v_total_count,
    v_last_liker_id,
    v_last_liker_name,
    v_last_liker_photo,
    v_last_liked_at;
END;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION get_potential_matches(UUID) TO anon, authenticated;

