#!/bin/bash

# Script to upgrade all Flutter packages to major versions using melos
# This script runs the upgrade sequentially to avoid conflicts

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

print_info "Starting major version upgrade for all packages..."

# Get list of packages from melos.yaml
mapfile -t packages < <(yq eval '.packages[]' "$SCRIPT_DIR/melos.yaml")

if [ ${#packages[@]} -eq 0 ]; then
    print_error "No packages found in melos.yaml"
    exit 1
fi

print_info "Found ${#packages[@]} packages to upgrade"

# Keep track of success/failure
declare -a successful_packages=()
declare -a failed_packages=()

# Function to upgrade a single package
upgrade_package() {
    local package_path="$1"
    local full_path="$SCRIPT_DIR/$package_path"
    
    if [ ! -d "$full_path" ]; then
        print_warning "Package directory not found: $full_path"
        return 1
    fi
    
    if [ ! -f "$full_path/pubspec.yaml" ]; then
        print_warning "No pubspec.yaml found in: $full_path"
        return 1
    fi
    
    print_info "Upgrading package: $package_path"
    
    # Change to package directory and run upgrade
    cd "$full_path"
    
    # Run flutter pub upgrade --major-versions
    if flutter pub upgrade --major-versions; then
        print_success "Successfully upgraded: $package_path"
        successful_packages+=("$package_path")
        return 0
    else
        print_error "Failed to upgrade: $package_path"
        failed_packages+=("$package_path")
        return 1
    fi
}

# Upgrade each package
for package in "${packages[@]}"; do
    upgrade_package "$package"
    echo "" # Add some spacing
done

# Return to original directory
cd "$SCRIPT_DIR"

# Print summary
echo ""
print_info "=== UPGRADE SUMMARY ==="

if [ ${#successful_packages[@]} -gt 0 ]; then
    print_success "Successfully upgraded ${#successful_packages[@]} packages:"
    for pkg in "${successful_packages[@]}"; do
        echo "  ✓ $pkg"
    done
fi

if [ ${#failed_packages[@]} -gt 0 ]; then
    print_error "Failed to upgrade ${#failed_packages[@]} packages:"
    for pkg in "${failed_packages[@]}"; do
        echo "  ✗ $pkg"
    done
fi

# Run melos bootstrap after all upgrades
print_info "Running melos bootstrap to resolve dependencies..."
if melos bootstrap; then
    print_success "Melos bootstrap completed successfully"
else
    print_error "Melos bootstrap failed"
    exit 1
fi

print_success "Major version upgrade process completed!"

# Optionally run analysis
read -p "Do you want to run 'melos analyze' to check for any issues? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "Running melos analyze..."
    melos analyze
fi

