-- Subscription Expiration Management Functions
-- Run this in your Supabase SQL Editor

-- Function to check and expire subscriptions
CREATE OR REPLACE FUNCTION check_and_expire_subscriptions()
RETURNS TABLE (
  expired_count INTEGER,
  expired_user_ids UUID[]
) AS $$
DECLARE
  expired_subscriptions RECORD;
  expired_count INTEGER := 0;
  expired_user_ids UUID[] := '{}';
BEGIN
  -- Get all active subscriptions that have expired
  FOR expired_subscriptions IN
    SELECT us.id, us.user_id, us.plan_type, us.end_date
    FROM user_subscriptions us
    WHERE us.status = 'active'
    AND us.end_date <= NOW()
  LOOP
    -- Update subscription status to expired
    UPDATE user_subscriptions 
    SET 
      status = 'expired',
      updated_at = NOW()
    WHERE id = expired_subscriptions.id;
    
    -- Update user profile to remove premium status
    UPDATE profiles 
    SET 
      is_premium = FALSE,
      premium_until = NULL,
      updated_at = NOW()
    WHERE id = expired_subscriptions.user_id;
    
    -- Track expiration event
    INSERT INTO user_events (
      event_type,
      event_data,
      user_id,
      timestamp
    ) VALUES (
      'subscription_expired',
      jsonb_build_object(
        'subscription_id', expired_subscriptions.id,
        'plan_type', expired_subscriptions.plan_type,
        'expired_at', NOW()
      ),
      expired_subscriptions.user_id,
      NOW()
    );
    
    -- Add to expired users list
    expired_count := expired_count + 1;
    expired_user_ids := array_append(expired_user_ids, expired_subscriptions.user_id);
  END LOOP;
  
  RETURN QUERY SELECT expired_count, expired_user_ids;
END;
$$ LANGUAGE plpgsql;

-- Function to get subscription status for a user
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

-- Function to extend subscription (for admin use)
CREATE OR REPLACE FUNCTION extend_subscription(
  user_uuid UUID,
  extension_days INTEGER
)
RETURNS BOOLEAN AS $$
DECLARE
  current_subscription RECORD;
  new_end_date TIMESTAMP WITH TIME ZONE;
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
  
  -- Calculate new end date
  new_end_date := current_subscription.end_date + (extension_days || ' days')::INTERVAL;
  
  -- Update subscription
  UPDATE user_subscriptions
  SET 
    end_date = new_end_date,
    updated_at = NOW()
  WHERE id = current_subscription.id;
  
  -- Update user profile
  UPDATE profiles
  SET 
    premium_until = new_end_date,
    updated_at = NOW()
  WHERE id = user_uuid;
  
  -- Track extension event
  INSERT INTO user_events (
    event_type,
    event_data,
    user_id,
    timestamp
  ) VALUES (
    'subscription_extended',
    jsonb_build_object(
      'subscription_id', current_subscription.id,
      'extension_days', extension_days,
      'new_end_date', new_end_date
    ),
    user_uuid,
    NOW()
  );
  
  RETURN TRUE;
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
  
  -- Track cancellation event
  INSERT INTO user_events (
    event_type,
    event_data,
    user_id,
    timestamp
  ) VALUES (
    'subscription_cancelled',
    jsonb_build_object(
      'subscription_id', current_subscription.id,
      'cancelled_at', NOW()
    ),
    user_uuid,
    NOW()
  );
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Function to get subscription analytics
CREATE OR REPLACE FUNCTION get_subscription_analytics()
RETURNS TABLE (
  total_subscriptions BIGINT,
  active_subscriptions BIGINT,
  expired_subscriptions BIGINT,
  cancelled_subscriptions BIGINT,
  total_revenue NUMERIC,
  monthly_revenue NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    (SELECT COUNT(*) FROM user_subscriptions) as total_subscriptions,
    (SELECT COUNT(*) FROM user_subscriptions WHERE status = 'active' AND end_date > NOW()) as active_subscriptions,
    (SELECT COUNT(*) FROM user_subscriptions WHERE status = 'expired') as expired_subscriptions,
    (SELECT COUNT(*) FROM user_subscriptions WHERE status = 'cancelled') as cancelled_subscriptions,
    (SELECT COALESCE(SUM(po.amount), 0) FROM payment_orders po 
     JOIN user_subscriptions us ON po.order_id = us.order_id 
     WHERE po.status = 'success') as total_revenue,
    (SELECT COALESCE(SUM(po.amount), 0) FROM payment_orders po 
     JOIN user_subscriptions us ON po.order_id = us.order_id 
     WHERE po.status = 'success' 
     AND po.created_at >= DATE_TRUNC('month', NOW())) as monthly_revenue;
END;
$$ LANGUAGE plpgsql;

-- Create a scheduled job to check expired subscriptions every hour
-- Note: This requires pg_cron extension to be enabled
-- SELECT cron.schedule('check-expired-subscriptions', '0 * * * *', 'SELECT check_and_expire_subscriptions();');

-- Create a view for subscription dashboard
CREATE OR REPLACE VIEW subscription_dashboard AS
SELECT 
  us.id as subscription_id,
  p.name as user_name,
  p.email as user_email,
  us.plan_type,
  us.status,
  us.start_date,
  us.end_date,
  EXTRACT(DAYS FROM (us.end_date - NOW()))::INTEGER as days_remaining,
  po.amount,
  po.payment_id,
  us.created_at
FROM user_subscriptions us
JOIN profiles p ON us.user_id = p.id
LEFT JOIN payment_orders po ON us.order_id = po.order_id
ORDER BY us.created_at DESC;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_status_end_date 
ON user_subscriptions(status, end_date) 
WHERE status = 'active';

CREATE INDEX IF NOT EXISTS idx_profiles_premium_until 
ON profiles(premium_until) 
WHERE is_premium = TRUE;

-- Grant permissions
GRANT EXECUTE ON FUNCTION check_and_expire_subscriptions() TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_subscription_status(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION extend_subscription(UUID, INTEGER) TO service_role;
GRANT EXECUTE ON FUNCTION cancel_user_subscription(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_subscription_analytics() TO service_role;
GRANT SELECT ON subscription_dashboard TO authenticated;
