-- Fix superlike limit to be 1 per day for ALL users (free and premium)
-- This updates the can_perform_action function to enforce superlike limit for everyone

CREATE OR REPLACE FUNCTION can_perform_action(
  p_user_id UUID,
  p_action TEXT,
  p_date DATE DEFAULT CURRENT_DATE
) RETURNS BOOLEAN AS $$
DECLARE
  user_premium BOOLEAN;
  daily_usage RECORD;
  action_limit INTEGER;
BEGIN
  -- Check if user exists and is premium
  SELECT COALESCE(is_premium, false) INTO user_premium 
  FROM profiles 
  WHERE id = p_user_id;
  
  -- Get daily usage for the date (for ALL users)
  SELECT * INTO daily_usage 
  FROM user_daily_limits 
  WHERE user_id = p_user_id AND date = p_date;
  
  -- Set limits based on action
  CASE p_action
    WHEN 'swipe' THEN 
      -- Premium users have unlimited swipes, free users have 20
      IF user_premium THEN
        action_limit := 999999; -- Effectively unlimited for premium
      ELSE
        action_limit := 20;
      END IF;
    WHEN 'super_like' THEN 
      -- ALL users (free and premium) have 1 superlike per day
      action_limit := 1;
    WHEN 'message' THEN 
      -- Premium users have unlimited messages, free users have 1
      IF user_premium THEN
        action_limit := 999999; -- Effectively unlimited for premium
      ELSE
        action_limit := 1;
      END IF;
    ELSE 
      action_limit := 0;
  END CASE;
  
  -- Check if limit reached
  CASE p_action
    WHEN 'swipe' THEN 
      RETURN COALESCE(daily_usage.swipes_used, 0) < action_limit;
    WHEN 'super_like' THEN 
      -- Enforce limit for ALL users (free and premium)
      RETURN COALESCE(daily_usage.super_likes_used, 0) < action_limit;
    WHEN 'message' THEN 
      RETURN COALESCE(daily_usage.messages_sent, 0) < action_limit;
    ELSE 
      RETURN FALSE;
  END CASE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update increment_daily_usage to track superlikes for ALL users
CREATE OR REPLACE FUNCTION increment_daily_usage(
  p_user_id UUID,
  p_action TEXT,
  p_date DATE DEFAULT CURRENT_DATE
) RETURNS VOID AS $$
DECLARE
  user_premium BOOLEAN;
BEGIN
  -- Check if user exists and is premium
  SELECT COALESCE(is_premium, false) INTO user_premium 
  FROM profiles 
  WHERE id = p_user_id;
  
  -- For swipes and messages: only track for free users
  -- For superlikes: track for ALL users (free and premium)
  IF p_action != 'super_like' AND user_premium THEN
    -- Premium users don't need tracking for swipes and messages
    RETURN;
  END IF;
  
  -- Insert or update daily usage
  -- Always track superlikes for all users, but only track swipes/messages for free users
  INSERT INTO user_daily_limits (user_id, date, swipes_used, super_likes_used, messages_sent)
  VALUES (
    p_user_id,
    p_date,
    CASE WHEN p_action = 'swipe' AND NOT user_premium THEN 1 ELSE 0 END,
    CASE WHEN p_action = 'super_like' THEN 1 ELSE 0 END,
    CASE WHEN p_action = 'message' AND NOT user_premium THEN 1 ELSE 0 END
  )
  ON CONFLICT (user_id, date)
  DO UPDATE SET
    swipes_used = CASE 
      WHEN p_action = 'swipe' AND NOT user_premium 
        THEN user_daily_limits.swipes_used + 1 
      ELSE user_daily_limits.swipes_used 
    END,
    super_likes_used = CASE 
      WHEN p_action = 'super_like' THEN user_daily_limits.super_likes_used + 1 
      ELSE user_daily_limits.super_likes_used 
    END,
    messages_sent = CASE 
      WHEN p_action = 'message' AND NOT user_premium 
        THEN user_daily_limits.messages_sent + 1 
      ELSE user_daily_limits.messages_sent 
    END,
    updated_at = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Verification query
SELECT 
  'Functions updated successfully. Superlike limit is now 1 per day for ALL users (free and premium).' as status;

