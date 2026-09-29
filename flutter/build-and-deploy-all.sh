#!/bin/bash

# Build and Deploy all Flutter Web Apps to Moqui
# This script builds Flutter web for admin, assessment and academy, then deploys to Moqui

set -e

# Color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."
ADMIN_DIR="$SCRIPT_DIR/packages/admin"
ASSESSMENT_DIR="$SCRIPT_DIR/packages/assessment"

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}Build & Deploy Flutter Apps to Moqui${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""

# Function to build and deploy an app
build_and_deploy() {
    local APP="$1"
    
    case "$APP" in
        admin)
            echo -e "${YELLOW}[1/3] Building and deploying Admin app...${NC}"
            "$ADMIN_DIR/deploy-web-to-moqui.sh" admin
            ;;
        assessment)
            echo -e "${YELLOW}[2/3] Building and deploying Assessment app...${NC}"
            "$ADMIN_DIR/deploy-web-to-moqui.sh" assessment
            ;;
        academy)
            echo -e "${YELLOW}[3/3] Building and deploying Academy app...${NC}"
            "$ADMIN_DIR/deploy-web-to-moqui.sh" academy
            ;;
    esac
}

# Parse arguments
APPS_TO_BUILD="admin assessment academy"

if [ "$1" != "" ]; then
    case "$1" in
        admin)
            APPS_TO_BUILD="admin"
            echo -e "${YELLOW}Building: Admin only${NC}"
            ;;
        assessment)
            APPS_TO_BUILD="assessment"
            echo -e "${YELLOW}Building: Assessment only${NC}"
            ;;
        academy)
            APPS_TO_BUILD="academy"
            echo -e "${YELLOW}Building: Academy only${NC}"
            ;;
        all)
            APPS_TO_BUILD="admin assessment academy"
            echo -e "${YELLOW}Building: All apps${NC}"
            ;;
        *)
            echo -e "${RED}Unknown app: $1${NC}"
            echo -e "${YELLOW}Usage: $0 [admin|assessment|academy|all]${NC}"
            echo -e "${YELLOW}Default (no args): builds all apps${NC}"
            exit 1
            ;;
    esac
fi

# Build and deploy each app
for APP in $APPS_TO_BUILD; do
    build_and_deploy "$APP"
    if [ $? -ne 0 ]; then
        echo -e "${RED}✗ Failed to build/deploy $APP${NC}"
        exit 1
    fi
done

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ All selected apps built and deployed!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}IMPORTANT: You must restart Moqui for changes to take effect!${NC}"
echo -e "${YELLOW}   1. Stop Moqui (Ctrl+C)"
echo -e "${YELLOW}   2. Restart with: cd $PROJECT_ROOT/moqui && java -jar moqui.war no-run-es${NC}"
echo ""
echo -e "${YELLOW}Access your apps at:${NC}"
echo -e "   Admin:      http://100000.localhost:8080/admin/"
echo -e "   Assessment: http://100000.localhost:8080/assessment/"
echo -e "   Academy:    http://100000.localhost:8080/academy/"
echo ""
