#!/bin/bash

# Fix iOS Build Script
# This script fixes common iOS build issues after removing PushKit

echo "🔧 Fixing iOS Build Issues..."
echo ""

# Step 1: Clean Flutter
echo "📦 Step 1: Cleaning Flutter..."
flutter clean

# Step 2: Get Flutter dependencies
echo "📦 Step 2: Getting Flutter dependencies..."
flutter pub get

# Step 3: Clean iOS build folders
echo "🧹 Step 3: Cleaning iOS build folders..."
cd ios
rm -rf Pods
rm -rf Podfile.lock
rm -rf .symlinks
rm -rf Flutter/Flutter.framework
rm -rf Flutter/Flutter.podspec
rm -rf .flutter-plugins
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# Step 4: Reinstall pods
echo "📦 Step 4: Reinstalling CocoaPods..."
pod deintegrate
pod install --repo-update

# Step 5: Update pods
echo "📦 Step 5: Updating pods..."
pod update

cd ..
echo ""
echo "✅ Build fix complete!"
echo ""
echo "📋 Next steps:"
echo "1. Open Xcode"
echo "2. Go to Signing & Capabilities"
echo "3. Under Background Modes, UNCHECK 'Voice over IP'"
echo "4. In Build Phases → Link Binary With Libraries, REMOVE PushKit.framework if still there"
echo "5. Product → Clean Build Folder (Shift+Cmd+K)"
echo "6. Try building again"
