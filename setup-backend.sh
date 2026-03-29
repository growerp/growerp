#!/usr/bin/env bash
# setup-backend.sh
# Symlinks GrowERP custom components into the moqui runtime component directory.
# Run once after cloning growerp1 and initialising submodules:
#   git submodule update --init --recursive
#   bash setup-backend.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
COMP_DIR="$REPO_ROOT/moqui/runtime/component"

if [ ! -d "$COMP_DIR" ]; then
  echo "ERROR: $COMP_DIR does not exist."
  echo "Run 'git submodule update --init --recursive' first."
  exit 1
fi

ln -sfn "$REPO_ROOT/backend"       "$COMP_DIR/growerp"
ln -sfn "$REPO_ROOT/pop-rest-store" "$COMP_DIR/PopRestStore"
ln -sfn "$REPO_ROOT/mantle-stripe"  "$COMP_DIR/mantle-stripe"

echo "Custom components linked into $COMP_DIR:"
ls -la "$COMP_DIR/growerp" "$COMP_DIR/PopRestStore" "$COMP_DIR/mantle-stripe"
