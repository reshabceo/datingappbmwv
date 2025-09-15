-- Create event collection tables for analytics tracking
-- These tables will store raw user events and session data

-- User Events Table - stores all user interactions
CREATE TABLE IF NOT EXISTS user_events (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id),
  event_type VARCHAR(50) NOT NULL,
  event_data JSONB DEFAULT '{}',
  session_id VARCHAR(50),
  timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User Sessions Table - tracks user session data
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

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_user_events_user_id ON user_events(user_id);
CREATE INDEX IF NOT EXISTS idx_user_events_event_type ON user_events(event_type);
CREATE INDEX IF NOT EXISTS idx_user_events_timestamp ON user_events(timestamp);
CREATE INDEX IF NOT EXISTS idx_user_events_session_id ON user_events(session_id);

CREATE INDEX IF NOT EXISTS idx_user_sessions_user_id ON user_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_sessions_session_id ON user_sessions(session_id);
CREATE INDEX IF NOT EXISTS idx_user_sessions_session_start ON user_sessions(session_start);

-- Enable RLS
ALTER TABLE user_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_sessions ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for admin access
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

-- Create function to automatically update session duration
CREATE OR REPLACE FUNCTION update_session_duration()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.session_end IS NOT NULL AND NEW.session_start IS NOT NULL THEN
    NEW.duration_seconds = EXTRACT(EPOCH FROM (NEW.session_end - NEW.session_start))::INTEGER;
  END IF;
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to update session duration
CREATE TRIGGER trigger_update_session_duration
  BEFORE UPDATE ON user_sessions
  FOR EACH ROW
  EXECUTE FUNCTION update_session_duration();

-- Create function to clean up old events (optional - for data retention)
CREATE OR REPLACE FUNCTION cleanup_old_events()
RETURNS void AS $$
BEGIN
  -- Delete events older than 90 days
  DELETE FROM user_events 
  WHERE created_at < NOW() - INTERVAL '90 days';
  
  -- Delete sessions older than 90 days
  DELETE FROM user_sessions 
  WHERE created_at < NOW() - INTERVAL '90 days';
END;
$$ LANGUAGE plpgsql;
