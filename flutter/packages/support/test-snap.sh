#!/bin/bash
set -e

echo "🔍 Testing GrowERP Support snap package..."

# Check if snap exists
SNAP_FILE=$(ls growerp-support_*.snap 2>/dev/null | head -1)
if [ -z "$SNAP_FILE" ]; then
    echo "❌ No snap file found. Please build the snap first."
    echo "Run: ./build-snap.sh"
    exit 1
fi

echo "📦 Found snap file: $SNAP_FILE"

# Check if snap is already installed
if snap list growerp-support >/dev/null 2>&1; then
    echo "🔄 Removing existing installation..."
    sudo snap remove growerp-support
fi

# Install the snap
echo "📥 Installing snap..."
sudo snap install --dangerous "$SNAP_FILE"

# Check installation
if snap list growerp-support >/dev/null 2>&1; then
    echo "✅ Snap installed successfully"
    
    # Show snap info
    echo ""
    echo "📋 Snap information:"
    snap info growerp-support
    
    # Test if the command is available
    echo ""
    echo "🧪 Testing if command is available..."
    if command -v growerp-support >/dev/null 2>&1; then
        echo "✅ Command 'growerp-support' is available"
        
        # Try to run the app in background for a few seconds
        echo "🚀 Testing app startup..."
        timeout 10s growerp-support &
        APP_PID=$!
        sleep 3
        
        if kill -0 $APP_PID 2>/dev/null; then
            echo "✅ App started successfully"
            kill $APP_PID 2>/dev/null || true
        else
            echo "❌ App failed to start or crashed immediately"
        fi
    else
        echo "❌ Command 'growerp-support' not found in PATH"
    fi
    
    echo ""
    echo "📱 To run the app:"
    echo "growerp-support"
    echo ""
    echo "🗑️ To remove:"
    echo "sudo snap remove growerp-support"
    
else
    echo "❌ Failed to install snap"
    exit 1
fi
