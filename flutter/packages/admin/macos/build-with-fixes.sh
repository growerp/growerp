#!/bin/bash
# Build macOS app with framework fixes for App Store upload

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Build macOS App with Framework Fixes            ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════╝${NC}"
echo ""

# Configuration
PROJECT_DIR="/Users/hans/growerp/flutter/packages/admin"
cd "$PROJECT_DIR"

# Step 1: Clean
echo -e "${YELLOW}[1/5]${NC} Cleaning..."
flutter clean
echo ""

# Step 2: Get dependencies
echo -e "${YELLOW}[2/5]${NC} Getting dependencies..."
flutter pub get
cd macos && pod install && cd ..
echo ""

# Step 3: Build
echo -e "${YELLOW}[3/5]${NC} Building macOS release..."
flutter build macos --release
echo ""

# Step 4: Fix frameworks
echo -e "${YELLOW}[4/5]${NC} Fixing framework structures..."

FRAMEWORKS_DIR="build/macos/Build/Products/Release/admin.app/Contents/Frameworks"

# Function to fix framework structure
fix_framework() {
    local fw="$1"
    local name=$(basename "$fw" .framework)
    
    # Skip if already properly structured
    if [ -L "$fw/Resources" ]; then
        return 0
    fi
    
    echo "  Fixing: $name.framework"
    
    # Create Versions structure
    mkdir -p "$fw/Versions/A"
    
    # Move Resources if it exists as a directory
    if [ -d "$fw/Resources" ] && [ ! -L "$fw/Resources" ]; then
        mv "$fw/Resources" "$fw/Versions/A/" 2>/dev/null || true
    fi
    
    # Move binary if it exists
    if [ -f "$fw/$name" ] && [ ! -L "$fw/$name" ]; then
        mv "$fw/$name" "$fw/Versions/A/" 2>/dev/null || true
    fi
    
    # Create Current symlink
    ( cd "$fw/Versions" && ln -sf A Current )
    
    # Create top-level symlinks
    ( cd "$fw" && ln -sf Versions/Current/Resources Resources 2>/dev/null || true )
    ( cd "$fw" && ln -sf "Versions/Current/$name" "$name" 2>/dev/null || true )
}

# Fix all frameworks
if [ -d "$FRAMEWORKS_DIR" ]; then
    find "$FRAMEWORKS_DIR" -name "*.framework" -maxdepth 1 -type d | while read framework; do
        fix_framework "$framework"
    done
    echo -e "${GREEN}✓${NC} Frameworks fixed"
else
    echo -e "${RED}✗${NC} Frameworks directory not found"
    exit 1
fi
echo ""

# Step 5: Create archive script
echo -e "${YELLOW}[5/5]${NC} Ready for archiving..."

cat > macos/post_build.sh << 'EOF'
#!/bin/bash
# This runs after Xcode archive to fix frameworks

set -e

echo "Post-build: Fixing frameworks in archive..."

# Find the archive
ARCHIVE_PATH="$ARCHIVE_PRODUCTS_PATH/Applications/admin.app"
FRAMEWORKS="$ARCHIVE_PATH/Contents/Frameworks"

if [ ! -d "$FRAMEWORKS" ]; then
    echo "No frameworks directory found"
    exit 0
fi

fix_framework() {
    local fw="$1"
    local name=$(basename "$fw" .framework)
    
    if [ -L "$fw/Resources" ]; then
        return 0
    fi
    
    echo "Fixing: $name.framework"
    
    mkdir -p "$fw/Versions/A"
    
    [ -d "$fw/Resources" ] && [ ! -L "$fw/Resources" ] && mv "$fw/Resources" "$fw/Versions/A/" 2>/dev/null || true
    [ -f "$fw/$name" ] && [ ! -L "$fw/$name" ] && mv "$fw/$name" "$fw/Versions/A/" 2>/dev/null || true
    
    ( cd "$fw/Versions" && ln -sf A Current )
    ( cd "$fw" && ln -sf Versions/Current/Resources Resources 2>/dev/null || true )
    ( cd "$fw" && ln -sf "Versions/Current/$name" "$name" 2>/dev/null || true )
}

find "$FRAMEWORKS" -name "*.framework" -maxdepth 1 -type d | while read framework; do
    fix_framework "$framework"
done

echo "✓ Post-build framework fix complete"
EOF

chmod +x macos/post_build.sh
echo ""

echo -e "${GREEN}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              Build Complete!                       ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Next: Archive in Xcode${NC}"
echo ""
echo "1. Open Xcode workspace:"
echo -e "   ${YELLOW}open macos/Runner.xcworkspace${NC}"
echo ""
echo "2. Before archiving, add a Run Script phase:"
echo "   - Select Runner target → Build Phases"
echo "   - Click '+' → New Run Script Phase"
echo "   - Add this script:"
echo '   ${PROJECT_DIR}/post_build.sh'
echo "   - Move it to AFTER 'Embed Frameworks'"
echo ""
echo "3. Then: Product → Archive"
echo ""
echo -e "${YELLOW}OR use the automated archive script:${NC}"
echo "   ./macos/archive-with-fixes.sh"
echo ""
