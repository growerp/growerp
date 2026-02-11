#!/bin/bash
# Complete archive with framework fixes

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Archive macOS App (with framework fixes)        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════╝${NC}"
echo ""

PROJECT_DIR="/Users/hans/growerp/flutter/packages/admin"
cd "$PROJECT_DIR"

# Clean and build
echo -e "${YELLOW}Building...${NC}"
flutter clean
flutter pub get
cd macos && pod install && cd ..
flutter build macos --release
echo ""

# Fix frameworks in build
echo -e "${YELLOW}Fixing frameworks...${NC}"
FRAMEWORKS_DIR="build/macos/Build/Products/Release/admin.app/Contents/Frameworks"

fix_framework() {
    local fw="$1"
    local name=$(basename "$fw" .framework)
    
    # Only fix if Resources is not already a symlink
    if [ ! -L "$fw/Resources" ]; then
        echo "  → $name.framework"
        
        # Create proper bundle structure
        mkdir -p "$fw/Versions/A"
        
        # Move existing files
        for item in "$fw"/*; do
            base=$(basename "$item")
            if [ "$base" != "Versions" ] && [ ! -L "$item" ]; then
                mv "$item" "$fw/Versions/A/" 2>/dev/null || true
            fi
        done
        
        # Create Current symlink
        ( cd "$fw/Versions" && rm -f Current && ln -s A Current )
        
        # Create top-level symlinks (MUST use Versions/Current/*, not Versions/A/*)
        ( cd "$fw" && rm -f Resources && ln -s Versions/Current/Resources Resources )
        ( cd "$fw" && rm -f "$name" && ln -s "Versions/Current/$name" "$name" )
    fi
}

if [ -d "$FRAMEWORKS_DIR" ]; then
    find "$FRAMEWORKS_DIR" -name "*.framework" -maxdepth 1 -type d | while read fw; do
        fix_framework "$fw"
    done
fi
echo ""

# Archive
echo -e "${YELLOW}Creating archive...${NC}"
ARCHIVE_PATH="$PROJECT_DIR/build/Runner.xcarchive"
rm -rf "$ARCHIVE_PATH"

cd macos
xcodebuild archive \
  -workspace Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -archivePath "$ARCHIVE_PATH" \
  -allowProvisioningUpdates \
  DEVELOPMENT_TEAM="P64T65C668" \
  CODE_SIGN_IDENTITY="Apple Distribution" \
  | grep -E "^\*\*|Archive" || true

cd ..
echo ""

# Fix frameworks in archive
echo -e "${YELLOW}Fixing frameworks in archive...${NC}"
ARCHIVE_FRAMEWORKS="$ARCHIVE_PATH/Products/Applications/admin.app/Contents/Frameworks"

if [ -d "$ARCHIVE_FRAMEWORKS" ]; then
    find "$ARCHIVE_FRAMEWORKS" -name "*.framework" -maxdepth 1 -type d | while read fw; do
        fix_framework "$fw"
    done
fi
echo ""

# Verify structure
echo -e "${YELLOW}Verifying framework structures...${NC}"
ERRORS=0

if [ -d "$ARCHIVE_FRAMEWORKS" ]; then
    find "$ARCHIVE_FRAMEWORKS" -name "*.framework" -maxdepth 1 -type d | while read fw; do
        name=$(basename "$fw" .framework)
        
        # Check for Resources symlink
        if [ -d "$fw/Resources" ] && [ ! -L "$fw/Resources" ]; then
            echo -e "  ❌ $name.framework: Resources is not a symlink"
            ERRORS=$((ERRORS + 1))
        else
            echo -e "  ✓ $name.framework"
        fi
    done
fi

if [ $ERRORS -gt 0 ]; then
    echo ""
    echo -e "${RED}⚠️  Some frameworks still have issues${NC}"
fi

echo ""
echo -e "${GREEN}✅ Archive created!${NC}"
echo ""
echo "Location: $ARCHIVE_PATH"
echo ""
echo -e "${BLUE}To upload:${NC}"
echo "  1. Open Xcode Organizer:"
echo "     open macos/Runner.xcworkspace"
echo "     Window → Organizer"
echo ""
echo "  2. Select the archive and click 'Distribute App'"
echo ""
echo -e "${YELLOW}OR export now:${NC}"
./macos/export-archive.sh
