# 🚀 Build and Deploy Guide - LoveBug App

## Current Status ✅

- ✅ Android build configuration is ready
- ✅ Java version warnings have been suppressed
- ✅ NDK is installed and working
- ✅ Package name: `com.lovebug.lovebug`
- ✅ Version: `1.0.0+3`

## Next Steps

### Step 1: Build Debug APK (For Testing)

Test your app on a device first:

```bash
flutter build apk --debug
```

The APK will be at: `build/app/outputs/flutter-apk/app-debug.apk`

Install it on your device:
```bash
# Connect your Android device via USB
# Enable USB debugging
adb install build/app/outputs/flutter-apk/app-debug.apk
```

### Step 2: Set Up App Signing (Required for Play Store)

**Create a Keystore:**

```bash
cd android
mkdir -p keystore
keytool -genkey -v -keystore keystore/lovebug-release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias lovebug
```

**Important:** Save the passwords you enter! You'll need them for all future updates.

**Create key.properties:**

```bash
cat > android/key.properties << EOF
storeFile=../keystore/lovebug-release-key.jks
storePassword=YOUR_KEYSTORE_PASSWORD
keyAlias=lovebug
keyPassword=YOUR_KEY_PASSWORD
EOF
```

**Update build.gradle.kts to use signing:**

The signing configuration is already in place, it just needs the `key.properties` file.

### Step 3: Build Release APK (For Direct Distribution)

```bash
flutter build apk --release
```

APK location: `build/app/outputs/flutter-apk/app-release.apk`

### Step 4: Build App Bundle (AAB) - For Play Store ⭐

**This is the recommended format for Google Play Store:**

```bash
flutter build appbundle --release
```

AAB location: `build/app/outputs/bundle/release/app-release.aab`

### Step 5: Prepare for Play Store

Before uploading, make sure you have:

1. **App Icon** - 512x512px PNG (no transparency)
2. **Feature Graphic** - 1024x500px PNG  
3. **Screenshots** - At least 2 screenshots (up to 8)
   - Phone: 16:9 or 9:16 ratio
   - Minimum 320px, maximum 3840px
4. **App Description** - Up to 4000 characters
5. **Short Description** - Up to 80 characters
6. **Privacy Policy URL** - Required for apps that collect user data

### Step 6: Upload to Google Play Console

1. Go to [Google Play Console](https://play.google.com/console)
2. Create a new app (or select existing)
3. Complete the store listing:
   - App name: **LoveBug**
   - Short description
   - Full description
   - Graphics (icon, screenshots, feature graphic)
   - Categorization
   - Contact details
   - Privacy policy URL

4. Go to **Production** → **Create new release**
5. Upload your AAB file: `build/app/outputs/bundle/release/app-release.aab`
6. Fill in **Release notes**
7. Review and **Start rollout to production**

### Step 7: Complete Required Sections

Make sure to complete:
- ✅ Store listing (all required fields)
- ✅ Content rating questionnaire
- ✅ Privacy policy
- ✅ Data safety section
- ✅ App access (if applicable)
- ✅ Pricing & distribution

### Step 8: Submit for Review

1. Review all sections for completeness
2. Click **Submit for review**
3. Wait for Google's review (usually 1-3 days)
4. You'll receive email notifications about the status

## Quick Build Commands

```bash
# Debug build (for testing)
flutter build apk --debug

# Release APK (for direct distribution)
flutter build apk --release

# Release App Bundle (for Play Store) ⭐
flutter build appbundle --release

# Clean and rebuild
flutter clean && flutter pub get && flutter build appbundle --release
```

## Troubleshooting

### If build fails:
```bash
# Clean everything
flutter clean
rm -rf android/.gradle android/app/.gradle
cd android && ./gradlew clean && cd ..

# Rebuild
flutter pub get
flutter build appbundle --release
```

### If signing fails:
- Make sure `android/key.properties` exists
- Verify keystore file path is correct
- Check passwords are correct

## Security Reminders

⚠️ **IMPORTANT:**
- Never commit `key.properties` or keystore files to git
- Keep backups of your keystore in secure locations
- Use strong passwords
- Enable Play App Signing in Play Console (recommended)

## Updating Your App

For future updates:

1. Update version in `pubspec.yaml`:
   ```yaml
   version: 1.0.1+4  # Increment both numbers
   ```

2. Build new release:
   ```bash
   flutter build appbundle --release
   ```

3. Upload new AAB to Play Console
4. Add release notes
5. Submit for review

---

**You're all set!** 🎉 Build your app and deploy to the Play Store!

