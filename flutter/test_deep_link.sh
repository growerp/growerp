#!/bin/bash

# Deep Link Testing Script for GrowERP Apps
# This script helps test deep links on Android and iOS devices/emulators

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show usage
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Test deep links for GrowERP apps on Android and iOS.

OPTIONS:
    -p, --platform PLATFORM    Platform to test (android|ios)
    -a, --app APP             App to test (admin|support|hotel)
    -r, --route ROUTE         Route to test (e.g., /user, /catalog/products)
    -s, --scheme SCHEME       Scheme to use (custom|https) [default: custom]
    -h, --help                Show this help message

EXAMPLES:
    # Test admin app with custom scheme on Android
    $0 -p android -a admin -r /user

    # Test support app with HTTPS on iOS
    $0 -p ios -a support -r /catalog/products -s https

    # Interactive mode (no arguments)
    $0

EOF
}

# Parse command line arguments
PLATFORM=""
APP=""
ROUTE=""
SCHEME="custom"

while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--platform)
            PLATFORM="$2"
            shift 2
            ;;
        -a|--app)
            APP="$2"
            shift 2
            ;;
        -r|--route)
            ROUTE="$2"
            shift 2
            ;;
        -s|--scheme)
            SCHEME="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Interactive mode if no arguments provided
if [ -z "$PLATFORM" ]; then
    echo "Select platform:"
    echo "1) Android"
    echo "2) iOS"
    read -p "Enter choice [1-2]: " platform_choice
    case $platform_choice in
        1) PLATFORM="android" ;;
        2) PLATFORM="ios" ;;
        *) print_error "Invalid choice"; exit 1 ;;
    esac
fi

if [ -z "$APP" ]; then
    echo ""
    echo "Select app:"
    echo "1) Admin"
    echo "2) Support"
    echo "3) Hotel"
    read -p "Enter choice [1-3]: " app_choice
    case $app_choice in
        1) APP="admin" ;;
        2) APP="support" ;;
        3) APP="hotel" ;;
        *) print_error "Invalid choice"; exit 1 ;;
    esac
fi

if [ -z "$ROUTE" ]; then
    echo ""
    echo "Enter route to test (e.g., /user, /catalog/products):"
    read -p "Route: " ROUTE
fi

if [ -z "$SCHEME" ]; then
    echo ""
    echo "Select scheme:"
    echo "1) Custom (growerp://)"
    echo "2) HTTPS"
    read -p "Enter choice [1-2]: " scheme_choice
    case $scheme_choice in
        1) SCHEME="custom" ;;
        2) SCHEME="https" ;;
        *) print_error "Invalid choice"; exit 1 ;;
    esac
fi

# Validate inputs
if [[ ! "$PLATFORM" =~ ^(android|ios)$ ]]; then
    print_error "Invalid platform: $PLATFORM (must be android or ios)"
    exit 1
fi

if [[ ! "$APP" =~ ^(admin|support|hotel)$ ]]; then
    print_error "Invalid app: $APP (must be admin, support, or hotel)"
    exit 1
fi

if [[ ! "$SCHEME" =~ ^(custom|https)$ ]]; then
    print_error "Invalid scheme: $SCHEME (must be custom or https)"
    exit 1
fi

# Ensure route starts with /
if [[ ! "$ROUTE" =~ ^/ ]]; then
    ROUTE="/$ROUTE"
fi

# Build the deep link URL
if [ "$SCHEME" = "custom" ]; then
    DEEP_LINK="growerp://${APP}${ROUTE}"
else
    DEEP_LINK="https://${APP}.growerp.com${ROUTE}"
fi

# Get package name
PACKAGE_NAME="org.growerp.${APP}"

print_info "Testing deep link: $DEEP_LINK"
print_info "Platform: $PLATFORM"
print_info "App: $APP"
print_info "Package: $PACKAGE_NAME"

# Test based on platform
if [ "$PLATFORM" = "android" ]; then
    # Check if adb is available
    if ! command -v adb &> /dev/null; then
        print_error "adb not found. Please install Android SDK Platform Tools."
        exit 1
    fi

    # Check if device/emulator is connected
    if ! adb devices | grep -q "device$"; then
        print_error "No Android device/emulator connected."
        print_info "Please start an emulator or connect a device."
        exit 1
    fi

    print_info "Launching deep link on Android..."
    adb shell am start -W -a android.intent.action.VIEW -d "$DEEP_LINK" "$PACKAGE_NAME"
    
    if [ $? -eq 0 ]; then
        print_info "Deep link launched successfully!"
    else
        print_error "Failed to launch deep link."
        exit 1
    fi

elif [ "$PLATFORM" = "ios" ]; then
    # Check if xcrun is available
    if ! command -v xcrun &> /dev/null; then
        print_error "xcrun not found. Please install Xcode."
        exit 1
    fi

    # Get booted simulator
    BOOTED_SIM=$(xcrun simctl list devices | grep "Booted" | head -1)
    if [ -z "$BOOTED_SIM" ]; then
        print_error "No iOS simulator is running."
        print_info "Please start an iOS simulator."
        exit 1
    fi

    print_info "Launching deep link on iOS simulator..."
    xcrun simctl openurl booted "$DEEP_LINK"
    
    if [ $? -eq 0 ]; then
        print_info "Deep link launched successfully!"
    else
        print_error "Failed to launch deep link."
        exit 1
    fi
fi

echo ""
print_info "Test completed!"
print_info "If the app didn't open the correct screen, check:"
print_info "  1. The app is installed"
print_info "  2. The route exists in the app"
print_info "  3. Deep linking is properly configured"
print_info ""
print_info "For HTTPS links, ensure server configuration is complete."
print_info "See docs/deep_linking.md for more information."
