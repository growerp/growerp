#!/bin/bash
# Deploy Flutter Admin Web Build to Moqui Runtime
# Called during Docker build process

set -e

FLUTTER_BUILD_DIR="/root/growerp/flutter/packages/admin/build/web"
MOQUI_ADMIN_DIR="/root/growerp/moqui/runtime/component/PopRestStore/screen/store/admin"
MOQUI_SCREEN_FILE="/root/growerp/moqui/runtime/component/PopRestStore/screen/store/admin.xml"

echo "========================================="
echo "Deploying Flutter Admin to Moqui Runtime"
echo "========================================="

# Verify Flutter build exists
if [ ! -d "$FLUTTER_BUILD_DIR" ]; then
    echo "ERROR: Flutter build directory not found at $FLUTTER_BUILD_DIR"
    exit 1
fi

if [ ! -f "$FLUTTER_BUILD_DIR/flutter_service_worker.js" ]; then
    echo "ERROR: flutter_service_worker.js not found"
    exit 1
fi

# Create admin directory
echo "Creating admin directory..."
mkdir -p "$MOQUI_ADMIN_DIR"

# Copy Flutter web build files
echo "Copying Flutter web files..."
cp -r "$FLUTTER_BUILD_DIR"/* "$MOQUI_ADMIN_DIR/"

# Fix base href in index.html
echo "Fixing base href to /admin/..."
sed -i 's|<base href="/">|<base href="/admin/">|g' "$MOQUI_ADMIN_DIR/index.html"

# Remove service worker registration (it's in root.html.ftl)
echo "Removing service worker registration from index.html..."
perl -i -0pe 's/<script>\s*if \(.serviceWorker. in navigator\).*?<\/script>\s*//gs' "$MOQUI_ADMIN_DIR/index.html"

# Add explanatory comment
sed -i 's|<script src="flutter_bootstrap.js" async></script>|  <!-- Service worker is already registered in root.html.ftl -->\n  <!-- Flutter bootstrap will find and use the already-registered and activated service worker -->\n  \n  <script src="flutter_bootstrap.js" async></script>|g' "$MOQUI_ADMIN_DIR/index.html"

# Create admin.xml screen definition
echo "Creating admin.xml screen..."
cat > "$MOQUI_SCREEN_FILE" << 'SCREEN_EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!--
Flutter Admin Web Application Screen
Serves the Flutter admin app and its assets
-->
<screen xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:noNamespaceSchemaLocation="http://moqui.org/xsd/xml-screen-2.1.xsd"
    standalone="true" require-authentication="anonymous-view">

    <widgets>
        <render-mode>
            <text type="html" location="component://PopRestStore/screen/store/admin/index.html"/>
        </render-mode>
    </widgets>
</screen>
SCREEN_EOF

# Verify deployment
echo ""
echo "Verifying deployment..."
if [ -f "$MOQUI_ADMIN_DIR/flutter_service_worker.js" ]; then
    echo "✓ flutter_service_worker.js"
else
    echo "✗ flutter_service_worker.js MISSING"
    exit 1
fi

if [ -f "$MOQUI_ADMIN_DIR/main.dart.js" ]; then
    SIZE=$(du -h "$MOQUI_ADMIN_DIR/main.dart.js" | cut -f1)
    echo "✓ main.dart.js ($SIZE)"
else
    echo "✗ main.dart.js MISSING"
    exit 1
fi

if [ -f "$MOQUI_ADMIN_DIR/index.html" ]; then
    echo "✓ index.html"
else
    echo "✗ index.html MISSING"
    exit 1
fi

if [ -f "$MOQUI_SCREEN_FILE" ]; then
    echo "✓ admin.xml screen"
else
    echo "✗ admin.xml screen MISSING"
    exit 1
fi

echo ""
echo "========================================="
echo "✓ Flutter Admin deployed successfully!"
echo "========================================="
echo "Files accessible at: /admin/"
echo "Service worker: /admin/flutter_service_worker.js"
