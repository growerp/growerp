#!/bin/bash

# GrowERP Production Release Tool Launcher
# This script provides environment validation and dependency management

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 GrowERP Production Release Tool${NC}"
echo "======================================"

# Function to print colored output
print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠️${NC} $1"
}

print_error() {
    echo -e "${RED}❌${NC} $1"
}

# Validate environment
validate_environment() {
    echo "Validating environment..."
    
    # Check if we're in the right directory
    if [[ -f "melos.yaml" || -f "pubspec.yaml" ]]; then
        print_status "Running from flutter directory"
    elif [[ (-f "../melos.yaml" || -f "../pubspec.yaml") && -f "release_tool.dart" ]]; then
        print_status "Running from release directory"
        cd ..
    else
        print_error "Please run this script from the flutter directory or flutter/release directory"
        exit 1
    fi
    
    # Check for required directories
    if [[ ! -d "../moqui" || ! -d "packages" ]]; then
        print_error "Please run this script from the flutter directory of the GrowERP project"
        exit 1
    fi
    
    # Check Git
    if ! command -v git &> /dev/null; then
        print_error "Git is not installed or not in PATH"
        exit 1
    fi
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed or not in PATH"
        exit 1
    fi
    
    # Check Dart
    if ! command -v dart &> /dev/null; then
        print_error "Dart is not installed or not in PATH"
        exit 1
    fi
    
    print_status "Environment validation completed"
}

# Install dependencies
install_dependencies() {
    echo "Checking and installing dependencies..."
    
    # Check if dcli is installed
    if ! dart pub global list | grep -q "dcli"; then
        echo "Installing dcli..."
        dart pub global activate dcli
        print_status "dcli installed"
    else
        print_status "dcli is already installed"
    fi
    
    # Check if path package is available (it's usually included with Dart)
    print_status "Dependencies ready"
}

# Run the release tool
run_release_tool() {
    local script_path
    
    # Determine script path
    if [[ -f "release/release_tool.dart" ]]; then
        script_path="release/release_tool.dart"
    elif [[ -f "release_tool.dart" ]]; then
        script_path="release_tool.dart"
    else
        print_error "Could not find release_tool.dart"
        exit 1
    fi
    
    echo "Starting release tool..."
    dart "$script_path" "$@"
}

# Main execution
main() {
    validate_environment
    install_dependencies
    echo ""
    run_release_tool "$@"
}

# Handle script interruption
trap 'echo -e "\n${YELLOW}Release process interrupted${NC}"; exit 130' INT

# Run main function
main "$@"