#!/bin/bash
#
# Run all 4 test slices in parallel, sharing a single Moqui + PostgreSQL backend.
# Each slice opens in its own terminal window.
#
# Usage: ./run_all_slices.sh
#
# Tests are isolated per slice because each package creates its own company/tenant.
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DC="docker compose -f $SCRIPT_DIR/ci/docker-compose-test.yml"

cd "$SCRIPT_DIR" || exit 1

export HOST_UID=$(id -u)
export HOST_GID=$(id -g)

# 1. Build the test runner image
echo "Building test runner image..."
$DC build sut

# 2. Start the shared backend (one instance for all slices)
echo "Starting shared Moqui backend..."
$DC up -d moqui-database moqui

# 3. Wait for Moqui to be healthy
echo "Waiting for Moqui..."
TIMEOUT=180
ELAPSED=0
while [ $ELAPSED -lt $TIMEOUT ]; do
  if $DC exec -T moqui curl -sf http://localhost/status 2>/dev/null; then
    echo "Moqui is ready."
    break
  fi
  echo "  ($ELAPSED/$TIMEOUT s)"
  sleep 10
  ELAPSED=$((ELAPSED + 10))
done
if [ $ELAPSED -ge $TIMEOUT ]; then
  echo "ERROR: Moqui not ready after $TIMEOUT seconds"
  $DC logs moqui
  exit 1
fi

# 4. Launch 4 sut containers in separate terminals.
#    Uses `docker compose run` so each slice gets its own container
#    while sharing the project network (and thus the same Moqui).
open_terminal() {
  local slice=$1
  local run_cmd="$DC run --rm -e PACKAGE_SLICE=$slice/4 -e PACKAGE_FILTER= -e TEST_FILE= sut"
  local wrap="$run_cmd; echo; echo '=== Slice $slice/4 done — press Enter to close ==='; read"

  if command -v gnome-terminal &>/dev/null; then
    gnome-terminal --title="GrowERP Test Slice $slice/4" -- bash -c "$wrap"
  elif command -v xterm &>/dev/null; then
    xterm -title "GrowERP Test Slice $slice/4" -e bash -c "$wrap" &
  elif command -v konsole &>/dev/null; then
    konsole --new-tab -p tabtitle="Slice $slice/4" -e bash -c "$wrap" &
  else
    return 1
  fi
}

if ! command -v gnome-terminal &>/dev/null && \
   ! command -v xterm &>/dev/null && \
   ! command -v konsole &>/dev/null; then
  echo ""
  echo "No terminal emulator found (tried gnome-terminal, xterm, konsole)."
  echo "Run these manually in 4 separate terminals:"
  for i in 1 2 3 4; do
    echo "  $DC run --rm -e PACKAGE_SLICE=$i/4 -e PACKAGE_FILTER= -e TEST_FILE= sut"
  done
  exit 0
fi

echo "Launching 4 slice terminals..."
for slice in 1 2 3 4; do
  open_terminal $slice
  sleep 1   # slight stagger so terminals don't all try to compile at once
done

echo ""
echo "All 4 slices started against the shared Moqui backend."
echo "When all terminals are done, stop the backend with:"
echo "  $DC down"
