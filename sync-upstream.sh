#!/usr/bin/env bash
# sync-upstream.sh
# Merges the latest upstream moqui commits into each growerp fork's `growerp` branch.
#
# Usage:
#   bash sync-upstream.sh [REPO_NAME]
#
# Without arguments: syncs all forks.
# With a repo name: syncs only that fork (e.g., bash sync-upstream.sh mantle-udm).
#
# After a successful sync, run sync-submodules.sh to update growerp1's submodule pointers.

set -euo pipefail

declare -A UPSTREAM=(
  ["moqui-framework"]="https://github.com/moqui/moqui-framework"
  ["moqui-runtime"]="https://github.com/moqui/moqui-runtime"
  ["mantle-udm"]="https://github.com/moqui/mantle-udm"
  ["mantle-usl"]="https://github.com/moqui/mantle-usl"
  ["moqui-fop"]="https://github.com/moqui/moqui-fop"
)

WORK_DIR=$(mktemp -d)
CONFLICTS=()

cleanup() {
  if [ ${#CONFLICTS[@]} -eq 0 ]; then
    rm -rf "$WORK_DIR"
  else
    echo ""
    echo "Temporary clones kept for conflict resolution at: $WORK_DIR"
  fi
}
trap cleanup EXIT

sync_repo() {
  local REPO="$1"
  local UPSTREAM_URL="${UPSTREAM[$REPO]}"
  local FORK="git@github.com:growerp/${REPO}.git"
  local CLONE_DIR="$WORK_DIR/$REPO"

  echo ""
  echo "=== Syncing growerp/${REPO} ==="
  git clone --quiet "$FORK" "$CLONE_DIR"
  cd "$CLONE_DIR"

  git remote add upstream "$UPSTREAM_URL"
  git fetch --quiet upstream

  git checkout growerp 2>/dev/null || git checkout -b growerp "origin/growerp"

  if git merge --no-edit upstream/master; then
    git push origin growerp
    echo "  ✓ growerp/${REPO} synced and pushed"
  else
    echo "  ✗ CONFLICT in growerp/${REPO}"
    echo "    Resolve manually:"
    echo "      cd $CLONE_DIR"
    echo "      git mergetool"
    echo "      git push origin growerp"
    CONFLICTS+=("$REPO")
    git merge --abort 2>/dev/null || true
  fi

  cd - > /dev/null
}

# Determine which repos to sync
if [ $# -gt 0 ]; then
  REPOS=("$@")
  for R in "${REPOS[@]}"; do
    if [ -z "${UPSTREAM[$R]+x}" ]; then
      echo "ERROR: Unknown repo '$R'. Valid options: ${!UPSTREAM[*]}"
      exit 1
    fi
  done
else
  REPOS=("${!UPSTREAM[@]}")
fi

for REPO in "${REPOS[@]}"; do
  sync_repo "$REPO"
done

echo ""
if [ ${#CONFLICTS[@]} -gt 0 ]; then
  echo "Sync completed with conflicts in: ${CONFLICTS[*]}"
  echo "Resolve them manually, then run sync-submodules.sh."
  exit 1
else
  echo "All forks synced successfully."
  echo "Run ./sync-submodules.sh to update growerp1 submodule pointers."
fi
