# Cross-Platform Call Testing Guide

## Overview
This guide will help you test audio and video calls between your iPhone app and Chrome browser using two different user profiles.

## Prerequisites
- iPhone with your LoveBug app installed
- Computer with Chrome browser
- Two different user accounts (one for iPhone, one for web)
- Both devices on the same network (for easier testing)

## Setup Steps

### 1. iPhone Setup (Your Profile)
1. **Open your LoveBug app** on iPhone
2. **Sign in** with your existing profile
3. **Navigate to matches** - you should see your existing matches
4. **Select a match** to open the chat screen
5. **Look for call buttons** - you should see audio and video call options

### 2. Web Setup (Test Profile)
1. **Open Chrome** and go to your web app URL
2. **Create a new account** or sign in with a different account
3. **Complete profile setup** if needed
4. **Navigate to matches** - you should see the same match
5. **Open the chat** with the same match

### 3. Database Setup (Required)
Make sure these tables exist in your Supabase database:

```sql
-- WebRTC Rooms Table
CREATE TABLE IF NOT EXISTS webrtc_rooms (
  id SERIAL PRIMARY KEY,
  room_id TEXT UNIQUE NOT NULL,
  offer JSONB,
  answer JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ICE Candidates Table
CREATE TABLE IF NOT EXISTS webrtc_ice_candidates (
  id SERIAL PRIMARY KEY,
  room_id TEXT NOT NULL,
  candidate TEXT,
  sdp_mid TEXT,
  sdp_mline_index INTEGER,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Call Sessions Table
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

-- Enable RLS
ALTER TABLE webrtc_rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE webrtc_ice_candidates ENABLE ROW LEVEL SECURITY;
ALTER TABLE call_sessions ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can access webrtc_rooms" ON webrtc_rooms FOR ALL USING (true);
CREATE POLICY "Users can access webrtc_ice_candidates" ON webrtc_ice_candidates FOR ALL USING (true);
CREATE POLICY "Users can access call_sessions" ON call_sessions FOR ALL USING (true);
```

## Testing Scenarios

### Scenario 1: Audio Call (iPhone → Web)
1. **On iPhone**: Tap the audio call button in the chat
2. **On Web**: You should see an incoming call notification
3. **Accept the call** on web
4. **Test audio** - speak into both devices
5. **Test controls** - mute/unmute, speaker toggle
6. **End call** from either device

### Scenario 2: Video Call (iPhone → Web)
1. **On iPhone**: Tap the video call button in the chat
2. **On Web**: Accept the incoming video call
3. **Test video** - you should see each other's video
4. **Test controls** - mute/unmute, video toggle, camera switch
5. **End call** from either device

### Scenario 3: Web → iPhone
1. **On Web**: Navigate to `/call/{roomId}/{matchId}/{callType}`
2. **On iPhone**: Accept the incoming call
3. **Test the connection** in both directions

## Troubleshooting

### Common Issues

#### 1. "No matches found"
- **Solution**: Make sure both users have matched with each other
- **Check**: Go to matches screen on both devices

#### 2. "Call failed to connect"
- **Solution**: Check network connectivity
- **Check**: Ensure both devices are on the same network
- **Check**: Verify STUN servers are accessible

#### 3. "No audio/video"
- **Solution**: Check browser permissions
- **Check**: Ensure microphone/camera access is granted
- **Check**: Test with different browsers

#### 4. "Database errors"
- **Solution**: Run the database setup SQL above
- **Check**: Verify Supabase connection
- **Check**: Check RLS policies

### Debug Steps

#### 1. Check Console Logs
- **iPhone**: Use Xcode console or Flutter logs
- **Web**: Open Chrome DevTools → Console

#### 2. Check Network
- **Test**: Ping between devices
- **Check**: Firewall settings
- **Check**: Router configuration

#### 3. Check Database
- **Verify**: Tables exist in Supabase
- **Check**: Data is being inserted
- **Monitor**: Real-time subscriptions

## Expected Behavior

### Audio Call
- ✅ Clear audio in both directions
- ✅ Mute/unmute functionality
- ✅ Speaker toggle
- ✅ Call end from either side

### Video Call
- ✅ Video streams in both directions
- ✅ Picture-in-picture local video
- ✅ Camera switch (if implemented)
- ✅ Video toggle functionality
- ✅ All audio controls from audio calls

## Testing Checklist

- [ ] iPhone app loads and shows matches
- [ ] Web app loads and shows matches
- [ ] Both users can see the same match
- [ ] Audio call initiates from iPhone
- [ ] Web receives incoming call notification
- [ ] Audio call connects successfully
- [ ] Audio is clear in both directions
- [ ] Mute/unmute works on both devices
- [ ] Call can be ended from either device
- [ ] Video call initiates from iPhone
- [ ] Web receives incoming video call
- [ ] Video call connects successfully
- [ ] Video streams are visible on both devices
- [ ] Video controls work (toggle, switch camera)
- [ ] Call can be ended from either device

## Next Steps

Once basic testing is working:

1. **Test on different networks** (mobile data vs WiFi)
2. **Test with poor network conditions**
3. **Test call quality and performance**
4. **Test call duration and stability**
5. **Test multiple simultaneous calls**

## Support

If you encounter issues:
1. Check the console logs on both devices
2. Verify database setup
3. Test with a simple WebRTC example first
4. Check network connectivity
5. Review Supabase real-time subscriptions

## URLs for Testing

### Web Call URLs
- Audio Call: `https://your-domain.com/call/{roomId}/{matchId}/audio`
- Video Call: `https://your-domain.com/call/{roomId}/{matchId}/video`

### Example URLs
```
https://your-domain.com/call/abc123/def456/audio
https://your-domain.com/call/abc123/def456/video
```

Replace `{roomId}` and `{matchId}` with actual values from your database.

