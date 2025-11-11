#!/bin/bash

# Quick build and deploy script for Assessment Flutter web app
# Usage: ./build-assessment.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ADMIN_DIR="$SCRIPT_DIR/packages/admin"

echo "Building and deploying Assessment app..."
"$ADMIN_DIR/deploy-web-to-moqui.sh" assessment

echo ""
echo "✓ Assessment app built and deployed!"
echo "⚠️  Restart Moqui for changes to take effect"
