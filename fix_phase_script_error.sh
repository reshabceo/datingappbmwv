#!/bin/bash

# Fix PhaseScriptExecution Error for Flutter iOS Build
# This script addresses common causes of PhaseScriptExecution failures

set -e

echo "🔧 Fixing PhaseScriptExecution Error..."
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Navigate to project directory
cd "$(dirname "$0")"

# Step 1: Verify Flutter installation
print_status "Step 1: Verifying Flutter installation..."
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed or not in PATH"
    exit 1
fi

FLUTTER_ROOT=$(flutter doctor -v | grep "Flutter version" | awk '{print $4}' | head -1)
if [ -z "$FLUTTER_ROOT" ]; then
    FLUTTER_ROOT=$(which flutter | xargs dirname | xargs dirname)
fi

if [ ! -f "$FLUTTER_ROOT/packages/flutter_tools/bin/xcode_backend.sh" ]; then
    print_error "Flutter backend script not found at: $FLUTTER_ROOT/packages/flutter_tools/bin/xcode_backend.sh"
    print_status "Running flutter precache..."
    flutter precache --ios
fi

print_success "Flutter found at: $FLUTTER_ROOT"

# Step 2: Clean Flutter
print_status "Step 2: Cleaning Flutter build..."
flutter clean

# Step 3: Get Flutter dependencies
print_status "Step 3: Getting Flutter dependencies..."
flutter pub get

# Step 4: Clean iOS build folders
print_status "Step 4: Cleaning iOS build folders..."
cd ios
rm -rf Pods
rm -rf Podfile.lock
rm -rf .symlinks
rm -rf Flutter/Flutter.framework
rm -rf Flutter/Flutter.podspec
rm -rf .flutter-plugins
rm -rf .flutter-plugins-dependencies
rm -rf build
rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-*

# Step 5: Clean Xcode DerivedData (optional but recommended)
print_status "Step 5: Cleaning Xcode DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData/* 2>/dev/null || true

# Step 6: Reinstall CocoaPods
print_status "Step 6: Reinstalling CocoaPods..."
export LANG=en_US.UTF-8
pod deintegrate 2>/dev/null || true
pod install --repo-update

cd ..

# Step 7: Verify Generated.xcconfig
print_status "Step 7: Verifying Flutter configuration..."
if [ ! -f "ios/Flutter/Generated.xcconfig" ]; then
    print_error "Generated.xcconfig not found. Regenerating..."
    flutter pub get
fi

# Verify FLUTTER_ROOT in Generated.xcconfig
if grep -q "FLUTTER_ROOT" ios/Flutter/Generated.xcconfig; then
    CONFIG_FLUTTER_ROOT=$(grep "FLUTTER_ROOT" ios/Flutter/Generated.xcconfig | cut -d'=' -f2)
    print_success "FLUTTER_ROOT in config: $CONFIG_FLUTTER_ROOT"
else
    print_error "FLUTTER_ROOT not found in Generated.xcconfig"
    exit 1
fi

# Step 8: Verify xcode_backend.sh exists and is executable
print_status "Step 8: Verifying Flutter backend script..."
BACKEND_SCRIPT="$CONFIG_FLUTTER_ROOT/packages/flutter_tools/bin/xcode_backend.sh"
if [ ! -f "$BACKEND_SCRIPT" ]; then
    print_error "xcode_backend.sh not found at: $BACKEND_SCRIPT"
    print_status "Running flutter precache..."
    flutter precache --ios
fi

if [ -f "$BACKEND_SCRIPT" ]; then
    chmod +x "$BACKEND_SCRIPT"
    print_success "Backend script verified and made executable"
else
    print_error "Backend script still not found after precache"
    exit 1
fi

# Step 9: Build iOS app to verify
print_status "Step 9: Building iOS app (no codesign) to verify setup..."
flutter build ios --no-codesign --debug 2>&1 | tail -20

print_success "Fix complete!"
echo ""
print_status "Next steps:"
echo "1. Open Xcode: open ios/Runner.xcworkspace"
echo "2. Product → Clean Build Folder (Shift+Cmd+K)"
echo "3. Close Xcode completely"
echo "4. Reopen Xcode and try building again (Cmd+R)"
echo ""
print_warning "If the error persists:"
echo "- Check Xcode build log for specific error details"
echo "- Ensure you're opening Runner.xcworkspace (not Runner.xcodeproj)"
echo "- Verify your signing team is configured in Signing & Capabilities"

