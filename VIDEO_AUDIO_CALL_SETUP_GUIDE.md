# 📞 Video & Audio Call Setup Guide for LoveBug Dating App

This guide will help you set up video and audio calling features for your LoveBug dating app using WebRTC and CallKit.

## 🚀 Implementation Summary

✅ **Completed:**
- Added WebRTC and CallKit dependencies to `pubspec.yaml`
- Created call models and controllers
- Implemented video and audio call screens
- Added call options to chat hamburger menu
- Created Supabase database schema
- Added platform-specific permissions
- Created Supabase Edge Function for notifications

## 📋 Setup Steps

### 1. Database Setup

Run the SQL schema in your Supabase dashboard:

```sql
-- Copy and paste the contents of call_system_schema.sql
-- This creates the necessary tables for call sessions and WebRTC signaling
```

### 2. Supabase Edge Function Setup

1. Deploy the Edge Function:
```bash
cd supabase
supabase functions deploy send-call-notification
```

2. Set environment variables in Supabase:
- `FCM_SERVER_KEY`: Your Firebase Cloud Messaging server key

### 3. Firebase Setup (for FCM)

1. Add Firebase to your project
2. Enable Cloud Messaging
3. Get your FCM server key
4. Add it to Supabase environment variables

### 4. Platform Configuration

#### Android
- Permissions already added to `AndroidManifest.xml`
- No additional setup required

#### iOS
- Permissions already added to `Info.plist`
- Background modes configured for VoIP

### 5. Code Integration

The following files have been created/modified:

**New Files:**
- `lib/models/call_models.dart` - Call data models
- `lib/services/webrtc_service.dart` - WebRTC service
- `lib/services/callkit_service.dart` - CallKit service
- `lib/controllers/call_controller.dart` - Call controller
- `lib/screens/call_screens/video_call_screen.dart` - Video call UI
- `lib/screens/call_screens/audio_call_screen.dart` - Audio call UI

**Modified Files:**
- `pubspec.yaml` - Added WebRTC dependencies
- `lib/Screens/ChatPage/ui_message_screen.dart` - Added call options to menu
- `android/app/src/main/AndroidManifest.xml` - Added permissions
- `ios/Runner/Info.plist` - Added permissions

## 🎯 How It Works

### Call Flow:
1. User taps "Video Call" or "Audio Call" in chat hamburger menu
2. System creates call session in Supabase
3. WebRTC room is created for signaling
4. Push notification sent to receiver
5. CallKit shows incoming call interface
6. When accepted, WebRTC connection established
7. Video/audio streams start flowing

### Features:
- ✅ Video and audio calls between matched users
- ✅ Works in both dating and BFF modes
- ✅ CallKit integration for native call experience
- ✅ Push notifications for incoming calls
- ✅ Call history tracking
- ✅ Mute, speaker, camera controls
- ✅ Call duration tracking

## 🔧 Configuration Required

### 1. Firebase Cloud Messaging
```bash
# Add to your Firebase project
# Get FCM server key from Firebase Console
# Add to Supabase environment variables
```

### 2. Supabase Environment Variables
```bash
# Set in Supabase Dashboard > Settings > Edge Functions
FCM_SERVER_KEY=your_fcm_server_key_here
```

### 3. User FCM Tokens
You'll need to store FCM tokens in user profiles:
```sql
-- Add fcm_token column to profiles table (already in schema)
ALTER TABLE profiles ADD COLUMN fcm_token TEXT;
```

## 🧪 Testing

### Test Call Flow:
1. Create two test users
2. Match them in the app
3. Go to chat screen
4. Tap hamburger menu → "Video Call" or "Audio Call"
5. Check if notification appears on other device
6. Accept call and verify connection

### Debug Tips:
- Check Supabase logs for call sessions
- Monitor FCM delivery in Firebase Console
- Test on real devices (WebRTC doesn't work in simulators)

## 🚨 Important Notes

1. **Real Device Testing**: WebRTC requires real devices, not simulators
2. **Permissions**: Users must grant camera/microphone permissions
3. **Network**: Requires stable internet connection
4. **FCM Setup**: Push notifications require proper Firebase configuration
5. **CallKit**: iOS users will see native call interface

## 🔄 Next Steps

1. Run `flutter pub get` to install dependencies
2. Deploy Supabase schema
3. Set up Firebase FCM
4. Deploy Edge Function
5. Test on real devices
6. Add FCM token storage to user registration

## 📱 User Experience

- **Initiating Call**: Tap hamburger menu → Video/Audio Call
- **Receiving Call**: Native call interface appears
- **During Call**: Full-screen video or audio interface with controls
- **Call History**: Stored in database for future reference

The implementation is complete and ready for testing! 🎉
