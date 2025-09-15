-- Complete setup script for analytics tracking
-- Run this script to set up all analytics tables and functions

-- 1. Create event collection tables
\i create-event-tables.sql

-- 2. Create analytics functions
\i create-analytics-functions.sql

-- 3. Add sample event data
\i add-sample-event-data.sql

-- 4. Update real-time metrics
SELECT update_real_time_metrics();

-- 5. Update daily analytics for the last 7 days
SELECT update_daily_analytics(CURRENT_DATE - INTERVAL '6 days');
SELECT update_daily_analytics(CURRENT_DATE - INTERVAL '5 days');
SELECT update_daily_analytics(CURRENT_DATE - INTERVAL '4 days');
SELECT update_daily_analytics(CURRENT_DATE - INTERVAL '3 days');
SELECT update_daily_analytics(CURRENT_DATE - INTERVAL '2 days');
SELECT update_daily_analytics(CURRENT_DATE - INTERVAL '1 day');
SELECT update_daily_analytics(CURRENT_DATE);

-- 6. Create a scheduled job to update metrics every 5 minutes
-- Note: This requires pg_cron extension to be enabled
-- CREATE EXTENSION IF NOT EXISTS pg_cron;
-- SELECT cron.schedule('update-real-time-metrics', '*/5 * * * *', 'SELECT update_real_time_metrics();');
-- SELECT cron.schedule('update-daily-analytics', '0 1 * * *', 'SELECT update_daily_analytics(CURRENT_DATE);');

-- 7. Verify setup
SELECT 'Event Tables Created' as status, COUNT(*) as count FROM user_events
UNION ALL
SELECT 'Session Tables Created', COUNT(*) FROM user_sessions
UNION ALL
SELECT 'Real-time Metrics Updated', COUNT(*) FROM real_time_metrics
UNION ALL
SELECT 'Platform Analytics Updated', COUNT(*) FROM platform_analytics
UNION ALL
SELECT 'Content Analytics Updated', COUNT(*) FROM content_analytics;
