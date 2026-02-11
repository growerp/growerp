#!/bin/bash
# Search for dSYM with specific UUID

TARGET_UUID="03B6A1A2-5E7D-3739-8E76-9D012056D4A4"

echo "Searching for dSYM with UUID: $TARGET_UUID"
echo "This may take a minute..."
echo ""

cd ~/Library/Developer/Xcode/Archives

for year_month in 2026-* 2025-*; do
    if [ -d "$year_month" ]; then
        echo "Checking $year_month..."
        for archive in "$year_month"/*.xcarchive; do
            if [ -d "$archive" ]; then
                # Check if this archive contains admin.app
                if [ -d "$archive/dSYMs/admin.app.dSYM" ]; then
                    UUID_CHECK=$(dwarfdump --uuid "$archive/dSYMs/admin.app.dSYM" 2>/dev/null | grep "$TARGET_UUID")
                    if [ -n "$UUID_CHECK" ]; then
                        echo ""
                        echo "✓ FOUND MATCHING ARCHIVE!"
                        echo "  Archive: $archive"
                        echo "  UUIDs:"
                        dwarfdump --uuid "$archive/dSYMs/admin.app.dSYM" 2>/dev/null
                        echo ""
                        echo "  dSYM Location:"
                        echo "  $archive/dSYMs/admin.app.dSYM"
                        exit 0
                    fi
                fi
            fi
        done
    fi
done

echo ""
echo "❌ No matching archive found with UUID $TARGET_UUID"
echo ""
echo "This means the build with those UUIDs:"
echo "  1. Was built on a different Mac, OR"
echo "  2. The archive was deleted, OR"
echo "  3. Was from before your current archives"
echo ""
echo "SOLUTION: Upload a NEW build version instead."
echo "  - Increment the build number in pubspec.yaml"
echo "  - Create a fresh archive"
echo "  - Upload the new version"
