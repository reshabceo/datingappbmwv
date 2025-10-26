# 🔧 WebRTC Call System Fix - Complete Guide

## 📊 Problem Summary

The call system was getting stuck in "connecting" state. The iPhone would show "Calling..." and Chrome would show "Connecting..." but the call would never establish.

### Root Causes Identified:

1. **Caller/Receiver Role Confusion**: Both peers were trying to create offers instead of properly coordinating who creates the offer (caller) and who creates the answer (receiver)

2. **Missing Answer Listener**: The caller wasn't properly listening for the answer from the receiver

3. **ICE Candidate Timing**: ICE candidates were being sent too quickly without allowing time for connectivity testing

4. **No Explicit Role Distinction**: The code didn't explicitly track whether a peer was the initiator or responder

## ✅ Fixes Applied

### 1. **Updated `webrtc_service.dart`**

#### Key Changes:
- Added `isInitiator` boolean flag to track caller vs receiver role
- Separated `_createRoom()` (for CALLER) and `_joinRoom()` (for RECEIVER)
- Added proper answer listener for caller using `_listenForAnswer()`
- Added ICE candidate delay (500ms) before sending to allow proper connectivity testing
- Improved logging for debugging
- Added stream subscriptions cleanup

#### Flow for CALLER (iPhone - www):
```dart
1. initializeCall(isInitiator: true)
2. _createRoom()
   - Create SDP offer
   - Store offer in webrtc_rooms table
   - Listen for answer from receiver
3. When answer received:
   - Set remote description (answer)
   - Start listening for ICE candidates
```

#### Flow for RECEIVER (Chrome - RESHAB):
```dart
1. initializeCall(isInitiator: false)
2. _joinRoom()
   - Get offer from webrtc_rooms table
   - Set remote description (offer)
   - Create SDP answer
   - Store answer in webrtc_rooms table
   - Start listening for ICE candidates
```

### 2. **Updated `call_listener_service.dart`**

- Added `isInitiator: false` when accepting calls
- This service handles incoming call notifications on receiver side

### 3. **Updated `callkit_listener_service.dart`**

- Added `isInitiator: false` when accepting calls via CallKit
- Handles iOS native call acceptance

### 4. **Updated `audio_call_screen.dart` and `video_call_screen.dart`**

- Determines initiator role from `CallPayload.callAction`
- If `callAction == CallAction.create` → caller (isInitiator: true)
- Otherwise → receiver (isInitiator: false)

## 🧪 Testing Instructions

### Prerequisites:
1. iPhone with the app installed
2. Chrome browser (or another device)
3. Both logged in as different users
4. Both users must be matched

### Test Scenario 1: iPhone → Chrome Audio Call

1. **iPhone (www - kavinanup.work@gmail.com)**:
   ```bash
   cd /Users/reshab/Desktop/datingappbmwv
   flutter run -v
   ```
   - Go to chat with RESHAB
   - Tap Audio Call button
   - **Expected logs**:
     ```
     📞 AudioCallScreen: Initializing as CALLER
     📞 Creating room as CALLER...
     ✅ Offer stored successfully
     📞 Listening for answer from receiver...
     ```

2. **Chrome (RESHAB - reshab.retheesh@gmail.com)**:
   ```bash
   # Already running from earlier
   ```
   - **Expected logs in Chrome Console (F12)**:
     ```
     📞 NEW INCOMING CALL DETECTED!
     📞 Accepting call: [call-id]
     📞 Joining room as RECEIVER...
     📞 Setting remote description (offer)...
     📞 Creating answer...
     ✅ Answer stored successfully
     ```

3. **Expected Result**:
   - iPhone should see: "📞 Answer received from receiver!"
   - Both should see: "✅ WebRTC connection established!"
   - Call state changes to "Connected"
   - Audio flows both ways

### Test Scenario 2: Chrome → iPhone Video Call

(Follow similar steps but reverse the roles)

## 📝 Key Debug Logs to Watch For

### On CALLER (iPhone):
```
📞 Initializing WebRTC call as CALLER
📞 Room ID: [room-id]
📞 Creating room as CALLER...
📞 Offer created: offer
✅ Offer stored successfully
📞 Listening for answer from receiver...
📞 Answer received from receiver!
📞 Setting remote description (answer)...
✅ Remote description set successfully
📞 Listening for ICE candidates...
📞 Sending ICE candidate to Supabase...
📞 Connection state changed: RTCPeerConnectionState.RTCPeerConnectionStateConnected
✅ WebRTC connection established!
```

### On RECEIVER (Chrome):
```
📞 NEW INCOMING CALL DETECTED!
📞 Accepting call: [call-id]
📞 Registering WebRTCService...
📞 Initializing WebRTC call as RECEIVER
📞 Joining room as RECEIVER...
📞 Setting remote description (offer)...
📞 Creating answer...
📞 Answer created: answer
✅ Answer stored successfully
📞 Listening for ICE candidates...
📞 Remote track received: audio
✅ Remote stream received with 1 tracks
📞 Connection state changed: RTCPeerConnectionState.RTCPeerConnectionStateConnected
✅ WebRTC connection established!
```

## ⚠️ Common Issues & Solutions

### Issue 1: "No offer found in room"
**Cause**: Receiver trying to join before caller creates the room
**Solution**: Ensure call_sessions table has the entry and webrtc_rooms has the offer

### Issue 2: ICE candidates not exchanging
**Cause**: Network/firewall blocking STUN servers
**Solution**: Check network connectivity, try different network

### Issue 3: Audio not heard despite connection
**Cause**: Muted tracks or speaker not enabled on mobile
**Solution**: Check mute status, ensure speaker is enabled on iOS

### Issue 4: Connection fails immediately
**Cause**: Incorrect remote description or ICE candidate format
**Solution**: Check browser compatibility, ensure SDP format is correct

## 🔍 Database Tables to Monitor

### 1. `call_sessions`
```sql
SELECT id, caller_id, receiver_id, state, type, created_at 
FROM call_sessions 
ORDER BY created_at DESC 
LIMIT 5;
```

**Expected states progression**:
- `initial` → `connecting` → `connected` → `disconnected`

### 2. `webrtc_rooms`
```sql
SELECT room_id, 
       offer IS NOT NULL as has_offer, 
       answer IS NOT NULL as has_answer,
       created_at 
FROM webrtc_rooms 
ORDER BY created_at DESC 
LIMIT 5;
```

**Expected**:
- Offer created first (by caller)
- Answer added shortly after (by receiver)

### 3. `webrtc_ice_candidates`
```sql
SELECT room_id, COUNT(*) as candidate_count
FROM webrtc_ice_candidates
GROUP BY room_id
ORDER BY MAX(created_at) DESC
LIMIT 5;
```

**Expected**:
- Multiple ICE candidates from both peers

## 📚 WebRTC Signaling Flow (Reference)

Based on flutter-webrtc-demo best practices:

```
CALLER                              RECEIVER
  |                                    |
  |-- 1. Create PeerConnection ------>|
  |                                    |
  |-- 2. Create Offer ---------------->|
  |                                    |
  |<- 3. Set Remote Desc (offer) ------|
  |                                    |
  |<- 4. Create Answer -----------------|
  |                                    |
  |-- 5. Set Remote Desc (answer) ---->|
  |                                    |
  |<----- 6. Exchange ICE Candidates -->|
  |<----- (continuous until connected)->|
  |                                    |
  |<----- 7. Connection Established --->|
  |                                    |
  |<----- 8. Media Streams Flow ------->|
```

## 🎯 Success Criteria

- [ ] Call notification appears on receiver
- [ ] Receiver accepts call
- [ ] Both see "Connecting..." status
- [ ] Connection establishes within 5-10 seconds
- [ ] Both see "Connected" status
- [ ] Audio/video streams in both directions
- [ ] Call can be ended from either side
- [ ] Database shows proper state progression

## 🚀 Next Steps

If calls still don't connect:

1. **Check STUN servers**: Try adding more STUN servers or a TURN server
2. **Network issues**: Test on same WiFi network first
3. **Browser compatibility**: Ensure using latest Chrome/Safari
4. **Mobile permissions**: Verify microphone/camera permissions granted
5. **Supabase real-time**: Verify real-time subscriptions are working

## 📞 Support

If you encounter issues:
1. Check all console logs (both iPhone terminal and Chrome DevTools)
2. Monitor Supabase real-time tab
3. Verify database entries are being created
4. Check network connectivity between devices

---

**Last Updated**: Saturday, October 25, 2025
**Version**: 2.0 - Complete WebRTC Signaling Fix

