-- Add subscription management functions
-- Run this after the basic tables are created

-- Function to check subscription validity
CREATE OR REPLACE FUNCTION check_subscription_validity(user_uuid UUID)
RETURNS BOOLEAN AS $$
DECLARE
  subscription_exists BOOLEAN;
BEGIN
  SELECT EXISTS(
    SELECT 1 FROM user_subscriptions 
    WHERE user_id = user_uuid 
    AND status = 'active' 
    AND end_date > NOW()
  ) INTO subscription_exists;
  
  RETURN subscription_exists;
END;
$$ LANGUAGE plpgsql;

-- Function to get subscription details
CREATE OR REPLACE FUNCTION get_user_subscription_status(user_uuid UUID)
RETURNS TABLE (
  is_premium BOOLEAN,
  plan_type TEXT,
  days_remaining INTEGER,
  subscription_id UUID,
  end_date TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.is_premium,
    us.plan_type,
    EXTRACT(DAYS FROM (us.end_date - NOW()))::INTEGER as days_remaining,
    us.id as subscription_id,
    us.end_date
  FROM profiles p
  LEFT JOIN user_subscriptions us ON p.id = us.user_id
  WHERE p.id = user_uuid
  AND (us.status = 'active' OR us.status IS NULL)
  AND (us.end_date > NOW() OR us.end_date IS NULL)
  ORDER BY us.created_at DESC
  LIMIT 1;
END;
$$ LANGUAGE plpgsql;

-- Function to automatically expire subscriptions
CREATE OR REPLACE FUNCTION expire_subscriptions()
RETURNS INTEGER AS $$
DECLARE
  expired_count INTEGER;
BEGIN
  -- Update expired subscriptions
  UPDATE user_subscriptions 
  SET status = 'expired', updated_at = NOW()
  WHERE status = 'active' 
  AND end_date <= NOW();
  
  GET DIAGNOSTICS expired_count = ROW_COUNT;
  
  -- Update user profiles
  UPDATE profiles 
  SET is_premium = FALSE, premium_until = NULL, updated_at = NOW()
  WHERE id IN (
    SELECT user_id FROM user_subscriptions 
    WHERE status = 'expired' AND end_date <= NOW()
  );
  
  RETURN expired_count;
END;
$$ LANGUAGE plpgsql;

-- Function to cancel subscription
CREATE OR REPLACE FUNCTION cancel_user_subscription(user_uuid UUID)
RETURNS BOOLEAN AS $$
DECLARE
  current_subscription RECORD;
BEGIN
  -- Get current active subscription
  SELECT * INTO current_subscription
  FROM user_subscriptions
  WHERE user_id = user_uuid
  AND status = 'active'
  AND end_date > NOW()
  ORDER BY created_at DESC
  LIMIT 1;
  
  IF current_subscription IS NULL THEN
    RETURN FALSE;
  END IF;
  
  -- Update subscription status
  UPDATE user_subscriptions
  SET 
    status = 'cancelled',
    cancelled_at = NOW(),
    updated_at = NOW()
  WHERE id = current_subscription.id;
  
  -- Update user profile
  UPDATE profiles
  SET 
    is_premium = FALSE,
    premium_until = NULL,
    updated_at = NOW()
  WHERE id = user_uuid;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for updated_at (only if they don't exist)
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_payment_orders_updated_at') THEN
        CREATE TRIGGER update_payment_orders_updated_at 
          BEFORE UPDATE ON payment_orders
          FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_user_subscriptions_updated_at') THEN
        CREATE TRIGGER update_user_subscriptions_updated_at 
          BEFORE UPDATE ON user_subscriptions
          FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_subscription_plans_updated_at') THEN
        CREATE TRIGGER update_subscription_plans_updated_at 
          BEFORE UPDATE ON subscription_plans
          FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
END $$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION check_subscription_validity(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_subscription_status(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION expire_subscriptions() TO service_role;
GRANT EXECUTE ON FUNCTION cancel_user_subscription(UUID) TO authenticated;
