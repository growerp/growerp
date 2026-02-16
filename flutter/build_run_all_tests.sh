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
Usage: $(basename "$0") [options] [package_filter]

Rebuild and run all GrowERP frontend and backend tests.
Search for [E] in the output to find errors.

Arguments:
  package_filter   Optional filter string. Only test packages whose name
                   contains this string (e.g. "marketing", "catalog").

Options:
  -h, --help       Show this help message and exit.

Examples:
  $(basename "$0")                  # Run all tests
  $(basename "$0") marketing        # Only test packages containing "marketing"
  $(basename "$0") catalog          # Only test packages containing "catalog"

Steps performed:
  1. Run Selenium hotel/admin tests (PopRestStore)
  2. Tear down any previous Docker test containers
  3. Copy the repo to /tmp/growerp for an isolated build
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

# Export package filter for docker-compose to pick up
export PACKAGE_FILTER="${1:-}"
echo "Package filter: ${PACKAGE_FILTER:-<none - running all tests>}"
## run selenium tests
# cd "$REPO_ROOT/moqui/runtime/component/PopRestStore/selenium" && \
#    npm install && \
#    npm run  testHotel && \
#    npm run testAdmin1 && \
#    npm run testAdmin2 && \
#    npm run testAdmin3 && \
#    cd -

# Tear down previous test containers (use flutter dir where compose file lives)
cd "$SCRIPT_DIR" && docker compose -f docker-compose-test.yml down
docker system prune -f
# docker volume prune -af

# Run directly from source location for faster iteration
cd "$SCRIPT_DIR" || { echo "ERROR: Could not change to $SCRIPT_DIR"; exit 1; }
PACKAGE_FILTER="$PACKAGE_FILTER" docker compose -f docker-compose-test.yml up


