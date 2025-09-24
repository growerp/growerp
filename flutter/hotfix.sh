#!/bin/bash

# GrowERP Hot Fix Release Launcher
# This script launches the hot fix tool from the hotfix subdirectory

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOTFIX_SCRIPT="$SCRIPT_DIR/hotfix/hotfix_release.sh"

if [[ ! -f "$HOTFIX_SCRIPT" ]]; then
    echo "Error: Hot fix script not found at $HOTFIX_SCRIPT"
    exit 1
fi

echo "🚀 Launching GrowERP Hot Fix Release Tool..."
exec "$HOTFIX_SCRIPT" "$@"