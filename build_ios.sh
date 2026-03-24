#!/bin/bash

# iOS Build Script for LoveBug Dating App
# This script cleans, builds, and opens the iOS project in Xcode

set -e

echo "🍎 Building iOS app for LoveBug..."
echo ""

# Navigate to project directory
cd "$(dirname "$0")"

# Step 1: Clean Flutter
echo "🧹 Step 1: Cleaning Flutter build..."
flutter clean

# Step 2: Get Flutter dependencies
echo "📦 Step 2: Getting Flutter dependencies..."
flutter pub get

# Step 3: Set encoding for CocoaPods
export LANG=en_US.UTF-8

# Step 4: Install CocoaPods dependencies
echo "📦 Step 3: Installing CocoaPods dependencies..."
cd ios
pod install
cd ..

# Step 5: Build iOS app (optional - can be done in Xcode)
echo "🔨 Step 4: Building iOS app..."
flutter build ios --no-codesign

# Step 6: Open in Xcode
echo "🚀 Step 5: Opening Xcode workspace..."
open ios/Runner.xcworkspace

echo ""
echo "✅ Build complete! Xcode is now open."
echo ""
echo "📋 Next steps in Xcode:"
echo "1. Select 'Runner' project in the left sidebar"
echo "2. Select 'Runner' target"
echo "3. Go to 'Signing & Capabilities' tab"
echo "4. Configure your signing team and bundle identifier"
echo "5. Build and run (Cmd+R) or Archive (Product → Archive)"
echo ""

