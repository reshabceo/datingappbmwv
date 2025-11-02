# iOS Push Notification Complete Reset Guide

## 🚨 **CRITICAL: Complete iOS Push Notification Reset**

The PushKit changes have likely broken iOS push notifications. Follow this complete reset process:

## **Step 1: Xcode Project Configuration**

### **1.1 Remove PushKit Framework (if still present)**
1. Open `ios/Runner.xcodeproj` in Xcode
2. Select the Runner target
3. Go to "Build Phases" → "Link Binary With Libraries"
4. Remove `PushKit.framework` if present
5. Clean build folder (Cmd+Shift+K)

### **1.2 Verify Background Modes**
1. Select Runner target
2. Go to "Signing & Capabilities"
3. Add "Background Modes" capability if not present
4. Enable ONLY:
   - ✅ Background processing
   - ✅ Background fetch
   - ❌ Voice over IP (REMOVE THIS)

### **1.3 Verify Push Notifications Capability**
1. In "Signing & Capabilities"
2. Add "Push Notifications" capability
3. Ensure it's enabled

## **Step 2: Firebase Configuration**

### **2.1 Download New APNs Certificate**
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Go to Project Settings → Cloud Messaging
4. Under "Apple app configuration":
   - Click "Upload" next to APNs certificates
   - Download a new APNs Auth Key (.p8 file)
   - Upload the .p8 file
   - Note the Key ID and Team ID

### **2.2 Update iOS App Configuration**
1. In Firebase Console → Project Settings
2. Under "Your apps" → iOS app
3. Download the new `GoogleService-Info.plist`
4. Replace the existing file in `ios/Runner/GoogleService-Info.plist`

## **Step 3: Apple Developer Account**

### **3.1 Verify App ID Configuration**
1. Go to [Apple Developer Console](https://developer.apple.com)
2. Go to Certificates, Identifiers & Profiles
3. Select your App ID
4. Ensure these capabilities are enabled:
   - ✅ Push Notifications
   - ❌ Voice over IP (REMOVE THIS)
5. Save changes

### **3.2 Regenerate Provisioning Profiles**
1. In Apple Developer Console
2. Go to Profiles
3. Delete existing profiles for your app
4. Create new profiles with updated capabilities
5. Download and install new profiles

## **Step 4: Xcode Project Cleanup**

### **4.1 Clean Everything**
```bash
cd /Users/reshab/Desktop/datingappbmwv
flutter clean
cd ios
rm -rf Pods Podfile.lock .symlinks
pod install --repo-update
cd ..
flutter pub get
```

### **4.2 Remove DerivedData**
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/*
```

## **Step 5: Test Configuration**

### **5.1 Build and Test**
```bash
flutter build ios --no-codesign
```

### **5.2 Verify in Xcode**
1. Open `ios/Runner.xcodeproj`
2. Build the project (Cmd+B)
3. Check for any errors related to push notifications

## **Step 6: Code Verification**

### **6.1 Check AppDelegate.swift**
Ensure it has:
- Firebase configuration
- UNUserNotificationCenter delegate
- Proper notification handling

### **6.2 Check Info.plist**
Ensure it has:
- Firebase configuration
- Background modes
- Push notification entitlements

## **Step 7: Test Push Notifications**

### **7.1 Test on Physical Device**
1. Install app on physical iOS device
2. Test push notifications
3. Check Xcode console for logs

### **7.2 Debug Steps**
1. Check if FCM token is generated
2. Check if APNs token is generated
3. Check if notifications are received
4. Check if CallKit is triggered

## **Common Issues and Solutions**

### **Issue 1: "No APNs token"**
- Solution: Regenerate provisioning profiles
- Check App ID capabilities

### **Issue 2: "Push notifications not received"**
- Solution: Verify Firebase configuration
- Check device token registration

### **Issue 3: "CallKit not showing"**
- Solution: Check background handler
- Verify notification payload

## **Verification Checklist**

- [ ] PushKit framework removed
- [ ] Voice over IP capability removed
- [ ] Push Notifications capability enabled
- [ ] Background Modes configured correctly
- [ ] APNs certificate uploaded to Firebase
- [ ] GoogleService-Info.plist updated
- [ ] App ID capabilities updated
- [ ] Provisioning profiles regenerated
- [ ] Xcode project cleaned
- [ ] App builds successfully
- [ ] Push notifications work on device

## **Next Steps After Reset**

1. Deploy the fixed edge function
2. Test Android push notifications
3. Test iOS push notifications
4. Test call connections
5. Verify all scenarios work

---

**Note**: This is a complete reset. All previous push notification configurations will be replaced with fresh ones.
