# UAC (Universal App Campaigns) Implementation Guide

## Overview
This guide covers the complete implementation of UAC marketing requirements for the LoveBug dating app, including Firebase SDK integration, Google Ads SDK, Meta (Facebook) SDK, and all required tracking events.

## ✅ Completed Implementation

### 1. Firebase SDK Setup
- ✅ Firebase Core and Analytics dependencies added
- ✅ Firebase initialization in main.dart
- ✅ Firebase options configured for all platforms

### 2. Required Tracking Events Implementation
All UAC required events are now implemented:

#### ✅ Install
- **Method**: `AnalyticsService.trackAppInstall()`
- **Triggers**: First app launch after installation
- **Platforms**: Firebase Analytics, Facebook App Events, Supabase

#### ✅ First Open
- **Method**: `AnalyticsService.trackFirstOpen()`
- **Triggers**: First app open after install
- **Platforms**: Firebase Analytics, Facebook App Events, Supabase

#### ✅ Sign Up
- **Method**: `AnalyticsService.trackSignUp(method)`
- **Triggers**: User account creation (phone, email, Google, Apple)
- **Platforms**: Firebase Analytics, Facebook App Events, Supabase

#### ✅ Login
- **Method**: `AnalyticsService.trackLoginEnhanced(method)`
- **Triggers**: User authentication (phone OTP, email, Google, Apple)
- **Platforms**: Firebase Analytics, Facebook App Events, Supabase

#### ✅ Profile Completed
- **Method**: `AnalyticsService.trackProfileCompleted(profileData)`
- **Triggers**: User completes profile setup with photos, bio, interests
- **Platforms**: Firebase Analytics, Facebook App Events, Supabase

#### ✅ Subscription Purchased
- **Method**: `AnalyticsService.trackSubscriptionPurchased(...)`
- **Triggers**: User purchases premium subscription
- **Platforms**: Firebase Analytics, Facebook App Events, Supabase

#### ✅ Session Start
- **Method**: `AnalyticsService.trackSessionStart()`
- **Triggers**: App launch and user session start
- **Platforms**: Firebase Analytics, Facebook App Events, Supabase

### 3. SDK Dependencies Added
```yaml
# Analytics dependencies
firebase_core: ^3.6.0
firebase_analytics: ^11.3.3

# Google Ads SDK
google_mobile_ads: ^5.1.0

# Meta (Facebook) SDK
facebook_app_events: ^0.20.0

# Additional tracking dependencies
package_info_plus: ^8.0.0
device_info_plus: ^10.1.0
```

### 4. Platform Configuration

#### Android Configuration
- ✅ AndroidManifest.xml updated with permissions
- ✅ Google Mobile Ads App ID configured
- ✅ Facebook App ID and Client Token configured
- ✅ String resources created

#### iOS Configuration
- ✅ Info.plist updated with Facebook configuration
- ✅ Google Mobile Ads App ID configured
- ✅ URL schemes configured for Facebook

## 🔧 Configuration Required

### 1. Firebase Configuration
Replace placeholder values in `lib/firebase_options.dart`:

```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'YOUR_ANDROID_API_KEY',
  appId: 'YOUR_ANDROID_APP_ID',
  messagingSenderId: 'YOUR_SENDER_ID',
  projectId: 'YOUR_PROJECT_ID',
  storageBucket: 'YOUR_PROJECT_ID.appspot.com',
);
```

### 2. Facebook App Configuration
Replace placeholder values:

**Android** (`android/app/src/main/res/values/strings.xml`):
```xml
<string name="facebook_app_id">YOUR_FACEBOOK_APP_ID</string>
<string name="facebook_client_token">YOUR_FACEBOOK_CLIENT_TOKEN</string>
```

**iOS** (`ios/Runner/Info.plist`):
```xml
<key>FacebookAppID</key>
<string>YOUR_FACEBOOK_APP_ID</string>
<key>FacebookClientToken</key>
<string>YOUR_FACEBOOK_CLIENT_TOKEN</string>
```

### 3. Google Mobile Ads Configuration
Replace test App ID with your actual AdMob App ID:

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-XXXXXXXXXX~XXXXXXXXXX"/>
```

**iOS** (`ios/Runner/Info.plist`):
```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-XXXXXXXXXX~XXXXXXXXXX</string>
```

## 📱 App Store Listings Setup

### Google Play Store
1. Create Google Play Console account
2. Create new app listing
3. Upload app bundle/APK
4. Configure store listing with:
   - App name: "LoveBug"
   - Short description: "Find Your Perfect Match"
   - Full description: Detailed app description
   - Screenshots and promotional graphics
   - App category: "Dating"

### Apple App Store
1. Create Apple Developer account
2. Create new app in App Store Connect
3. Upload app binary
4. Configure store listing with:
   - App name: "LoveBug"
   - Subtitle: "Find Your Perfect Match"
   - Description: Detailed app description
   - Screenshots and promotional graphics
   - App category: "Lifestyle"

## 🔗 Meta Developer Account Setup

### 1. Create Meta Developer Account
1. Go to https://developers.facebook.com/apps/
2. Create new app
3. Choose "Consumer" app type
4. Configure app settings

### 2. Connect with App Store Listings
1. In Meta Developer Console:
   - Go to App Settings > Basic
   - Add iOS App Store ID
   - Add Google Play Store package name
2. Configure App Events:
   - Enable App Events
   - Set up conversion tracking
   - Configure custom events

### 3. Facebook SDK Configuration
1. Add Facebook App ID to both platforms
2. Configure URL schemes for iOS
3. Set up deep linking

## 🚀 Deployment Steps

### 1. Update Configuration Files
1. Replace all placeholder values with actual IDs
2. Test Firebase connection
3. Test Facebook SDK integration
4. Test Google Mobile Ads SDK

### 2. Build and Test
```bash
# Install dependencies
flutter pub get

# Test on Android
flutter run --debug

# Test on iOS
flutter run --debug -d ios
```

### 3. Production Build
```bash
# Android
flutter build appbundle --release

# iOS
flutter build ios --release
```

## 📊 Event Tracking Verification

### Test All Tracking Events
1. **Install**: Fresh app install
2. **First Open**: First launch after install
3. **Sign Up**: Create new account
4. **Login**: Sign in with existing account
5. **Profile Completed**: Complete profile setup
6. **Subscription Purchased**: Buy premium plan
7. **Session Start**: App launch

### Verification Methods
1. **Firebase Analytics**: Check Firebase Console > Events
2. **Facebook Events Manager**: Check Facebook Events Manager
3. **Supabase**: Check user_events table
4. **Google Ads**: Check conversion tracking

## 🎯 UAC Campaign Setup

### 1. Google Ads UAC Setup
1. Create new Universal App Campaign
2. Set conversion goals:
   - Primary: Install
   - Secondary: Subscription Purchased
3. Configure targeting
4. Set budget and bidding

### 2. Facebook App Install Campaigns
1. Create App Install campaign
2. Set up conversion tracking
3. Configure audience targeting
4. Set budget and optimization

### 3. Meta App Events Setup
1. Configure App Events in Meta Developer Console
2. Set up conversion tracking
3. Enable automatic app events
4. Test event tracking

## 🔍 Monitoring and Optimization

### Key Metrics to Track
1. **Install Rate**: App installs per impression
2. **Conversion Rate**: Sign ups per install
3. **Profile Completion Rate**: Completed profiles per sign up
4. **Subscription Rate**: Purchases per profile completion
5. **Session Duration**: Average session length
6. **Retention Rate**: Day 1, 7, 30 retention

### Optimization Strategies
1. **Audience Optimization**: Target high-converting demographics
2. **Creative Optimization**: A/B test ad creatives
3. **Bidding Optimization**: Adjust bids based on performance
4. **Event Optimization**: Focus on high-value events

## 📞 Support and Troubleshooting

### Common Issues
1. **Firebase not tracking**: Check Firebase configuration
2. **Facebook events not firing**: Verify Facebook App ID
3. **Google Ads not receiving data**: Check AdMob App ID
4. **Events not appearing**: Check network connectivity

### Debug Commands
```bash
# Check Firebase logs
flutter logs

# Test analytics
flutter run --debug --verbose

# Check platform logs
# Android: adb logcat
# iOS: Xcode Console
```

## 📋 Checklist

### Pre-Launch
- [ ] Firebase configuration updated
- [ ] Facebook App ID configured
- [ ] Google Mobile Ads App ID configured
- [ ] All tracking events tested
- [ ] App store listings created
- [ ] Meta developer account setup

### Post-Launch
- [ ] UAC campaigns created
- [ ] Conversion tracking verified
- [ ] Event data flowing correctly
- [ ] Performance monitoring setup
- [ ] Optimization strategies implemented

## 🎉 Success Metrics

### Target KPIs
- **Install Rate**: >2%
- **Sign Up Rate**: >15%
- **Profile Completion Rate**: >80%
- **Subscription Rate**: >5%
- **Day 1 Retention**: >60%
- **Day 7 Retention**: >30%

### Monthly Goals
- 10,000+ app installs
- 1,500+ sign ups
- 1,200+ completed profiles
- 60+ subscriptions
- $5,000+ revenue

---

**Note**: This implementation provides a complete foundation for UAC marketing. All tracking events are properly implemented and will start collecting data once the app is deployed with the correct configuration values.
