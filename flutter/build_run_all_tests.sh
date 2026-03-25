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
Tests run on Linux desktop with xvfb (no Android emulator needed).
Search for [E] in the output to find errors.

Arguments:
  package_filter   Optional filter string. Only test packages whose name
                   contains this string (e.g. "marketing", "catalog").
  test_file        Optional path to a specific test file to run
                   (e.g. "packages/growerp_core/example/integration_test/dynamic_menu_test.dart")
                   If this looks like a file path (contains "/" or ".dart"), it will be treated as a test file.

Options:
  -h, --help       Show this help message and exit.

Environment variables:
  PACKAGE_SLICE    Run one of 4 parallel slices, e.g. PACKAGE_SLICE=2/4.
                   Ignored when package_filter or test_file is provided.

Examples:
  $(basename "$0")                  # Run all tests
  $(basename "$0") marketing        # Only test packages containing "marketing"
  $(basename "$0") catalog          # Only test packages containing "catalog"
  $(basename "$0") packages/growerp_core/example/integration_test/dynamic_menu_test.dart  # Run single test
  PACKAGE_SLICE=1/4 $(basename "$0")   # Run slice 1 of 4
  PACKAGE_SLICE=2/4 $(basename "$0")   # Run slice 2 of 4
  PACKAGE_SLICE=3/4 $(basename "$0")   # Run slice 3 of 4
  PACKAGE_SLICE=4/4 $(basename "$0")   # Run slice 4 of 4

Steps performed:
  1. Start Docker Compose services (postgres, moqui)
  2. Wait for Moqui backend to be healthy
  3. Run Flutter integration tests on Linux desktop via xvfb
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

set -x
clear

START_TIME=$(date +%s)

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
    echo "Test file not found at: $SCRIPT_DIR/$TEST_FILE"
    echo "Searching in packages..."

    FILENAME=$(basename "$TEST_FILE")
    FOUND_FILES=$(find "$SCRIPT_DIR/packages" -name "$FILENAME" -type f 2>/dev/null)

    if [ -z "$FOUND_FILES" ]; then
      echo "ERROR: Test file not found: $ARG"
      echo "Available test files (sample):"
      find "$SCRIPT_DIR/packages" -path "*/integration_test/*.dart" -type f | head -10
      exit 1
    fi

    MATCH_COUNT=$(echo "$FOUND_FILES" | wc -l)
    if [ "$MATCH_COUNT" -eq 1 ]; then
      TEST_FILE=$(echo "$FOUND_FILES" | sed "s|$SCRIPT_DIR/||")
      echo "Found test file: $TEST_FILE"
    else
      echo "Found $MATCH_COUNT matching files:"
      echo "$FOUND_FILES" | nl
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
  export PACKAGE_FILTER="$ARG"
  export TEST_FILE=""
  echo "Package filter: ${PACKAGE_FILTER:-<none - running all tests>}"
fi

cd "$SCRIPT_DIR" || { echo "ERROR: Could not change to $SCRIPT_DIR"; exit 1; }

# Export host UID/GID so the container creates files with the correct ownership
export HOST_UID=$(id -u)
export HOST_GID=$(id -g)

# Rebuild the test runner image to pick up Dockerfile changes (e.g. xvfb, Linux deps)
echo "Building test runner image..."
docker compose -f ci/docker-compose-test.yml build sut

# Start backend services (no emulator needed — tests run on Linux desktop)
docker compose -f ci/docker-compose-test.yml down moqui 2>/dev/null || true
docker compose -f ci/docker-compose-test.yml up -d moqui-database moqui

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

# Run tests — capture output for post-run failure summary
LOG_FILE=$(mktemp /tmp/growerp_test_XXXXXX.log)
PACKAGE_FILTER="$PACKAGE_FILTER" TEST_FILE="$TEST_FILE" PACKAGE_SLICE="${PACKAGE_SLICE:-}" \
  docker compose -f ci/docker-compose-test.yml up --exit-code-from sut sut 2>&1 | tee "$LOG_FILE"
TEST_EXIT_CODE=${PIPESTATUS[0]}

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
HOURS=$((ELAPSED / 3600))
MINUTES=$(( (ELAPSED % 3600) / 60 ))
SECONDS=$((ELAPSED % 60))
echo "Total runtime: ${HOURS}h ${MINUTES}m ${SECONDS}s"

# Show a summary of failed tests
echo ""
echo "=== FAILED TESTS ==="
FAILED_LINES=$(grep -E ' FAILED$|\[E\]' "$LOG_FILE" || true)
if [ -z "$FAILED_LINES" ]; then
  echo "No failures detected."
else
  echo "$FAILED_LINES"
fi
rm -f "$LOG_FILE"

exit $TEST_EXIT_CODE
