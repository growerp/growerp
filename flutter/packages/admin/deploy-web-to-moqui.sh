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

APP_NAME="${1:-both}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Function to deploy a single app
deploy_app() {
    local APP="$1"
    local PACKAGE_DIR
    local APP_DIR_NAME
    local SCREEN_FILE_NAME
    local SCREEN_COMMENT
    local SCREEN_DESCRIPTION
    local SCREEN_AUTH
    local BASE_PATH

    case "$APP" in
        admin)
            PACKAGE_DIR="$PROJECT_ROOT/flutter/packages/admin"
            APP_DIR_NAME="admin"
            SCREEN_FILE_NAME="admin.xml"
            SCREEN_COMMENT="Flutter Admin Web Application Screen"
            SCREEN_DESCRIPTION="Serves the Flutter admin app and its assets"
            SCREEN_AUTH="anonymous-view"
            BASE_PATH="/admin/"
            ;;
        assessment)
            PACKAGE_DIR="$PROJECT_ROOT/flutter/packages/assessment"
            APP_DIR_NAME="assessment"
            SCREEN_FILE_NAME="assessmentApp.xml"
            SCREEN_COMMENT="GrowERP Assessment Flutter App Screen"
            SCREEN_DESCRIPTION="Serves the Flutter assessment app and assets"
            SCREEN_AUTH="anonymous-view"
            BASE_PATH="/assessment/"
            ;;
        freelance)
            PACKAGE_DIR="$PROJECT_ROOT/flutter/packages/freelance"
            APP_DIR_NAME="freelance"
            SCREEN_FILE_NAME="freelance.xml"
            SCREEN_COMMENT="GrowERP Freelance Flutter App Screen"
            SCREEN_DESCRIPTION="Serves the Flutter freelance app and assets"
            SCREEN_AUTH="anonymous-view"
            BASE_PATH="/freelance/"
            ;;
        *)
            echo -e "${RED}Unknown app: $APP${NC}"
            return 1
            ;;
    esac

    FLUTTER_BUILD_DIR="$PACKAGE_DIR/build/web"
    MOQUI_TARGET_DIR="$PROJECT_ROOT/moqui/runtime/component/PopRestStore/screen/store/$APP_DIR_NAME"
    MOQUI_SCREEN_FILE="$PROJECT_ROOT/moqui/runtime/component/PopRestStore/screen/store/$SCREEN_FILE_NAME"

    echo -e "${YELLOW}Deploying Flutter ${APP} Web Build to Moqui...${NC}"

    # Build the app
    echo -e "${YELLOW}Building Flutter web with WASM for ${APP}...${NC}"
    cd "$PACKAGE_DIR"
    
    # Temporarily modify app_settings.json so the built app talks to the local
    # Moqui (relative /rest) instead of the production backend it ships with.
    APP_SETTINGS="assets/cfg/app_settings.json"
    APP_SETTINGS_BACKUP="assets/cfg/app_settings.json.backup"
    cp "$APP_SETTINGS" "$APP_SETTINGS_BACKUP"

    # Empty databaseUrl => baseUrl resolves to the serving origin ("/"), so the
    # retrofit paths (which already start with "rest/") become "/rest/s1/...".
    # Using "/rest" here would double to "/rest/rest/s1/..." and 404.
    echo -e "${YELLOW}Configuring for local deployment (using relative URLs)...${NC}"
    sed -i 's|"databaseUrl": *"https://backend\.growerp\.com"|"databaseUrl": ""|g' "$APP_SETTINGS"
    sed -i 's|"chatUrl": *"wss://backend\.growerp\.com"|"chatUrl": "ws://localhost:8080/chat"|g' "$APP_SETTINGS"

    # --pwa-strategy=none: do NOT generate or register a service worker. These apps are
    # served inside Moqui (the assessment app runs in an iframe) and need no offline
    # support. The SW only caused stale-bundle pain after every redeploy because
    # version.json is not bumped, so browsers kept serving the previous build.
    flutter build web --wasm --pwa-strategy=none
    BUILD_RESULT=$?

    # Restore original app_settings.json
    if [ -f "$APP_SETTINGS_BACKUP" ]; then
        echo -e "${YELLOW}Restoring original app_settings.json...${NC}"
        mv "$APP_SETTINGS_BACKUP" "$APP_SETTINGS"
    fi
    
    if [ $BUILD_RESULT -ne 0 ]; then
        echo -e "${RED}✗ Failed to build ${APP}${NC}"
        return 1
    fi
    echo -e "${GREEN}✓ ${APP^} web build completed${NC}"

    # Check if Flutter build directory exists
    if [ ! -d "$FLUTTER_BUILD_DIR" ]; then
        echo -e "${RED}Error: Flutter build directory not found at $FLUTTER_BUILD_DIR${NC}"
        echo -e "${YELLOW}Please run 'flutter build web' first${NC}"
        return 1
    fi

    # Create target directory if it doesn't exist
    echo -e "Creating target directory: $MOQUI_TARGET_DIR"
    mkdir -p "$MOQUI_TARGET_DIR"

    # Create screen file if it doesn't exist
    if [ ! -f "$MOQUI_SCREEN_FILE" ]; then
        echo -e "Creating $SCREEN_FILE_NAME screen..."
        
        # For admin app, create enhanced screen with setup notice fallback
        if [ "$APP" = "admin" ]; then
            cat > "$MOQUI_SCREEN_FILE" << 'SCREEN_EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!--
Flutter Admin Web Application Screen
Serves the Flutter admin app and its assets
If not deployed, shows setup instructions
-->
<screen xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:noNamespaceSchemaLocation="http://moqui.org/xsd/xml-screen-2.1.xsd"
    standalone="true" require-authentication="anonymous-view">

    <actions>
        <script><![CDATA[
            // Check if the Flutter admin build has been deployed
            def indexResource = ec.resource.getLocationReference("component://PopRestStore/screen/store/admin/index.html")
            context.adminDeployed = indexResource != null && indexResource.exists
        ]]></script>
    </actions>

    <widgets>
        <render-mode>
            <text type="html"><![CDATA[
                <#if adminDeployed!false>
                    ${ec.resource.getLocationText("component://PopRestStore/screen/store/admin/index.html", false)}
                <#else>
                    ${ec.resource.getLocationText("component://PopRestStore/screen/store/admin_setup_notice.html", false)}
                </#if>
            ]]></text>
        </render-mode>
    </widgets>
</screen>
SCREEN_EOF
        else
            # For other apps, use simple screen
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
        fi
        echo -e "${GREEN}✓ $SCREEN_FILE_NAME screen created${NC}"
    else
        echo -e "${GREEN}✓ $SCREEN_FILE_NAME screen already exists${NC}"
    fi

    # Create setup notice file for admin app if it doesn't exist
    if [ "$APP" = "admin" ]; then
        SETUP_NOTICE_FILE="$PROJECT_ROOT/moqui/runtime/component/PopRestStore/screen/store/admin_setup_notice.html"
        if [ ! -f "$SETUP_NOTICE_FILE" ]; then
            echo -e "Creating setup notice file..."
            cat > "$SETUP_NOTICE_FILE" << 'NOTICE_EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>GrowERP Admin - Setup Required</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        .container {
            background: white;
            border-radius: 20px;
            padding: 40px;
            max-width: 700px;
            box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
        }
        .icon { font-size: 64px; text-align: center; margin-bottom: 20px; }
        h1 { color: #333; margin-bottom: 10px; font-size: 2em; text-align: center; }
        .subtitle { color: #666; margin-bottom: 30px; font-size: 1.1em; text-align: center; }
        .notice-box {
            background: #fff3cd;
            border-left: 4px solid #ffc107;
            padding: 20px;
            margin-bottom: 30px;
            border-radius: 4px;
        }
        .notice-box h2 { color: #856404; margin-bottom: 10px; font-size: 1.2em; }
        .notice-box p { color: #856404; line-height: 1.6; margin-bottom: 10px; }
        .steps {
            background: #f8f9fa;
            border-left: 4px solid #667eea;
            padding: 20px;
            margin-bottom: 20px;
            border-radius: 4px;
        }
        .steps h3 { color: #333; margin-bottom: 15px; font-size: 1.1em; }
        .steps ol { margin-left: 20px; color: #555; line-height: 1.8; }
        .steps li { margin-bottom: 10px; }
        code {
            background: #e9ecef;
            padding: 3px 8px;
            border-radius: 4px;
            font-family: 'Courier New', monospace;
            font-size: 0.9em;
            color: #d63384;
        }
        .command-box {
            background: #1e1e1e;
            color: #d4d4d4;
            padding: 15px;
            border-radius: 8px;
            margin: 15px 0;
            font-family: 'Courier New', monospace;
        }
        .info-box {
            background: #d1ecf1;
            border-left: 4px solid #0c5460;
            padding: 15px;
            margin-top: 20px;
            border-radius: 4px;
        }
        .info-box p { color: #0c5460; line-height: 1.6; margin-bottom: 8px; }
        .info-box p:last-child { margin-bottom: 0; }
    </style>
</head>
<body>
    <div class="container">
        <div class="icon">⚙️</div>
        <h1>GrowERP Admin Setup Required</h1>
        <p class="subtitle">The Flutter web application needs to be built and deployed</p>
        
        <div class="notice-box">
            <h2>🔧 What's happening?</h2>
            <p>You're seeing this page because the GrowERP Admin Flutter web application hasn't been deployed to the Moqui backend yet.</p>
            <p>This is normal when running GrowERP locally without Docker.</p>
        </div>
        
        <div class="steps">
            <h3>📋 Setup Instructions</h3>
            <ol>
                <li>Open a terminal and navigate to the admin package:
                    <div class="command-box">cd flutter/packages/admin</div>
                </li>
                <li>Run the build and deploy script:
                    <div class="command-box">./build-and-deploy-web.sh</div>
                </li>
                <li>Wait for the build to complete (this may take a few minutes)</li>
                <li>Refresh this page - the admin application should now load!</li>
            </ol>
        </div>
        
        <div class="info-box">
            <p><strong>💡 Note:</strong> This setup is only needed once, or after you make changes to the admin web application.</p>
            <p><strong>🐳 Docker Users:</strong> If you're using Docker, the deployment happens automatically during the container build process.</p>
            <p><strong>📚 Documentation:</strong> See <code>flutter/packages/admin/DEPLOY_WEB.md</code> for more details.</p>
        </div>
    </div>
</body>
</html>
NOTICE_EOF
            echo -e "${GREEN}✓ Setup notice file created${NC}"
        fi
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

    # Build with --pwa-strategy=none means no service worker is registered going forward.
    # But browsers that visited a PREVIOUS deploy still have an old SW installed that will
    # keep serving the stale bundle. Inject a snippet that unregisters any existing SW and
    # drops its caches on load, so those clients self-heal without a manual cache clear.
    echo -e "Injecting service-worker unregister snippet into index.html..."
    if [ -f "$MOQUI_TARGET_DIR/index.html" ]; then
        perl -i -pe 's{(<script src="flutter_bootstrap\.js")}{<script>if("serviceWorker" in navigator){navigator.serviceWorker.getRegistrations().then(function(rs){rs.forEach(function(r){r.unregister()})});if(window.caches){caches.keys().then(function(ks){ks.forEach(function(k){caches.delete(k)})})}}</script>\n  $1}' "$MOQUI_TARGET_DIR/index.html"
        echo -e "${GREEN}✓ SW unregister snippet injected${NC}"
    fi

    # Verify critical files were copied
    if [ -f "$MOQUI_TARGET_DIR/index.html" ]; then
        echo -e "${GREEN}✓ index.html deployed successfully${NC}"
    else
        echo -e "${RED}✗ index.html deployment failed${NC}"
        return 1
    fi

    if [ -f "$MOQUI_TARGET_DIR/main.dart.js" ]; then
        echo -e "${GREEN}✓ main.dart.js deployed successfully${NC}"
    else
        echo -e "${RED}✗ main.dart.js deployment failed${NC}"
        return 1
    fi

    echo -e "${GREEN}✓ Flutter ${APP} web build successfully deployed to Moqui!${NC}"
    echo -e "${YELLOW}Files are now accessible at: $BASE_PATH${NC}"
    return 0
}

# Main script logic
echo -e "${YELLOW}Deploying Flutter Web Builds to Moqui...${NC}"

case "$APP_NAME" in
    both|all|"")
        echo -e "${YELLOW}Deploying admin and assessment apps${NC}"
        deploy_app admin
        ADMIN_RESULT=$?
        deploy_app assessment
        ASSESSMENT_RESULT=$?
        
        if [ $ADMIN_RESULT -ne 0 ] || [ $ASSESSMENT_RESULT -ne 0 ]; then
            echo -e "${RED}✗ One or more deployments failed${NC}"
            exit 1
        fi
        ;;
    admin|assessment|freelance)
        deploy_app "$APP_NAME"
        if [ $? -ne 0 ]; then
            exit 1
        fi
        ;;
    *)
        echo -e "${RED}Unknown app: $APP_NAME${NC}"
        echo -e "${YELLOW}Usage: $0 [admin|assessment|freelance|both|all]${NC}"
        echo -e "${YELLOW}Default (no args): deploys all apps${NC}"
        exit 1
        ;;
esac
echo -e ""
echo -e "${GREEN}✓ All apps successfully deployed!${NC}"
echo -e "${YELLOW}⚠️  IMPORTANT: You must restart Moqui for changes to take effect!${NC}"
echo -e "${YELLOW}   Stop Moqui (Ctrl+C) and restart with: java -jar moqui.war${NC}"
