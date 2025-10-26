-- Fixed setup script for analytics tracking
-- This script only uses existing user IDs from auth.users table

-- 1. Create event collection tables (only if they don't exist)
CREATE TABLE IF NOT EXISTS user_events (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id),
  event_type VARCHAR(50) NOT NULL,
  event_data JSONB DEFAULT '{}',
  session_id VARCHAR(50),
  timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS user_sessions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id),
  session_id VARCHAR(50) UNIQUE NOT NULL,
  session_start TIMESTAMP WITH TIME ZONE NOT NULL,
  session_end TIMESTAMP WITH TIME ZONE,
  duration_seconds INTEGER,
  device_type VARCHAR(20),
  app_version VARCHAR(10),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Create indexes (only if they don't exist)
CREATE INDEX IF NOT EXISTS idx_user_events_user_id ON user_events(user_id);
CREATE INDEX IF NOT EXISTS idx_user_events_event_type ON user_events(event_type);
CREATE INDEX IF NOT EXISTS idx_user_events_timestamp ON user_events(timestamp);
CREATE INDEX IF NOT EXISTS idx_user_events_session_id ON user_events(session_id);

CREATE INDEX IF NOT EXISTS idx_user_sessions_user_id ON user_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_sessions_session_id ON user_sessions(session_id);
CREATE INDEX IF NOT EXISTS idx_user_sessions_session_start ON user_sessions(session_start);

-- 3. Enable RLS (only if not already enabled)
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_class WHERE relname = 'user_events' AND relrowsecurity = true) THEN
    ALTER TABLE user_events ENABLE ROW LEVEL SECURITY;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM pg_class WHERE relname = 'user_sessions' AND relrowsecurity = true) THEN
    ALTER TABLE user_sessions ENABLE ROW LEVEL SECURITY;
  END IF;
END $$;

-- 4. Create RLS policies (drop existing first to avoid conflicts)
DROP POLICY IF EXISTS "Admin can view user events" ON user_events;
DROP POLICY IF EXISTS "Admin can insert user events" ON user_events;
DROP POLICY IF EXISTS "Users can insert their own events" ON user_events;
DROP POLICY IF EXISTS "Admin can view user sessions" ON user_sessions;
DROP POLICY IF EXISTS "Admin can insert user sessions" ON user_sessions;
DROP POLICY IF EXISTS "Users can insert their own sessions" ON user_sessions;
DROP POLICY IF EXISTS "Users can update their own sessions" ON user_sessions;

CREATE POLICY "Admin can view user events" ON user_events
FOR SELECT USING (auth.uid() = '0d535be0-df84-442d-a11f-1fd5107bd6ea'::uuid);

CREATE POLICY "Admin can insert user events" ON user_events
FOR INSERT WITH CHECK (auth.uid() = '0d535be0-df84-442d-a11f-1fd5107bd6ea'::uuid);

CREATE POLICY "Users can insert their own events" ON user_events
FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admin can view user sessions" ON user_sessions
FOR SELECT USING (auth.uid() = '0d535be0-df84-442d-a11f-1fd5107bd6ea'::uuid);

CREATE POLICY "Admin can insert user sessions" ON user_sessions
FOR INSERT WITH CHECK (auth.uid() = '0d535be0-df84-442d-a11f-1fd5107bd6ea'::uuid);

CREATE POLICY "Users can insert their own sessions" ON user_sessions
FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own sessions" ON user_sessions
FOR UPDATE USING (auth.uid() = user_id);

-- 5. Clear any existing sample data to avoid conflicts
DELETE FROM user_events WHERE session_id LIKE 'session_%';
DELETE FROM user_sessions WHERE session_id LIKE 'session_%';

-- 6. Add sample event data using ONLY existing user IDs from auth.users
INSERT INTO user_events (user_id, event_type, event_data, session_id, timestamp)
SELECT 
  u.id as user_id,
  CASE (random() * 7)::int
    WHEN 0 THEN 'session_start'
    WHEN 1 THEN 'swipe_action'
    WHEN 2 THEN 'message_sent'
    WHEN 3 THEN 'match_created'
    WHEN 4 THEN 'story_viewed'
    WHEN 5 THEN 'profile_created'
    WHEN 6 THEN 'feature_used'
    ELSE 'session_start'
  END as event_type,
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
    ELSE jsonb_build_object('timestamp', NOW() - (random() * INTERVAL '7 days'))
  END as event_data,
  'session_' || (random() * 1000)::int as session_id,
  NOW() - (random() * INTERVAL '7 days') as timestamp
FROM (
  SELECT id FROM auth.users LIMIT 5
) u
CROSS JOIN generate_series(1, 10) -- Generate 10 events per user
WHERE u.id IS NOT NULL;

-- 7. Add sample session data using ONLY existing user IDs from auth.users
INSERT INTO user_sessions (user_id, session_id, session_start, session_end, duration_seconds, device_type, app_version)
SELECT 
  u.id as user_id,
  'session_' || (random() * 1000)::int as session_id,
  NOW() - (random() * INTERVAL '7 days') as session_start,
  CASE 
    WHEN random() > 0.1 THEN NOW() - (random() * INTERVAL '6 days')
    ELSE NULL
  END as session_end,
  CASE 
    WHEN random() > 0.1 THEN (300 + random() * 3600)::int
    ELSE NULL
  END as duration_seconds,
  CASE (random() * 3)::int
    WHEN 0 THEN 'android'
    WHEN 1 THEN 'ios'
    ELSE 'web'
  END as device_type,
  '1.0.' || (random() * 10)::int as app_version
FROM (
  SELECT id FROM auth.users LIMIT 5
) u
CROSS JOIN generate_series(1, 3) -- Generate 3 sessions per user
WHERE u.id IS NOT NULL;

-- 8. Update session durations
UPDATE user_sessions 
SET duration_seconds = EXTRACT(EPOCH FROM (session_end - session_start))::INTEGER
WHERE session_end IS NOT NULL AND session_start IS NOT NULL;

-- 9. Verify setup
SELECT 'Setup Complete' as status, 
       (SELECT COUNT(*) FROM user_events) as event_count,
       (SELECT COUNT(*) FROM user_sessions) as session_count;
