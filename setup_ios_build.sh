#!/bin/bash

echo "🚀 Setting up iOS build for LoveBug dating app..."

# Navigate to project directory
cd /Users/reshab/Desktop/datingappbmwv

echo "📱 Checking connected devices..."
flutter devices

echo "🔧 Cleaning previous builds..."
flutter clean

echo "📦 Getting dependencies..."
flutter pub get

echo "🍎 Opening Xcode for code signing setup..."
open ios/Runner.xcworkspace

echo ""
echo "📋 MANUAL STEPS REQUIRED:"
echo "1. In Xcode, select 'Runner' project in the left sidebar"
echo "2. Select 'Runner' target"
echo "3. Go to 'Signing & Capabilities' tab"
echo "4. Check 'Automatically manage signing'"
echo "5. Select your Development Team (your Apple ID)"
echo "6. Change Bundle Identifier to something unique (e.g., com.yourname.lovebug)"
echo "7. Save the project (Cmd+S)"
echo ""
echo "8. On your iPhone:"
echo "   - Go to Settings > General > VPN & Device Management"
echo "   - Trust your developer certificate if prompted"
echo ""
echo "9. Once code signing is configured, run:"
echo "   flutter run -d '00008140-001C65993AE3001C'"
echo ""
echo "✅ Xcode is now open for you to configure code signing!"
