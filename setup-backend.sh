#!/usr/bin/env bash
# setup-backend.sh
# Clones moqui-runtime (with its component submodules) if not already present,
# then symlinks GrowERP custom components into the moqui runtime component directory.
#
# Usage: ./setup-backend.sh [--help]
#
# Clone protocol (SSH vs HTTPS) is inherited from the root growerp repo's
# origin remote: SSH origin -> clone everything via SSH, HTTPS -> via HTTPS.
#
# Options:
#   --help    Show this help message and exit

set -euo pipefail

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --help)
            echo "Usage: ./setup-backend.sh [--help]"
            echo ""
            echo "Clone protocol is inherited from the root growerp repo's origin remote."
            echo ""
            echo "Options:"
            echo "  --help    Show this help message and exit"
            exit 0
            ;;
        *)
            echo "Unknown parameter passed: $1"
            echo "Usage: ./setup-backend.sh [--help]"
            exit 1
            ;;
    esac
done

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"

# Inherit clone protocol from the root repo's origin remote
ORIGIN_URL="$(git -C "$REPO_ROOT" remote get-url origin 2>/dev/null || echo "")"
if [[ "$ORIGIN_URL" == git@* || "$ORIGIN_URL" == ssh://* ]]; then
  USE_SSH=true
  echo "Root origin is SSH -> cloning via SSH"
else
  USE_SSH=false
  echo "Root origin is HTTPS -> cloning via HTTPS"
fi
MOQUI_DIR="$REPO_ROOT/moqui"
RUNTIME_DIR="$MOQUI_DIR/runtime"
COMP_DIR="$RUNTIME_DIR/component"

if [ ! -d "$MOQUI_DIR" ]; then
  echo "ERROR: $MOQUI_DIR does not exist."
  echo "Run 'git submodule update --init --recursive' first."
  exit 1
fi

# moqui-runtime is not a submodule of moqui-framework — clone it if missing
if [ ! -d "$RUNTIME_DIR" ]; then
  echo "Cloning moqui-runtime into $RUNTIME_DIR ..."
  if [ "$USE_SSH" = true ]; then
    git clone -b growerp git@github.com:growerp/moqui-runtime.git "$RUNTIME_DIR"
  else
    git clone -b growerp https://github.com/growerp/moqui-runtime.git "$RUNTIME_DIR"
  fi
fi

# Initialise runtime's own submodules (mantle-udm, mantle-usl, moqui-fop)
if [ -f "$RUNTIME_DIR/.gitmodules" ]; then
  echo "Initialising moqui-runtime submodules ..."
  if [ "$USE_SSH" = true ]; then
    sed -i 's|https://github.com/|git@github.com:|g' "$RUNTIME_DIR/.gitmodules"
    git -C "$RUNTIME_DIR" submodule sync
  fi
  git -C "$RUNTIME_DIR" submodule update --init --recursive
fi

if [ ! -d "$COMP_DIR" ]; then
  echo "ERROR: $COMP_DIR still does not exist after cloning runtime."
  exit 1
fi

ln -sfn "../../../backend"        "$COMP_DIR/growerp"
ln -sfn "../../../pop-rest-store" "$COMP_DIR/PopRestStore"
ln -sfn "../../../mantle-stripe"  "$COMP_DIR/mantle-stripe"
ln -sfn "../../../moqui-adk"      "$COMP_DIR/moqui-adk"
ln -sfn "../../../moqui-mcp"      "$COMP_DIR/moqui-mcp"

echo "Custom components linked into $COMP_DIR:"
ls -la "$COMP_DIR/growerp" "$COMP_DIR/PopRestStore" "$COMP_DIR/mantle-stripe" \
       "$COMP_DIR/moqui-adk" "$COMP_DIR/moqui-mcp"

