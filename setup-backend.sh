#!/usr/bin/env bash
# setup-backend.sh
# Clones moqui-runtime (with its component submodules) if not already present,
# then symlinks GrowERP custom components into the moqui runtime component directory.
#
# Run once after cloning growerp and initialising the moqui submodule:
#   git clone https://github.com/growerp/growerp
#   cd growerp
#   git submodule update --init --recursive
#   bash setup-backend.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
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
  git clone -b growerp https://github.com/growerp/moqui-runtime.git "$RUNTIME_DIR"
fi

# Initialise runtime's own submodules (mantle-udm, mantle-usl, moqui-fop)
if [ -f "$RUNTIME_DIR/.gitmodules" ]; then
  echo "Initialising moqui-runtime submodules ..."
  git -C "$RUNTIME_DIR" submodule update --init --recursive
fi

if [ ! -d "$COMP_DIR" ]; then
  echo "ERROR: $COMP_DIR still does not exist after cloning runtime."
  exit 1
fi

ln -sfn "$REPO_ROOT/backend"       "$COMP_DIR/growerp"
ln -sfn "$REPO_ROOT/pop-rest-store" "$COMP_DIR/PopRestStore"
ln -sfn "$REPO_ROOT/mantle-stripe"  "$COMP_DIR/mantle-stripe"

echo "Custom components linked into $COMP_DIR:"
ls -la "$COMP_DIR/growerp" "$COMP_DIR/PopRestStore" "$COMP_DIR/mantle-stripe"
