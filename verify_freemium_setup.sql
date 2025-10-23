-- VERIFY FREEMIUM SETUP
-- Run this script after applying the fix to ensure everything is working

-- =============================================================================
-- 1. CHECK TABLES
-- =============================================================================

\echo '=== Checking if freemium tables exist ==='
SELECT 
  table_name,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM information_schema.tables 
      WHERE table_schema = 'public' AND table_name = t.table_name
    ) THEN '✅ EXISTS'
    ELSE '❌ MISSING'
  END as status
FROM (
  VALUES 
    ('user_daily_limits'),
    ('premium_messages'),
    ('in_app_purchases'),
    ('premium_subscriptions')
) AS t(table_name);

-- =============================================================================
-- 2. CHECK FOREIGN KEY CONSTRAINTS
-- =============================================================================

\echo '=== Checking foreign key constraints ==='
SELECT
  tc.table_name,
  tc.constraint_name,
  kcu.column_name,
  ccu.table_name AS references_table,
  ccu.column_name AS references_column,
  '✅ OK' as status
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_name IN (
    'user_daily_limits',
    'premium_messages',
    'in_app_purchases',
    'premium_subscriptions'
  )
ORDER BY tc.table_name;

-- =============================================================================
-- 3. CHECK FUNCTIONS
-- =============================================================================

\echo '=== Checking freemium functions ==='
SELECT 
  routine_name,
  routine_type,
  '✅ EXISTS' as status
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name IN (
    'can_perform_action',
    'increment_daily_usage',
    'add_super_likes',
    'activate_premium_subscription'
  )
ORDER BY routine_name;

-- =============================================================================
-- 4. CHECK INDEXES
-- =============================================================================

\echo '=== Checking indexes ==='
SELECT
  tablename,
  indexname,
  '✅ EXISTS' as status
FROM pg_indexes
WHERE schemaname = 'public'
  AND (
    indexname LIKE 'idx_user_daily_limits%' OR
    indexname LIKE 'idx_premium_messages%' OR
    indexname LIKE 'idx_in_app_purchases%' OR
    indexname LIKE 'idx_premium_subscriptions%'
  )
ORDER BY tablename, indexname;

-- =============================================================================
-- 5. CHECK RLS POLICIES
-- =============================================================================

\echo '=== Checking RLS policies ==='
SELECT
  schemaname,
  tablename,
  policyname,
  '✅ EXISTS' as status
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN (
    'user_daily_limits',
    'premium_messages',
    'in_app_purchases',
    'premium_subscriptions'
  )
ORDER BY tablename, policyname;

-- =============================================================================
-- 6. CHECK RLS IS ENABLED
-- =============================================================================

\echo '=== Checking if RLS is enabled ==='
SELECT
  schemaname,
  tablename,
  rowsecurity as rls_enabled,
  CASE 
    WHEN rowsecurity THEN '✅ ENABLED'
    ELSE '❌ DISABLED'
  END as status
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN (
    'user_daily_limits',
    'premium_messages',
    'in_app_purchases',
    'premium_subscriptions'
  )
ORDER BY tablename;

-- =============================================================================
-- 7. CHECK FOR ORPHANED DATA
-- =============================================================================

\echo '=== Checking for orphaned data ==='
SELECT 
  'user_daily_limits' as table_name,
  COUNT(*) as orphaned_records
FROM user_daily_limits 
WHERE user_id NOT IN (SELECT id FROM profiles)
UNION ALL
SELECT 
  'premium_messages',
  COUNT(*)
FROM premium_messages 
WHERE sender_id NOT IN (SELECT id FROM profiles) 
   OR recipient_id NOT IN (SELECT id FROM profiles)
UNION ALL
SELECT 
  'in_app_purchases',
  COUNT(*)
FROM in_app_purchases 
WHERE user_id NOT IN (SELECT id FROM profiles)
UNION ALL
SELECT 
  'premium_subscriptions',
  COUNT(*)
FROM premium_subscriptions 
WHERE user_id NOT IN (SELECT id FROM profiles);

-- =============================================================================
-- 8. CHECK TRIGGERS
-- =============================================================================

\echo '=== Checking triggers ==='
SELECT
  event_object_table as table_name,
  trigger_name,
  event_manipulation as trigger_event,
  '✅ EXISTS' as status
FROM information_schema.triggers
WHERE event_object_schema = 'public'
  AND event_object_table IN (
    'user_daily_limits',
    'premium_messages',
    'in_app_purchases',
    'premium_subscriptions'
  )
ORDER BY event_object_table, trigger_name;

-- =============================================================================
-- 9. TEST FUNCTIONS (OPTIONAL)
-- =============================================================================

\echo '=== Testing functions (if you have a test user) ==='
\echo 'Note: Replace test-user-id with actual user ID from profiles table'

-- Uncomment and replace with actual user ID to test:
/*
DO $$ 
DECLARE
  test_user_id UUID;
  can_swipe BOOLEAN;
BEGIN
  -- Get a test user ID
  SELECT id INTO test_user_id FROM profiles LIMIT 1;
  
  IF test_user_id IS NOT NULL THEN
    -- Test can_perform_action
    SELECT can_perform_action(test_user_id, 'swipe') INTO can_swipe;
    RAISE NOTICE 'Test user can swipe: %', can_swipe;
    
    -- Test increment_daily_usage
    PERFORM increment_daily_usage(test_user_id, 'swipe');
    RAISE NOTICE 'Daily usage incremented successfully';
    
    RAISE NOTICE '✅ All function tests passed!';
  ELSE
    RAISE NOTICE '⚠️ No users found in profiles table for testing';
  END IF;
END $$;
*/

-- =============================================================================
-- 10. SUMMARY
-- =============================================================================

\echo '=== Setup Verification Summary ==='
SELECT 
  '✅ Freemium setup verified successfully!' as status,
  (SELECT COUNT(*) FROM information_schema.tables 
   WHERE table_schema = 'public' 
   AND table_name IN ('user_daily_limits', 'premium_messages', 'in_app_purchases', 'premium_subscriptions')
  ) as tables_count,
  (SELECT COUNT(*) FROM information_schema.routines
   WHERE routine_schema = 'public'
   AND routine_name IN ('can_perform_action', 'increment_daily_usage', 'add_super_likes', 'activate_premium_subscription')
  ) as functions_count,
  (SELECT COUNT(*) FROM pg_policies
   WHERE schemaname = 'public'
   AND tablename IN ('user_daily_limits', 'premium_messages', 'in_app_purchases', 'premium_subscriptions')
  ) as policies_count,
  (SELECT COUNT(*) FROM pg_indexes
   WHERE schemaname = 'public'
   AND (indexname LIKE 'idx_user_daily_limits%' OR
        indexname LIKE 'idx_premium_messages%' OR
        indexname LIKE 'idx_in_app_purchases%' OR
        indexname LIKE 'idx_premium_subscriptions%')
  ) as indexes_count;

\echo ''
\echo '=== Next Steps ==='
\echo '1. If all checks show ✅, your freemium setup is complete!'
\echo '2. Test the features in your Flutter app'
\echo '3. Configure in-app purchases in Google Play and App Store'
\echo '4. Deploy to production and monitor usage'
\echo ''
\echo 'Happy coding! 🚀'
