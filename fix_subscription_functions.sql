-- Fix Subscription Functions - Remove email column references
-- Run this in your Supabase SQL Editor

-- Drop existing functions first
DROP FUNCTION IF EXISTS check_subscriptions_expiring_soon();
DROP FUNCTION IF EXISTS get_expiring_subscriptions();
DROP FUNCTION IF EXISTS send_subscription_warnings();
DROP FUNCTION IF EXISTS process_subscription_notifications();

-- Recreate functions without email column
CREATE OR REPLACE FUNCTION check_subscriptions_expiring_soon()
RETURNS TABLE (
  user_id UUID,
  user_name TEXT,
  plan_type TEXT,
  days_remaining INTEGER,
  end_date TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.id as user_id,
    p.name as user_name,
    us.plan_type,
    EXTRACT(DAYS FROM (us.end_date - NOW()))::INTEGER as days_remaining,
    us.end_date
  FROM user_subscriptions us
  JOIN profiles p ON us.user_id = p.id
  WHERE us.status = 'active'
  AND us.end_date > NOW()
  AND us.end_date <= (NOW() + INTERVAL '7 days')
  ORDER BY us.end_date ASC;
END;
$$ LANGUAGE plpgsql;

-- Function to get all users with expiring subscriptions (for notifications)
CREATE OR REPLACE FUNCTION get_expiring_subscriptions()
RETURNS TABLE (
  user_id UUID,
  user_name TEXT,
  plan_type TEXT,
  days_remaining INTEGER,
  end_date TIMESTAMP WITH TIME ZONE,
  subscription_id UUID
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.id as user_id,
    p.name as user_name,
    us.plan_type,
    EXTRACT(DAYS FROM (us.end_date - NOW()))::INTEGER as days_remaining,
    us.end_date,
    us.id as subscription_id
  FROM user_subscriptions us
  JOIN profiles p ON us.user_id = p.id
  WHERE us.status = 'active'
  AND us.end_date > NOW()
  AND us.end_date <= (NOW() + INTERVAL '7 days')
  ORDER BY us.end_date ASC;
END;
$$ LANGUAGE plpgsql;

-- Function to send subscription warning notifications
CREATE OR REPLACE FUNCTION send_subscription_warnings()
RETURNS INTEGER AS $$
DECLARE
  expiring_subscription RECORD;
  warning_count INTEGER := 0;
BEGIN
  -- Get all subscriptions expiring in 7 days
  FOR expiring_subscription IN
    SELECT * FROM get_expiring_subscriptions()
  LOOP
    -- Insert warning event
    INSERT INTO user_events (
      event_type,
      event_data,
      user_id,
      timestamp
    ) VALUES (
      'subscription_warning',
      jsonb_build_object(
        'subscription_id', expiring_subscription.subscription_id,
        'plan_type', expiring_subscription.plan_type,
        'days_remaining', expiring_subscription.days_remaining,
        'end_date', expiring_subscription.end_date,
        'warning_type', '7_day_warning'
      ),
      expiring_subscription.user_id,
      NOW()
    );
    
    warning_count := warning_count + 1;
  END LOOP;
  
  RETURN warning_count;
END;
$$ LANGUAGE plpgsql;

-- Function to check and send all subscription notifications
CREATE OR REPLACE FUNCTION process_subscription_notifications()
RETURNS TABLE (
  warnings_sent INTEGER,
  expirations_processed INTEGER
) AS $$
DECLARE
  warning_count INTEGER;
  expiration_count INTEGER;
BEGIN
  -- Send 7-day warnings
  SELECT send_subscription_warnings() INTO warning_count;
  
  -- Process expirations
  SELECT check_and_expire_subscriptions() INTO expiration_count;
  
  RETURN QUERY SELECT warning_count, expiration_count;
END;
$$ LANGUAGE plpgsql;

-- Grant permissions
GRANT EXECUTE ON FUNCTION check_subscriptions_expiring_soon() TO authenticated;
GRANT EXECUTE ON FUNCTION get_expiring_subscriptions() TO authenticated;
GRANT EXECUTE ON FUNCTION send_subscription_warnings() TO service_role;
GRANT EXECUTE ON FUNCTION process_subscription_notifications() TO service_role;
