#!/bin/bash
FLUTTER_DIR="/tmp/flutter_install"
mkdir -p "$FLUTTER_DIR"
cd "$FLUTTER_DIR"
wget -q --show-progress https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.22.2-stable.tar.xz
# Replace with desired version
tar xf flutter_linux_3.22.2-stable.tar.xz
export FLUTTER_ROOT="$FLUTTER_DIR/flutter"
export PATH="$FLUTTER_ROOT/bin:$PATH"
echo "Flutter installed successfully"