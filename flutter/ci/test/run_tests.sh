#! /bin/bash
#
# Headless test runner for GrowERP Flutter integration tests.
# Runs on Linux desktop with xvfb (virtual framebuffer) — no Android emulator needed.
#
# Environment variables (set by docker-compose-test.yml):
#   BACKEND_URL   — REST backend URL (default: http://moqui)
#   CHAT_URL      — WebSocket URL (default: ws://moqui)
#   SCREEN_WIDTH  — Logical screen width in px (default: 412, phone emulation)
#   SCREEN_HEIGHT — Logical screen height in px (default: 732)
#   PACKAGE_FILTER — Only test packages matching this string (optional)
#   PACKAGE_SLICE  — Run a slice of all packages, format "N/TOTAL" e.g. "2/4" (optional)
#   TEST_FILE      — Run a single test file (optional)
#
set -x
echo "Starting Linux desktop headless test runner..."

# When running as non-root (host UID), use root's pub-cache which was made
# world-writable in the Dockerfile. Also ensure HOME is set for git/flutter.
export HOME=${HOME:-/home/mobiledevops}
export PUB_CACHE=/root/.pub-cache
export PATH="$PATH:/root/.pub-cache/bin"

# git safe directory (mounted volume may have different owner)
git config --global --add safe.directory '*' 2>/dev/null || 
  git config --system --add safe.directory '*' 2>/dev/null || true

# Ensure melos is available (pre-installed in image, but verify)
which melos || dart pub global activate melos

# Purge all .dart_tool directories from the mounted volume.
# The host machine's .dart_tool/package_config.json files contain paths
# like ../../../../../hans/development/flutter/ which don't exist inside
# the container.  Removing them before melos bootstrap ensures fresh
# package configs with correct Docker-internal paths.
echo "Purging stale .dart_tool directories from host volume..."
find packages -name '.dart_tool' -type d -exec rm -rf {} + 2>/dev/null || true

# Also clean build/ directories to avoid incremental-build artifacts
# that reference stale package_config paths.
echo "Cleaning stale build artifacts..."
melos exec --dir-exists="integration_test" --concurrency=4 -- flutter clean 2>/dev/null || true

# Bootstrap workspace — regenerates .dart_tool/package_config.json in every
# package with paths correct for the Docker container.
melos bootstrap

# Run code generation (freezed, json_serializable, retrofit).
# The volume mount overwrites the Docker image's generated *.freezed.dart /
# *.g.dart files with the unbuilt host checkout, so we must regenerate them
# here — after bootstrap but before any flutter build or test commands.
echo "Running code generation (melos build)..."
melos build --no-select

# Enable Linux desktop if not already enabled
if ! flutter config | grep -q 'enable-linux-desktop: true'; then
  echo "Enabling Linux desktop support..."
  flutter config --enable-linux-desktop
fi

# Start Xvfb as a persistent background daemon.
# Using xvfb-run wraps only a single command; when melos launches multiple
# flutter test processes sequentially, the display goes stale after the first
# one finishes, causing "The log reader stopped unexpectedly".
# By running Xvfb as a daemon we keep the display alive for the entire session.
export DISPLAY=:99
Xvfb :99 -screen 0 1024x768x24 -ac +extension GLX +render -noreset &
XVFB_PID=$!
sleep 2
if ! kill -0 $XVFB_PID 2>/dev/null; then
  echo "ERROR: Xvfb failed to start"
  exit 1
fi
echo "Xvfb started on DISPLAY=$DISPLAY (PID $XVFB_PID)"

# Defaults for environment variables
export BACKEND_URL="${BACKEND_URL:-http://moqui}"
export CHAT_URL="${CHAT_URL:-ws://moqui}"
export SCREEN_WIDTH="${SCREEN_WIDTH:-412}"
export SCREEN_HEIGHT="${SCREEN_HEIGHT:-732}"

# Wait for Moqui backend to be ready (docker-compose healthcheck handles this,
# but belt-and-suspenders for standalone usage)
echo "Verifying Moqui backend connectivity at $BACKEND_URL ..."
TIMEOUT=120
ELAPSED=0
while [ $ELAPSED -lt $TIMEOUT ]; do
  if curl -sf "${BACKEND_URL}/status" -o /dev/null 2>/dev/null; then
    echo "Moqui backend is ready."
    break
  fi
  echo "Waiting for Moqui... ($ELAPSED/$TIMEOUT seconds)"
  sleep 5
  ELAPSED=$((ELAPSED + 5))
done
if [ $ELAPSED -ge $TIMEOUT ]; then
  echo "ERROR: Moqui backend not ready after $TIMEOUT seconds at $BACKEND_URL"
  exit 1
fi

# Quick connectivity test
echo "Testing backend connectivity..."
HTTP_CODE=$(curl -s --max-time 10 \
  "${BACKEND_URL}/rest/s1/growerp/100/CheckEmail?email=test@test.com" \
  -o /dev/null -w "%{http_code}")
echo "Backend connectivity test: HTTP $HTTP_CODE"

# Ensure the initial GrowERP admin user exists.
# On a fresh database (DB_DATA=INSTALL), seed data creates the GROWERP owner
# party but no user accounts.  The first call to the Register endpoint with
# userGroupId=GROWERP_M_ADMIN triggers create#Tenant which sets up the initial
# company and admin user.  Subsequent tests rely on this user existing.
echo "Checking / creating initial GrowERP admin user..."
INIT_EMAIL="test0@example.com"
CHECK_RESULT=$(curl -s --max-time 10 \
  "${BACKEND_URL}/rest/s1/growerp/100/CheckEmail?email=${INIT_EMAIL}")
EMAIL_EXISTS=$(echo "$CHECK_RESULT" | grep -o '"ok" *: *true' || true)

if [ -z "$EMAIL_EXISTS" ]; then
  echo "Initial admin user not found — registering ${INIT_EMAIL} ..."
  REG_RESPONSE=$(curl -s --max-time 30 -X POST \
    -H "Content-Type: application/json" \
    -d "{
      \"classificationId\": \"AppAdmin\",
      \"firstName\": \"Test\",
      \"lastName\": \"Admin\",
      \"email\": \"${INIT_EMAIL}\",
      \"userGroupId\": \"GROWERP_M_ADMIN\"
    }" \
    "${BACKEND_URL}/rest/s1/growerp/100/Register")
  echo "Registration response: $REG_RESPONSE"
  # Verify registration succeeded (response should contain ownerPartyId)
  if echo "$REG_RESPONSE" | grep -q "ownerPartyId"; then
    echo "Initial admin user created successfully."
  else
    echo "WARNING: Initial admin registration may have failed. Tests will attempt their own registration."
  fi
else
  echo "Initial admin user already exists."
fi

# Run tests
if [ -n "$TEST_FILE" ]; then
  echo "Running specific test file: $TEST_FILE"

  # Check if file exists, if not try to find it
  if [ ! -f "$TEST_FILE" ]; then
    FOUND_FILE=$(find packages -name "$(basename "$TEST_FILE")" -type f 2>/dev/null | head -1)
    if [ -n "$FOUND_FILE" ]; then
      echo "Found test file at: $FOUND_FILE"
      TEST_FILE="$FOUND_FILE"
    else
      echo "ERROR: Could not find test file: $TEST_FILE"
      find packages -path "*/integration_test/*.dart" -type f | head -20
      exit 1
    fi
  fi

  # Extract package directory from test file path
  PACKAGE_DIR="${TEST_FILE%/integration_test/*}"
  if [ -z "$PACKAGE_DIR" ] || [ "$PACKAGE_DIR" = "$TEST_FILE" ]; then
    echo "ERROR: Failed to extract package directory from: $TEST_FILE"
    exit 1
  fi

  if [ -d "$PACKAGE_DIR" ] && [ -f "$PACKAGE_DIR/pubspec.yaml" ]; then
    echo "Running test from package directory: $PACKAGE_DIR"
    cd "$PACKAGE_DIR" || exit 1
    # Don't flutter clean here — it would delete package_config.json.
    # The startup cleanup already handled stale artifacts.
    flutter pub get

    TEST_FILE_RELATIVE="${TEST_FILE#$PACKAGE_DIR/}"
    echo "Test file: $TEST_FILE_RELATIVE"

    flutter test -d linux "$TEST_FILE_RELATIVE" \
        --dart-define=BACKEND_URL="$BACKEND_URL" \
        --dart-define=CHAT_URL="$CHAT_URL" \
        --dart-define=SCREEN_WIDTH="$SCREEN_WIDTH" \
        --dart-define=SCREEN_HEIGHT="$SCREEN_HEIGHT"
    TEST_EXIT=$?
    cd - > /dev/null || true
  else
    echo "ERROR: Could not find package directory for test: $TEST_FILE"
    TEST_EXIT=1
  fi

elif [ -n "$PACKAGE_FILTER" ]; then
  echo "Running tests for packages matching: *${PACKAGE_FILTER}*"
  melos exec --scope="*${PACKAGE_FILTER}*" --dir-exists="integration_test" --concurrency=1 -- \
    "flutter pub get && flutter test integration_test -d linux \
      --dart-define=BACKEND_URL=$BACKEND_URL \
      --dart-define=CHAT_URL=$CHAT_URL \
      --dart-define=SCREEN_WIDTH=$SCREEN_WIDTH \
      --dart-define=SCREEN_HEIGHT=$SCREEN_HEIGHT"
  TEST_EXIT=$?
else
  echo "Running all tests sequentially by package..."

  WORKSPACE_ROOT="$(pwd)"

  # Build ordered package list from pubspec.yaml (melos order), filtered to
  # packages that actually have an integration_test/ directory.
  mapfile -t PACKAGES_WITH_TESTS < <(
    grep '^\s*- packages/' pubspec.yaml | sed 's/.*- //' | tr -d ' \r' | while IFS= read -r pkg_path; do
      [ -d "${pkg_path}/integration_test" ] && echo "$pkg_path"
    done
  )

  echo "Packages with integration tests (${#PACKAGES_WITH_TESTS[@]}):"
  for p in "${PACKAGES_WITH_TESTS[@]}"; do echo "  $p"; done

  # Apply slicing if PACKAGE_SLICE is set (e.g. "2/4" = second quarter of all packages)
  if [ -n "$PACKAGE_SLICE" ]; then
    SLICE_NUM="${PACKAGE_SLICE%/*}"
    SLICE_TOTAL="${PACKAGE_SLICE#*/}"
    TOTAL_PKGS=${#PACKAGES_WITH_TESTS[@]}
    SLICE_SIZE=$(( (TOTAL_PKGS + SLICE_TOTAL - 1) / SLICE_TOTAL ))
    START=$(( (SLICE_NUM - 1) * SLICE_SIZE ))
    END=$(( START + SLICE_SIZE ))
    [ $END -gt $TOTAL_PKGS ] && END=$TOTAL_PKGS
    echo "Slice $PACKAGE_SLICE: running packages $((START+1))-$END of $TOTAL_PKGS"
    PACKAGES_WITH_TESTS=("${PACKAGES_WITH_TESTS[@]:$START:$((END-START))}")
  fi

  FAILED_PACKAGES=()
  ALL_FAILED_TESTS=()

  for pkg_path in "${PACKAGES_WITH_TESTS[@]}"; do
    PKG_NAME=$(basename "$pkg_path")
    PARENT_NAME=$(basename "$(dirname "$pkg_path")")
    # Display as "growerp_catalog_example" or just "admin"
    if [ "$PKG_NAME" = "example" ]; then
      DISPLAY_NAME="${PARENT_NAME}_example"
    else
      DISPLAY_NAME="$PKG_NAME"
    fi

    echo ""
    echo "============================================================"
    echo "=== Package: $DISPLAY_NAME ($pkg_path)"
    echo "============================================================"

    PKG_LOG=$(mktemp /tmp/pkg_test_XXXXXX.log)

    (
      cd "$WORKSPACE_ROOT/$pkg_path" || exit 1
      if [ ! -d "linux" ]; then
        echo "Linux platform not found — adding Linux support..."
        flutter create --platforms=linux .
      fi
      FAIL=0
      for f in integration_test/*.dart; do
        flutter test "$f" -d linux \
          --dart-define=BACKEND_URL="$BACKEND_URL" \
          --dart-define=CHAT_URL="$CHAT_URL" \
          --dart-define=SCREEN_WIDTH="$SCREEN_WIDTH" \
          --dart-define=SCREEN_HEIGHT="$SCREEN_HEIGHT" || FAIL=1
      done
      exit $FAIL
    ) 2>&1 | tee "$PKG_LOG"
    PKG_EXIT=${PIPESTATUS[0]}

    if [ $PKG_EXIT -eq 0 ]; then
      echo ">>> RESULT: $DISPLAY_NAME PASSED <<<"
    else
      echo ">>> RESULT: $DISPLAY_NAME FAILED <<<"
      FAILED_PACKAGES+=("$DISPLAY_NAME")
      while IFS= read -r line; do
        [ -n "$line" ] && ALL_FAILED_TESTS+=("[$DISPLAY_NAME] $line")
      done < <(grep -E '\[E\]| FAILED$' "$PKG_LOG" || true)
    fi

    rm -f "$PKG_LOG"
  done

  echo ""
  echo "============================================================"
  echo "=== FINAL TEST SUMMARY"
  echo "============================================================"
  echo "Packages tested : ${#PACKAGES_WITH_TESTS[@]}"
  echo "Packages failed : ${#FAILED_PACKAGES[@]}"

  if [ ${#FAILED_PACKAGES[@]} -gt 0 ]; then
    echo ""
    echo "Failed packages:"
    for pkg in "${FAILED_PACKAGES[@]}"; do
      echo "  - $pkg"
    done
    echo ""
    echo "Failed tests:"
    for test_line in "${ALL_FAILED_TESTS[@]}"; do
      echo "  $test_line"
    done
  else
    echo "All packages passed!"
  fi

  [ ${#FAILED_PACKAGES[@]} -eq 0 ]
  TEST_EXIT=$?
fi

# Clean up Xvfb
if [ -n "$XVFB_PID" ] && kill -0 "$XVFB_PID" 2>/dev/null; then
  kill "$XVFB_PID" 2>/dev/null || true
  echo "Xvfb stopped."
fi

exit $TEST_EXIT
