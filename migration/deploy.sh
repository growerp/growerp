#!/usr/bin/env bash
# Run the migrations of a just deployed backend version, see README.md.
# Usage: deploy.sh <backend version> <backend url>
#   1.22.0 runs 1.22/; a version without a directory has nothing to migrate.
#   MOQUI_PASSWORD (SystemSupport) must be set. Retries while the new backend
#   starts: until it runs, a new migration service is unknown (500). Every
#   service is idempotent, so running one again is safe.
set -euo pipefail
version="${1:?usage: deploy.sh <backend version> <backend url>}"
url="${2:?usage: deploy.sh <backend version> <backend url>}"
: "${MOQUI_PASSWORD:?set MOQUI_PASSWORD (SystemSupport password of $url)}"
cd "$(dirname "$0")"
minor="${version%.*}"

if ! grep -qv '^\s*\(#\|$\)' "$minor/services.txt" 2>/dev/null; then
    echo "No migrations for $minor"
    exit 0
fi

for attempt in $(seq 1 20); do
    if ./run.sh "$minor" "$url"; then
        echo "Migrations of $minor done on $url"
        exit 0
    fi
    echo "Attempt $attempt failed, backend may still be starting; retry in 30s"
    sleep 30
done
echo "Migrations of $minor failed on $url"
exit 1
