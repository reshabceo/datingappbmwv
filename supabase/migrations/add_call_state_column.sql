-- Add call_state column to webrtc_rooms table
ALTER TABLE webrtc_rooms 
ADD COLUMN call_state TEXT DEFAULT 'active' CHECK (call_state IN ('active', 'ended', 'failed'));

-- Add ended_at and ended_by columns for call state tracking
ALTER TABLE webrtc_rooms 
ADD COLUMN ended_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN ended_by UUID REFERENCES auth.users(id);

-- Create index for better performance on call state queries
CREATE INDEX idx_webrtc_rooms_call_state ON webrtc_rooms(call_state);
CREATE INDEX idx_webrtc_rooms_ended_by ON webrtc_rooms(ended_by);

-- Update existing rows to have 'active' call_state
UPDATE webrtc_rooms SET call_state = 'active' WHERE call_state IS NULL;
