#!/bin/bash

# GrowERP Hot Fix Release Script Wrapper
# This script ensures the proper environment and runs the Dart hot fix script

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DART_SCRIPT="$SCRIPT_DIR/hotfix_release.dart"

# Check if we're in the flutter directory or hotfix subdirectory
if [[ -f "../melos.yaml" ]]; then
    # We're in the hotfix subdirectory, move to flutter directory
    cd ..
elif [[ ! -f "melos.yaml" ]]; then
    echo "Error: This script must be run from the flutter directory or flutter/hotfix directory"
    echo "Current directory: $(pwd)"
    echo "Expected to find: melos.yaml (in flutter dir) or ../melos.yaml (in hotfix dir)"
    exit 1
fi

# Check if dart is available
if ! command -v dart &> /dev/null; then
    echo "Error: Dart is not installed or not in PATH"
    exit 1
fi

# Ensure pub dependencies are available
if [[ ! -f "pubspec.lock" ]]; then
    echo "Installing pub dependencies..."
    dart pub get
fi

# Check if dcli is installed
if ! dart pub deps | grep -q "dcli"; then
    echo "Installing dcli..."
    dart pub global activate dcli
    dcli install
fi

# Check if we're in a git repository
if [[ ! -d ".git" ]] && [[ ! -d "../.git" ]]; then
    echo "Error: This script must be run from within a git repository"
    exit 1
fi

# Check if there are uncommitted changes
if ! git diff-index --quiet HEAD --; then
    echo "Warning: You have uncommitted changes in your working directory."
    echo "The hot fix process will create a new branch, but you may want to"
    echo "commit or stash your changes first."
    echo ""
    read -p "Continue anyway? [y/N]: " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Hot fix cancelled."
        exit 1
    fi
fi

# Check if Docker is running
if ! docker info &> /dev/null; then
    echo "Error: Docker is not running. Please start Docker first."
    exit 1
fi

echo "Starting GrowERP Hot Fix Release Process..."
echo "============================================"

# Run the Dart script
dart "$DART_SCRIPT" "$@"