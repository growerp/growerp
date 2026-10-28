#!/usr/bin/env bash
# Run the migrations of a just deployed backend version, see README.md.
# Usage: deploy.sh <backend version> <backend url> [previous backend version]
#   1.22.0 runs 1.22/. With the version the server ran before, every minor
#   version directory from that one up to the new one runs, oldest first, so a
#   server going from 1.20 to 1.22 also gets 1.21/. A version without a
#   directory has nothing to migrate.
#   SYSTEMSUPPORT_PASSWORD (SystemSupport) must be set. Retries while the new backend
#   starts: until it runs, a new migration service is unknown (500). Every
#   service is idempotent, so running one again is safe.
set -euo pipefail
version="${1:?usage: deploy.sh <backend version> <backend url> [previous backend version]}"
url="${2:?usage: deploy.sh <backend version> <backend url> [previous backend version]}"
previous="${3:-$version}"
: "${SYSTEMSUPPORT_PASSWORD:?set SYSTEMSUPPORT_PASSWORD (SystemSupport password of $url)}"
cd "$(dirname "$0")"
to="${version%.*}"
from="${previous%.*}"

# minor version directories from..to, oldest first
minors=()
for dir in $(ls -d [0-9]*.[0-9]* 2>/dev/null | sort -V); do
    [ "$(printf '%s\n%s\n' "$from" "$dir" | sort -V | head -1)" == "$from" ] || continue
    [ "$(printf '%s\n%s\n' "$dir" "$to" | sort -V | head -1)" == "$dir" ] || continue
    grep -qv '^\s*\(#\|$\)' "$dir/services.txt" 2>/dev/null && minors+=("$dir")
done
if [ ${#minors[@]} -eq 0 ]; then
    echo "No migrations for $from..$to"
    exit 0
fi

for minor in "${minors[@]}"; do
    for attempt in $(seq 1 20); do
        if ./run.sh "$minor" "$url"; then
            echo "Migrations of $minor done on $url"
            continue 2
        fi
        echo "Attempt $attempt failed, backend may still be starting; retry in 30s"
        sleep 30
    done
    echo "Migrations of $minor failed on $url"
    exit 1
done
