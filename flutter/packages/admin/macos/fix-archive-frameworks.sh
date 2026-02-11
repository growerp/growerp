#!/bin/bash
# Fix framework symlinks in existing archive

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}Fixing framework symlinks in archive...${NC}"
echo ""

PROJECT_DIR="/Users/hans/growerp/flutter/packages/admin"
ARCHIVE_PATH="$PROJECT_DIR/build/Runner.xcarchive"

if [ ! -d "$ARCHIVE_PATH" ]; then
    echo -e "${RED}❌ No archive found at $ARCHIVE_PATH${NC}"
    exit 1
fi

FRAMEWORKS_DIR="$ARCHIVE_PATH/Products/Applications/admin.app/Contents/Frameworks"

if [ ! -d "$FRAMEWORKS_DIR" ]; then
    echo -e "${RED}❌ Frameworks directory not found${NC}"
    exit 1
fi

echo "Archive: $ARCHIVE_PATH"
echo "Frameworks: $FRAMEWORKS_DIR"
echo ""

FIXED=0
ALREADY_OK=0

for fw in "$FRAMEWORKS_DIR"/*.framework; do
    if [ ! -d "$fw" ]; then
        continue
    fi
    
    name=$(basename "$fw" .framework)
    
    # Check and fix Resources symlink
    if [ -L "$fw/Resources" ]; then
        target=$(readlink "$fw/Resources")
        if [[ "$target" != "Versions/Current/Resources" ]]; then
            echo -e "${YELLOW}Fixing: $name.framework${NC}"
            echo "  Old: Resources -> $target"
            ( cd "$fw" && rm -f Resources && ln -s Versions/Current/Resources Resources )
            echo "  New: Resources -> Versions/Current/Resources"
            FIXED=$((FIXED + 1))
        else
            echo -e "${GREEN}✓ $name.framework${NC}"
            ALREADY_OK=$((ALREADY_OK + 1))
        fi
    elif [ -d "$fw/Resources" ]; then
        echo -e "${RED}⚠️  $name.framework - Resources is a directory, not symlink!${NC}"
        echo "  Converting to proper structure..."
        
        # Create Versions/A if needed
        mkdir -p "$fw/Versions/A"
        
        # Move Resources directory
        if [ -d "$fw/Resources" ]; then
            mv "$fw/Resources" "$fw/Versions/A/"
        fi
        
        # Move binary if exists
        if [ -f "$fw/$name" ] && [ ! -L "$fw/$name" ]; then
            mv "$fw/$name" "$fw/Versions/A/"
        fi
        
        # Create Current symlink
        ( cd "$fw/Versions" && rm -f Current && ln -s A Current )
        
        # Create proper symlinks
        ( cd "$fw" && ln -s Versions/Current/Resources Resources )
        ( cd "$fw" && ln -s "Versions/Current/$name" "$name" )
        
        echo "  ✓ Fixed"
        FIXED=$((FIXED + 1))
    fi
    
    # Check and fix binary symlink
    if [ -L "$fw/$name" ]; then
        target=$(readlink "$fw/$name")
        if [[ "$target" != "Versions/Current/$name" ]]; then
            echo "  Fixing binary symlink..."
            ( cd "$fw" && rm -f "$name" && ln -s "Versions/Current/$name" "$name" )
        fi
    fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}Summary:${NC}"
echo "  ✓ Already correct: $ALREADY_OK frameworks"
echo "  🔧 Fixed: $FIXED frameworks"
echo ""

if [ $FIXED -gt 0 ]; then
    echo -e "${GREEN}✅ Archive has been fixed and is ready for upload!${NC}"
else
    echo -e "${GREEN}✅ All frameworks were already correct!${NC}"
fi

echo ""
echo "Now upload via Xcode Organizer:"
echo "  ./macos/upload-via-organizer.sh"
echo ""
