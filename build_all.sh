#!/bin/bash

# Build script for iOS and Android
# Usage: ./build_all.sh

set -e  # Exit on error

echo "🚀 Starting build process for LoveBug Dating App..."
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Get the project directory
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

echo -e "${BLUE}📦 Step 1: Cleaning previous builds...${NC}"
flutter clean
echo -e "${GREEN}✅ Clean complete${NC}"
echo ""

echo -e "${BLUE}📥 Step 2: Getting dependencies...${NC}"
flutter pub get
echo -e "${GREEN}✅ Dependencies updated${NC}"
echo ""

# Ask which platform to build
echo -e "${YELLOW}Which platform would you like to build?${NC}"
echo "1) iOS only"
echo "2) Android only"
echo "3) Both iOS and Android"
read -p "Enter choice (1-3): " choice

case $choice in
  1)
    echo -e "${BLUE}🍎 Building iOS...${NC}"
    flutter build ios --release
    echo -e "${GREEN}✅ iOS build complete!${NC}"
    echo -e "${YELLOW}📝 Next steps:${NC}"
    echo "   1. Open ios/Runner.xcworkspace in Xcode"
    echo "   2. Product → Archive"
    echo "   3. Distribute to App Store Connect"
    ;;
  2)
    echo -e "${BLUE}🤖 Building Android APK...${NC}"
    flutter build apk --release
    echo -e "${GREEN}✅ Android APK build complete!${NC}"
    echo -e "${YELLOW}📦 APK location:${NC} build/app/outputs/flutter-apk/app-release.apk"
    echo ""
    echo -e "${BLUE}🤖 Building Android App Bundle (AAB)...${NC}"
    flutter build appbundle --release
    echo -e "${GREEN}✅ Android AAB build complete!${NC}"
    echo -e "${YELLOW}📦 AAB location:${NC} build/app/outputs/bundle/release/app-release.aab"
    ;;
  3)
    echo -e "${BLUE}🍎 Building iOS...${NC}"
    flutter build ios --release
    echo -e "${GREEN}✅ iOS build complete!${NC}"
    echo ""
    echo -e "${BLUE}🤖 Building Android APK...${NC}"
    flutter build apk --release
    echo -e "${GREEN}✅ Android APK build complete!${NC}"
    echo ""
    echo -e "${BLUE}🤖 Building Android App Bundle (AAB)...${NC}"
    flutter build appbundle --release
    echo -e "${GREEN}✅ Android AAB build complete!${NC}"
    echo ""
    echo -e "${YELLOW}📝 Next steps:${NC}"
    echo "   iOS:"
    echo "   1. Open ios/Runner.xcworkspace in Xcode"
    echo "   2. Product → Archive"
    echo "   3. Distribute to App Store Connect"
    echo ""
    echo "   Android:"
    echo "   - APK: build/app/outputs/flutter-apk/app-release.apk"
    echo "   - AAB: build/app/outputs/bundle/release/app-release.aab"
    ;;
  *)
    echo -e "${RED}❌ Invalid choice${NC}"
    exit 1
    ;;
esac

echo ""
echo -e "${GREEN}🎉 Build process complete!${NC}"


