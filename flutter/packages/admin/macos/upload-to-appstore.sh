#!/bin/bash
# Upload script for uploading the archive to App Store Connect

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PROJECT_DIR="/Users/hans/growerp/flutter/packages/admin"
ARCHIVE_PATH="$PROJECT_DIR/build/Runner.xcarchive"
EXPORT_PATH="$PROJECT_DIR/build/export"
EXPORT_OPTIONS="$PROJECT_DIR/macos/ExportOptions.plist"

echo -e "${BLUE}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Upload to App Store Connect                      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if archive exists
if [ ! -d "$ARCHIVE_PATH" ]; then
    echo -e "${RED}✗ Archive not found!${NC}"
    echo "Please run './build-for-appstore.sh' first"
    exit 1
fi

# Export archive
echo -e "${YELLOW}[1/2]${NC} Exporting archive for App Store..."
rm -rf "$EXPORT_PATH"
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_PATH" \
  -exportOptionsPlist "$EXPORT_OPTIONS" \
  -allowProvisioningUpdates

if [ ! -d "$EXPORT_PATH" ]; then
    echo -e "${RED}✗ Export failed!${NC}"
    exit 1
fi

echo -e "${GREEN}✓${NC} Export complete"
echo ""

# Upload
echo -e "${YELLOW}[2/2]${NC} Uploading to App Store Connect..."
echo ""
echo -e "${BLUE}Upload Method:${NC}"
echo "  1. Use Transporter app (recommended)"
echo "  2. Use altool command line"
echo "  3. Use Xcode Organizer"
echo ""

read -p "Select upload method (1-3): " -n 1 -r
echo ""

case $REPLY in
    1)
        echo ""
        echo -e "${YELLOW}Opening Transporter app...${NC}"
        echo ""
        echo "In Transporter:"
        echo "  1. Click '+' or drag and drop"
        echo "  2. Select: $EXPORT_PATH/admin.pkg"
        echo "  3. Click 'Deliver'"
        echo ""
        open -a Transporter "$EXPORT_PATH"
        ;;
    2)
        echo ""
        echo -e "${YELLOW}Using altool...${NC}"
        echo ""
        read -p "Enter your Apple ID email: " APPLE_ID
        echo ""
        echo "Enter your app-specific password (or keychain item name):"
        echo "To create an app-specific password, visit:"
        echo "https://appleid.apple.com/account/manage"
        echo ""
        read -s -p "Password: " APP_PASSWORD
        echo ""
        echo ""
        
        PKG_PATH=$(find "$EXPORT_PATH" -name "*.pkg" -type f | head -1)
        
        if [ -z "$PKG_PATH" ]; then
            echo -e "${RED}✗ No .pkg file found in export path${NC}"
            exit 1
        fi
        
        echo "Uploading $PKG_PATH..."
        xcrun altool --upload-app \
          --type macos \
          --file "$PKG_PATH" \
          --username "$APPLE_ID" \
          --password "$APP_PASSWORD" \
          --verbose
        
        if [ $? -eq 0 ]; then
            echo ""
            echo -e "${GREEN}✓ Upload successful!${NC}"
        else
            echo ""
            echo -e "${RED}✗ Upload failed${NC}"
            exit 1
        fi
        ;;
    3)
        echo ""
        echo -e "${YELLOW}Opening Xcode Organizer...${NC}"
        echo ""
        open "$PROJECT_DIR/macos/Runner.xcworkspace"
        sleep 2
        osascript -e 'tell application "Xcode" to activate'
        osascript -e 'tell application "System Events" to keystroke "9" using {command down, shift down}' 2>/dev/null || true
        echo ""
        echo "In Xcode Organizer:"
        echo "  1. Select the latest archive"
        echo "  2. Click 'Distribute App'"
        echo "  3. Choose 'App Store Connect'"
        echo "  4. Follow the wizard"
        ;;
    *)
        echo ""
        echo -e "${RED}Invalid selection${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                    Complete!                       ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo "  1. Wait for processing (15-30 minutes)"
echo "  2. Check App Store Connect → TestFlight"
echo "  3. Test the build"
echo "  4. Submit for review when ready"
echo ""
echo "Monitor status at:"
echo "  https://appstoreconnect.apple.com"
echo ""
