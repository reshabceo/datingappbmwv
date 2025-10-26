# WebRTC Call Testing Checklist

## ✅ Pre-Test Setup Complete
- [x] Database schemas applied in Supabase
- [x] TURN server added to code
- [x] ICE state logging added
- [x] Call decoupled from push notifications
- [x] Debug logging table created

---

## 🧪 Test 1: Google Chrome → iPhone (Same Network)

### Step 1: Hot Restart Both Apps
```bash
# Chrome Web
flutter run -d chrome --hot

# Or refresh browser if already running
```

### Step 2: Initiate Call from Chrome
1. Open Chrome app
2. Go to chat with iPhone user (Kavin)
3. Click the **audio call button** ☎️

### Step 3: Look for These Logs on Chrome Console

**✅ Expected logs (in order):**
```
📞 AudioCallScreen: _initializeCall() called
📞 AudioCallScreen: Initializing as CALLER
📞 AudioCallScreen: About to call webrtcService.initializeCall()
📞 WebRTCService.initializeCall() called with isInitiator=true
📞 Initializing WebRTC call as CALLER
📞 About to call _createRoom() as CALLER
📞 _createRoom() called with roomId: [some-uuid]
📞 Creating room as CALLER...
📞 Offer created: offer
📞 Offer SDP (first 200 chars): v=0...
📞 Storing offer in Supabase...
✅ Offer stored successfully
📞 Listening for answer from receiver...
🧊 Local ICE candidate generated:
   - Candidate (first 80 chars): candidate:... typ host...
✅ ICE candidate sent successfully
🧊 Local ICE candidate generated:
   - Candidate: candidate:... typ srflx... (SERVER REFLEXIVE - from STUN)
🧊 Local ICE candidate generated:
   - Candidate: candidate:... typ relay... (RELAY - from TURN)
🧊 ICE Connection State: RTCIceConnectionStateChecking
🧊 ICE Connection State: RTCIceConnectionStateConnected
✅ ICE connection established successfully!
📞 Remote track received: audio
```

**🚨 If you don't see these logs:**
- Missing "Creating room as CALLER" → Call screen didn't open or isInitiator=false
- Missing "Offer stored successfully" → Database permissions issue
- Missing "typ relay" candidates → TURN server not working
- Stuck at "Checking" → ICE candidates not exchanging

### Step 4: Look for These Logs on iPhone (Xcode Console)

**✅ Expected logs (in order):**
```
📞 ═══════════════════════════════════════════════
📞 INCOMING CALL RECEIVED VIA REALTIME LISTENER!
📞 ═══════════════════════════════════════════════
📞 Processing incoming call...
📞 Incoming audio call from: [caller-id]
[User taps "Accept"]
📞 AudioCallScreen: _initializeCall() called
📞 AudioCallScreen: Initializing as RECEIVER
📞 WebRTCService.initializeCall() called with isInitiator=false
📞 Initializing WebRTC call as RECEIVER
📞 About to call _joinRoom() as RECEIVER
📞 Joining room as RECEIVER...
📞 Got offer from database
📞 Offer has [X] lines
📞 Set remote description (offer)
📞 Creating answer...
📞 Answer created: answer
📞 Set local description (answer)
📞 Answer stored successfully
📞 Listening for remote ICE candidates...
🧊 Remote ICE candidate received: candidate:... typ host...
🧊 Remote ICE candidate received: candidate:... typ relay...
🧊 ICE Connection State: RTCIceConnectionStateChecking
🧊 ICE Connection State: RTCIceConnectionStateConnected
✅ ICE connection established successfully!
📞 Remote track received: audio
```

### Step 5: Verify Audio
- [ ] Can Chrome hear iPhone?
- [ ] Can iPhone hear Chrome?
- [ ] Call timer is running on both screens
- [ ] No echo or audio distortion

### Step 6: Check Database (Optional)
```sql
-- See the offer and answer
SELECT room_id, 
       CASE WHEN offer IS NOT NULL THEN '✅ Offer' ELSE '❌ No Offer' END,
       CASE WHEN answer IS NOT NULL THEN '✅ Answer' ELSE '❌ No Answer' END
FROM webrtc_rooms 
ORDER BY created_at DESC 
LIMIT 1;

-- Count ICE candidates
SELECT room_id, COUNT(*) as candidate_count
FROM webrtc_ice_candidates
WHERE created_at > NOW() - INTERVAL '5 minutes'
GROUP BY room_id;

-- Check call session state
SELECT caller_id, receiver_id, type, state, created_at
FROM call_sessions
ORDER BY created_at DESC
LIMIT 1;
```

**Expected:**
- ✅ Offer: Present
- ✅ Answer: Present
- ICE candidates: 10+ per side
- Call state: 'connected'

---

## 🧪 Test 2: iPhone → Google Chrome

### Repeat same test but initiate from iPhone
1. Open iPhone app
2. Go to chat with Chrome user (Reshab)
3. Tap audio call button
4. Chrome should see incoming call dialog
5. Accept on Chrome
6. Verify audio works both ways

---

## 🧪 Test 3: Different Networks (If Available)

### iPhone on LTE, Chrome on Wi-Fi
1. Disconnect iPhone from Wi-Fi
2. Enable cellular data
3. Run Test 1 again
4. **Critical check**: Look for `typ relay` candidates
5. Verify call still connects

**Why this matters:**
- Without TURN, cross-network calls fail
- With TURN, relay candidates provide fallback path
- Should see both srflx (STUN) and relay (TURN) candidates

---

## 🐛 Troubleshooting Guide

### Problem: Chrome doesn't create offer

**Symptoms:**
- No "Creating room as CALLER..." log
- Call screen may not even open

**Debug:**
```javascript
// Check Chrome console for navigation errors
// Look for: "AudioCallScreen: _initializeCall() called"
```

**Fix if missing:**
1. Verify call button actually navigates to call screen
2. Check that `CallAction.create` is passed in payload
3. Verify WebRTC service is initialized

### Problem: iPhone doesn't see incoming call

**Symptoms:**
- No incoming call dialog on iPhone
- No "INCOMING CALL RECEIVED" log

**Debug:**
```sql
-- Check if call_session was created
SELECT * FROM call_sessions 
WHERE receiver_id = 'IPHONE_USER_ID'
ORDER BY created_at DESC LIMIT 1;
```

**Fix if row exists but no dialog:**
1. Check if CallListenerService is initialized
2. Verify RLS policies allow receiver to read call_sessions
3. Check Supabase realtime subscription status

### Problem: Stuck at "connecting"

**Symptoms:**
- ICE state stays at "RTCIceConnectionStateChecking"
- Never reaches "Connected"
- May timeout after 30 seconds

**Debug:**
```sql
-- Check if ICE candidates are being stored
SELECT COUNT(*), room_id 
FROM webrtc_ice_candidates 
WHERE created_at > NOW() - INTERVAL '5 minutes'
GROUP BY room_id;
```

**Common causes:**
1. **No relay candidates** → TURN not working
   - Check TURN server is reachable: `telnet openrelay.metered.ca 80`
   - Verify credentials in code match TURN server

2. **ICE candidates not exchanging** → Database issue
   - Check RLS policies on webrtc_ice_candidates
   - Verify both sides can read/write

3. **Firewall blocking UDP** → Use TCP relay
   - TURN with `?transport=tcp` should work

### Problem: No audio after "connected"

**Symptoms:**
- ICE shows "connected"
- But no audio heard on either side

**Debug:**
```javascript
// Check Chrome console for:
"📞 Remote track received: audio"
```

**Fix if missing:**
1. Check microphone permissions granted
2. Verify `getUserMedia` succeeded
3. Check if tracks were added to peer connection:
   ```dart
   _localStream?.getTracks().forEach((track) {
     _peerConnection?.addTrack(track, _localStream!);
   });
   ```

### Problem: Call works on same network but fails on different networks

**Symptoms:**
- LAN calls work fine
- LTE → Wi-Fi calls fail
- No relay candidates in logs

**This confirms:** TURN server issue

**Fix:**
1. Verify TURN credentials
2. Check TURN server is actually running and reachable
3. For production, set up your own TURN server (recommended)

---

## 📊 Success Criteria

### ✅ Test is SUCCESSFUL if:
- [x] Chrome shows "Creating room as CALLER..."
- [x] iPhone shows "INCOMING CALL RECEIVED..."
- [x] Both show "ICE connection established successfully!"
- [x] Both can hear each other clearly
- [x] Call timer runs on both screens
- [x] Database shows offer, answer, and ICE candidates
- [x] Relay candidates appear in logs (typ relay)

### ❌ Test FAILED if:
- [ ] Chrome never creates offer
- [ ] iPhone doesn't get incoming call notification
- [ ] Stuck at "connecting" > 10 seconds
- [ ] No relay candidates (only host/srflx)
- [ ] Can't hear audio on one or both sides
- [ ] Call disconnects immediately

---

## 📝 Report Results

After testing, share:

1. **Chrome console logs** (copy all 📞 and 🧊 logs)
2. **iPhone Xcode logs** (copy all 📞 and 🧊 logs)
3. **Database verification** (run the SQL queries above)
4. **Network setup** (same network? different networks?)
5. **Result** (audio worked? any issues?)

---

## 🎯 What Should Happen

### Ideal Flow (5-10 seconds total)
```
0s:  Chrome user taps call button
1s:  Chrome: "Creating room as CALLER..."
2s:  iPhone: "INCOMING CALL RECEIVED..."
3s:  iPhone user taps "Accept"
4s:  iPhone: "Joining room as RECEIVER..."
5s:  Both: "ICE Connection State: Checking"
7s:  Both: "ICE Connection State: Connected"
8s:  Audio starts flowing 🎉
```

### Timeline Breakdown
- **0-2s**: Signaling (offer/answer exchange)
- **2-7s**: ICE negotiation (finding best path)
- **7s+**: Audio flows via selected path

If it takes longer than 15 seconds, something is wrong.

---

## 🚀 Ready to Test!

**What you need:**
- ✅ Chrome browser with app running
- ✅ iPhone with app installed  
- ✅ Both logged into different accounts
- ✅ Both have matched with each other
- ✅ Chrome console open (F12)
- ✅ Xcode console open (for iPhone logs)

**Start with Test 1** and let me know what logs you see! 🎉

