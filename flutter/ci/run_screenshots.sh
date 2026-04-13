#!/usr/bin/env bash
#
# Screenshot runner for GrowERP hotel store screenshots.
# Runs flutter drive on Linux desktop with Xvfb so the test_driver
# onScreenshot callback can write PNG files to packages/hotel/screenshots/.
#
# Environment variables (set by docker-compose-screenshot.yml):
#   BACKEND_URL   — REST backend URL (default: http://moqui)
#   CHAT_URL      — WebSocket URL    (default: ws://moqui)
#   SCREEN_WIDTH  — Logical screen width  (default: 412)
#   SCREEN_HEIGHT — Logical screen height (default: 892)
#
set -euo pipefail

echo "=== GrowERP screenshot runner ==="

export HOME=${HOME:-/home/mobiledevops}
export PUB_CACHE=/root/.pub-cache
export PATH="$PATH:/root/.pub-cache/bin"

git config --global --add safe.directory '*' 2>/dev/null || true

which melos || dart pub global activate melos

# Purge stale .dart_tool dirs from mounted host volume
echo "Purging stale .dart_tool directories..."
find packages -name '.dart_tool' -type d -exec rm -rf {} + 2>/dev/null || true

echo "Cleaning stale build artefacts..."
melos exec --dir-exists="integration_test" --concurrency=4 -- flutter clean 2>/dev/null || true

melos bootstrap

echo "Running code generation..."
melos build --no-select

if ! flutter config | grep -q 'enable-linux-desktop: true'; then
  flutter config --enable-linux-desktop
fi

export DISPLAY=:99
Xvfb :99 -screen 0 1920x1080x24 -ac +extension GLX +render -noreset &
XVFB_PID=$!
sleep 2
if ! kill -0 "$XVFB_PID" 2>/dev/null; then
  echo "ERROR: Xvfb failed to start"
  exit 1
fi
echo "Xvfb started (PID $XVFB_PID)"

export BACKEND_URL="${BACKEND_URL:-http://moqui}"
export CHAT_URL="${CHAT_URL:-ws://moqui}"
export SCREEN_WIDTH="${SCREEN_WIDTH:-412}"
export SCREEN_HEIGHT="${SCREEN_HEIGHT:-892}"

echo "Verifying Moqui backend at $BACKEND_URL ..."
TIMEOUT=120
ELAPSED=0
while [ $ELAPSED -lt $TIMEOUT ]; do
  if curl -sf "${BACKEND_URL}/status" -o /dev/null 2>/dev/null; then
    echo "Moqui ready."
    break
  fi
  echo "Waiting... ($ELAPSED/$TIMEOUT s)"
  sleep 5
  ELAPSED=$((ELAPSED + 5))
done
[ $ELAPSED -ge $TIMEOUT ] && { echo "ERROR: Moqui not ready"; exit 1; }

PKG_DIR="packages/hotel"
cd "$PKG_DIR"

if [ ! -d "linux" ]; then
  echo "Adding Linux desktop support..."
  flutter create --platforms=linux .
fi

flutter pub get

echo "Running screenshot test (flutter drive) ..."
echo "  SCREEN: ${SCREEN_WIDTH}x${SCREEN_HEIGHT}"
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/screenshot_test.dart \
  -d linux \
  --dart-define="BACKEND_URL=$BACKEND_URL" \
  --dart-define="CHAT_URL=$CHAT_URL" \
  --dart-define="SCREEN_WIDTH=$SCREEN_WIDTH" \
  --dart-define="SCREEN_HEIGHT=$SCREEN_HEIGHT"

DRIVE_EXIT=$?

echo ""
if [ $DRIVE_EXIT -eq 0 ]; then
  echo "Screenshots captured in $PKG_DIR/screenshots/"
  ls -lh screenshots/ 2>/dev/null || echo "(no screenshots directory found)"
else
  echo "ERROR: flutter drive exited with code $DRIVE_EXIT"
fi

kill "$XVFB_PID" 2>/dev/null || true
exit $DRIVE_EXIT
