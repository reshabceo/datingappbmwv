#!/bin/bash

echo "🚀 Building LoveBug for TestFlight Upload..."
echo "=============================================="

# Navigate to project directory
cd /Users/reshab/Desktop/datingappbmwv

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed or not in PATH"
    exit 1
fi

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    print_error "Xcode is not installed or not in PATH"
    exit 1
fi

print_status "Flutter version:"
flutter --version

print_status "Cleaning previous builds..."
flutter clean

print_status "Getting dependencies..."
flutter pub get

print_status "Running flutter pub upgrade..."
flutter pub upgrade

print_status "Checking for any issues..."
flutter doctor

print_status "Building iOS app for release..."
flutter build ios --release --no-codesign

if [ $? -ne 0 ]; then
    print_error "Flutter build failed!"
    exit 1
fi

print_status "Building archive for TestFlight..."
cd ios

# Build archive using xcodebuild
xcodebuild -workspace Runner.xcworkspace \
           -scheme Runner \
           -configuration Release \
           -destination generic/platform=iOS \
           -archivePath build/Runner.xcarchive \
           archive

if [ $? -ne 0 ]; then
    print_error "Xcode archive build failed!"
    exit 1
fi

print_success "Archive created successfully!"

print_status "Exporting IPA for TestFlight..."
xcodebuild -exportArchive \
           -archivePath build/Runner.xcarchive \
           -exportPath build/ \
           -exportOptionsPlist ExportOptions.plist

if [ $? -ne 0 ]; then
    print_error "IPA export failed!"
    print_warning "You may need to create ExportOptions.plist file"
    print_status "Creating ExportOptions.plist..."
    
    cat > ExportOptions.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>55A3C29ND7</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <false/>
</dict>
</plist>
EOF
    
    print_status "Retrying IPA export with created ExportOptions.plist..."
    xcodebuild -exportArchive \
               -archivePath build/Runner.xcarchive \
               -exportPath build/ \
               -exportOptionsPlist ExportOptions.plist
fi

if [ $? -eq 0 ]; then
    print_success "IPA exported successfully!"
    
    # Find the IPA file
    IPA_FILE=$(find build -name "*.ipa" | head -1)
    if [ -n "$IPA_FILE" ]; then
        print_success "IPA file location: $IPA_FILE"
        print_status "File size: $(du -h "$IPA_FILE" | cut -f1)"
        
        print_status "Opening build directory..."
        open build/
        
        echo ""
        echo "🎉 TestFlight Build Complete!"
        echo "=============================="
        echo "📱 IPA file: $IPA_FILE"
        echo ""
        echo "📋 Next Steps:"
        echo "1. Open Xcode"
        echo "2. Go to Window > Organizer"
        echo "3. Select your archive"
        echo "4. Click 'Distribute App'"
        echo "5. Choose 'App Store Connect'"
        echo "6. Follow the upload wizard"
        echo ""
        echo "Or use Application Loader/Transporter app to upload the IPA directly."
        
    else
        print_error "IPA file not found in build directory"
        exit 1
    fi
else
    print_error "IPA export failed!"
    exit 1
fi

print_status "Build process completed!"


