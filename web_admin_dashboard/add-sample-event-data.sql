-- Add sample event data for testing analytics
-- This will populate the event tables with realistic sample data

-- Generate sample user events for the last 7 days
INSERT INTO user_events (user_id, event_type, event_data, session_id, timestamp)
SELECT 
  -- Use existing user IDs from profiles table
  p.id as user_id,
  -- Random event types (ensure no NULL values)
  CASE (random() * 7)::int
    WHEN 0 THEN 'session_start'
    WHEN 1 THEN 'swipe_action'
    WHEN 2 THEN 'message_sent'
    WHEN 3 THEN 'match_created'
    WHEN 4 THEN 'story_viewed'
    WHEN 5 THEN 'profile_created'
    WHEN 6 THEN 'feature_used'
    ELSE 'session_start' -- Fallback to prevent NULL
  END as event_type,
  -- Event data based on event type
  CASE (random() * 7)::int
    WHEN 0 THEN jsonb_build_object(
      'session_id', 'session_' || (random() * 1000)::int,
      'timestamp', NOW() - (random() * INTERVAL '7 days')
    )
    WHEN 1 THEN jsonb_build_object(
      'action', CASE (random() * 3)::int WHEN 0 THEN 'like' WHEN 1 THEN 'pass' ELSE 'super_like' END,
      'target_user_id', 'user_' || (random() * 100)::int,
      'timestamp', NOW() - (random() * INTERVAL '7 days')
    )
    WHEN 2 THEN jsonb_build_object(
      'match_id', 'match_' || (random() * 50)::int,
      'message_type', 'text',
      'timestamp', NOW() - (random() * INTERVAL '7 days')
    )
    WHEN 3 THEN jsonb_build_object(
      'match_id', 'match_' || (random() * 50)::int,
      'other_user_id', 'user_' || (random() * 100)::int,
      'timestamp', NOW() - (random() * INTERVAL '7 days')
    )
    WHEN 4 THEN jsonb_build_object(
      'story_id', 'story_' || (random() * 30)::int,
      'story_user_id', 'user_' || (random() * 100)::int,
      'timestamp', NOW() - (random() * INTERVAL '7 days')
    )
    WHEN 5 THEN jsonb_build_object(
      'profile_data', jsonb_build_object(
        'has_photos', (random() > 0.5),
        'has_bio', (random() > 0.3),
        'age', (18 + random() * 50)::int
      ),
      'timestamp', NOW() - (random() * INTERVAL '7 days')
    )
    WHEN 6 THEN jsonb_build_object(
      'feature_name', CASE (random() * 5)::int
        WHEN 0 THEN 'swipe_feature'
        WHEN 1 THEN 'chat_feature'
        WHEN 2 THEN 'story_feature'
        WHEN 3 THEN 'profile_edit'
        ELSE 'match_feature'
      END,
      'parameters', jsonb_build_object(
        'usage_count', (1 + random() * 10)::int
      ),
      'timestamp', NOW() - (random() * INTERVAL '7 days')
    )
  END as event_data,
  -- Session ID
  'session_' || (random() * 1000)::int as session_id,
  -- Random timestamp within last 7 days
  NOW() - (random() * INTERVAL '7 days') as timestamp
FROM (
  SELECT id FROM profiles LIMIT 10
) p
CROSS JOIN generate_series(1, 20) -- Generate 20 events per user
WHERE p.id IS NOT NULL;

-- Generate sample user sessions for the last 7 days
INSERT INTO user_sessions (user_id, session_id, session_start, session_end, duration_seconds, device_type, app_version)
SELECT 
  p.id as user_id,
  'session_' || (random() * 1000)::int as session_id,
  NOW() - (random() * INTERVAL '7 days') as session_start,
  CASE 
    WHEN random() > 0.1 THEN NOW() - (random() * INTERVAL '6 days') -- 90% have ended
    ELSE NULL -- 10% are still active
  END as session_end,
  CASE 
    WHEN random() > 0.1 THEN (300 + random() * 3600)::int -- 5 minutes to 1 hour
    ELSE NULL
  END as duration_seconds,
  CASE (random() * 3)::int
    WHEN 0 THEN 'android'
    WHEN 1 THEN 'ios'
    ELSE 'web'
  END as device_type,
  '1.0.' || (random() * 10)::int as app_version
FROM (
  SELECT id FROM profiles LIMIT 10
) p
CROSS JOIN generate_series(1, 5) -- Generate 5 sessions per user
WHERE p.id IS NOT NULL;

-- Update some sessions to have proper duration calculation
UPDATE user_sessions 
SET duration_seconds = EXTRACT(EPOCH FROM (session_end - session_start))::INTEGER
WHERE session_end IS NOT NULL AND session_start IS NOT NULL;
