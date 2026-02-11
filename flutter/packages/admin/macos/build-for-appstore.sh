#!/bin/bash
# GrowERP Admin - macOS App Store Build & Archive Script
# This script builds, archives, and prepares the app for App Store upload

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_DIR="/Users/hans/growerp/flutter/packages/admin"
WORKSPACE="macos/Runner.xcworkspace"
SCHEME="Runner"
CONFIGURATION="Release"
ARCHIVE_PATH="build/Runner.xcarchive"
EXPORT_PATH="build/export"
TEAM_ID="P64T65C668"
BUNDLE_ID="org.growerp.admin"

echo -e "${BLUE}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   GrowERP Admin - macOS App Store Build Script    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════╝${NC}"
echo ""

# Change to project directory
cd "$PROJECT_DIR"

# Step 1: Clean
echo -e "${YELLOW}[1/6]${NC} Cleaning previous builds..."
flutter clean
rm -rf "$ARCHIVE_PATH" "$EXPORT_PATH"
echo -e "${GREEN}✓${NC} Clean complete"
echo ""

# Step 2: Get dependencies
echo -e "${YELLOW}[2/6]${NC} Getting Flutter dependencies..."
flutter pub get
echo -e "${GREEN}✓${NC} Dependencies resolved"
echo ""

# Step 3: Build Flutter release
echo -e "${YELLOW}[3/6]${NC} Building Flutter macOS release..."
flutter build macos --release
echo -e "${GREEN}✓${NC} Flutter build complete"
echo ""

# Step 4: Pod install (ensure CocoaPods dependencies are up to date)
echo -e "${YELLOW}[4/6]${NC} Updating CocoaPods dependencies..."
cd macos
pod install --repo-update
cd ..
echo -e "${GREEN}✓${NC} CocoaPods updated"
echo ""

# Step 5: Archive
echo -e "${YELLOW}[5/6]${NC} Creating Xcode archive..."
echo "This may take several minutes..."
xcodebuild archive \
  -workspace "$WORKSPACE" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -archivePath "$ARCHIVE_PATH" \
  -allowProvisioningUpdates \
  DEVELOPMENT_TEAM="$TEAM_ID" \
  CODE_SIGN_IDENTITY="Apple Distribution" \
  | grep -E "^\*\*|error:|warning:|note:|Archive succeeded" || true

if [ ! -d "$ARCHIVE_PATH" ]; then
    echo -e "${RED}✗${NC} Archive failed!"
    exit 1
fi

echo -e "${GREEN}✓${NC} Archive created successfully"
echo ""

# Step 6: Verify dSYM
echo -e "${YELLOW}[6/6]${NC} Verifying dSYM files..."
DSYM_PATH="$ARCHIVE_PATH/dSYMs/admin.app.dSYM"
if [ -d "$DSYM_PATH" ]; then
    echo -e "${GREEN}✓${NC} dSYM found at: $DSYM_PATH"
    echo ""
    echo -e "${BLUE}UUIDs in dSYM:${NC}"
    dwarfdump --uuid "$DSYM_PATH" 2>/dev/null || echo "  (dwarfdump not available)"
else
    echo -e "${RED}✗${NC} Warning: dSYM not found!"
fi
echo ""

# Summary
echo -e "${GREEN}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              Build Complete Successfully!          ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Archive Location:${NC}"
echo "  $PROJECT_DIR/$ARCHIVE_PATH"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo "  1. Open Xcode Organizer:"
echo "     ${YELLOW}open macos/Runner.xcworkspace${NC}"
echo "     Then: Window → Organizer → Archives"
echo ""
echo "  2. Select the latest archive"
echo ""
echo "  3. Click 'Distribute App' → 'App Store Connect'"
echo ""
echo "  4. Follow the upload wizard"
echo ""
echo -e "${BLUE}Alternative - Upload via command line:${NC}"
echo "  Run: ${YELLOW}./upload-to-appstore.sh${NC}"
echo ""
echo -e "${BLUE}Archive Info:${NC}"
echo "  Bundle ID: $BUNDLE_ID"
echo "  Team ID: $TEAM_ID"
echo "  Configuration: $CONFIGURATION"
echo ""

# Open Organizer
read -p "Open Xcode Organizer now? (y/n) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Opening Xcode..."
    open "$WORKSPACE"
    sleep 2
    osascript -e 'tell application "Xcode" to activate'
    # Attempt to open Organizer (may not work in all Xcode versions)
    osascript -e 'tell application "System Events" to keystroke "9" using {command down, shift down}' 2>/dev/null || true
fi

echo ""
echo -e "${GREEN}Done!${NC}"
