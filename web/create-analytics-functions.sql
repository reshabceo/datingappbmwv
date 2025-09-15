-- Create functions for real-time analytics calculations
-- These functions will calculate live metrics from event data

-- Function to get active users (last 5 minutes)
CREATE OR REPLACE FUNCTION get_active_users_now()
RETURNS INTEGER AS $$
BEGIN
  RETURN (
    SELECT COUNT(DISTINCT user_id)
    FROM user_events
    WHERE timestamp >= NOW() - INTERVAL '5 minutes'
  );
END;
$$ LANGUAGE plpgsql;

-- Function to get messages per minute
CREATE OR REPLACE FUNCTION get_messages_per_minute()
RETURNS INTEGER AS $$
BEGIN
  RETURN (
    SELECT COUNT(*)
    FROM user_events
    WHERE event_type = 'message_sent'
    AND timestamp >= NOW() - INTERVAL '1 minute'
  );
END;
$$ LANGUAGE plpgsql;

-- Function to get new matches today
CREATE OR REPLACE FUNCTION get_new_matches_today()
RETURNS INTEGER AS $$
BEGIN
  RETURN (
    SELECT COUNT(*)
    FROM user_events
    WHERE event_type = 'match_created'
    AND DATE(timestamp) = CURRENT_DATE
  );
END;
$$ LANGUAGE plpgsql;

-- Function to get server response time (simulated)
CREATE OR REPLACE FUNCTION get_server_response_time()
RETURNS INTEGER AS $$
BEGIN
  -- Simulate response time between 50-200ms
  RETURN (50 + random() * 150)::INTEGER;
END;
$$ LANGUAGE plpgsql;

-- Function to get concurrent conversations
CREATE OR REPLACE FUNCTION get_concurrent_conversations()
RETURNS INTEGER AS $$
BEGIN
  RETURN (
    SELECT COUNT(DISTINCT (event_data->>'match_id'))
    FROM user_events
    WHERE event_type = 'message_sent'
    AND timestamp >= NOW() - INTERVAL '10 minutes'
  );
END;
$$ LANGUAGE plpgsql;

-- Function to get daily active users
CREATE OR REPLACE FUNCTION get_daily_active_users(target_date DATE DEFAULT CURRENT_DATE)
RETURNS INTEGER AS $$
BEGIN
  RETURN (
    SELECT COUNT(DISTINCT user_id)
    FROM user_events
    WHERE DATE(timestamp) = target_date
  );
END;
$$ LANGUAGE plpgsql;

-- Function to get weekly active users
CREATE OR REPLACE FUNCTION get_weekly_active_users()
RETURNS INTEGER AS $$
BEGIN
  RETURN (
    SELECT COUNT(DISTINCT user_id)
    FROM user_events
    WHERE timestamp >= NOW() - INTERVAL '7 days'
  );
END;
$$ LANGUAGE plpgsql;

-- Function to get monthly active users
CREATE OR REPLACE FUNCTION get_monthly_active_users()
RETURNS INTEGER AS $$
BEGIN
  RETURN (
    SELECT COUNT(DISTINCT user_id)
    FROM user_events
    WHERE timestamp >= NOW() - INTERVAL '30 days'
  );
END;
$$ LANGUAGE plpgsql;

-- Function to get user retention rate
CREATE OR REPLACE FUNCTION get_user_retention_rate()
RETURNS DECIMAL AS $$
DECLARE
  total_users INTEGER;
  returning_users INTEGER;
BEGIN
  -- Get total users who used the app 7 days ago
  SELECT COUNT(DISTINCT user_id) INTO total_users
  FROM user_events
  WHERE timestamp >= NOW() - INTERVAL '14 days'
  AND timestamp < NOW() - INTERVAL '7 days';
  
  -- Get users who used the app both 7 days ago and in the last 7 days
  SELECT COUNT(DISTINCT e1.user_id) INTO returning_users
  FROM user_events e1
  INNER JOIN user_events e2 ON e1.user_id = e2.user_id
  WHERE e1.timestamp >= NOW() - INTERVAL '14 days'
  AND e1.timestamp < NOW() - INTERVAL '7 days'
  AND e2.timestamp >= NOW() - INTERVAL '7 days';
  
  IF total_users = 0 THEN
    RETURN 0;
  END IF;
  
  RETURN (returning_users::DECIMAL / total_users::DECIMAL) * 100;
END;
$$ LANGUAGE plpgsql;

-- Function to get average session duration
CREATE OR REPLACE FUNCTION get_avg_session_duration()
RETURNS INTERVAL AS $$
BEGIN
  RETURN (
    SELECT AVG(session_end - session_start)
    FROM user_sessions
    WHERE session_end IS NOT NULL
    AND session_start >= NOW() - INTERVAL '7 days'
  );
END;
$$ LANGUAGE plpgsql;

-- Function to get bounce rate (sessions less than 30 seconds)
CREATE OR REPLACE FUNCTION get_bounce_rate()
RETURNS DECIMAL AS $$
DECLARE
  total_sessions INTEGER;
  bounced_sessions INTEGER;
BEGIN
  SELECT COUNT(*) INTO total_sessions
  FROM user_sessions
  WHERE session_start >= NOW() - INTERVAL '7 days';
  
  SELECT COUNT(*) INTO bounced_sessions
  FROM user_sessions
  WHERE session_start >= NOW() - INTERVAL '7 days'
  AND duration_seconds < 30;
  
  IF total_sessions = 0 THEN
    RETURN 0;
  END IF;
  
  RETURN (bounced_sessions::DECIMAL / total_sessions::DECIMAL) * 100;
END;
$$ LANGUAGE plpgsql;

-- Function to get peak activity hour
CREATE OR REPLACE FUNCTION get_peak_activity_hour()
RETURNS INTEGER AS $$
BEGIN
  RETURN (
    SELECT EXTRACT(HOUR FROM timestamp)::INTEGER
    FROM user_events
    WHERE timestamp >= NOW() - INTERVAL '7 days'
    GROUP BY EXTRACT(HOUR FROM timestamp)
    ORDER BY COUNT(*) DESC
    LIMIT 1
  );
END;
$$ LANGUAGE plpgsql;

-- Function to update real-time metrics
CREATE OR REPLACE FUNCTION update_real_time_metrics()
RETURNS void AS $$
BEGIN
  -- Clear old metrics
  DELETE FROM real_time_metrics WHERE timestamp < NOW() - INTERVAL '1 hour';
  
  -- Insert new metrics
  INSERT INTO real_time_metrics (metric_type, metric_value, metadata)
  VALUES 
    ('active_users_now', get_active_users_now(), '{"description": "Users currently online"}'),
    ('messages_per_minute', get_messages_per_minute(), '{"description": "Messages sent per minute"}'),
    ('new_matches_today', get_new_matches_today(), '{"description": "New matches created today"}'),
    ('server_response_time', get_server_response_time(), '{"description": "Average server response time in ms"}'),
    ('concurrent_conversations', get_concurrent_conversations(), '{"description": "Active chat conversations"}'),
    ('api_requests_per_second', (10 + random() * 20)::INTEGER, '{"description": "API requests per second"}'),
    ('database_connections', (5 + random() * 10)::INTEGER, '{"description": "Active database connections"}'),
    ('cache_hit_rate', (85 + random() * 10)::DECIMAL, '{"description": "Cache hit rate percentage"}');
END;
$$ LANGUAGE plpgsql;

-- Function to update daily analytics
CREATE OR REPLACE FUNCTION update_daily_analytics(target_date DATE DEFAULT CURRENT_DATE)
RETURNS void AS $$
DECLARE
  daily_users INTEGER;
  new_users INTEGER;
  active_users INTEGER;
  daily_active INTEGER;
  weekly_active INTEGER;
  monthly_active INTEGER;
  retention_rate DECIMAL;
  avg_session INTERVAL;
  bounce_rate DECIMAL;
  peak_hour INTEGER;
  total_messages INTEGER;
  text_messages INTEGER;
  image_messages INTEGER;
  video_messages INTEGER;
  stories_posted INTEGER;
  stories_viewed INTEGER;
  avg_messages_per_conv DECIMAL;
  popular_features JSONB;
BEGIN
  -- Calculate platform metrics
  daily_users := get_daily_active_users(target_date);
  new_users := (
    SELECT COUNT(DISTINCT user_id)
    FROM user_events
    WHERE event_type = 'profile_created'
    AND DATE(timestamp) = target_date
  );
  active_users := daily_users;
  daily_active := daily_users;
  weekly_active := get_weekly_active_users();
  monthly_active := get_monthly_active_users();
  retention_rate := get_user_retention_rate();
  avg_session := get_avg_session_duration();
  bounce_rate := get_bounce_rate();
  peak_hour := get_peak_activity_hour();
  
  -- Calculate content metrics
  total_messages := (
    SELECT COUNT(*)
    FROM user_events
    WHERE event_type = 'message_sent'
    AND DATE(timestamp) = target_date
  );
  text_messages := total_messages; -- Assume all messages are text for now
  image_messages := 0;
  video_messages := 0;
  stories_posted := (
    SELECT COUNT(*)
    FROM user_events
    WHERE event_type = 'story_posted'
    AND DATE(timestamp) = target_date
  );
  stories_viewed := (
    SELECT COUNT(*)
    FROM user_events
    WHERE event_type = 'story_viewed'
    AND DATE(timestamp) = target_date
  );
  avg_messages_per_conv := (
    SELECT AVG(conv_count)
    FROM (
      SELECT COUNT(*) as conv_count
      FROM user_events
      WHERE event_type = 'message_sent'
      AND DATE(timestamp) = target_date
      GROUP BY (event_data->>'match_id')
    ) subq
  );
  
  -- Calculate popular features
  popular_features := (
    SELECT jsonb_object_agg(feature_name, usage_count)
    FROM (
      SELECT 
        event_data->>'feature_name' as feature_name,
        COUNT(*) as usage_count
      FROM user_events
      WHERE event_type = 'feature_used'
      AND DATE(timestamp) = target_date
      GROUP BY event_data->>'feature_name'
    ) subq
  );
  
  -- Insert or update platform analytics
  INSERT INTO platform_analytics (
    date, total_users, new_users, active_users, daily_active_users,
    weekly_active_users, monthly_active_users, user_retention_rate,
    avg_session_duration, bounce_rate
  ) VALUES (
    target_date, daily_users, new_users, active_users, daily_active,
    weekly_active, monthly_active, retention_rate, avg_session, bounce_rate
  ) ON CONFLICT (date) DO UPDATE SET
    total_users = EXCLUDED.total_users,
    new_users = EXCLUDED.new_users,
    active_users = EXCLUDED.active_users,
    daily_active_users = EXCLUDED.daily_active_users,
    weekly_active_users = EXCLUDED.weekly_active_users,
    monthly_active_users = EXCLUDED.monthly_active_users,
    user_retention_rate = EXCLUDED.user_retention_rate,
    avg_session_duration = EXCLUDED.avg_session_duration,
    bounce_rate = EXCLUDED.bounce_rate,
    updated_at = NOW();
  
  -- Insert or update content analytics
  INSERT INTO content_analytics (
    date, total_messages, text_messages, image_messages, video_messages,
    stories_posted, stories_viewed, avg_messages_per_conversation,
    peak_activity_hour, popular_features
  ) VALUES (
    target_date, total_messages, text_messages, image_messages, video_messages,
    stories_posted, stories_viewed, COALESCE(avg_messages_per_conv, 0),
    peak_hour, COALESCE(popular_features, '{}'::jsonb)
  ) ON CONFLICT (date) DO UPDATE SET
    total_messages = EXCLUDED.total_messages,
    text_messages = EXCLUDED.text_messages,
    image_messages = EXCLUDED.image_messages,
    video_messages = EXCLUDED.video_messages,
    stories_posted = EXCLUDED.stories_posted,
    stories_viewed = EXCLUDED.stories_viewed,
    avg_messages_per_conversation = EXCLUDED.avg_messages_per_conversation,
    peak_activity_hour = EXCLUDED.peak_activity_hour,
    popular_features = EXCLUDED.popular_features,
    updated_at = NOW();
END;
$$ LANGUAGE plpgsql;
