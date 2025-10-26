# 📞 Call Debug Guide

## **Setup Instructions**

### **1. Set up Supabase Debug Table**
Run the SQL script in your Supabase dashboard:
```sql
-- Copy and paste the contents of supabase_debug_setup.sql
```

### **2. For Your Apple Phone (iOS Debugging)**

**Option A: Xcode Console (Recommended)**
1. Connect iPhone to Mac
2. Open Xcode → Window → Devices and Simulators
3. Select your iPhone → Click "Open Console"
4. Filter by "LoveBug" or "com.lovebug.app"
5. Look for logs starting with "📞 CALL DEBUG:"

**Option B: Terminal (Advanced)**
```bash
# List connected devices
xcrun devicectl list devices

# Stream logs from specific device
xcrun devicectl device install app --device [DEVICE_ID] [APP_PATH]
```

### **3. For Your Friend's Android Device**

**Option A: ADB over WiFi (Same Network)**
```bash
# Enable USB debugging on Android device first
# Connect via USB, then:
adb tcpip 5555
adb connect [ANDROID_DEVICE_IP]:5555

# Stream logs
adb logcat | grep -E "(CALL DEBUG|WebRTC|flutter_webrtc)"
```

**Option B: Remote Debugging via Supabase**
- All call events are automatically logged to Supabase
- Check the `call_debug_logs` table in your Supabase dashboard
- Filter by `call_id` to see logs for specific calls

### **4. Real-time Debug Monitoring**

**View Debug Logs in Supabase:**
```sql
-- Get all call logs for a specific call
SELECT * FROM call_debug_logs 
WHERE call_id = 'your-call-id' 
ORDER BY timestamp;

-- Get recent call errors
SELECT * FROM call_debug_logs 
WHERE event LIKE '%error%' 
ORDER BY timestamp DESC 
LIMIT 50;

-- Get WebRTC connection issues
SELECT * FROM call_debug_logs 
WHERE event LIKE 'webrtc_%' 
ORDER BY timestamp DESC 
LIMIT 20;
```

## **Testing Scenarios**

### **Test 1: Audio Call (iOS → Android)**
1. Start call from iOS device
2. Accept call on Android device
3. Check logs for:
   - `call_initiated`
   - `webrtc_connection_established`
   - `call_connected`
   - Audio quality issues

### **Test 2: Video Call (Android → iOS)**
1. Start video call from Android
2. Accept call on iOS
3. Check logs for:
   - Video stream initialization
   - Camera permissions
   - Network bandwidth issues

### **Test 3: Network Issues**
1. Test on different networks (WiFi vs Mobile)
2. Test with poor signal strength
3. Check logs for:
   - `network_conditions`
   - Connection drops
   - Reconnection attempts

## **Common Issues & Debug Points**

### **Audio Issues**
- Check microphone permissions
- Look for `webrtc_audio_track_failed`
- Check device audio settings

### **Video Issues**
- Check camera permissions
- Look for `webrtc_video_track_failed`
- Check device camera availability

### **Connection Issues**
- Check STUN server connectivity
- Look for `webrtc_ice_connection_failed`
- Check network firewall settings

### **Call State Issues**
- Look for `call_state_change` events
- Check for unexpected state transitions
- Monitor call duration and end reasons

## **Debug Commands**

### **Check Call History**
```sql
SELECT 
  call_id,
  event,
  timestamp,
  data,
  error
FROM call_debug_logs 
WHERE user_id = 'your-user-id'
ORDER BY timestamp DESC 
LIMIT 20;
```

### **Find Failed Calls**
```sql
SELECT 
  call_id,
  event,
  error,
  timestamp
FROM call_debug_logs 
WHERE error IS NOT NULL
ORDER BY timestamp DESC;
```

### **Monitor WebRTC Events**
```sql
SELECT 
  call_id,
  event,
  data->>'webrtc_data' as webrtc_info,
  timestamp
FROM call_debug_logs 
WHERE event LIKE 'webrtc_%'
ORDER BY timestamp DESC;
```

## **Troubleshooting Steps**

1. **Check Permissions**: Ensure microphone/camera permissions are granted
2. **Network Test**: Test on different networks (WiFi vs Mobile)
3. **Device Compatibility**: Check if both devices support WebRTC
4. **Firewall Issues**: Check if corporate/school networks block WebRTC
5. **STUN Server**: Verify STUN server connectivity

## **Log Analysis**

### **Successful Call Flow**
```
📞 CALL DEBUG: call_initiated
📞 CALL DEBUG: webrtc_peer_connection_created
📞 CALL DEBUG: webrtc_ice_candidates_gathered
📞 CALL DEBUG: webrtc_connection_established
📞 CALL DEBUG: call_connected
```

### **Failed Call Flow**
```
📞 CALL DEBUG: call_initiated
📞 CALL DEBUG: webrtc_peer_connection_created
📞 CALL DEBUG: webrtc_ice_connection_failed
📞 CALL DEBUG: call_error - ICE connection failed
```

## **Performance Monitoring**

- **Call Quality**: Monitor audio/video quality metrics
- **Connection Time**: Time from call start to connection
- **Network Usage**: Bandwidth consumption during calls
- **Battery Impact**: Device battery usage during calls

## **Emergency Debugging**

If calls are completely failing:
1. Check Supabase logs for any errors
2. Verify WebRTC service is properly initialized
3. Check device permissions and capabilities
4. Test with different call participants
5. Check network connectivity and firewall settings
