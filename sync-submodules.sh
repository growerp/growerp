#!/usr/bin/env bash
# sync-submodules.sh
# Updates growerp1's submodule pointers to the latest commits on each
# growerp fork's `growerp` branch, then commits and optionally pushes.
#
# Usage:
#   bash sync-submodules.sh           # update, commit (no push)
#   bash sync-submodules.sh --push    # update, commit, and push
#   bash sync-submodules.sh --force   # skip pre-flight clean check
#   bash sync-submodules.sh --ssh     # use SSH instead of HTTPS for GitHub URLs

set -euo pipefail

PUSH=false
FORCE=false
SSH=false
for ARG in "$@"; do
  [ "$ARG" = "--push"  ] && PUSH=true
  [ "$ARG" = "--force" ] && FORCE=true
  [ "$ARG" = "--ssh" ] && SSH=true
done

if $SSH; then
  echo "=== Using SSH for GitHub URLs ==="
  export GIT_CONFIG_COUNT=1
  export GIT_CONFIG_KEY_0="url.git@github.com:.insteadOf"
  export GIT_CONFIG_VALUE_0="https://github.com/"
fi

# Resolve growerp1 root (script lives at repo root)
REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$REPO_ROOT/moqui/runtime"
cd "$REPO_ROOT"

check_clean() {
  local path="$1" label="$2" dirty=0
  if ! git -C "$path" diff --quiet 2>/dev/null || \
     ! git -C "$path" diff --cached --quiet 2>/dev/null; then
    echo "  DIRTY (uncommitted changes): $label"
    dirty=1
  fi
  local upstream ahead
  upstream=$(git -C "$path" rev-parse --abbrev-ref "@{upstream}" 2>/dev/null || true)
  if [ -n "$upstream" ]; then
    ahead=$(git -C "$path" rev-list --count "${upstream}..HEAD" 2>/dev/null || echo 0)
    if [ "$ahead" -gt 0 ]; then
      echo "  UNPUSHED ($ahead commit(s)): $label"
      dirty=1
    fi
  fi
  return $dirty
}

if ! $FORCE; then
  echo "=== Pre-flight: checking for uncommitted/unpushed changes ==="
  PREFLIGHT_OK=true
  check_clean "$REPO_ROOT" "growerp (root)" || PREFLIGHT_OK=false
  while IFS= read -r subpath; do
    rel="${subpath#$REPO_ROOT/}"
    check_clean "$subpath" "$rel" || PREFLIGHT_OK=false
  done < <(git submodule foreach --recursive --quiet 'echo "$toplevel/$sm_path"')

  if [ -d "$RUNTIME_DIR/.git" ]; then
    check_clean "$RUNTIME_DIR" "moqui/runtime" || PREFLIGHT_OK=false
    while IFS= read -r subpath; do
      rel="${subpath#$REPO_ROOT/}"
      check_clean "$subpath" "$rel" || PREFLIGHT_OK=false
    done < <(git -C "$RUNTIME_DIR" submodule foreach --recursive --quiet \
               'echo "$toplevel/$sm_path"')
  fi

  if ! $PREFLIGHT_OK; then
    echo ""
    echo "Abort: resolve issues above, or rerun with --force to skip this check."
    exit 1
  fi
  echo "All clean. Proceeding."
  echo ""
fi

echo "=== Updating submodule pointers (--remote --recursive) ==="
git submodule update --remote --recursive --merge

echo ""
echo "=== Submodule status ==="
git submodule status --recursive

# Stage all updated submodule pointers
git add .

if git diff --cached --quiet; then
  echo ""
  echo "No submodule pointer changes to commit."
else
  git commit -m "chore: update submodules to latest growerp branch"
  echo ""
  echo "Committed updated submodule pointers."

  if $PUSH; then
    git push
    echo "Pushed to origin."
  else
    echo "Run 'git push' to publish."
  fi
fi

# Update moqui-runtime submodule pointers
if [ -d "$RUNTIME_DIR/.git" ]; then
  echo ""
  echo "=== Updating moqui-runtime submodule pointers (--remote --recursive) ==="
  git -C "$RUNTIME_DIR" submodule update --remote --recursive --merge

  echo ""
  echo "=== moqui-runtime submodule status ==="
  git -C "$RUNTIME_DIR" submodule status --recursive

  git -C "$RUNTIME_DIR" add .

  if git -C "$RUNTIME_DIR" diff --cached --quiet; then
    echo ""
    echo "No moqui-runtime submodule pointer changes to commit."
  else
    git -C "$RUNTIME_DIR" commit -m "chore: update submodules to latest growerp branch"
    echo ""
    echo "Committed moqui-runtime submodule pointers."

    if $PUSH; then
      git -C "$RUNTIME_DIR" push
      echo "Pushed moqui-runtime to origin."
    else
      echo "Run 'git -C moqui/runtime push' to publish."
    fi
  fi
fi
