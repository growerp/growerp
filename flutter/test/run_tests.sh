#! /bin/bash
set -x
sleep 50

# git safe directory (mounted volume may have different owner)
git config --global --add safe.directory '*'

# Ensure melos is available
dart pub global activate melos
export PATH="$PATH":"$HOME/.pub-cache/bin"

# Disable Gradle daemon and run Kotlin compiler in-process to prevent memory issues
export GRADLE_OPTS="-Dorg.gradle.daemon=false -Xmx2g -Dkotlin.compiler.execution.strategy=in-process"

# Resolve emulator hostname using curl (which handles Docker DNS correctly)
EMULATOR_IP=$(curl -s -o /dev/null -w '%{remote_ip}' http://emulator:5557/ --connect-timeout 5 2>/dev/null)
if [ -n "$EMULATOR_IP" ]; then
  # Add to /etc/hosts for other tools (flutter, adb)
  echo "$EMULATOR_IP emulator" >> /etc/hosts
  adb connect "$EMULATOR_IP":5557
  DEVICE_ID="$EMULATOR_IP:5557"
else
  echo "Resolving emulator IP failed, trying fallback..."
  adb connect emulator:5557
  # Wait for device to be connected and get the ID from flutter devices
  sleep 5
  DEVICE_ID=$(flutter devices | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:555[0-9]' | head -n 1)
  if [ -z "$DEVICE_ID" ]; then
      DEVICE_ID="emulator:5557"
  fi
fi
echo "Using DEVICE_ID: $DEVICE_ID"

flutter devices
adb wait-for-device shell 'while [[ -z $(getprop sys.boot_completed) ]]; do sleep 1; done; input keyevent 82'

# hack just for  automated testing
sed -i -e 's\overrideUrl: null\overrideUrl: "http://moqui"\g' packages/growerp_core/lib/src/domains/common/integration_test/common_test.dart

#cd packages/admin
#sed -i -e 's\"databaseUrlDebug": "",\"databaseUrlDebug": "http://moqui",\g' assets/cfg/app_settings.json
#sed -i -e 's\"chatUrlDebug": "",\"chatUrlDebug": "ws://chat:8080",\g' assets/cfg/app_settings.json
#flutter test integration_test -d $DEVICE_ID

# Run tests with optional package filter
if [ -n "$PACKAGE_FILTER" ]; then
  echo "Running tests for packages matching: *${PACKAGE_FILTER}*"
  melos exec --scope="*${PACKAGE_FILTER}*" --dir-exists="integration_test" --concurrency=1 -- \
    bash -c '$MELOS_ROOT_PATH/test/set_app_settings.sh && flutter test integration_test -d '$DEVICE_ID
else
  echo "Running all tests"
  melos run test-headless --no-select
fi

# Take a screenshot of the Flutter app.
# mkdir -p 'screenshots' || exit 1
# adb shell screencap /sdcard/screenshot.png

# adb pull /sdcard/screenshot.png screenshots/flutter-screen.png

# sleep infinity
