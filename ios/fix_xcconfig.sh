#!/bin/bash

# Fix Xcode configuration paths
# This script ensures the Generated.xcconfig file is properly referenced

cd "$(dirname "$0")"

echo "🔧 Fixing Xcode configuration..."

# Ensure Generated.xcconfig exists
if [ ! -f "Flutter/Generated.xcconfig" ]; then
    echo "❌ Generated.xcconfig not found. Running flutter pub get..."
    cd ..
    flutter pub get
    cd ios
fi

# Verify the file exists
if [ -f "Flutter/Generated.xcconfig" ]; then
    echo "✅ Generated.xcconfig found"
else
    echo "❌ Failed to generate Generated.xcconfig"
    exit 1
fi

# Clean Xcode build folder
echo "🧹 Cleaning Xcode build folder..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# Reinstall pods
echo "📦 Reinstalling CocoaPods..."
export LANG=en_US.UTF-8
pod install

echo "✅ Configuration fix complete!"
echo "📝 Next steps:"
echo "   1. Open Runner.xcworkspace (not Runner.xcodeproj)"
echo "   2. Clean Build Folder (Cmd+Shift+K)"
echo "   3. Build the project (Cmd+B)"

