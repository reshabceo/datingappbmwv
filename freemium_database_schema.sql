-- FREEMIUM SYSTEM DATABASE SCHEMA
-- Complete implementation for dating app freemium model

-- =============================================================================
-- 1. DAILY LIMITS TRACKING
-- =============================================================================

-- Track daily usage for free users
CREATE TABLE IF NOT EXISTS user_daily_limits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  date DATE DEFAULT CURRENT_DATE,
  swipes_used INTEGER DEFAULT 0,
  super_likes_used INTEGER DEFAULT 0,
  messages_sent INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, date)
);

-- =============================================================================
-- 2. PREMIUM MESSAGES (BEFORE MATCHING)
-- =============================================================================

-- Store messages sent before matching (Tinder-like feature)
CREATE TABLE IF NOT EXISTS premium_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  recipient_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  message_content TEXT NOT NULL,
  is_blurred BOOLEAN DEFAULT true,
  revealed_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================================================
-- 3. IN-APP PURCHASES
-- =============================================================================

-- Track individual super like purchases and other in-app purchases
CREATE TABLE IF NOT EXISTS in_app_purchases (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  purchase_type TEXT NOT NULL, -- 'super_like_5', 'super_like_10', 'super_like_20', 'premium_1_month', etc.
  amount DECIMAL(10,2) NOT NULL,
  currency TEXT DEFAULT 'INR',
  platform TEXT NOT NULL, -- 'google_play', 'apple_pay', 'cashfree'
  transaction_id TEXT,
  status TEXT DEFAULT 'pending', -- 'pending', 'completed', 'failed', 'refunded'
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================================================
-- 4. REWIND TRACKING
-- =============================================================================

-- Track swipe history for rewind feature
ALTER TABLE swipes ADD COLUMN IF NOT EXISTS can_rewind BOOLEAN DEFAULT false;
ALTER TABLE swipes ADD COLUMN IF NOT EXISTS rewinded_at TIMESTAMP WITH TIME ZONE;

-- =============================================================================
-- 5. ENABLE ROW LEVEL SECURITY
-- =============================================================================

ALTER TABLE user_daily_limits ENABLE ROW LEVEL SECURITY;
ALTER TABLE premium_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE in_app_purchases ENABLE ROW LEVEL SECURITY;

-- =============================================================================
-- 6. RLS POLICIES
-- =============================================================================

-- User daily limits policies
CREATE POLICY "Users can view their own daily limits"
ON user_daily_limits FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own daily limits"
ON user_daily_limits FOR UPDATE
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own daily limits"
ON user_daily_limits FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Premium messages policies
CREATE POLICY "Users can view messages sent to them"
ON premium_messages FOR SELECT
USING (auth.uid() = recipient_id);

CREATE POLICY "Users can view messages they sent"
ON premium_messages FOR SELECT
USING (auth.uid() = sender_id);

CREATE POLICY "Users can insert their own messages"
ON premium_messages FOR INSERT
WITH CHECK (auth.uid() = sender_id);

CREATE POLICY "Users can update messages they sent"
ON premium_messages FOR UPDATE
USING (auth.uid() = sender_id);

-- In-app purchases policies
CREATE POLICY "Users can view their own purchases"
ON in_app_purchases FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own purchases"
ON in_app_purchases FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- =============================================================================
-- 7. DATABASE FUNCTIONS
-- =============================================================================

-- Check if user can perform action (swipe, super_like, message)
CREATE OR REPLACE FUNCTION can_perform_action(
  p_user_id UUID,
  p_action TEXT
) RETURNS BOOLEAN AS $$
DECLARE
  v_is_premium BOOLEAN;
  v_daily_usage RECORD;
  v_can_perform BOOLEAN := true;
BEGIN
  -- Check if user is premium
  SELECT is_premium INTO v_is_premium
  FROM profiles
  WHERE id = p_user_id;
  
  -- Premium users have no limits
  IF v_is_premium = true THEN
    RETURN true;
  END IF;
  
  -- Get today's usage for free users
  SELECT swipes_used, super_likes_used, messages_sent
  INTO v_daily_usage
  FROM user_daily_limits
  WHERE user_id = p_user_id AND date = CURRENT_DATE;
  
  -- Check limits based on action
  CASE p_action
    WHEN 'swipe' THEN
      v_can_perform := COALESCE(v_daily_usage.swipes_used, 0) < 20;
    WHEN 'super_like' THEN
      v_can_perform := COALESCE(v_daily_usage.super_likes_used, 0) < 1;
    WHEN 'message' THEN
      v_can_perform := COALESCE(v_daily_usage.messages_sent, 0) < 1;
    ELSE
      v_can_perform := false;
  END CASE;
  
  RETURN v_can_perform;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get daily usage for a user
CREATE OR REPLACE FUNCTION get_daily_usage(
  p_user_id UUID,
  p_date DATE DEFAULT CURRENT_DATE
) RETURNS TABLE (
  swipes_used INTEGER,
  super_likes_used INTEGER,
  messages_sent INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COALESCE(udl.swipes_used, 0) as swipes_used,
    COALESCE(udl.super_likes_used, 0) as super_likes_used,
    COALESCE(udl.messages_sent, 0) as messages_sent
  FROM user_daily_limits udl
  WHERE udl.user_id = p_user_id AND udl.date = p_date;
  
  -- If no record exists, return zeros
  IF NOT FOUND THEN
    RETURN QUERY SELECT 0, 0, 0;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Increment daily usage
CREATE OR REPLACE FUNCTION increment_daily_usage(
  p_user_id UUID,
  p_action TEXT
) RETURNS BOOLEAN AS $$
DECLARE
  v_is_premium BOOLEAN;
BEGIN
  -- Check if user is premium
  SELECT is_premium INTO v_is_premium
  FROM profiles
  WHERE id = p_user_id;
  
  -- Premium users don't need tracking
  IF v_is_premium = true THEN
    RETURN true;
  END IF;
  
  -- Insert or update daily usage
  INSERT INTO user_daily_limits (user_id, date, swipes_used, super_likes_used, messages_sent)
  VALUES (
    p_user_id,
    CURRENT_DATE,
    CASE WHEN p_action = 'swipe' THEN 1 ELSE 0 END,
    CASE WHEN p_action = 'super_like' THEN 1 ELSE 0 END,
    CASE WHEN p_action = 'message' THEN 1 ELSE 0 END
  )
  ON CONFLICT (user_id, date)
  DO UPDATE SET
    swipes_used = CASE 
      WHEN p_action = 'swipe' THEN user_daily_limits.swipes_used + 1 
      ELSE user_daily_limits.swipes_used 
    END,
    super_likes_used = CASE 
      WHEN p_action = 'super_like' THEN user_daily_limits.super_likes_used + 1 
      ELSE user_daily_limits.super_likes_used 
    END,
    messages_sent = CASE 
      WHEN p_action = 'message' THEN user_daily_limits.messages_sent + 1 
      ELSE user_daily_limits.messages_sent 
    END,
    updated_at = NOW();
  
  RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Send premium message before matching
CREATE OR REPLACE FUNCTION send_premium_message(
  p_recipient_id UUID,
  p_message_content TEXT
) RETURNS JSONB AS $$
DECLARE
  v_sender_id UUID;
  v_is_premium BOOLEAN;
  v_result JSONB;
BEGIN
  -- Get current user
  v_sender_id := auth.uid();
  
  IF v_sender_id IS NULL THEN
    RETURN jsonb_build_object('error', 'User not authenticated');
  END IF;
  
  -- Check if sender is premium
  SELECT is_premium INTO v_is_premium
  FROM profiles
  WHERE id = v_sender_id;
  
  IF v_is_premium != true THEN
    RETURN jsonb_build_object('error', 'Premium subscription required to send messages before matching');
  END IF;
  
  -- Insert premium message
  INSERT INTO premium_messages (sender_id, recipient_id, message_content)
  VALUES (v_sender_id, p_recipient_id, p_message_content);
  
  -- Create activity feed entry for recipient
  INSERT INTO user_events (
    event_type,
    event_data,
    user_id,
    timestamp
  ) VALUES (
    'premium_message_received',
    jsonb_build_object(
      'sender_id', v_sender_id,
      'message_preview', LEFT(p_message_content, 50),
      'is_blurred', true
    ),
    p_recipient_id,
    NOW()
  );
  
  RETURN jsonb_build_object('success', true, 'message_id', (SELECT id FROM premium_messages WHERE sender_id = v_sender_id AND recipient_id = p_recipient_id ORDER BY created_at DESC LIMIT 1));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Reveal premium message (when recipient gets premium)
CREATE OR REPLACE FUNCTION reveal_premium_message(
  p_message_id UUID
) RETURNS JSONB AS $$
DECLARE
  v_recipient_id UUID;
  v_is_premium BOOLEAN;
BEGIN
  -- Get current user
  v_recipient_id := auth.uid();
  
  IF v_recipient_id IS NULL THEN
    RETURN jsonb_build_object('error', 'User not authenticated');
  END IF;
  
  -- Check if recipient is premium
  SELECT is_premium INTO v_is_premium
  FROM profiles
  WHERE id = v_recipient_id;
  
  IF v_is_premium != true THEN
    RETURN jsonb_build_object('error', 'Premium subscription required to view messages');
  END IF;
  
  -- Update message to reveal
  UPDATE premium_messages
  SET is_blurred = false, revealed_at = NOW()
  WHERE id = p_message_id AND recipient_id = v_recipient_id;
  
  RETURN jsonb_build_object('success', true);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================================================
-- 8. GRANT PERMISSIONS
-- =============================================================================

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION can_perform_action(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION get_daily_usage(UUID, DATE) TO authenticated;
GRANT EXECUTE ON FUNCTION increment_daily_usage(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION send_premium_message(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION reveal_premium_message(UUID) TO authenticated;

-- =============================================================================
-- 9. INDEXES FOR PERFORMANCE
-- =============================================================================

CREATE INDEX IF NOT EXISTS idx_user_daily_limits_user_date ON user_daily_limits(user_id, date);
CREATE INDEX IF NOT EXISTS idx_premium_messages_recipient ON premium_messages(recipient_id);
CREATE INDEX IF NOT EXISTS idx_premium_messages_sender ON premium_messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_in_app_purchases_user ON in_app_purchases(user_id);
CREATE INDEX IF NOT EXISTS idx_swipes_can_rewind ON swipes(can_rewind) WHERE can_rewind = true;

-- =============================================================================
-- 10. SAMPLE DATA FOR TESTING
-- =============================================================================

-- Insert sample super like packages
INSERT INTO in_app_purchases (user_id, purchase_type, amount, currency, platform, status) VALUES
('00000000-0000-0000-0000-000000000000', 'super_like_5', 99.00, 'INR', 'google_play', 'completed'),
('00000000-0000-0000-0000-000000000000', 'super_like_10', 179.00, 'INR', 'apple_pay', 'completed'),
('00000000-0000-0000-0000-000000000000', 'super_like_20', 299.00, 'INR', 'google_play', 'completed')
ON CONFLICT DO NOTHING;

-- Success message
SELECT 'Freemium database schema created successfully!' as result;
