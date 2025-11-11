# 🚀 Quick Start Guide - Build & Deploy LoveBug

## ✅ Current Status
- Build configuration: ✅ Ready
- Java warnings: ✅ Fixed
- Package name: `com.lovebug.lovebug`
- Version: `1.0.0+3`

## 📱 Step-by-Step: Build for Play Store

### Step 1: Test Build (Optional but Recommended)
```bash
flutter build apk --debug
```
Install on device to test: `adb install build/app/outputs/flutter-apk/app-debug.apk`

### Step 2: Create Keystore (One-Time Setup)
```bash
cd android
mkdir -p keystore
keytool -genkey -v -keystore keystore/lovebug-release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias lovebug
```
**Save the passwords!** You'll need them forever.

### Step 3: Create key.properties
```bash
# Edit this file with your actual passwords
cat > android/key.properties << 'EOF'
storeFile=../keystore/lovebug-release-key.jks
storePassword=YOUR_KEYSTORE_PASSWORD_HERE
keyAlias=lovebug
keyPassword=YOUR_KEY_PASSWORD_HERE
EOF
```

### Step 4: Build Release App Bundle (AAB)
```bash
flutter build appbundle --release
```
Output: `build/app/outputs/bundle/release/app-release.aab`

### Step 5: Upload to Play Store
1. Go to https://play.google.com/console
2. Create app or select existing
3. Production → Create new release
4. Upload `app-release.aab`
5. Add release notes
6. Submit for review

## 🎯 That's It!

Your app is ready for the Play Store! 🎉

For detailed instructions, see `BUILD_AND_DEPLOY.md`

