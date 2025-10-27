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

APP_NAME="${1:-admin}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

case "$APP_NAME" in
    admin)
        PACKAGE_DIR="$PROJECT_ROOT/flutter/packages/admin"
        APP_DIR_NAME="admin"
        SCREEN_FILE_NAME="admin.xml"
        SCREEN_COMMENT="Flutter Admin Web Application Screen"
        SCREEN_DESCRIPTION="Serves the Flutter admin app and its assets"
        SCREEN_AUTH="anonymous-view"
        BASE_PATH="/admin/"
        ;;
    landingpage)
        PACKAGE_DIR="$PROJECT_ROOT/flutter/packages/landing_page"
        APP_DIR_NAME="landingpage"
        SCREEN_FILE_NAME="landingpage.xml"
        SCREEN_COMMENT="GrowERP Public Landing Page Screen"
        SCREEN_DESCRIPTION="Serves the public landing page Flutter app and assets"
        SCREEN_AUTH="anonymous-all"
        BASE_PATH="/landingpage/"
        ;;
    *)
        echo -e "${RED}Unknown app: $APP_NAME${NC}"
        exit 1
        ;;
esac

FLUTTER_BUILD_DIR="$PACKAGE_DIR/build/web"
MOQUI_TARGET_DIR="$PROJECT_ROOT/moqui/runtime/component/PopRestStore/screen/store/$APP_DIR_NAME"
MOQUI_SCREEN_FILE="$PROJECT_ROOT/moqui/runtime/component/PopRestStore/screen/store/$SCREEN_FILE_NAME"

echo -e "${YELLOW}Deploying Flutter ${APP_NAME^} Web Build to Moqui...${NC}"

# Always rebuild admin and landing_page packages
echo -e "${YELLOW}Building Flutter web with WASM for admin...${NC}"
cd "$PROJECT_ROOT/flutter/packages/admin"
flutter build web --wasm
echo -e "${GREEN}✓ Admin web build completed${NC}"

echo -e "${YELLOW}Building Flutter web with WASM for landing_page...${NC}"
cd "$PROJECT_ROOT/flutter/packages/landing_page"
flutter build web --wasm
echo -e "${GREEN}✓ Landing page web build completed${NC}"

# Reset to package directory for deployment
cd "$PACKAGE_DIR"

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

# Create target directory if it doesn't exist
echo -e "Creating target directory: $MOQUI_TARGET_DIR"
mkdir -p "$MOQUI_TARGET_DIR"

# Create screen file if it doesn't exist
if [ ! -f "$MOQUI_SCREEN_FILE" ]; then
    echo -e "Creating $SCREEN_FILE_NAME screen..."
    cat > "$MOQUI_SCREEN_FILE" << SCREEN_EOF
<?xml version="1.0" encoding="UTF-8"?>
<!--
$SCREEN_COMMENT
$SCREEN_DESCRIPTION
-->
<screen xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:noNamespaceSchemaLocation="http://moqui.org/xsd/xml-screen-2.1.xsd"
    standalone="true" require-authentication="$SCREEN_AUTH">

    <widgets>
        <render-mode>
            <text type="html" location="component://PopRestStore/screen/store/$APP_DIR_NAME/index.html"/>
        </render-mode>
    </widgets>
</screen>
SCREEN_EOF
    echo -e "${GREEN}✓ $SCREEN_FILE_NAME screen created${NC}"
else
    echo -e "${GREEN}✓ $SCREEN_FILE_NAME screen already exists${NC}"
fi

# Copy Flutter web build files
echo -e "Copying Flutter web files..."
cp -r "$FLUTTER_BUILD_DIR"/* "$MOQUI_TARGET_DIR/"

# Fix the base href in index.html to work with the desired path
echo -e "Fixing base href in index.html..."
if [ -f "$MOQUI_TARGET_DIR/index.html" ]; then
    sed -i "s|<base href=\"/\">|<base href=\"$BASE_PATH\">|g" "$MOQUI_TARGET_DIR/index.html"
    echo -e "${GREEN}✓ Base href fixed${NC}"
fi

# Remove service worker registration from index.html (it's registered globally)
echo -e "Removing service worker registration from index.html (registered in root.html.ftl)..."
if [ -f "$MOQUI_TARGET_DIR/index.html" ]; then
    perl -i -0pe 's/<script>\s*if \(.serviceWorker. in navigator\).*?<\/script>\s*//gs' "$MOQUI_TARGET_DIR/index.html"

    sed -i "s|<script src=\"flutter_bootstrap.js\" async></script>|<!-- Service worker is already registered in root.html.ftl -->\n  <!-- Flutter bootstrap will find and use the already-registered and activated service worker -->\n  \n  <script src=\"flutter_bootstrap.js\" async></script>|g" "$MOQUI_TARGET_DIR/index.html"
    echo -e "${GREEN}✓ Service worker registration removed${NC}"
fi

# Verify critical files were copied
if [ -f "$MOQUI_TARGET_DIR/flutter_service_worker.js" ]; then
    echo -e "${GREEN}✓ flutter_service_worker.js deployed successfully${NC}"
else
    echo -e "${RED}✗ flutter_service_worker.js deployment failed${NC}"
    exit 1
fi

if [ -f "$MOQUI_TARGET_DIR/index.html" ]; then
    echo -e "${GREEN}✓ index.html deployed successfully${NC}"
else
    echo -e "${RED}✗ index.html deployment failed${NC}"
    exit 1
fi

if [ -f "$MOQUI_TARGET_DIR/main.dart.js" ]; then
    echo -e "${GREEN}✓ main.dart.js deployed successfully${NC}"
else
    echo -e "${RED}✗ main.dart.js deployment failed${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Flutter ${APP_NAME^} web build successfully deployed to Moqui!${NC}"
echo -e "${YELLOW}Files are now accessible at: $BASE_PATH${NC}"
echo -e "${YELLOW}Service worker accessible at: ${BASE_PATH}flutter_service_worker.js${NC}"
echo -e ""
echo -e "${YELLOW}⚠️  IMPORTANT: You must restart Moqui for changes to take effect!${NC}"
echo -e "${YELLOW}   Stop Moqui (Ctrl+C) and restart with: java -jar moqui.war${NC}"
