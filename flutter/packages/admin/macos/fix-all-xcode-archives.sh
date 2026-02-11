#!/bin/bash
# Fix all frameworks in all Xcode archives

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Fixing all frameworks in Xcode Archives...${NC}"
echo ""

ARCHIVES_DIR="$HOME/Library/Developer/Xcode/Archives"
FIXED_COUNT=0

# Process all archives from today
for archive in "$ARCHIVES_DIR"/2026-02-11/*.xcarchive; do
    if [ ! -d "$archive" ]; then
        continue
    fi
    
    archive_name=$(basename "$archive")
    echo "Archive: $archive_name"
    
    frameworks_dir="$archive/Products/Applications/admin.app/Contents/Frameworks"
    
    if [ ! -d "$frameworks_dir" ]; then
        echo "  (no frameworks)"
        continue
    fi
    
    # Fix each framework
    for fw in "$frameworks_dir"/*.framework; do
        if [ ! -d "$fw" ]; then
            continue
        fi
        
        name=$(basename "$fw" .framework)
        
        # Check Resources symlink
        if [ -L "$fw/Resources" ]; then
            target=$(readlink "$fw/Resources")
            if [[ "$target" != "Versions/Current/Resources" ]]; then
                ( cd "$fw" && rm -f Resources && ln -s Versions/Current/Resources Resources )
                echo "  ✓ Fixed: $name.framework"
                FIXED_COUNT=$((FIXED_COUNT + 1))
            fi
        fi
        
        # Check binary symlink
        if [ -L "$fw/$name" ]; then
            target=$(readlink "$fw/$name")
            if [[ "$target" != "Versions/Current/$name" ]]; then
                ( cd "$fw" && rm -f "$name" && ln -s "Versions/Current/$name" "$name" )
            fi
        fi
    done
done

echo ""
echo -e "${GREEN}✅ Fixed $FIXED_COUNT framework symlinks${NC}"
echo ""
echo "Now upload via Xcode Organizer"
