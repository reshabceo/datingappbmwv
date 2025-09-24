-- Test Payment System
-- Run this to test your payment and subscription system

-- 1. Check if all required tables exist
SELECT 
  table_name,
  CASE 
    WHEN table_name IN ('payment_orders', 'user_subscriptions', 'profiles', 'user_events', 'subscription_plans') 
    THEN '✅ Required'
    ELSE '❌ Missing'
  END as status
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('payment_orders', 'user_subscriptions', 'profiles', 'user_events', 'subscription_plans');

-- 2. Check if all required functions exist
SELECT 
  routine_name,
  CASE 
    WHEN routine_name IN (
      'check_and_expire_subscriptions',
      'get_user_subscription_status', 
      'extend_subscription',
      'cancel_user_subscription',
      'check_subscriptions_expiring_soon',
      'send_subscription_warnings'
    ) 
    THEN '✅ Required'
    ELSE '❌ Missing'
  END as status
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name IN (
  'check_and_expire_subscriptions',
  'get_user_subscription_status', 
  'extend_subscription',
  'cancel_user_subscription',
  'check_subscriptions_expiring_soon',
  'send_subscription_warnings'
);

-- 3. Check subscription plans
SELECT 
  name,
  description,
  price_monthly,
  price_yearly,
  features,
  is_active,
  sort_order
FROM subscription_plans 
ORDER BY price_monthly;

-- 4. Test subscription status function (replace with actual user ID)
-- SELECT * FROM get_user_subscription_status('your-user-id-here');

-- 5. Test expiring subscriptions check
SELECT * FROM check_subscriptions_expiring_soon();

-- 6. Test subscription warnings
SELECT send_subscription_warnings();

-- 7. Check recent payment orders
SELECT 
  order_id,
  user_id,
  plan_type,
  amount,
  status,
  created_at
FROM payment_orders 
ORDER BY created_at DESC 
LIMIT 10;

-- 8. Check recent user events
SELECT 
  event_type,
  user_id,
  timestamp,
  event_data
FROM user_events 
ORDER BY timestamp DESC 
LIMIT 10;
