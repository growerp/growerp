#!/bin/bash

# Deploy Flutter Admin Web Build to Moqui PopRestStore
# This script copies the Flutter web build files to the Moqui component directory
# so they can be served at the /admin/ path

set -e

# Color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

FLUTTER_BUILD_DIR="$SCRIPT_DIR/build/web"
MOQUI_ADMIN_DIR="$PROJECT_ROOT/moqui/runtime/component/PopRestStore/screen/store/admin"
MOQUI_SCREEN_FILE="$PROJECT_ROOT/moqui/runtime/component/PopRestStore/screen/store/admin.xml"

echo -e "${YELLOW}Deploying Flutter Admin Web Build to Moqui...${NC}"

# Check if Flutter build directory exists
if [ ! -d "$FLUTTER_BUILD_DIR" ]; then
    echo -e "${RED}Error: Flutter build directory not found at $FLUTTER_BUILD_DIR${NC}"
    echo -e "${YELLOW}Please run 'flutter build web' first${NC}"
    exit 1
fi

# Check if flutter_service_worker.js exists
if [ ! -f "$FLUTTER_BUILD_DIR/flutter_service_worker.js" ]; then
    echo -e "${RED}Error: flutter_service_worker.js not found in build directory${NC}"
    echo -e "${YELLOW}Please ensure the Flutter web build completed successfully${NC}"
    exit 1
fi

# Create Moqui admin directory if it doesn't exist
echo -e "Creating admin directory: $MOQUI_ADMIN_DIR"
mkdir -p "$MOQUI_ADMIN_DIR"

# Create admin.xml screen if it doesn't exist
if [ ! -f "$MOQUI_SCREEN_FILE" ]; then
    echo -e "Creating admin.xml screen..."
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
    echo -e "${GREEN}✓ admin.xml screen created${NC}"
else
    echo -e "${GREEN}✓ admin.xml screen already exists${NC}"
fi

# Copy Flutter web build files
echo -e "Copying Flutter web files..."
cp -r "$FLUTTER_BUILD_DIR"/* "$MOQUI_ADMIN_DIR/"

# Fix the base href in index.html to work with /admin/ path
echo -e "Fixing base href in index.html..."
if [ -f "$MOQUI_ADMIN_DIR/index.html" ]; then
    sed -i 's|<base href="/">|<base href="/admin/">|g' "$MOQUI_ADMIN_DIR/index.html"
    echo -e "${GREEN}✓ Base href fixed${NC}"
fi

# Remove service worker registration from index.html (it's registered in root.html.ftl)
echo -e "Removing service worker registration from index.html (registered in root.html.ftl)..."
if [ -f "$MOQUI_ADMIN_DIR/index.html" ]; then
    # Use perl for multi-line matching and replacement
    perl -i -0pe 's/<script>\s*if \(.serviceWorker. in navigator\).*?<\/script>\s*//gs' "$MOQUI_ADMIN_DIR/index.html"
    
    # Add explanatory comment before flutter_bootstrap.js
    sed -i 's|<script src="flutter_bootstrap.js" async></script>|<!-- Service worker is already registered in root.html.ftl -->\n  <!-- Flutter bootstrap will find and use the already-registered and activated service worker -->\n  \n  <script src="flutter_bootstrap.js" async></script>|g' "$MOQUI_ADMIN_DIR/index.html"
    echo -e "${GREEN}✓ Service worker registration removed${NC}"
fi

# Verify critical files were copied
if [ -f "$MOQUI_ADMIN_DIR/flutter_service_worker.js" ]; then
    echo -e "${GREEN}✓ flutter_service_worker.js deployed successfully${NC}"
else
    echo -e "${RED}✗ flutter_service_worker.js deployment failed${NC}"
    exit 1
fi

if [ -f "$MOQUI_ADMIN_DIR/index.html" ]; then
    echo -e "${GREEN}✓ index.html deployed successfully${NC}"
else
    echo -e "${RED}✗ index.html deployment failed${NC}"
    exit 1
fi

if [ -f "$MOQUI_ADMIN_DIR/main.dart.js" ]; then
    echo -e "${GREEN}✓ main.dart.js deployed successfully${NC}"
else
    echo -e "${RED}✗ main.dart.js deployment failed${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Flutter Admin web build successfully deployed to Moqui!${NC}"
echo -e "${YELLOW}Files are now accessible at: /admin/${NC}"
echo -e "${YELLOW}Service worker accessible at: /admin/flutter_service_worker.js${NC}"
echo -e ""
echo -e "${YELLOW}⚠️  IMPORTANT: You must restart Moqui for changes to take effect!${NC}"
echo -e "${YELLOW}   Stop Moqui (Ctrl+C) and restart with: java -jar moqui.war${NC}"
