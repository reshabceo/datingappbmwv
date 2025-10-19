#!/bin/bash

echo "📱 Installing LoveBug app to your iPhone..."

# Check if device is connected
DEVICE_ID="00008140-001C65993AE3001C"
echo "🔍 Checking if iPhone is connected..."

if xcrun devicectl list devices | grep -q "$DEVICE_ID"; then
    echo "✅ iPhone found: Mr. G63's iPhone"
    
    # Method 1: Try using xcrun devicectl
    echo "📦 Attempting to install app using devicectl..."
    if xcrun devicectl device install app --device "$DEVICE_ID" build/ios/iphoneos/Runner.app; then
        echo "✅ App installed successfully!"
        exit 0
    else
        echo "❌ devicectl installation failed, trying alternative method..."
    fi
    
    # Method 2: Try using ios-deploy (if available)
    if command -v ios-deploy &> /dev/null; then
        echo "📦 Attempting to install using ios-deploy..."
        ios-deploy --bundle build/ios/iphoneos/Runner.app
    else
        echo "💡 ios-deploy not found. Installing it..."
        brew install ios-deploy
        ios-deploy --bundle build/ios/iphoneos/Runner.app
    fi
    
else
    echo "❌ iPhone not found. Please make sure:"
    echo "   1. iPhone is connected via USB"
    echo "   2. iPhone is unlocked"
    echo "   3. You've trusted this computer on your iPhone"
    echo ""
    echo "📋 Available devices:"
    xcrun devicectl list devices
fi

echo ""
echo "🔄 Alternative: Use Xcode directly:"
echo "   1. Open ios/Runner.xcworkspace in Xcode"
echo "   2. Select your iPhone as target device"
echo "   3. Click the Play button (▶️)"
echo ""
echo "📱 Manual installation steps:"
echo "   1. Open Xcode"
echo "   2. Go to Window > Devices and Simulators"
echo "   3. Select your iPhone"
echo "   4. Drag and drop the Runner.app from build/ios/iphoneos/ to the device"
