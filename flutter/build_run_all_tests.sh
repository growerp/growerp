#! /bin/bash
#
# Rebuild and test frontend and backend
# search for [E] in the result for errors.
#
# Usage: ./build_run_all_tests.sh [options] [package_filter]
# Example: ./build_run_all_tests.sh marketing  # Only tests packages containing "marketing"
#

usage() {
  cat <<EOF
Usage: $(basename "$0") [options] [package_filter|test_file]

Rebuild and run GrowERP frontend and backend tests.
Search for [E] in the output to find errors.

Arguments:
  package_filter   Optional filter string. Only test packages whose name
                   contains this string (e.g. "marketing", "catalog").
  test_file        Optional path to a specific test file to run
                   (e.g. "packages/growerp_core/example/integration_test/dynamic_menu_test.dart")
                   If this looks like a file path (contains "/" or ".dart"), it will be treated as a test file.

Options:
  -h, --help       Show this help message and exit.

Examples:
  $(basename "$0")                  # Run all tests
  $(basename "$0") marketing        # Only test packages containing "marketing"
  $(basename "$0") catalog          # Only test packages containing "catalog"
  $(basename "$0") packages/growerp_core/example/integration_test/dynamic_menu_test.dart  # Run single test

Steps performed:
  1. Run Selenium hotel/admin tests (PopRestStore)
  2. Tear down any previous Docker test containers
  3. Copy the repo to /tmp/growerp for an isolated build (release uses /tmp/growerpRelease, so both can run in parallel)
  4. Start Docker Compose test environment and run Flutter integration tests
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

set -x
clear

# Resolve absolute paths regardless of where the script is invoked from
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# Determine if the argument is a test file or package filter
ARG="${1:-}"
if [[ "$ARG" == *"/"* ]] || [[ "$ARG" == *".dart"* ]]; then
  # It's a test file path - normalize and find it
  TEST_FILE="$ARG"
  
  # Remove leading "flutter/" if present (for consistency when called from repo root)
  TEST_FILE="${TEST_FILE#flutter/}"
  
  # Check if file exists at the given path
  if [ ! -f "$SCRIPT_DIR/$TEST_FILE" ]; then
    # Try to find the file by searching in packages
    echo "Test file not found at: $SCRIPT_DIR/$TEST_FILE"
    echo "Searching in packages..."
    
    # Extract the filename if a partial path was given
    FILENAME=$(basename "$TEST_FILE")
    FOUND_FILES=$(find "$SCRIPT_DIR/packages" -name "$FILENAME" -type f 2>/dev/null)
    
    if [ -z "$FOUND_FILES" ]; then
      echo "ERROR: Test file not found: $ARG"
      echo "Available test files (sample):"
      find "$SCRIPT_DIR/packages" -path "*/integration_test/*.dart" -type f | head -10
      exit 1
    fi
    
    # Count matches
    MATCH_COUNT=$(echo "$FOUND_FILES" | wc -l)
    if [ "$MATCH_COUNT" -eq 1 ]; then
      # Single match found
      TEST_FILE=$(echo "$FOUND_FILES" | sed "s|$SCRIPT_DIR/||")
      echo "Found test file: $TEST_FILE"
    else
      # Multiple matches - let user choose or use the first one containing example/
      echo "Found $MATCH_COUNT matching files:"
      echo "$FOUND_FILES" | nl
      
      # Prefer example/ paths
      PREFERRED=$(echo "$FOUND_FILES" | grep "/example/integration_test/" | head -1)
      if [ -n "$PREFERRED" ]; then
        TEST_FILE=$(echo "$PREFERRED" | sed "s|$SCRIPT_DIR/||")
        echo "Using (prefers example/): $TEST_FILE"
      else
        TEST_FILE=$(echo "$FOUND_FILES" | head -1 | sed "s|$SCRIPT_DIR/||")
        echo "Using first match: $TEST_FILE"
      fi
    fi
  fi
  
  export TEST_FILE="$TEST_FILE"
  export PACKAGE_FILTER=""
  echo "Running test file: $TEST_FILE"
else
  # It's a package filter (or empty)
  export PACKAGE_FILTER="$ARG"
  export TEST_FILE=""
  echo "Package filter: ${PACKAGE_FILTER:-<none - running all tests>}"
fi
## run selenium tests
# cd "$REPO_ROOT/moqui/runtime/component/PopRestStore/selenium" && \
#    npm install && \
#    npm run  testHotel && \
#    npm run testAdmin1 && \
#    npm run testAdmin2 && \
#    npm run testAdmin3 && \
#    cd -

# Tear down previous test containers (use flutter dir where compose file lives)
# cd "$SCRIPT_DIR" && docker compose -f ci/docker-compose-test.yml down
# docker system prune -f
# docker volume prune -af

# Copy the flutter directory to /tmp/growerp for an isolated test run
# (release uses /tmp/growerpRelease, so CI and release can run in parallel)
# This prevents test scripts (e.g. sed on app_settings.json) from modifying source files
TMP_DIR="/tmp/growerp"
echo "Copying flutter directory to $TMP_DIR for isolated test run..."

# Remove previous test directory, handling permission issues from Docker root-owned files
if [ -d "$TMP_DIR" ]; then
  if ! rm -rf "$TMP_DIR" 2>/dev/null; then
    # If rm fails due to permissions (Docker files owned by root), try with sudo
    if command -v sudo &> /dev/null && [ "$EUID" -ne 0 ]; then
      echo "Requesting sudo to remove Docker-created root-owned files..."
      sudo rm -rf "$TMP_DIR"
    else
      # If sudo not available or already root, fail
      echo "ERROR: Cannot remove $TMP_DIR due to permission issues. Try running with sudo or manually remove: sudo rm -rf $TMP_DIR"
      exit 1
    fi
  fi
fi

mkdir -p "$TMP_DIR"
cp -a "$SCRIPT_DIR/" "$TMP_DIR/flutter/"
# Copy moqui component for the moqui container volume mount
mkdir -p "$TMP_DIR/moqui/runtime"
cp -a "$REPO_ROOT/moqui/runtime/component" "$TMP_DIR/moqui/runtime/component"

cd "$TMP_DIR/flutter" || { echo "ERROR: Could not change to $TMP_DIR/flutter"; exit 1; }
# Stop and restart backend services to ensure fresh state with correct volume mounts
docker compose -f ci/docker-compose-test.yml down moqui 2>/dev/null || true
docker compose -f ci/docker-compose-test.yml up -d moqui-database moqui emulator

# Wait for moqui to be ready (check REST API)
echo "Waiting for Moqui backend to be ready..."
MOQUI_TIMEOUT=120
MOQUI_ELAPSED=0
while [ $MOQUI_ELAPSED -lt $MOQUI_TIMEOUT ]; do
  if docker compose -f ci/docker-compose-test.yml exec -T moqui curl -sf http://localhost/status 2>/dev/null; then
    echo "Moqui is ready"
    break
  fi
  echo "Waiting for Moqui... ($MOQUI_ELAPSED/$MOQUI_TIMEOUT seconds)"
  sleep 5
  MOQUI_ELAPSED=$((MOQUI_ELAPSED+5))
done

# Run tests
PACKAGE_FILTER="$PACKAGE_FILTER" TEST_FILE="$TEST_FILE" docker compose -f ci/docker-compose-test.yml up sut


