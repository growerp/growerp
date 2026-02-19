#!/usr/bin/env bash

set -ex

# Clean up stale lock files from previous emulator runs to prevent
# "Running multiple emulators with the same AVD" FATAL error
find /root/.android/avd/ -name "*.lock" -delete 2>/dev/null || true
find /root/.android/avd/ -name "*.lock.lock" -delete 2>/dev/null || true
find /root/.android/avd/ -name "*.tmp-*" -delete 2>/dev/null || true

./adb_redirect.sh
./run_emulator.sh
