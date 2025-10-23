-- Call System Database Schema for LoveBug Dating App
-- This schema supports video and audio calls between matched users

-- Create call_sessions table to track call history
CREATE TABLE IF NOT EXISTS call_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id UUID NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
  caller_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  receiver_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('audio', 'video')),
  state TEXT NOT NULL DEFAULT 'initial' CHECK (state IN ('initial', 'connecting', 'connected', 'disconnected', 'failed')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  ended_at TIMESTAMP WITH TIME ZONE,
  is_bff_match BOOLEAN DEFAULT FALSE,
  duration_seconds INTEGER DEFAULT 0
);

-- Create webrtc_rooms table for WebRTC signaling
CREATE TABLE IF NOT EXISTS webrtc_rooms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id TEXT UNIQUE NOT NULL,
  offer JSONB,
  answer JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '1 hour')
);

-- Create webrtc_ice_candidates table for ICE candidate exchange
CREATE TABLE IF NOT EXISTS webrtc_ice_candidates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id TEXT NOT NULL,
  candidate TEXT NOT NULL,
  sdp_mid TEXT,
  sdp_mline_index INTEGER,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_call_sessions_match_id ON call_sessions(match_id);
CREATE INDEX IF NOT EXISTS idx_call_sessions_caller_id ON call_sessions(caller_id);
CREATE INDEX IF NOT EXISTS idx_call_sessions_receiver_id ON call_sessions(receiver_id);
CREATE INDEX IF NOT EXISTS idx_call_sessions_created_at ON call_sessions(created_at);
CREATE INDEX IF NOT EXISTS idx_webrtc_rooms_room_id ON webrtc_rooms(room_id);
CREATE INDEX IF NOT EXISTS idx_webrtc_ice_candidates_room_id ON webrtc_ice_candidates(room_id);

-- Enable RLS (Row Level Security)
ALTER TABLE call_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE webrtc_rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE webrtc_ice_candidates ENABLE ROW LEVEL SECURITY;

-- RLS Policies for call_sessions
CREATE POLICY "Users can view their own call sessions" ON call_sessions
  FOR SELECT USING (
    auth.uid() = caller_id OR auth.uid() = receiver_id
  );

CREATE POLICY "Users can create call sessions" ON call_sessions
  FOR INSERT WITH CHECK (
    auth.uid() = caller_id
  );

CREATE POLICY "Users can update their own call sessions" ON call_sessions
  FOR UPDATE USING (
    auth.uid() = caller_id OR auth.uid() = receiver_id
  );

-- RLS Policies for webrtc_rooms
CREATE POLICY "Anyone can create webrtc rooms" ON webrtc_rooms
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Anyone can read webrtc rooms" ON webrtc_rooms
  FOR SELECT USING (true);

CREATE POLICY "Anyone can update webrtc rooms" ON webrtc_rooms
  FOR UPDATE USING (true);

CREATE POLICY "Anyone can delete webrtc rooms" ON webrtc_rooms
  FOR DELETE USING (true);

-- RLS Policies for webrtc_ice_candidates
CREATE POLICY "Anyone can manage ice candidates" ON webrtc_ice_candidates
  FOR ALL USING (true);

-- Function to clean up expired rooms
CREATE OR REPLACE FUNCTION cleanup_expired_webrtc_rooms()
RETURNS void AS $$
BEGIN
  DELETE FROM webrtc_rooms WHERE expires_at < NOW();
  DELETE FROM webrtc_ice_candidates WHERE created_at < NOW() - INTERVAL '1 hour';
END;
$$ LANGUAGE plpgsql;

-- Function to update call duration when call ends
CREATE OR REPLACE FUNCTION update_call_duration()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.state = 'disconnected' AND OLD.state != 'disconnected' THEN
    NEW.duration_seconds = EXTRACT(EPOCH FROM (NOW() - NEW.created_at))::INTEGER;
    NEW.ended_at = NOW();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to automatically update call duration
CREATE TRIGGER trigger_update_call_duration
  BEFORE UPDATE ON call_sessions
  FOR EACH ROW
  EXECUTE FUNCTION update_call_duration();

-- Add fcm_token column to profiles table if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'profiles' AND column_name = 'fcm_token') THEN
    ALTER TABLE profiles ADD COLUMN fcm_token TEXT;
  END IF;
END $$;

-- Create a view for call statistics
CREATE OR REPLACE VIEW call_statistics AS
SELECT 
  cs.caller_id,
  cs.receiver_id,
  COUNT(*) as total_calls,
  COUNT(CASE WHEN cs.state = 'connected' THEN 1 END) as successful_calls,
  AVG(cs.duration_seconds) as avg_duration,
  MAX(cs.created_at) as last_call_time
FROM call_sessions cs
GROUP BY cs.caller_id, cs.receiver_id;

-- Grant necessary permissions
GRANT ALL ON call_sessions TO authenticated;
GRANT ALL ON webrtc_rooms TO authenticated;
GRANT ALL ON webrtc_ice_candidates TO authenticated;
GRANT SELECT ON call_statistics TO authenticated;
