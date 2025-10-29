# Call State Management Guide

## Overview
This document defines the call state lifecycle for `call_sessions` table in the database. Proper state management is critical for:
- **Analytics**: Understanding user behavior (decline rates, timeout patterns, etc.)
- **Database Integrity**: Avoiding constraint violations (Postgres 23514 errors)
- **Debugging**: Clear state history for troubleshooting production issues

---

## Call State Lifecycle

### State Flow Diagram
```
┌─────────┐
│ initial │  (Call session created)
└────┬────┘
     │
     v
┌─────────┐
│ ringing │  (Push notification sent, device ringing)
└────┬────┘
     │
     ├─→ [declined]  (User rejects call)
     ├─→ [timeout]   (No answer within 30s)
     ├─→ [canceled]  (Caller cancels before answer)
     │
     v
┌────────────┐
│ connecting │  (User accepts, WebRTC negotiating)
└─────┬──────┘
      │
      ├─→ [timeout]   (WebRTC negotiation fails)
      │
      v
┌───────────┐
│ connected │  (Active call in progress)
└─────┬─────┘
      │
      v
┌────────┐
│ ended  │  (Normal call termination)
└────────┘
```

---

## State Definitions

### Active States (Call In Progress)

| State | Description | When Set | Analytics Use |
|-------|-------------|----------|---------------|
| `initial` | Call session created, not yet ringing | Call session created in DB | Track call initiation rate |
| `ringing` | Push notification sent, receiver's phone ringing | After push notification sent | Measure notification delivery |
| `connecting` | User accepted, WebRTC negotiation in progress | User taps "Accept" | Track acceptance rate |
| `connected` | WebRTC established, active call | WebRTC peer connection established | Measure successful connection rate |

### Terminal States (Call Ended)

| State | Description | When Set | Analytics Use |
|-------|-------------|----------|---------------|
| `ended` | Normal call termination | Either party hangs up during/after connected state | Track successful call completion |
| `declined` | User explicitly rejected the call | User taps "Decline" button | **Critical**: Measure rejection rate by time/user |
| `canceled` | Caller canceled before answer | Caller hangs up while ringing | Track caller patience/behavior |
| `timeout` | No answer within timeout period | 30s timeout expires without answer | **Critical**: Identify notification/availability issues |

### Legacy States (Deprecated, Backwards Compatibility)

| State | Description | Migration Path |
|-------|-------------|----------------|
| `disconnected` | Old generic disconnect | Normalized to `ended` |
| `failed` | Old generic failure | Normalized to `ended` |

> **Note**: Legacy states are automatically normalized to `ended` by `_normalizeDbState()` in `webrtc_service.dart`

---

## Implementation Guidelines

### ✅ DO: Use Specific Terminal States

```dart
// ✅ GOOD - Specific, analytics-friendly
await SupabaseService.client
    .from('call_sessions')
    .update({
      'state': 'declined',  // Clear: user rejected
      'ended_at': DateTime.now().toIso8601String(),
    })
    .eq('id', callId);
```

### ❌ DON'T: Use Generic States

```dart
// ❌ BAD - Loses valuable analytics data
await SupabaseService.client
    .from('call_sessions')
    .update({
      'state': 'failed',  // Ambiguous: declined? timeout? network error?
      'ended_at': DateTime.now().toIso8601String(),
    })
    .eq('id', callId);
```

### State Selection Logic

```dart
// User explicitly declines
state = 'declined'

// Caller cancels while waiting for answer
state = 'canceled'

// No answer within timeout (30s)
state = 'timeout'

// Normal hangup during/after connected
state = 'ended'

// WebRTC negotiation succeeds
state = 'connected'

// User accepts, WebRTC negotiating
state = 'connecting'
```

---

## Database Schema

### Constraint Definition
```sql
ALTER TABLE call_sessions 
ADD CONSTRAINT call_sessions_state_check 
CHECK (state IN (
  'initial', 'ringing', 'connecting', 'connected',  -- Active
  'ended', 'declined', 'canceled', 'timeout',       -- Terminal
  'disconnected', 'failed'                          -- Legacy
));
```

### Key Columns
- `state` (TEXT NOT NULL): Current call state
- `ended_at` (TIMESTAMP): Set ONLY for terminal states
- `created_at` (TIMESTAMP): Call initiation time

---

## Code Locations

### State Management Functions

| Function | File | Purpose |
|----------|------|---------|
| `_updateDbStateSafe()` | `lib/services/webrtc_service.dart:1433` | Safe DB state updates with normalization |
| `_normalizeDbState()` | `lib/services/webrtc_service.dart:1465` | Normalize legacy states to valid ones |
| `_isTerminalState()` | `lib/services/webrtc_service.dart:1476` | Check if state is terminal (for `ended_at`) |

### State Write Locations

| File | Lines | States Used |
|------|-------|-------------|
| `webrtc_service.dart` | 951, 968, 974, 1296, 1491, 1514 | `connected`, `disconnected`, `failed`, `canceled`, `timeout` |
| `call_controller.dart` | 258 | `ended` |
| `callkit_listener_service.dart` | 213, 241, 281 | `declined`, `ended`, `timeout` |
| `call_listener_service.dart` | 579, 715 | `connecting`, `declined` |

---

## Analytics Query Examples

### Call Outcome Breakdown (Last 30 Days)
```sql
SELECT 
  state,
  COUNT(*) as total_calls,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as percentage
FROM call_sessions 
WHERE created_at > NOW() - INTERVAL '30 days'
  AND state IN ('ended', 'declined', 'canceled', 'timeout')
GROUP BY state
ORDER BY total_calls DESC;
```

### Hourly Timeout Patterns (Identify Peak Failure Times)
```sql
SELECT 
  EXTRACT(HOUR FROM created_at) as hour,
  COUNT(*) as timeout_count,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as pct_of_timeouts
FROM call_sessions 
WHERE state = 'timeout' 
  AND created_at > NOW() - INTERVAL '7 days'
GROUP BY hour
ORDER BY hour;
```

### User Decline Rate (Top 20 Most Declined Users)
```sql
SELECT 
  receiver_id,
  COUNT(*) as times_declined,
  ROUND(COUNT(*) * 100.0 / 
    (SELECT COUNT(*) 
     FROM call_sessions cs2 
     WHERE cs2.receiver_id = cs1.receiver_id 
       AND cs2.state IN ('declined', 'ended', 'timeout', 'canceled')
    ), 2) as decline_rate_pct
FROM call_sessions cs1
WHERE state = 'declined' 
  AND created_at > NOW() - INTERVAL '30 days'
GROUP BY receiver_id
HAVING COUNT(*) > 5
ORDER BY times_declined DESC
LIMIT 20;
```

### Average Time to Answer (Ringing → Connecting)
```sql
-- Requires tracking state transition timestamps (future enhancement)
-- For now, estimate from created_at to first state change
```

---

## Migration & Deployment

### Step 1: Run Database Migration
```bash
# Run this SQL script on your Supabase instance
psql $DATABASE_URL -f fix_call_sessions_state_constraint.sql
```

### Step 2: Deploy Code Changes
All code changes are backwards compatible:
- ✅ New states work immediately after migration
- ✅ Old `disconnected`/`failed` normalized to `ended`
- ✅ Zero downtime deployment

### Step 3: Monitor
```sql
-- Check for any remaining legacy state usage
SELECT state, COUNT(*) 
FROM call_sessions 
WHERE created_at > NOW() - INTERVAL '1 day'
  AND state IN ('disconnected', 'failed')
GROUP BY state;
```

If count is 0 for 1 week, you can safely remove legacy states from schema in next release.

---

## Troubleshooting

### Postgres 23514 Error: "new row violates check constraint"
**Cause**: Attempting to write a state not in the allowed list  
**Fix**: 
1. Verify migration ran: `SELECT * FROM information_schema.check_constraints WHERE constraint_name = 'call_sessions_state_check'`
2. Check code is using valid states (see State Definitions table)
3. Ensure all state writes use `_updateDbStateSafe()` or valid terminal states

### `ended_at` Set for Active Call States
**Cause**: Logic error setting `ended_at` for non-terminal states  
**Fix**: Only set `ended_at` when `_isTerminalState()` returns true

### Analytics Show All Calls as "ended"
**Cause**: Using generic state instead of specific terminal states  
**Fix**: Update code to use `declined`, `canceled`, `timeout` appropriately

---

## Future Enhancements

1. **State Transition Tracking**
   - Add `call_state_history` table to track all state changes with timestamps
   - Enables funnel analysis (initial → ringing → connecting → connected)

2. **Network Failure States**
   - Add `network_error` state for ICE connection failures
   - Distinguish from user-initiated actions

3. **Reconnection States**
   - Add `reconnecting` state for temporary disconnects
   - Track call recovery success rate

4. **Duration Tracking**
   - Calculate `duration_seconds` for connected calls
   - Measure average call duration by time of day

---

## Questions?

Contact the backend team or see:
- Database migration: `fix_call_sessions_state_constraint.sql`
- State management code: `lib/services/webrtc_service.dart`
- Git commit: [Bug 5 Fix - Call State Constraint]

