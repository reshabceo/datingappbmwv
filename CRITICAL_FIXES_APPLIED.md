# 🔧 CRITICAL WEBRTC FIXES APPLIED

**Date:** October 25, 2025  
**File Modified:** `lib/services/webrtc_service.dart`

---

## 🚨 ROOT CAUSES IDENTIFIED

### **Error 1: Duplicate Key Constraint Violation (iPhone)**
```
PostgrestException(message: duplicate key value violates unique constraint "webrtc_rooms_room_id_key", code: 23505)
```
- **Cause:** Old room data not cleaned up from previous failed calls
- **Result:** New calls fail immediately with "duplicate key" error

### **Error 2: 406 Not Acceptable (Chrome)**
```
GET webrtc_rooms?select=offer&room_id=eq.XXX 406 (Not Acceptable)
```
- **Cause:** Using `.single()` which throws error when no rows found
- **Result:** Chrome receiver fails to join room, incorrectly switches to caller mode

### **Error 3: No Database Cleanup**
- **Cause:** `endCall()` method doesn't delete room data
- **Result:** Old data accumulates, blocking future calls with same room ID

---

## ✅ FIXES APPLIED

### **Fix 1: Use UPSERT Instead of INSERT**
**Location:** Line ~263-270

**Before:**
```dart
await SupabaseService.client.from('webrtc_rooms').insert(roomData);
```

**After:**
```dart
// CRITICAL FIX: Use upsert instead of insert to handle duplicate room IDs
// This prevents "duplicate key" errors when retrying calls
await SupabaseService.client
    .from('webrtc_rooms')
    .upsert(roomData, onConflict: 'room_id');
```

**Impact:** 
- ✅ No more "duplicate key" errors
- ✅ Retrying calls works seamlessly
- ✅ Handles race conditions gracefully

---

### **Fix 2: Use MAYBESINGLE Instead of SINGLE**
**Location:** Line ~286-292

**Before:**
```dart
final roomData = await SupabaseService.client
    .from('webrtc_rooms')
    .select('offer')
    .eq('room_id', roomId)
    .single();  // Throws 406 error if no rows
```

**After:**
```dart
// CRITICAL FIX: Use maybeSingle() instead of single()
// single() throws 406 error when no rows found, maybeSingle() returns null
final roomData = await SupabaseService.client
    .from('webrtc_rooms')
    .select('offer')
    .eq('room_id', roomId)
    .maybeSingle();  // Returns null gracefully
```

**Impact:**
- ✅ No more 406 errors
- ✅ Proper null handling
- ✅ Clean error messages

---

### **Fix 3: Add Retry Logic with Delay**
**Location:** Line ~294-358

**Added:**
```dart
// CRITICAL FIX: Check if roomData is null OR if offer is null
if (roomData == null || roomData['offer'] == null) {
  print('⚠️ Join failed due to 0 rows (no offer). Acting as CALLER now...');
  print('📞 This usually means the CALLER hasn\'t created the room yet.');
  print('📞 Waiting 2 seconds before creating room as fallback...');
  
  // Wait a bit for the caller to create the room
  await Future.delayed(Duration(seconds: 2));
  
  // Try fetching again
  final retryRoomData = await SupabaseService.client
      .from('webrtc_rooms')
      .select('offer')
      .eq('room_id', roomId)
      .maybeSingle();
  
  // If still no offer, THEN switch to caller mode
  if (retryRoomData == null || retryRoomData['offer'] == null) {
    print('⚠️ Still no offer after retry. Switching to CALLER mode...');
    // ... switch to caller mode
  } else {
    // Got the offer on retry, continue as receiver
    print('✅ Got offer on retry, continuing as RECEIVER...');
    // ... continue with receiver flow
  }
}
```

**Impact:**
- ✅ Handles timing issues between caller and receiver
- ✅ Prevents both peers from becoming callers
- ✅ Graceful fallback if caller fails

---

### **Fix 4: Add Room Data Cleanup on Call End**
**Location:** Line ~674-696

**Added:**
```dart
// CRITICAL FIX: Clean up room data to prevent duplicate key errors on next call
if (_currentCallId != null) {
  try {
    print('🧹 Cleaning up WebRTC room data for: $_currentCallId');
    
    // Delete room data (offer/answer)
    await SupabaseService.client
        .from('webrtc_rooms')
        .delete()
        .eq('room_id', _currentCallId!);
    print('✅ Cleaned up room data');
    
    // Delete ICE candidates
    await SupabaseService.client
        .from('webrtc_ice_candidates')
        .delete()
        .eq('room_id', _currentCallId!);
    print('✅ Cleaned up ICE candidates');
  } catch (e) {
    print('⚠️ Error cleaning up room data (non-critical): $e');
    // Non-critical error, continue with call cleanup
  }
}
```

**Impact:**
- ✅ Clean database after each call
- ✅ No stale data blocking future calls
- ✅ Better resource management

---

## 📋 TESTING INSTRUCTIONS

### **Step 1: Hot Restart Both Apps**
```bash
# Stop all running instances
# Then restart:
flutter run -d chrome
flutter run -d <your-iphone-device-id>
```

### **Step 2: Make Test Call (iPhone → Chrome)**
1. **iPhone:** Initiate audio call
2. **Chrome:** Accept incoming call
3. **Watch logs for:**

**Expected iPhone Logs:**
```
📞 Storing offer in Supabase...
✅ Offer stored successfully (upsert)
🧊 Local ICE candidate generated
📤 Sending ICE candidate to Supabase...
✅ ICE candidate sent successfully
```

**Expected Chrome Logs:**
```
📞 NEW INCOMING CALL DETECTED!
📞 Joining room as RECEIVER...
✅ Got offer on retry, continuing as RECEIVER...
📞 Answer created: answer
✅ Answer stored successfully
🧊 Local ICE candidate generated
```

### **Step 3: End Call and Verify Cleanup**
**Expected Logs:**
```
📞 Ending call...
🧹 Cleaning up WebRTC room data for: <room-id>
✅ Cleaned up room data
✅ Cleaned up ICE candidates
✅ Call ended successfully
```

### **Step 4: Test Second Call (Verify No Duplicate Key Error)**
1. Make another call with same users
2. **Should NOT see:**
   - ❌ "duplicate key value violates unique constraint"
   - ❌ "406 (Not Acceptable)"
3. **Should see:**
   - ✅ "Offer stored successfully (upsert)"
   - ✅ Call connects properly

---

## 🎯 EXPECTED OUTCOMES

### **Before Fixes:**
- ❌ First call: "duplicate key" error (iPhone)
- ❌ First call: 406 error (Chrome)
- ❌ Both devices stuck at "connecting"
- ❌ Second call: Same errors persist

### **After Fixes:**
- ✅ First call: Clean offer/answer exchange
- ✅ First call: No 406 errors
- ✅ Call progresses to ICE candidate exchange
- ✅ Second call: Works without errors (cleanup successful)
- ✅ Audio connection may still need STUN/TURN verification

---

## 🔍 DEBUGGING TIPS

### **If Call Still Doesn't Connect:**

1. **Check for STUN/TURN Logs:**
   ```
   🧊 Local ICE candidate generated:
      - Candidate (first 80 chars): candidate:... typ relay ...
   ```
   - Should see `typ relay` for TURN candidates
   - Should see `typ srflx` for STUN candidates

2. **Check ICE Connection State:**
   ```
   🧊 ICE CONNECTION STATE: RTCIceConnectionStateChecking
   🧊 ICE CONNECTION STATE: RTCIceConnectionStateConnected
   ```

3. **Verify Answer Exchange:**
   ```
   📞 Answer stored successfully
   📞 Got answer from receiver
   ✅ Remote description (answer) set successfully
   ```

### **Common Issues:**

| Issue | Cause | Solution |
|-------|-------|----------|
| Still getting duplicate key | Old data in DB | Manually delete from `webrtc_rooms` table |
| No relay candidates | TURN server down | Check `openrelay.metered.ca` status |
| 406 errors persist | Old code running | Hard restart Flutter (not hot reload) |
| Call connects but no audio | ICE failed | Check firewall/network settings |

---

## ✅ ALL FIXES COMPLETED

**Status:** ✅ **READY FOR TESTING**

All critical fixes have been applied to `lib/services/webrtc_service.dart`:
1. ✅ UPSERT instead of INSERT
2. ✅ MAYBESINGLE instead of SINGLE
3. ✅ Retry logic with 2-second delay
4. ✅ Room data cleanup on call end

**Next Step:** Hot restart both apps and test iPhone → Chrome call.

