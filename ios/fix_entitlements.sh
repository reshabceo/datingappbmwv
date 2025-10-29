#!/bin/bash

# Script to fix iOS entitlements for push notifications
echo "🔧 Fixing iOS entitlements for push notifications..."

# Check if entitlements file exists
if [ ! -f "Runner/Runner.entitlements" ]; then
    echo "❌ Runner.entitlements file not found!"
    exit 1
fi

# Check if the entitlements file has the correct content
if ! grep -q "aps-environment" "Runner/Runner.entitlements"; then
    echo "❌ aps-environment not found in entitlements file!"
    exit 1
fi

echo "✅ Entitlements file looks good"

# Clean and rebuild
echo "🧹 Cleaning iOS build..."
cd ..
flutter clean
cd ios

echo "📦 Running pod install..."
pod install

echo "🔨 Building iOS app..."
cd ..
flutter build ios --debug

echo "✅ iOS build completed with entitlements fix!"
echo ""
echo "📝 Next steps:"
echo "1. Open ios/Runner.xcworkspace in Xcode"
echo "2. Select the Runner target"
echo "3. Go to Signing & Capabilities"
echo "4. Verify that 'Push Notifications' capability is enabled"
echo "5. Make sure the entitlements file is properly referenced"
echo "6. Build and run the app"
echo ""
echo "🔍 To verify the fix worked, check the logs for:"
echo "- 'APNs token obtained' instead of 'APNs token not available'"
echo "- 'FCM Token obtained' instead of 'FCM Token is empty'"
