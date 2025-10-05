#!/bin/bash
set -e
FLUTTER_VERSION="3.35.0" # I will use a more recent version to ensure it's available
URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
echo "Found URL: $URL"
FLUTTER_DIR="/tmp/flutter_install"
mkdir -p "$FLUTTER_DIR"
cd "$FLUTTER_DIR"
wget -O "flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" "$URL"
tar xf "flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
export FLUTTER_ROOT="$FLUTTER_DIR/flutter"
export PATH="$FLUTTER_ROOT/bin:$PATH"
cd /app
flutter pub get
melos l10n --no-select
melos build --no-select
