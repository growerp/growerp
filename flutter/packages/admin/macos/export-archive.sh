#!/bin/bash
# Export and validate archive for App Store

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

PROJECT_DIR="/Users/hans/growerp/flutter/packages/admin"
ARCHIVE_PATH="$PROJECT_DIR/build/Runner.xcarchive"
EXPORT_PATH="$PROJECT_DIR/build/export"

if [ ! -d "$ARCHIVE_PATH" ]; then
    echo -e "${RED}No archive found. Run ./macos/archive-with-fixes.sh first${NC}"
    exit 1
fi

echo -e "${BLUE}Exporting archive for App Store...${NC}"
echo ""

rm -rf "$EXPORT_PATH"

xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_PATH" \
  -exportOptionsPlist "$PROJECT_DIR/macos/ExportOptions.plist" \
  -allowProvisioningUpdates \
  | grep -E "^\*\*|Export" || true

echo ""

if [ -d "$EXPORT_PATH" ]; then
    echo -e "${GREEN}✅ Export successful!${NC}"
    echo ""
    echo "Package location:"
    find "$EXPORT_PATH" -name "*.pkg" -o -name "*.app"
    echo ""
    
    echo -e "${BLUE}Upload options:${NC}"
    echo ""
    echo "1. Use Transporter app:"
    echo "   open -a Transporter \"$EXPORT_PATH\""
    echo ""
    echo "2. Use altool:"
    echo "   xcrun altool --upload-app --type macos \\"
    echo "     --file \"$EXPORT_PATH/admin.pkg\" \\"
    echo "     --username YOUR_APPLE_ID \\"
    echo "     --password @keychain:AC_PASSWORD"
    echo ""
    
    read -p "Open in Transporter now? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        open -a Transporter "$EXPORT_PATH"
    fi
else
    echo -e "${RED}❌ Export failed${NC}"
    exit 1
fi
