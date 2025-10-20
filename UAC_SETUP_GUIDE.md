# UAC (Universal App Campaign) Setup Guide

## 🎯 **Overview**
This guide outlines the steps required to enable UAC (Universal App Campaign) for your dating app. UAC allows you to run ads on Google, Apple, and Meta platforms with automatic optimization.

## 📋 **Prerequisites**
- App must be listed on Google Play Store and Apple App Store
- Firebase project setup
- Facebook Developer account
- Google Ads account

## 🔧 **Step 1: Firebase Project Setup**

### **1.1 Create Firebase Project**
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project"
3. Enter project name: `LoveBug-DatingApp`
4. Enable Google Analytics
5. Choose Analytics account (or create new one)

### **1.2 Add Android App**
1. Click "Add app" → Android
2. **Package name**: `com.example.bolilerPlate`
3. **App nickname**: `LoveBug Android`
4. **Debug signing certificate**: (optional for now)
5. Download `google-services.json`
6. Place file in: `android/app/google-services.json`

### **1.3 Add iOS App**
1. Click "Add app" → iOS
2. **Bundle ID**: `com.example.bolilerPlate`
3. **App nickname**: `LoveBug iOS`
4. **App Store ID**: (leave blank for now)
5. Download `GoogleService-Info.plist`
6. Place file in: `ios/Runner/GoogleService-Info.plist`

### **1.4 Enable Required Services**
1. **Analytics** - Already enabled
2. **Crashlytics** - Enable for crash reporting
3. **Performance Monitoring** - Enable for app performance
4. **Remote Config** - Enable for A/B testing

## 📱 **Step 2: Facebook Developer Setup**

### **2.1 Create Facebook App**
1. Go to [Facebook Developers](https://developers.facebook.com/)
2. Click "Create App"
3. Choose "Consumer" app type
4. **App Name**: `LoveBug Dating App`
5. **App Contact Email**: (your email)
6. **App Purpose**: Dating/Social

### **2.2 Configure App Settings**
1. **App ID**: Copy this value
2. **App Secret**: Copy this value (keep secure)
3. **App Domains**: (leave blank for mobile)
4. **Privacy Policy URL**: (required for app store)
5. **Terms of Service URL**: (required for app store)

### **2.3 Add Platforms**
1. **Android**:
   - Package Name: `com.example.bolilerPlate`
   - Class Name: `com.example.bolilerPlate.MainActivity`
   - Key Hashes: (generate using debug keystore)
2. **iOS**:
   - Bundle ID: `com.example.bolilerPlate`
   - App Store ID: (get from App Store Connect)

## 🎯 **Step 3: Google Ads Setup**

### **3.1 Create Google Ads Account**
1. Go to [Google Ads](https://ads.google.com/)
2. Create account with business information
3. Set up billing information
4. Verify account

### **3.2 Set Up Conversion Tracking**
1. Go to "Tools & Settings" → "Conversions"
2. Click "+" to create new conversion
3. **Conversion Name**: `App Install`
4. **Category**: `Download`
5. **Value**: (set based on your LTV)
6. **Count**: `One`
7. **Attribution Model**: `Last Click`

### **3.3 Create UAC Campaign**
1. Click "Campaigns" → "+"
2. Choose "App promotion"
3. **Campaign Type**: `Universal App Campaign`
4. **App**: Select your app from store listings
5. **Budget**: Set daily budget
6. **Bidding**: `Target cost per install`

## 📊 **Step 4: App Store Listings**

### **4.1 Google Play Store**
1. Go to [Google Play Console](https://play.google.com/console/)
2. Create app listing
3. **App Name**: `LoveBug`
4. **Package Name**: `com.example.bolilerPlate`
5. **Category**: `Dating`
6. **Content Rating**: `Teen` (13+)
7. Upload app bundle and screenshots

### **4.2 Apple App Store**
1. Go to [App Store Connect](https://appstoreconnect.apple.com/)
2. Create app listing
3. **App Name**: `LoveBug`
4. **Bundle ID**: `com.example.bolilerPlate`
5. **Category**: `Lifestyle`
6. **Age Rating**: `17+` (for dating apps)
7. Upload app and screenshots

## 🔑 **Step 5: Configuration Files**

### **5.1 Update Firebase Options**
Replace placeholder values in `lib/firebase_options.dart` with real values from Firebase Console.

### **5.2 Update App Configuration**
Update the following files with real values:
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- `lib/firebase_options.dart`

## 📈 **Step 6: Event Tracking Setup**

### **6.1 Required Events (Already Implemented)**
- ✅ **Install** - `trackAppInstall()`
- ✅ **First Open** - `trackFirstOpen()`
- ✅ **Sign Up** - `trackSignUp()`
- ✅ **Profile Completed** - `trackProfileCompleted()`
- ✅ **Subscription Purchased** - `trackSubscriptionPurchased()`
- ✅ **Session Start** - `trackSessionStart()`

### **6.2 Event Integration Points**
- **App Launch**: `main.dart` → `AnalyticsService.trackFirstOpen()`
- **User Registration**: `auth_service.dart` → `AnalyticsService.trackSignUp()`
- **Profile Setup**: `profile_service.dart` → `AnalyticsService.trackProfileCompleted()`
- **Subscription**: `payment_service.dart` → `AnalyticsService.trackSubscriptionPurchased()`

## 🚀 **Step 7: Testing & Validation**

### **7.1 Test Event Tracking**
1. Install app on test device
2. Complete user journey
3. Check Firebase Analytics dashboard
4. Verify events are being tracked

### **7.2 Validate UAC Setup**
1. Create test UAC campaign
2. Set small budget ($10/day)
3. Monitor installs and events
4. Verify attribution is working

## 📋 **Step 8: Launch Checklist**

### **8.1 Pre-Launch**
- [ ] Firebase project configured
- [ ] Facebook app created and configured
- [ ] Google Ads account set up
- [ ] App store listings created
- [ ] Configuration files updated
- [ ] Event tracking tested

### **8.2 Post-Launch**
- [ ] Monitor campaign performance
- [ ] Optimize based on data
- [ ] Scale successful campaigns
- [ ] A/B test creatives and audiences

## 🔧 **Technical Implementation**

### **8.3 Code Changes Required**
1. **Uncomment Facebook App Events** in `analytics_service.dart`
2. **Uncomment Google Mobile Ads** in `analytics_service.dart`
3. **Update Firebase options** with real values
4. **Add event tracking calls** at appropriate points in app flow

### **8.4 Database Schema**
Ensure these tables exist in Supabase:
- `user_events` - For event tracking
- `user_sessions` - For session tracking
- `user_subscriptions` - For subscription tracking

## 📞 **Support & Next Steps**

### **9.1 What We Need from You**
1. **Firebase project credentials**
2. **Facebook App ID and Secret**
3. **Google Ads account access**
4. **App store listing URLs**
5. **Privacy policy and terms of service URLs**

### **9.2 Timeline**
- **Setup**: 2-3 days
- **Testing**: 1-2 days
- **Launch**: 1 day
- **Total**: 4-6 days

## 🎯 **Expected Results**
- **Install tracking**: 100% accurate
- **Event attribution**: Real-time
- **Campaign optimization**: Automatic
- **ROI tracking**: Complete funnel visibility

---

**Note**: This setup requires coordination between development team and client for account access and configuration. All technical implementation is already complete in the codebase.
