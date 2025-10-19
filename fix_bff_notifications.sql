-- Fix BFF Notifications in Activity Feed
-- The get_user_activities function needs to include BFF matches

-- Drop and recreate the function to include BFF matches
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
    -- Activity Type 1: New likes on your profile (dating mode)
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
        THEN p.photos->0->>0::TEXT 
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
    
    -- Activity Type 2: New matches (dating mode)
    SELECT 
      m.id as activity_id,
      'match'::TEXT as activity_type,
      CASE 
        WHEN m.user_id_1 = p_user_id THEN m.user_id_2
        ELSE m.user_id_1
      END as other_user_id,
      CASE 
        WHEN m.user_id_1 = p_user_id THEN COALESCE(p2.name, 'User')::TEXT
        ELSE COALESCE(p1.name, 'User')::TEXT
      END as other_user_name,
      CASE 
        WHEN m.user_id_1 = p_user_id THEN 
          CASE 
            WHEN p2.photos IS NOT NULL AND jsonb_array_length(p2.photos) > 0 
            THEN p2.photos->0->>0::TEXT 
            ELSE ''::TEXT 
          END
        ELSE 
          CASE 
            WHEN p1.photos IS NOT NULL AND jsonb_array_length(p1.photos) > 0 
            THEN p1.photos->0->>0::TEXT 
            ELSE ''::TEXT 
          END
      END as other_user_photo,
      NULL::TEXT as message_preview,
      m.created_at,
      TRUE as is_unread
    FROM matches m
    LEFT JOIN profiles p1 ON p1.id = m.user_id_1
    LEFT JOIN profiles p2 ON p2.id = m.user_id_2
    WHERE (m.user_id_1 = p_user_id OR m.user_id_2 = p_user_id)
      AND m.status = 'matched'
      AND m.created_at > NOW() - INTERVAL '7 days'
    
    UNION ALL
    
    -- Activity Type 3: New BFF likes on your profile
    SELECT 
      bs.id as activity_id,
      CASE 
        WHEN bs.action = 'super_like' THEN 'super_like'::TEXT 
        ELSE 'like'::TEXT 
      END as activity_type,
      bs.swiper_id as other_user_id,
      COALESCE(p.name, 'User')::TEXT as other_user_name,
      CASE 
        WHEN p.photos IS NOT NULL AND jsonb_array_length(p.photos) > 0 
        THEN p.photos->0->>0::TEXT 
        ELSE ''::TEXT 
      END as other_user_photo,
      NULL::TEXT as message_preview,
      bs.created_at,
      TRUE as is_unread
    FROM bff_swipes bs
    LEFT JOIN profiles p ON p.id = bs.swiper_id
    WHERE bs.swiped_id = p_user_id 
      AND bs.action IN ('like', 'super_like')
      -- Only show BFF likes if they haven't matched yet
      AND NOT EXISTS (
        SELECT 1 FROM bff_matches bm 
        WHERE (bm.user_id_1 = p_user_id AND bm.user_id_2 = bs.swiper_id)
           OR (bm.user_id_2 = p_user_id AND bm.user_id_1 = bs.swiper_id)
      )
      AND bs.created_at > NOW() - INTERVAL '7 days'
    
    UNION ALL
    
    -- Activity Type 4: New BFF matches
    SELECT 
      bm.id as activity_id,
      'bff_match'::TEXT as activity_type,
      CASE 
        WHEN bm.user_id_1 = p_user_id THEN bm.user_id_2
        ELSE bm.user_id_1
      END as other_user_id,
      CASE 
        WHEN bm.user_id_1 = p_user_id THEN COALESCE(p2.name, 'User')::TEXT
        ELSE COALESCE(p1.name, 'User')::TEXT
      END as other_user_name,
      CASE 
        WHEN bm.user_id_1 = p_user_id THEN 
          CASE 
            WHEN p2.photos IS NOT NULL AND jsonb_array_length(p2.photos) > 0 
            THEN p2.photos->0->>0::TEXT 
            ELSE ''::TEXT 
          END
        ELSE 
          CASE 
            WHEN p1.photos IS NOT NULL AND jsonb_array_length(p1.photos) > 0 
            THEN p1.photos->0->>0::TEXT 
            ELSE ''::TEXT 
          END
      END as other_user_photo,
      NULL::TEXT as message_preview,
      bm.created_at,
      TRUE as is_unread
    FROM bff_matches bm
    LEFT JOIN profiles p1 ON p1.id = bm.user_id_1
    LEFT JOIN profiles p2 ON p2.id = bm.user_id_2
    WHERE (bm.user_id_1 = p_user_id OR bm.user_id_2 = p_user_id)
      AND bm.status = 'matched'
      AND bm.created_at > NOW() - INTERVAL '7 days'
    
    UNION ALL
    
    -- Activity Type 5: New messages (dating chats)
    SELECT 
      msg.id as activity_id,
      'message'::TEXT as activity_type,
      msg.sender_id as other_user_id,
      COALESCE(p.name, 'User')::TEXT as other_user_name,
      CASE 
        WHEN p.photos IS NOT NULL AND jsonb_array_length(p.photos) > 0 
        THEN p.photos->0->>0::TEXT 
        ELSE ''::TEXT 
      END as other_user_photo,
      LEFT(msg.content, 50)::TEXT as message_preview,
      msg.created_at,
      NOT msg.is_read as is_unread
    FROM messages msg
    LEFT JOIN profiles p ON p.id = msg.sender_id
    LEFT JOIN matches m ON m.id = msg.match_id
    WHERE msg.sender_id != p_user_id
      AND (m.user_id_1 = p_user_id OR m.user_id_2 = p_user_id)
      AND msg.created_at > NOW() - INTERVAL '7 days'
    
    UNION ALL
    
    -- Activity Type 6: New BFF messages
    SELECT 
      bmsg.id as activity_id,
      'bff_message'::TEXT as activity_type,
      bmsg.sender_id as other_user_id,
      COALESCE(p.name, 'User')::TEXT as other_user_name,
      CASE 
        WHEN p.photos IS NOT NULL AND jsonb_array_length(p.photos) > 0 
        THEN p.photos->0->>0::TEXT 
        ELSE ''::TEXT 
      END as other_user_photo,
      LEFT(bmsg.text, 50)::TEXT as message_preview,
      bmsg.created_at,
      TRUE as is_unread
    FROM bff_messages bmsg
    LEFT JOIN profiles p ON p.id = bmsg.sender_id
    LEFT JOIN bff_chats bc ON bc.id = bmsg.chat_id
    WHERE bmsg.sender_id != p_user_id
      AND (bc.user_a_id = p_user_id OR bc.user_b_id = p_user_id)
      AND bmsg.created_at > NOW() - INTERVAL '7 days'
      
  ) combined_activities
  ORDER BY created_at DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- Grant permissions
GRANT EXECUTE ON FUNCTION get_user_activities(UUID, INT) TO authenticated;

-- Test the function
SELECT 
    'Testing updated get_user_activities function' as test_name,
    COUNT(*) as total_activities
FROM get_user_activities('7ffe44fe-9c0f-4783-aec2-a6172a6e008b', 50);

-- Show recent activities including BFF matches
SELECT 
    activity_type,
    other_user_name,
    created_at,
    is_unread
FROM get_user_activities('7ffe44fe-9c0f-4783-aec2-a6172a6e008b', 10)
ORDER BY created_at DESC;
