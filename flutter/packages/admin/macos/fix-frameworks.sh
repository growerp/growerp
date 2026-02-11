#!/bin/bash
# Fix malformed frameworks before archiving
# This addresses the "Malformed Framework" error for frameworks like objective_c.framework

set -e

echo "🔧 Fixing framework structures for App Store upload..."
echo ""

# Navigate to project
cd /Users/hans/growerp/flutter/packages/admin

# Find all frameworks in the build
FRAMEWORKS_DIR="build/macos/Build/Products/Release/admin.app/Contents/Frameworks"

if [ ! -d "$FRAMEWORKS_DIR" ]; then
    echo "❌ Frameworks directory not found. Build the app first:"
    echo "   flutter build macos --release"
    exit 1
fi

echo "Checking frameworks in:"
echo "  $FRAMEWORKS_DIR"
echo ""

# Function to fix a framework's structure
fix_framework() {
    local framework_path="$1"
    local framework_name=$(basename "$framework_path" .framework)
    
    echo "Checking: $framework_name.framework"
    
    # Check if it's missing the proper structure
    if [ ! -L "$framework_path/Resources" ] && [ -d "$framework_path/Resources" ]; then
        echo "  ⚠️  Needs fixing (Resources is a directory, not a symlink)"
        
        # Create Versions directory if it doesn't exist
        if [ ! -d "$framework_path/Versions" ]; then
            mkdir -p "$framework_path/Versions/A"
            ln -sf A "$framework_path/Versions/Current"
        fi
        
        # Move Resources to Versions/A if not already there
        if [ -d "$framework_path/Resources" ] && [ ! -L "$framework_path/Resources" ]; then
            mv "$framework_path/Resources" "$framework_path/Versions/A/"
        fi
        
        # Create symbolic links
        if [ ! -L "$framework_path/Resources" ]; then
            ln -sf Versions/Current/Resources "$framework_path/Resources"
        fi
        
        # Move the binary if needed
        if [ -f "$framework_path/$framework_name" ] && [ ! -L "$framework_path/$framework_name" ]; then
            mv "$framework_path/$framework_name" "$framework_path/Versions/A/"
            ln -sf "Versions/Current/$framework_name" "$framework_path/$framework_name"
        fi
        
        echo "  ✓ Fixed"
    else
        echo "  ✓ OK"
    fi
}

# Fix all .framework bundles
find "$FRAMEWORKS_DIR" -name "*.framework" -type d -maxdepth 1 | while read framework; do
    fix_framework "$framework"
done

echo ""
echo "✅ Framework structure check complete!"
echo ""
echo "Now you can archive in Xcode:"
echo "  1. Open: macos/Runner.xcworkspace"
echo "  2. Product → Archive"
echo "  3. Distribute to App Store"
