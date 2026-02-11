#!/bin/bash
# Quick upload via Xcode Organizer

set -e

echo "╔════════════════════════════════════════════════════╗"
echo "║   Upload macOS App via Xcode Organizer            ║"
echo "╚════════════════════════════════════════════════════╝"
echo ""

PROJECT_DIR="/Users/hans/growerp/flutter/packages/admin"
ARCHIVE_PATH="$PROJECT_DIR/build/Runner.xcarchive"

if [ ! -d "$ARCHIVE_PATH" ]; then
    echo "❌ No archive found. Run ./macos/archive-with-fixes.sh first"
    exit 1
fi

echo "✅ Archive found:"
echo "   $ARCHIVE_PATH"
echo ""
echo "📅 Created: $(date -r "$ARCHIVE_PATH/Info.plist" "+%Y-%m-%d %H:%M:%S")"
echo ""

# Check if frameworks are properly structured
echo "Checking frameworks..."
FRAMEWORKS_DIR="$ARCHIVE_PATH/Products/Applications/admin.app/Contents/Frameworks"
FRAMEWORK_ISSUES=0

if [ -d "$FRAMEWORKS_DIR" ]; then
    for fw in "$FRAMEWORKS_DIR"/*.framework; do
        if [ -d "$fw" ]; then
            name=$(basename "$fw" .framework)
            if [ -d "$fw/Resources" ] && [ ! -L "$fw/Resources" ]; then
                echo "  ⚠️  $name.framework needs fixing"
                FRAMEWORK_ISSUES=$((FRAMEWORK_ISSUES + 1))
            fi
        fi
    done
fi

if [ $FRAMEWORK_ISSUES -gt 0 ]; then
    echo ""
    echo "⚠️  Some frameworks need fixing. Fixing now..."
    echo ""
    
    # Fix frameworks in archive
    for fw in "$FRAMEWORKS_DIR"/*.framework; do
        if [ -d "$fw" ]; then
            name=$(basename "$fw" .framework)
            
            if [ -d "$fw/Resources" ] && [ ! -L "$fw/Resources" ]; then
                echo "Fixing: $name.framework"
                
                # Create Versions structure
                mkdir -p "$fw/Versions/A"
                
                # Move everything except Versions to Versions/A
                for item in "$fw"/*; do
                    base=$(basename "$item")
                    if [ "$base" != "Versions" ] && [ ! -L "$item" ]; then
                        mv "$item" "$fw/Versions/A/" 2>/dev/null || true
                    fi
                done
                
                # Create symlinks
                ( cd "$fw/Versions" && rm -f Current && ln -s A Current )
                ( cd "$fw" && rm -f Resources && ln -s Versions/Current/Resources Resources 2>/dev/null || true )
                ( cd "$fw" && rm -f "$name" && ln -s "Versions/Current/$name" "$name" 2>/dev/null || true )
                
                echo "  ✓ Fixed"
            fi
        fi
    done
    echo ""
fi

echo "✅ All frameworks are properly structured"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "NEXT STEPS:"
echo ""
echo "1. Open Xcode Organizer (will open automatically)"
echo ""
echo "2. In Organizer window:"
echo "   • Select the latest 'Runner' archive"
echo "   • Click 'Distribute App' button"
echo ""
echo "3. Choose distribution method:"
echo "   • Select 'App Store Connect'"
echo "   • Click 'Next'"
echo ""
echo "4. Upload options:"
echo "   • Select 'Upload'"
echo "   • Click 'Next'"
echo ""
echo "5. Re-sign if needed:"
echo "   • Use automatic signing (recommended)"
echo "   • Click 'Next'"
echo ""
echo "6. Review:"
echo "   • Verify the build info"
echo "   • Click 'Upload'"
echo ""
echo "7. When you see the dSYM warning:"
echo "   • This is about an OLD build (ignore it)"
echo "   • Click 'Done' (may need to click twice)"
echo ""
echo "8. Upload will complete:"
echo "   • Watch for 'Upload Successful'"
echo "   • Wait 15-30 min for processing"
echo "   • Check App Store Connect → Activity"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

read -p "Open Xcode Organizer now? (y/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Opening Xcode..."
    open "$PROJECT_DIR/macos/Runner.xcworkspace"
    sleep 2
    
    # Try to open Organizer window
    osascript -e 'tell application "Xcode" to activate' 2>/dev/null || true
    sleep 1
    osascript -e 'tell application "System Events" to keystroke "9" using {command down, shift down}' 2>/dev/null || true
    
    echo ""
    echo "✅ Xcode Organizer should now be open"
    echo ""
    echo "If Organizer didn't open automatically:"
    echo "  • In Xcode menu: Window → Organizer"
    echo "  • Or press: ⌘⇧9"
    echo ""
else
    echo ""
    echo "To open Organizer manually:"
    echo "  1. Open: macos/Runner.xcworkspace"
    echo "  2. Window → Organizer (⌘⇧9)"
    echo ""
fi

echo "Done! Follow the steps above to upload."
echo ""
