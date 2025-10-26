-- WebRTC Database Setup for Cross-Platform Call Testing
-- Run this script in your Supabase SQL editor

-- 1. Create WebRTC Rooms Table
CREATE TABLE IF NOT EXISTS webrtc_rooms (
  id SERIAL PRIMARY KEY,
  room_id TEXT UNIQUE NOT NULL,
  offer JSONB,
  answer JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Create ICE Candidates Table
CREATE TABLE IF NOT EXISTS webrtc_ice_candidates (
  id SERIAL PRIMARY KEY,
  room_id TEXT NOT NULL,
  candidate TEXT,
  sdp_mid TEXT,
  sdp_mline_index INTEGER,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Create Call Sessions Table
CREATE TABLE IF NOT EXISTS call_sessions (
  id TEXT PRIMARY KEY,
  match_id TEXT NOT NULL,
  caller_id TEXT NOT NULL,
  receiver_id TEXT,
  type TEXT NOT NULL CHECK (type IN ('audio', 'video')),
  state TEXT NOT NULL CHECK (state IN ('initial', 'connecting', 'connected', 'disconnected', 'failed')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  ended_at TIMESTAMP WITH TIME ZONE,
  is_bff_match BOOLEAN DEFAULT FALSE
);

-- 4. Enable Row Level Security
ALTER TABLE webrtc_rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE webrtc_ice_candidates ENABLE ROW LEVEL SECURITY;
ALTER TABLE call_sessions ENABLE ROW LEVEL SECURITY;

-- 5. Create RLS Policies
-- Allow all authenticated users to access webrtc_rooms
CREATE POLICY "Users can access webrtc_rooms" ON webrtc_rooms 
  FOR ALL USING (auth.role() = 'authenticated');

-- Allow all authenticated users to access webrtc_ice_candidates
CREATE POLICY "Users can access webrtc_ice_candidates" ON webrtc_ice_candidates 
  FOR ALL USING (auth.role() = 'authenticated');

-- Allow users to access their own call sessions
CREATE POLICY "Users can access call_sessions" ON call_sessions 
  FOR ALL USING (
    auth.uid()::text = caller_id OR 
    auth.uid()::text = receiver_id
  );

-- 6. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_webrtc_rooms_room_id ON webrtc_rooms(room_id);
CREATE INDEX IF NOT EXISTS idx_webrtc_ice_candidates_room_id ON webrtc_ice_candidates(room_id);
CREATE INDEX IF NOT EXISTS idx_call_sessions_caller_id ON call_sessions(caller_id);
CREATE INDEX IF NOT EXISTS idx_call_sessions_receiver_id ON call_sessions(receiver_id);
CREATE INDEX IF NOT EXISTS idx_call_sessions_match_id ON call_sessions(match_id);

-- 7. Create function to clean up old rooms (optional)
CREATE OR REPLACE FUNCTION cleanup_old_webrtc_rooms()
RETURNS void AS $$
BEGIN
  -- Delete rooms older than 24 hours
  DELETE FROM webrtc_rooms 
  WHERE created_at < NOW() - INTERVAL '24 hours';
  
  -- Delete ICE candidates for deleted rooms
  DELETE FROM webrtc_ice_candidates 
  WHERE room_id NOT IN (SELECT room_id FROM webrtc_rooms);
END;
$$ LANGUAGE plpgsql;

-- 8. Create function to get call statistics (optional)
CREATE OR REPLACE FUNCTION get_call_stats(user_id_param TEXT)
RETURNS TABLE (
  total_calls BIGINT,
  audio_calls BIGINT,
  video_calls BIGINT,
  successful_calls BIGINT,
  failed_calls BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COUNT(*) as total_calls,
    COUNT(*) FILTER (WHERE type = 'audio') as audio_calls,
    COUNT(*) FILTER (WHERE type = 'video') as video_calls,
    COUNT(*) FILTER (WHERE state = 'connected') as successful_calls,
    COUNT(*) FILTER (WHERE state = 'failed') as failed_calls
  FROM call_sessions
  WHERE caller_id = user_id_param OR receiver_id = user_id_param;
END;
$$ LANGUAGE plpgsql;

-- 9. Grant necessary permissions
GRANT ALL ON webrtc_rooms TO authenticated;
GRANT ALL ON webrtc_ice_candidates TO authenticated;
GRANT ALL ON call_sessions TO authenticated;

-- 10. Create real-time subscriptions (if needed)
-- Note: Real-time is automatically enabled for tables with RLS

-- Verification queries
SELECT 'webrtc_rooms table created' as status;
SELECT 'webrtc_ice_candidates table created' as status;
SELECT 'call_sessions table created' as status;
SELECT 'RLS policies created' as status;
SELECT 'Indexes created' as status;
SELECT 'Setup complete!' as status;
