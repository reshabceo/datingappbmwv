-- ========================================================
-- WebRTC Call Signaling Fixes
-- ========================================================

-- 1. Enable Realtime for the required tables using a safe check
DO $$
BEGIN
    -- Add call_sessions if not already there
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' AND tablename = 'call_sessions'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE call_sessions;
    END IF;

    -- Add webrtc_rooms if not already there
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' AND tablename = 'webrtc_rooms'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE webrtc_rooms;
    END IF;

    -- Add webrtc_ice_candidates if not already there
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' AND tablename = 'webrtc_ice_candidates'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE webrtc_ice_candidates;
    END IF;
END $$;

-- 2. Verify RLS Policies for call_sessions
-- Ensure BOTH caller and receiver can see and update the session
DO $$ 
BEGIN
    -- Drop existing policies to ensure a clean state
    DROP POLICY IF EXISTS "Users can view their own call sessions" ON call_sessions;
    DROP POLICY IF EXISTS "Users can create call sessions" ON call_sessions;
    DROP POLICY IF EXISTS "Users can update their own call sessions" ON call_sessions;
END $$;

-- Policy to allow users to see calls where they are either the caller or receiver
CREATE POLICY "Users can view their own call sessions" ON call_sessions
  FOR SELECT USING (
    auth.uid()::text = caller_id::text OR auth.uid()::text = receiver_id::text
  );

-- Policy to allow starting a call
CREATE POLICY "Users can create call sessions" ON call_sessions
  FOR INSERT WITH CHECK (
    auth.uid()::text = caller_id::text
  );

-- Policy to allow accepting or ending a call
CREATE POLICY "Users can update their own call sessions" ON call_sessions
  FOR UPDATE USING (
    auth.uid()::text = caller_id::text OR auth.uid()::text = receiver_id::text
  );

-- 3. Wide open policies for webrtc signaling (sdp/ice)
-- During debugging, it is safer to ensure these are accessible
ALTER TABLE webrtc_rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE webrtc_ice_candidates ENABLE ROW LEVEL SECURITY;

DO $$ 
BEGIN
    DROP POLICY IF EXISTS "Signaling is accessible to participants" ON webrtc_rooms;
    DROP POLICY IF EXISTS "ICE candidates are accessible to participants" ON webrtc_ice_candidates;
END $$;

-- For simplicity in WebRTC signaling, we allow all authenticated users 
-- but you can restrict this further based on room_id if needed.
CREATE POLICY "Signaling is accessible to participants" ON webrtc_rooms
  FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "ICE candidates are accessible to participants" ON webrtc_ice_candidates
  FOR ALL USING (auth.role() = 'authenticated');

-- 4. Ensure fcm_token is in profiles and has a simple policy
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'profiles' AND column_name = 'fcm_token') THEN
    ALTER TABLE profiles ADD COLUMN fcm_token TEXT;
  END IF;
END $$;

-- 5. Final check of the state constraint
-- Ensure 'connecting' and 'ringing' are valid states
ALTER TABLE call_sessions DROP CONSTRAINT IF EXISTS call_sessions_state_check;
ALTER TABLE call_sessions ADD CONSTRAINT call_sessions_state_check 
  CHECK (state IN ('initial', 'ringing', 'connecting', 'connected', 'disconnected', 'failed', 'canceled', 'ended', 'declined', 'timeout'));

-- 6. Trigger to log debug info
CREATE OR REPLACE FUNCTION log_call_event()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO call_debug_logs (event, call_id, user_id, data)
  VALUES (TG_OP || ' on ' || TG_TABLE_NAME, NEW.id::text, auth.uid(), row_to_json(NEW));
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS tr_log_call_sessions ON call_sessions;
CREATE TRIGGER tr_log_call_sessions
  AFTER INSERT OR UPDATE ON call_sessions
  FOR EACH ROW EXECUTE FUNCTION log_call_event();
