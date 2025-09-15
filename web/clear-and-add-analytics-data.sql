-- Clear existing analytics data and add fresh sample data
-- This handles the duplicate key constraint issue

-- Step 1: Clear all existing analytics data
DELETE FROM platform_analytics;
DELETE FROM content_analytics;
DELETE FROM revenue_analytics;
DELETE FROM real_time_metrics;

-- Step 2: Reset sequences (if any)
-- This ensures clean data insertion

-- Step 3: Generate platform analytics data for the last 30 days
INSERT INTO platform_analytics (date, total_users, new_users, active_users, daily_active_users, weekly_active_users, monthly_active_users, user_retention_rate, avg_session_duration, bounce_rate)
SELECT 
  date_series.date,
  -- Total users grows over time
  (1000 + (date_series.day_offset * 15) + (random() * 20)::integer) as total_users,
  -- New users per day (varies)
  (5 + (random() * 15)::integer) as new_users,
  -- Active users (60-80% of total)
  ((1000 + (date_series.day_offset * 15)) * (0.6 + random() * 0.2))::integer as active_users,
  -- Daily active users (40-60% of active)
  ((1000 + (date_series.day_offset * 15)) * (0.4 + random() * 0.2))::integer as daily_active_users,
  -- Weekly active users (70-90% of active)
  ((1000 + (date_series.day_offset * 15)) * (0.7 + random() * 0.2))::integer as weekly_active_users,
  -- Monthly active users (85-95% of active)
  ((1000 + (date_series.day_offset * 15)) * (0.85 + random() * 0.1))::integer as monthly_active_users,
  -- User retention rate (65-85%)
  (65 + random() * 20)::decimal(5,2) as user_retention_rate,
  -- Average session duration (15-45 minutes)
  (interval '15 minutes' + (random() * interval '30 minutes')) as avg_session_duration,
  -- Bounce rate (15-35%)
  (15 + random() * 20)::decimal(5,2) as bounce_rate
FROM (
  SELECT 
    (CURRENT_DATE - (30 - generate_series(0, 29))::integer) as date,
    (30 - generate_series(0, 29)) as day_offset
) as date_series
ORDER BY date_series.date;

-- Step 4: Generate content analytics data for the last 30 days
INSERT INTO content_analytics (date, total_messages, text_messages, image_messages, video_messages, stories_posted, stories_viewed, avg_messages_per_conversation, peak_activity_hour, popular_features)
SELECT 
  date_series.date,
  -- Total messages (grows with user base)
  (500 + (date_series.day_offset * 25) + (random() * 100)::integer) as total_messages,
  -- Text messages (70-80% of total)
  ((500 + (date_series.day_offset * 25)) * (0.7 + random() * 0.1))::integer as text_messages,
  -- Image messages (15-25% of total)
  ((500 + (date_series.day_offset * 25)) * (0.15 + random() * 0.1))::integer as image_messages,
  -- Video messages (5-15% of total)
  ((500 + (date_series.day_offset * 25)) * (0.05 + random() * 0.1))::integer as video_messages,
  -- Stories posted (varies)
  (10 + (random() * 30)::integer) as stories_posted,
  -- Stories viewed (3-5x stories posted)
  ((10 + (random() * 30)) * (3 + random() * 2))::integer as stories_viewed,
  -- Average messages per conversation (8-15)
  (8 + random() * 7)::decimal(5,2) as avg_messages_per_conversation,
  -- Peak activity hour (18-22)
  (18 + (random() * 4)::integer) as peak_activity_hour,
  -- Popular features (JSON)
  jsonb_build_object(
    'swipe_feature', (50 + random() * 100)::integer,
    'chat_feature', (200 + random() * 150)::integer,
    'story_feature', (30 + random() * 50)::integer,
    'match_feature', (80 + random() * 120)::integer,
    'profile_edit', (20 + random() * 30)::integer
  ) as popular_features
FROM (
  SELECT 
    (CURRENT_DATE - (30 - generate_series(0, 29))::integer) as date,
    (30 - generate_series(0, 29)) as day_offset
) as date_series
ORDER BY date_series.date;

-- Step 5: Generate revenue analytics data for the last 30 days
INSERT INTO revenue_analytics (date, total_revenue, subscription_revenue, new_subscriptions, cancelled_subscriptions, active_subscriptions, mrr, churn_rate)
SELECT 
  date_series.date,
  -- Total revenue (grows over time)
  (10000 + (date_series.day_offset * 500) + (random() * 1000)::integer) as total_revenue,
  -- Subscription revenue (80-90% of total)
  ((10000 + (date_series.day_offset * 500)) * (0.8 + random() * 0.1))::decimal(12,2) as subscription_revenue,
  -- New subscriptions (varies)
  (2 + (random() * 8)::integer) as new_subscriptions,
  -- Cancelled subscriptions (1-3 per day)
  (1 + (random() * 2)::integer) as cancelled_subscriptions,
  -- Active subscriptions (grows with new, decreases with cancelled)
  (100 + (date_series.day_offset * 2) + (random() * 10)::integer) as active_subscriptions,
  -- MRR (Monthly Recurring Revenue)
  (8000 + (date_series.day_offset * 400) + (random() * 800)::integer) as mrr,
  -- Churn rate (2-8%)
  (2 + random() * 6)::decimal(5,2) as churn_rate
FROM (
  SELECT 
    (CURRENT_DATE - (30 - generate_series(0, 29))::integer) as date,
    (30 - generate_series(0, 29)) as day_offset
) as date_series
ORDER BY date_series.date;

-- Step 6: Generate real-time metrics (current data)
INSERT INTO real_time_metrics (metric_type, metric_value, metadata)
VALUES 
  ('active_users_now', (50 + random() * 100)::integer, '{"description": "Users currently online"}'),
  ('messages_per_minute', (2 + random() * 8)::integer, '{"description": "Messages sent per minute"}'),
  ('new_matches_today', (5 + random() * 15)::integer, '{"description": "New matches created today"}'),
  ('server_response_time', (50 + random() * 100)::integer, '{"description": "Average server response time in ms"}'),
  ('concurrent_conversations', (20 + random() * 30)::integer, '{"description": "Active chat conversations"}'),
  ('api_requests_per_second', (10 + random() * 20)::integer, '{"description": "API requests per second"}'),
  ('database_connections', (5 + random() * 10)::integer, '{"description": "Active database connections"}'),
  ('cache_hit_rate', (85 + random() * 10)::decimal(5,2), '{"description": "Cache hit rate percentage"}');
