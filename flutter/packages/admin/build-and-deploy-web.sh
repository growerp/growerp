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

echo -e "${YELLOW}Building Flutter Admin Web Application...${NC}"

# Clean previous build
echo -e "Cleaning previous build..."
flutter clean

# Get dependencies
echo -e "Getting Flutter dependencies..."
flutter pub get

# Build for web
echo -e "Building for web..."
flutter build web --release

echo -e "${GREEN}✓ Flutter build completed successfully${NC}"

# Deploy to Moqui
echo -e "\n${YELLOW}Deploying to Moqui...${NC}"
"$SCRIPT_DIR/deploy-web-to-moqui.sh"

echo -e "\n${GREEN}✓✓✓ Build and deployment completed successfully! ✓✓✓${NC}"
