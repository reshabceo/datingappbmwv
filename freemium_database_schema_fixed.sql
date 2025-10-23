-- FREEMIUM SYSTEM DATABASE SCHEMA - FIXED VERSION
-- Complete implementation for dating app freemium model

-- =============================================================================
-- 1. DAILY LIMITS TRACKING
-- =============================================================================

-- Track daily usage for free users
CREATE TABLE IF NOT EXISTS user_daily_limits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  date DATE DEFAULT CURRENT_DATE,
  swipes_used INTEGER DEFAULT 0,
  super_likes_used INTEGER DEFAULT 0,
  messages_sent INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, date)
);

-- Add foreign key constraint after table creation
ALTER TABLE user_daily_limits 
ADD CONSTRAINT user_daily_limits_user_id_fkey 
FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE;

-- =============================================================================
-- 2. PREMIUM MESSAGES (BEFORE MATCHING)
-- =============================================================================

-- Store messages sent before matching (Tinder-like feature)
CREATE TABLE IF NOT EXISTS premium_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id UUID NOT NULL,
  recipient_id UUID NOT NULL,
  message_content TEXT NOT NULL,
  is_blurred BOOLEAN DEFAULT true,
  revealed_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add foreign key constraints after table creation
ALTER TABLE premium_messages 
ADD CONSTRAINT premium_messages_sender_id_fkey 
FOREIGN KEY (sender_id) REFERENCES profiles(id) ON DELETE CASCADE;

ALTER TABLE premium_messages 
ADD CONSTRAINT premium_messages_recipient_id_fkey 
FOREIGN KEY (recipient_id) REFERENCES profiles(id) ON DELETE CASCADE;

-- =============================================================================
-- 3. IN-APP PURCHASES
-- =============================================================================

-- Track individual super like purchases and subscriptions
CREATE TABLE IF NOT EXISTS in_app_purchases (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  purchase_type TEXT NOT NULL, -- 'super_like_5', 'super_like_10', 'super_like_20', 'premium_1_month', etc.
  amount DECIMAL(10,2) NOT NULL,
  currency TEXT DEFAULT 'INR',
  platform TEXT NOT NULL, -- 'google_play', 'apple_pay', 'cashfree'
  transaction_id TEXT,
  status TEXT DEFAULT 'pending', -- 'pending', 'completed', 'failed', 'refunded'
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add foreign key constraint after table creation
ALTER TABLE in_app_purchases 
ADD CONSTRAINT in_app_purchases_user_id_fkey 
FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE;

-- =============================================================================
-- 4. REWIND FUNCTIONALITY
-- =============================================================================

-- Add rewind columns to existing swipes table
ALTER TABLE swipes 
ADD COLUMN IF NOT EXISTS can_rewind BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS rewinded_at TIMESTAMP WITH TIME ZONE;

-- =============================================================================
-- 5. PREMIUM SUBSCRIPTION TRACKING
-- =============================================================================

-- Track premium subscription status
CREATE TABLE IF NOT EXISTS premium_subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  subscription_type TEXT NOT NULL, -- 'monthly', 'quarterly', 'semiannual'
  start_date TIMESTAMP WITH TIME ZONE NOT NULL,
  end_date TIMESTAMP WITH TIME ZONE NOT NULL,
  is_active BOOLEAN DEFAULT true,
  payment_method TEXT, -- 'in_app_purchase', 'cashfree', 'stripe'
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add foreign key constraint after table creation
ALTER TABLE premium_subscriptions 
ADD CONSTRAINT premium_subscriptions_user_id_fkey 
FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE;

-- =============================================================================
-- 6. FUNCTIONS FOR FREEMIUM LOGIC
-- =============================================================================

-- Function to check if user can perform action
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
  -- Check if user is premium
  SELECT is_premium INTO user_premium 
  FROM profiles 
  WHERE id = p_user_id;
  
  -- Premium users have no limits
  IF user_premium THEN
    RETURN TRUE;
  END IF;
  
  -- Get daily usage for the date
  SELECT * INTO daily_usage 
  FROM user_daily_limits 
  WHERE user_id = p_user_id AND date = p_date;
  
  -- Set limits for free users
  CASE p_action
    WHEN 'swipe' THEN action_limit := 20;
    WHEN 'super_like' THEN action_limit := 1;
    WHEN 'message' THEN action_limit := 1;
    ELSE action_limit := 0;
  END CASE;
  
  -- Check if limit reached
  CASE p_action
    WHEN 'swipe' THEN 
      RETURN COALESCE(daily_usage.swipes_used, 0) < action_limit;
    WHEN 'super_like' THEN 
      RETURN COALESCE(daily_usage.super_likes_used, 0) < action_limit;
    WHEN 'message' THEN 
      RETURN COALESCE(daily_usage.messages_sent, 0) < action_limit;
    ELSE 
      RETURN FALSE;
  END CASE;
END;
$$ LANGUAGE plpgsql;

-- Function to increment daily usage
CREATE OR REPLACE FUNCTION increment_daily_usage(
  p_user_id UUID,
  p_action TEXT,
  p_date DATE DEFAULT CURRENT_DATE
) RETURNS VOID AS $$
BEGIN
  -- Insert or update daily usage
  INSERT INTO user_daily_limits (user_id, date, swipes_used, super_likes_used, messages_sent)
  VALUES (
    p_user_id, 
    p_date,
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
END;
$$ LANGUAGE plpgsql;

-- Function to add super likes to user account
CREATE OR REPLACE FUNCTION add_super_likes(
  p_user_id UUID,
  p_super_likes_to_add INTEGER
) RETURNS VOID AS $$
BEGIN
  -- This function would typically update a user's super like balance
  -- For now, we'll just log the addition
  INSERT INTO in_app_purchases (
    user_id, 
    purchase_type, 
    amount, 
    currency, 
    platform, 
    status
  ) VALUES (
    p_user_id,
    'super_like_pack_' || p_super_likes_to_add,
    0.00, -- Free super likes from purchase
    'INR',
    'in_app_purchase',
    'completed'
  );
END;
$$ LANGUAGE plpgsql;

-- Function to activate premium subscription
CREATE OR REPLACE FUNCTION activate_premium_subscription(
  p_user_id UUID,
  p_duration_months INTEGER,
  p_payment_method TEXT DEFAULT 'in_app_purchase'
) RETURNS VOID AS $$
DECLARE
  start_date TIMESTAMP WITH TIME ZONE;
  end_date TIMESTAMP WITH TIME ZONE;
BEGIN
  start_date := NOW();
  end_date := start_date + (p_duration_months || ' months')::INTERVAL;
  
  -- Insert subscription record
  INSERT INTO premium_subscriptions (
    user_id,
    subscription_type,
    start_date,
    end_date,
    payment_method
  ) VALUES (
    p_user_id,
    CASE p_duration_months
      WHEN 1 THEN 'monthly'
      WHEN 3 THEN 'quarterly'
      WHEN 6 THEN 'semiannual'
      ELSE 'monthly'
    END,
    start_date,
    end_date,
    p_payment_method
  );
  
  -- Update user's premium status
  UPDATE profiles 
  SET is_premium = true 
  WHERE id = p_user_id;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- 7. INDEXES FOR PERFORMANCE
-- =============================================================================

-- Indexes for daily limits
CREATE INDEX IF NOT EXISTS idx_user_daily_limits_user_date 
ON user_daily_limits(user_id, date);

-- Indexes for premium messages
CREATE INDEX IF NOT EXISTS idx_premium_messages_recipient 
ON premium_messages(recipient_id);

CREATE INDEX IF NOT EXISTS idx_premium_messages_sender 
ON premium_messages(sender_id);

-- Indexes for in-app purchases
CREATE INDEX IF NOT EXISTS idx_in_app_purchases_user 
ON in_app_purchases(user_id);

CREATE INDEX IF NOT EXISTS idx_in_app_purchases_status 
ON in_app_purchases(status);

-- Indexes for premium subscriptions
CREATE INDEX IF NOT EXISTS idx_premium_subscriptions_user 
ON premium_subscriptions(user_id);

CREATE INDEX IF NOT EXISTS idx_premium_subscriptions_active 
ON premium_subscriptions(is_active);

-- =============================================================================
-- 8. ROW LEVEL SECURITY (RLS) POLICIES
-- =============================================================================

-- Enable RLS on all tables
ALTER TABLE user_daily_limits ENABLE ROW LEVEL SECURITY;
ALTER TABLE premium_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE in_app_purchases ENABLE ROW LEVEL SECURITY;
ALTER TABLE premium_subscriptions ENABLE ROW LEVEL SECURITY;

-- Daily limits policies
CREATE POLICY "Users can view their own daily limits" ON user_daily_limits
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own daily limits" ON user_daily_limits
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own daily limits" ON user_daily_limits
  FOR UPDATE USING (auth.uid() = user_id);

-- Premium messages policies
CREATE POLICY "Users can view messages sent to them" ON premium_messages
  FOR SELECT USING (auth.uid() = recipient_id OR auth.uid() = sender_id);

CREATE POLICY "Users can send premium messages" ON premium_messages
  FOR INSERT WITH CHECK (auth.uid() = sender_id);

CREATE POLICY "Users can update messages they sent" ON premium_messages
  FOR UPDATE USING (auth.uid() = sender_id);

-- In-app purchases policies
CREATE POLICY "Users can view their own purchases" ON in_app_purchases
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own purchases" ON in_app_purchases
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Premium subscriptions policies
CREATE POLICY "Users can view their own subscriptions" ON premium_subscriptions
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own subscriptions" ON premium_subscriptions
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- =============================================================================
-- 9. TRIGGERS FOR AUTOMATIC UPDATES
-- =============================================================================

-- Trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply triggers to all tables
CREATE TRIGGER update_user_daily_limits_updated_at
  BEFORE UPDATE ON user_daily_limits
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_premium_messages_updated_at
  BEFORE UPDATE ON premium_messages
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_in_app_purchases_updated_at
  BEFORE UPDATE ON in_app_purchases
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_premium_subscriptions_updated_at
  BEFORE UPDATE ON premium_subscriptions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================================================
-- 10. SAMPLE DATA FOR TESTING (OPTIONAL)
-- =============================================================================

-- Uncomment the following lines to add sample data for testing
-- Note: Replace with actual user IDs from your profiles table

/*
-- Sample daily limits for testing
INSERT INTO user_daily_limits (user_id, swipes_used, super_likes_used, messages_sent)
SELECT 
  id,
  FLOOR(RANDOM() * 15)::INTEGER, -- Random swipes used (0-15)
  FLOOR(RANDOM() * 2)::INTEGER,  -- Random super likes used (0-1)
  FLOOR(RANDOM() * 2)::INTEGER   -- Random messages sent (0-1)
FROM profiles 
WHERE id IS NOT NULL
LIMIT 10;
*/

-- =============================================================================
-- COMPLETION MESSAGE
-- =============================================================================

-- The freemium system is now ready!
-- All tables, functions, indexes, and policies have been created.
-- You can now use the freemium features in your Flutter app.
