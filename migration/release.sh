#!/usr/bin/env bash
# Move the migrations of next/ to the minor version directory of a new backend
# version (1.21.3 -> 1.21/, appended when it exists), start an empty next/ and
# rebuild the table in README.md. Run by the "update staging" workflow.
# Usage: release.sh <version>
set -euo pipefail
cd "$(dirname "$0")"
version="${1:?usage: release.sh <version>}"
minor="${version%.*}"
header="# Migrations for the version not yet released, see ../README.md"

grep -qv '^\s*\(#\|$\)' next/services.txt 2>/dev/null || exit 0
mkdir -p "$minor"
grep -vxF "$header" next/services.txt >> "$minor/services.txt"
echo "$header" > next/services.txt
echo "Migrations of next moved to migration/$minor"

# table rows: one per directory, oldest first, next last
rows=$(for dir in $(ls -d */ | tr -d / | grep -vx next | sort -V) next; do
    services=$(grep -o 'migrate#[A-Za-z0-9]*' "$dir/services.txt" | sed 's/.*/`&`/' | paste -sd, | sed 's/,/, /g')
    echo "| $dir | $services |"
done)
awk -v rows="$rows" '
    /^\|---\|---\|$/ { print; print rows; skip = 1; next }
    skip && /^\|/ { next }
    { skip = 0; print }
' README.md > README.md.new
mv README.md.new README.md
