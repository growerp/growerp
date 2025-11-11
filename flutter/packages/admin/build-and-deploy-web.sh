#!/bin/bash

# Build Flutter Admin Web and Assessment App and Deploy to Moqui
# This script builds the Flutter admin web app and assessment app, then deploys both to Moqui

set -e

# Color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
ASSESSMENT_DIR="$PROJECT_ROOT/flutter/packages/assessment"

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

echo -e "\n${YELLOW}Building Flutter Assessment Web Application...${NC}"
pushd "$ASSESSMENT_DIR" > /dev/null
echo -e "Cleaning previous build..."
flutter clean
echo -e "Getting Flutter dependencies..."
flutter pub get
echo -e "Building for web (with source maps)..."
flutter build web --release --wasm
popd > /dev/null
echo -e "${GREEN}✓ Assessment build completed successfully${NC}"

echo -e "\n${YELLOW}Deploying Assessment web build to Moqui...${NC}"
"$SCRIPT_DIR/deploy-web-to-moqui.sh" assessment

echo -e "\n${GREEN}✓✓✓ Admin and Assessment builds deployed successfully! ✓✓✓${NC}"
