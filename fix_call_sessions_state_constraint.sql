-- ============================================================================
-- Fix call_sessions State Constraint (Bug 5)
-- ============================================================================
-- This migration expands the allowed states for call analytics and fixes
-- Postgres 23514 constraint violations
--
-- SAFE TO RUN: This is a metadata-only change (instant execution)
-- ROLLBACK PLAN: See rollback script at bottom
-- ============================================================================

-- Step 1: Drop the old constraint
ALTER TABLE call_sessions 
DROP CONSTRAINT IF EXISTS call_sessions_state_check;

-- Step 2: Add the new expanded constraint
ALTER TABLE call_sessions 
ADD CONSTRAINT call_sessions_state_check 
CHECK (state IN (
  -- Active call states
  'initial',      -- Call session created, not yet ringing
  'ringing',      -- Push notification sent, receiver's device ringing
  'connecting',   -- Receiver accepted, WebRTC negotiation in progress
  'connected',    -- WebRTC connected, active call in progress
  
  -- Terminal states (call ended)
  'ended',        -- Normal call termination (either party hung up)
  'declined',     -- Receiver explicitly rejected the call
  'canceled',     -- Caller canceled before receiver answered
  'timeout',      -- No answer within timeout period (30s default)
  
  -- Legacy states (deprecated, kept for backwards compatibility)
  'disconnected', -- Old state, now normalized to 'ended'
  'failed'        -- Old state, now normalized to appropriate terminal state
));

-- Step 3: Create index for analytics queries
CREATE INDEX IF NOT EXISTS idx_call_sessions_state_analytics 
ON call_sessions(state, created_at) 
WHERE state IN ('ended', 'declined', 'canceled', 'timeout');

-- Step 4: Add comment for documentation
COMMENT ON COLUMN call_sessions.state IS 
'Call state: initial → ringing → connecting → connected → [ended|declined|canceled|timeout]. Legacy: disconnected, failed';

-- ============================================================================
-- Verification Query - Run this to check the constraint is in place
-- ============================================================================
-- SELECT constraint_name, check_clause 
-- FROM information_schema.check_constraints 
-- WHERE constraint_name = 'call_sessions_state_check';

-- ============================================================================
-- Analytics Queries - Examples of what you can now track
-- ============================================================================

-- Call outcome breakdown (last 30 days)
-- SELECT 
--   state,
--   COUNT(*) as total_calls,
--   ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as percentage
-- FROM call_sessions 
-- WHERE created_at > NOW() - INTERVAL '30 days'
--   AND state IN ('ended', 'declined', 'canceled', 'timeout')
-- GROUP BY state
-- ORDER BY total_calls DESC;

-- Hourly timeout pattern (identify peak failure times)
-- SELECT 
--   EXTRACT(HOUR FROM created_at) as hour,
--   COUNT(*) as timeout_count
-- FROM call_sessions 
-- WHERE state = 'timeout' 
--   AND created_at > NOW() - INTERVAL '7 days'
-- GROUP BY hour
-- ORDER BY hour;

-- ============================================================================
-- ROLLBACK SCRIPT (if you need to revert)
-- ============================================================================
-- ALTER TABLE call_sessions DROP CONSTRAINT IF EXISTS call_sessions_state_check;
-- ALTER TABLE call_sessions ADD CONSTRAINT call_sessions_state_check 
-- CHECK (state IN ('initial', 'connecting', 'connected', 'disconnected', 'failed'));
-- DROP INDEX IF EXISTS idx_call_sessions_state_analytics;

