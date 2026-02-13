#! /bin/bash
#
# Rebuild and test frontend and backend
# search for [E] in the result for errors.
#
# Usage: ./build_run_all_tests.sh [package_filter]
# Example: ./build_run_all_tests.sh marketing  # Only tests packages containing "marketing"
#
set -x
clear

# Resolve absolute paths regardless of where the script is invoked from
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# Export package filter for docker-compose to pick up
export PACKAGE_FILTER="${1:-}"
echo "Package filter: ${PACKAGE_FILTER:-<none - running all tests>}"
## run selenium tests
cd "$REPO_ROOT/moqui/runtime/component/PopRestStore/selenium" && \
    npm run  testHotel && \
    npm run testAdmin1 && \
    npm run testAdmin2 && \
    npm run testAdmin3 && \
    cd -

docker compose -f docker-compose.test.yml down
docker image rm flutter-sut:latest -f
docker image rm flutter-moqui:latest -f
docker system prune -f
# docker volume prune -af
rm -rf /tmp/growerp
cp -r "$REPO_ROOT" /tmp/growerp
cd /tmp/growerp/flutter || { echo "ERROR: /tmp/growerp/flutter not found after copy"; exit 1; }
PACKAGE_FILTER="$PACKAGE_FILTER" docker compose -f docker-compose-test.yml up


