#!/usr/bin/env bash
# sync-submodules.sh
# Updates growerp1's submodule pointers to the latest commits on each
# growerp fork's `growerp` branch, then commits and optionally pushes.
#
# Usage:
#   bash sync-submodules.sh           # update, commit (no push)
#   bash sync-submodules.sh --push    # update, commit, and push

set -euo pipefail

PUSH=false
for ARG in "$@"; do
  [ "$ARG" = "--push" ] && PUSH=true
done

# Resolve growerp1 root (script lives at repo root)
REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$REPO_ROOT"

echo "=== Updating submodule pointers (--remote --recursive) ==="
git submodule update --remote --recursive --merge

echo ""
echo "=== Submodule status ==="
git submodule status --recursive

# Stage the updated moqui submodule pointer
git add moqui

if git diff --cached --quiet; then
  echo ""
  echo "No submodule pointer changes to commit."
else
  git commit -m "chore: update moqui submodules to latest growerp branch"
  echo ""
  echo "Committed updated submodule pointers."

  if $PUSH; then
    git push
    echo "Pushed to origin."
  else
    echo "Run 'git push' to publish."
  fi
fi
