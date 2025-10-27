#!/bin/bash

# Build Flutter Admin Web and Deploy to Moqui
# This script builds the Flutter admin web app and deploys it to Moqui

set -e

# Color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
LANDING_PAGE_DIR="$PROJECT_ROOT/flutter/packages/landing_page"

echo -e "${YELLOW}Building Flutter Admin Web Application...${NC}"
pushd "$SCRIPT_DIR" > /dev/null
echo -e "Cleaning previous build..."
flutter clean
echo -e "Getting Flutter dependencies..."
flutter pub get
echo -e "Building for web (with source maps)..."
flutter build web --release --wasm
popd > /dev/null
echo -e "${GREEN}✓ Flutter Admin build completed successfully${NC}"

echo -e "\n${YELLOW}Deploying Admin web build to Moqui...${NC}"
"$SCRIPT_DIR/deploy-web-to-moqui.sh" admin

echo -e "\n${YELLOW}Building Flutter Landing Page Web Application...${NC}"
pushd "$LANDING_PAGE_DIR" > /dev/null
echo -e "Cleaning previous build..."
flutter clean
echo -e "Getting Flutter dependencies..."
flutter pub get
echo -e "Building for web (with source maps)..."
flutter build web --release --wasm
popd > /dev/null
echo -e "${GREEN}✓ Landing Page build completed successfully${NC}"

echo -e "\n${YELLOW}Deploying Landing Page web build to Moqui...${NC}"
"$SCRIPT_DIR/deploy-web-to-moqui.sh" landingpage

echo -e "\n${GREEN}✓✓✓ Admin and Landing Page builds deployed successfully! ✓✓✓${NC}"
