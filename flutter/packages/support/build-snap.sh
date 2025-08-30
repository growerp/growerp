#!/bin/bash
set -e

echo "Building GrowERP  snap package..."

# Ensure we're in the correct directory
cd "$(dirname "$0")"

# Check if Flutter Linux build exists
if [ ! -f "build/linux/x64/release/bundle/support" ]; then
    echo "Linux build not found. Building Flutter app first..."
    flutter build linux --release
fi

# Clean previous snap build artifacts
echo "Cleaning previous build artifacts..."
rm -rf parts prime stage *.snap

# Build the snap
echo "Building snap package..."
if command -v snapcraft >/dev/null 2>&1; then
    snapcraft pack --destructive-mode
else
    echo "Error: snapcraft is not installed. Please install it with:"
    echo "sudo snap install snapcraft --classic"
    exit 1
fi

# Check if snap was created successfully
SNAP_FILE=$(ls growerp-support_*.snap 2>/dev/null | head -1)
if [ -n "$SNAP_FILE" ]; then
    echo "✅ Snap package created successfully: $SNAP_FILE"
    echo ""
    echo "To install locally:"
    echo "sudo snap install --dangerous $SNAP_FILE"
    echo ""
    echo "To test the installation:"
    echo "./growerp-support"
    echo ""
    echo "To uninstall:"
    echo "sudo snap remove growerp-support"
    echo 
    echo "To upload/register:"
    echo "snapcraft register growerp-support"
    echo "snapcraft upload growerp-support_*.snap --release=stable"
else
    echo "❌ Failed to create snap package"
    exit 1
fi
