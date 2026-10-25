#!/usr/bin/env bash
# Run the one-time migration services of one version, see README.md.
# Usage: run.sh <version dir> [backend url]
#   MOQUI_USER (default SystemSupport) and MOQUI_PASSWORD must be set.
set -euo pipefail
dir="$(cd "$(dirname "$0")" && pwd)/${1:?usage: run.sh <version dir> [backend url]}"
url="${2:-http://localhost:8080}/apps/tools/Service/ServiceRun/runJson"
: "${MOQUI_PASSWORD:?set MOQUI_PASSWORD}"
[ -f "$dir/services.txt" ] || { echo "no $dir/services.txt"; exit 1; }

grep -v '^\s*\(#\|$\)' "$dir/services.txt" | while read -r service params; do
    echo "== $service $params"
    args=(-sS --fail-with-body -u "${MOQUI_USER:-SystemSupport}:$MOQUI_PASSWORD" -d "serviceName=$service")
    for p in $params; do args+=(-d "$p"); done
    curl "${args[@]}" "$url"
    echo
done
