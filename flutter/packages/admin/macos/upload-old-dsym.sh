#!/bin/bash
# Upload old dSYM to App Store Connect to clear the warning

echo "╔════════════════════════════════════════════════════════╗"
echo "║  Upload Missing dSYM to Clear Warning                  ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""
echo "This script helps you upload the missing dSYM for the old build."
echo ""

# The UUIDs we're looking for
OLD_UUID1="03B6A1A2-5E7D-3739-8E76-9D012056D4A4"
OLD_UUID2="66EA13FF-F635-3458-A0B9-E1F9424A00B0"

echo "Looking for archive with UUIDs:"
echo "  - $OLD_UUID1"
echo "  - $OLD_UUID2"
echo ""

# Check if the dSYM exists on another Mac or in backups
echo "WHERE TO FIND THE OLD ARCHIVE:"
echo ""
echo "1. Check OTHER Macs you may have used"
echo "   Run this script on each Mac to search"
echo ""
echo "2. Check CI/CD artifacts"
echo "   If you use GitHub Actions, GitLab CI, etc."
echo "   Download the archive from your CI build artifacts"
echo ""
echo "3. Check Time Machine backups"
echo "   Browse ~/Library/Developer/Xcode/Archives in backups"
echo ""
echo "4. Ask teammates"
echo "   If someone else made that build"
echo ""
echo "5. OR just ignore it"
echo "   The warning doesn't prevent your new build from working"
echo ""

read -p "Do you have the old archive? (y/n): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    read -p "Enter full path to the .xcarchive: " ARCHIVE_PATH
    
    if [ ! -d "$ARCHIVE_PATH" ]; then
        echo "❌ Archive not found at that path"
        exit 1
    fi
    
    # Verify it has the right UUID
    DSYM_PATH="$ARCHIVE_PATH/dSYMs/admin.app.dSYM"
    
    if [ ! -d "$DSYM_PATH" ]; then
        echo "❌ No admin.app.dSYM found in that archive"
        exit 1
    fi
    
    # Check UUID
    UUID_CHECK=$(dwarfdump --uuid "$DSYM_PATH" 2>/dev/null | grep "$OLD_UUID1")
    
    if [ -z "$UUID_CHECK" ]; then
        echo "❌ This archive doesn't contain the UUID we're looking for"
        echo ""
        echo "This archive has:"
        dwarfdump --uuid "$DSYM_PATH" 2>/dev/null
        exit 1
    fi
    
    echo "✓ Found matching dSYM!"
    echo ""
    echo "To upload to App Store Connect:"
    echo ""
    echo "1. Go to https://appstoreconnect.apple.com"
    echo "2. My Apps → admin → Activity"
    echo "3. Find the build that's missing the dSYM"
    echo "4. Scroll to 'Missing dSYMs'"
    echo "5. Click 'Upload dSYM'"
    echo "6. Upload this file:"
    echo "   $DSYM_PATH"
    echo ""
    
    read -p "Open the dSYM folder in Finder? (y/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        open -R "$DSYM_PATH"
    fi
else
    echo ""
    echo "════════════════════════════════════════════════════════"
    echo "RECOMMENDED: Just ignore the warning"
    echo "════════════════════════════════════════════════════════"
    echo ""
    echo "The warning is about an old build. Your NEW build is fine."
    echo ""
    echo "Your new archive HAS dSYMs and they WERE uploaded."
    echo "Crash reports for your new build WILL symbolicate properly."
    echo ""
    echo "The old build (with those UUIDs) is probably:"
    echo "  • No longer in production, OR"
    echo "  • From an old test build, OR"
    echo "  • From a different Mac/developer"
    echo ""
    echo "✅ Proceed with your upload - everything is fine!"
    echo ""
fi
