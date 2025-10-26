# Apply Database Schemas

Run these SQL files in Supabase SQL Editor in this order:

1. **call_system_schema.sql** - Core call tables (call_sessions, webrtc_rooms, webrtc_ice_candidates)
2. **supabase/migrations/create_call_debug_logs.sql** - Debug logging table

## Quick Apply Command

```bash
# If you have supabase CLI installed and linked:
supabase db push

# Or manually copy-paste each file into Supabase SQL Editor
```

## Verify Tables Exist

Run this in Supabase SQL Editor:

```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('call_sessions', 'webrtc_rooms', 'webrtc_ice_candidates', 'call_debug_logs');
```

Should return 4 rows.

## Verify RLS Policies

```sql
SELECT tablename, policyname, cmd, qual 
FROM pg_policies 
WHERE tablename IN ('call_sessions', 'webrtc_rooms', 'webrtc_ice_candidates', 'call_debug_logs');
```

Should show policies for each table.

