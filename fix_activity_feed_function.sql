-- Fix Activity Feed Function for JSONB photos column
-- Run this to replace the previous function

DROP FUNCTION IF EXISTS get_user_activities(UUID, INT);

CREATE OR REPLACE FUNCTION get_user_activities(p_user_id UUID, p_limit INT DEFAULT 50)
RETURNS TABLE (
  activity_id UUID,
  activity_type TEXT,
  other_user_id UUID,
  other_user_name TEXT,
  other_user_photo TEXT,
  message_preview TEXT,
  created_at TIMESTAMP WITH TIME ZONE,
  is_unread BOOLEAN
) 
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT * FROM (
    -- Activity Type 1: New likes on your profile
    SELECT 
      s.id as activity_id,
      CASE 
        WHEN s.action = 'super_like' THEN 'super_like'::TEXT 
        ELSE 'like'::TEXT 
      END as activity_type,
      s.swiper_id as other_user_id,
      COALESCE(p.name, 'User')::TEXT as other_user_name,
      CASE 
        WHEN p.photos IS NOT NULL AND jsonb_array_length(p.photos) > 0 
        THEN (p.photos->0)::TEXT 
        ELSE ''::TEXT 
      END as other_user_photo,
      NULL::TEXT as message_preview,
      s.created_at,
      TRUE as is_unread
    FROM swipes s
    LEFT JOIN profiles p ON p.id = s.swiper_id
    WHERE s.swiped_id = p_user_id 
      AND s.action IN ('like', 'super_like')
      -- Only show likes if they haven't matched yet
      AND NOT EXISTS (
        SELECT 1 FROM matches m 
        WHERE (m.user_id_1 = p_user_id AND m.user_id_2 = s.swiper_id)
           OR (m.user_id_2 = p_user_id AND m.user_id_1 = s.swiper_id)
      )
      AND s.created_at > NOW() - INTERVAL '7 days'
    
    UNION ALL
    
    -- Activity Type 2: New matches
    SELECT 
      m.id as activity_id,
      'match'::TEXT as activity_type,
      CASE 
        WHEN m.user_id_1 = p_user_id THEN m.user_id_2 
        ELSE m.user_id_1 
      END as other_user_id,
      COALESCE(p.name, 'User')::TEXT as other_user_name,
      CASE 
        WHEN p.photos IS NOT NULL AND jsonb_array_length(p.photos) > 0 
        THEN (p.photos->0)::TEXT 
        ELSE ''::TEXT 
      END as other_user_photo,
      NULL::TEXT as message_preview,
      m.created_at,
      TRUE as is_unread
    FROM matches m
    LEFT JOIN profiles p ON p.id = CASE 
      WHEN m.user_id_1 = p_user_id THEN m.user_id_2 
      ELSE m.user_id_1 
    END
    WHERE (m.user_id_1 = p_user_id OR m.user_id_2 = p_user_id)
      AND m.status = 'matched'
      AND m.created_at > NOW() - INTERVAL '7 days'
    
    UNION ALL
    
    -- Activity Type 3: New messages
    SELECT 
      msg.id as activity_id,
      'message'::TEXT as activity_type,
      msg.sender_id as other_user_id,
      COALESCE(p.name, 'User')::TEXT as other_user_name,
      CASE 
        WHEN p.photos IS NOT NULL AND jsonb_array_length(p.photos) > 0 
        THEN (p.photos->0)::TEXT 
        ELSE ''::TEXT 
      END as other_user_photo,
      SUBSTRING(msg.content, 1, 50)::TEXT as message_preview,
      msg.created_at,
      NOT msg.is_read as is_unread
    FROM messages msg
    JOIN matches m ON m.id = msg.match_id
    LEFT JOIN profiles p ON p.id = msg.sender_id
    WHERE (m.user_id_1 = p_user_id OR m.user_id_2 = p_user_id)
      AND msg.sender_id != p_user_id
      AND msg.created_at > NOW() - INTERVAL '3 days'
  ) activities
  ORDER BY created_at DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_user_activities(UUID, INT) TO authenticated;

-- Test it
SELECT 
  activity_type,
  other_user_name,
  message_preview,
  created_at,
  is_unread
FROM get_user_activities(
  (SELECT id FROM auth.users WHERE email = 'reshab.retheesh@gmail.com'),
  50
);

