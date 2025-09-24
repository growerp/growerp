#!/bin/bash

# Script to update timeout values in all app_settings.json files
# This addresses timeout issues with demo data creation on cloud servers

echo "Updating timeout values in all app_settings.json files..."

# Find all app_settings.json files and update timeout values
find . -name "app_settings.json" -type f | while read -r file; do
    echo "Updating $file"
    
    # Check if the file contains the timeout configuration
    if grep -q "connectTimeoutProd" "$file"; then
        # Update timeout values using sed
        sed -i.bak \
            -e 's/"connectTimeoutProd": *[0-9]*/"connectTimeoutProd": 30/' \
            -e 's/"receiveTimeoutProd": *[0-9]*/"receiveTimeoutProd": 300/' \
            -e 's/"connectTimeoutTest": *[0-9]*/"connectTimeoutTest": 30/' \
            -e 's/"receiveTimeoutTest": *[0-9]*/"receiveTimeoutTest": 600/' \
            "$file"
        
        echo "  ✓ Updated timeout values in $file"
        
        # Remove backup file
        rm "${file}.bak" 2>/dev/null || true
    else
        echo "  - No timeout configuration found in $file"
    fi
done

echo ""
echo "✅ Timeout update completed!"
echo ""
echo "Summary of changes:"
echo "  - connectTimeoutProd: 10 → 30 seconds"
echo "  - receiveTimeoutProd: 10 → 300 seconds (5 minutes)"
echo "  - connectTimeoutTest: 20 → 30 seconds"
echo "  - receiveTimeoutTest: 40 → 600 seconds (10 minutes)"
echo ""
echo "📝 Note: These changes will help resolve timeout issues when creating demo data"
echo "   on cloud servers where database operations can take longer."