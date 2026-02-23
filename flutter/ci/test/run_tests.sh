#! /bin/bash
set -x
echo "Starting test runner (emulator should be healthy)..."
sleep 10

# git safe directory (mounted volume may have different owner)
git config --global --add safe.directory '*'

# Ensure melos is available
dart pub global activate melos
export PATH="$PATH":"$HOME/.pub-cache/bin"

# Re-bootstrap workspace to pick up any new packages added since the image was built
# (e.g. packages with 'resolution: workspace' not present in the pre-built image)
melos bootstrap

# Disable Gradle daemon and run Kotlin compiler in-process to prevent memory issues
export GRADLE_OPTS="-Dorg.gradle.daemon=false -Xmx2g -Dkotlin.compiler.execution.strategy=in-process"

# Wait for emulator to be accessible with retries
MAX_RETRIES=30
RETRY_COUNT=0
EMULATOR_IP=""

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
  EMULATOR_IP=$(getent hosts emulator | awk '{print $1}' | head -n 1)
  if [ -n "$EMULATOR_IP" ]; then
    echo "Resolved emulator IP: $EMULATOR_IP"
    break
  fi
  echo "Waiting for emulator DNS resolution... (attempt $((RETRY_COUNT+1))/$MAX_RETRIES)"
  sleep 2
  RETRY_COUNT=$((RETRY_COUNT+1))
done

if [ -n "$EMULATOR_IP" ]; then
  echo "Connecting to emulator at $EMULATOR_IP:5557"
  adb connect "$EMULATOR_IP":5557 || true
  export DEVICE_ID="$EMULATOR_IP:5557"
else
  echo "Failed to resolve emulator via getent, trying direct hostname..."
  adb connect emulator:5557 || true
  export DEVICE_ID="emulator:5557"
fi

echo "Using DEVICE_ID: $DEVICE_ID"

flutter devices

# Wait for device to be online with timeout
echo "Waiting for Android device to be detected by adb..."
TIMEOUT=300
ELAPSED=0
while [ $ELAPSED -lt $TIMEOUT ]; do
  if adb devices | grep -q "$DEVICE_ID.*device$"; then
    echo "Device detected by adb"
    break
  fi
  echo "Waiting for device... ($ELAPSED/$TIMEOUT seconds)"
  sleep 5
  ELAPSED=$((ELAPSED+5))
done

if [ $ELAPSED -ge $TIMEOUT ]; then
  echo "ERROR: Device not detected after $TIMEOUT seconds"
  adb devices
  exit 1
fi

# Wait for boot to complete
echo "Waiting for Android device to complete boot..."
BOOT_TIMEOUT=180
BOOT_ELAPSED=0
while [ $BOOT_ELAPSED -lt $BOOT_TIMEOUT ]; do
  BOOT_STATUS=$(adb -s "$DEVICE_ID" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')
  if [ "$BOOT_STATUS" = "1" ]; then
    echo "Device boot completed"
    break
  fi
  echo "Waiting for boot... ($BOOT_ELAPSED/$BOOT_TIMEOUT seconds)"
  sleep 5
  BOOT_ELAPSED=$((BOOT_ELAPSED+5))
done

if [ $BOOT_ELAPSED -ge $BOOT_TIMEOUT ]; then
  echo "ERROR: Device boot did not complete after $BOOT_TIMEOUT seconds"
  adb -s "$DEVICE_ID" shell getprop | grep boot
  exit 1
fi

# Unlock screen
adb -s "$DEVICE_ID" shell input keyevent 82 || true
sleep 2

echo "Emulator is ready for testing"

# Patch all app_settings.json files to use Docker container hostnames
# This avoids hardcoding Docker URLs in the source repository
echo "Patching app_settings.json files for Docker networking..."
find packages -path '*/assets/cfg/app_settings.json' -exec \
  sed -i 's|"databaseUrlDebug": "[^"]*"|"databaseUrlDebug": "http://moqui"|g; s|"chatUrlDebug": "[^"]*"|"chatUrlDebug": "ws://moqui"|g' {} \;
echo "Patched app_settings.json files:" 
find packages -path '*/assets/cfg/app_settings.json' -exec grep -l 'http://moqui' {} \;

# Run tests with optional test file or package filter
if [ -n "$TEST_FILE" ]; then
  echo "Running specific test file: $TEST_FILE"
  
  # Check if file exists, if not try to find it
  if [ ! -f "$TEST_FILE" ]; then
    echo "Test file not found at: $TEST_FILE"
    # Try to find the file in packages
    FOUND_FILE=$(find packages -name "$(basename "$TEST_FILE")" -type f 2>/dev/null | head -1)
    if [ -n "$FOUND_FILE" ]; then
      echo "Found test file at: $FOUND_FILE"
      TEST_FILE="$FOUND_FILE"
    else
      echo "ERROR: Could not find test file: $TEST_FILE"
      echo "Available test files:"
      find packages -path "*/integration_test/*.dart" -type f | head -20
      exit 1
    fi
  fi
  
  # For integration tests, we need to run them from the package's example directory
  # Extract package and example path from test file path
  # e.g., packages/growerp_core/example/integration_test/dynamic_menu_test.dart
  #       -> packages/growerp_core/example
  
  # Use bash string manipulation instead of sed for better portability
  PACKAGE_DIR="$TEST_FILE"
  # Remove everything after and including "integration_test" or "lib/src"
  PACKAGE_DIR="${PACKAGE_DIR%/integration_test/*}"
  PACKAGE_DIR="${PACKAGE_DIR%/lib/src/*}"
  
  # Verify we got a valid package directory
  if [ -z "$PACKAGE_DIR" ] || [ "$PACKAGE_DIR" = "$TEST_FILE" ]; then
    echo "ERROR: Failed to extract package directory from: $TEST_FILE"
    echo "Please ensure test file is in: packages/PACKAGE_NAME/example/integration_test/TEST_FILE.dart"
    exit 1
  fi
  
  if [ -d "$PACKAGE_DIR" ] && [ -f "$PACKAGE_DIR/pubspec.yaml" ]; then
    echo "Running test from package directory: $PACKAGE_DIR"
    cd "$PACKAGE_DIR" || exit 1
    
    # Ensure dependencies are resolved for this package
    flutter pub get
    
    # Get just the test file path relative to the package
    # e.g., integration_test/dynamic_menu_test.dart
    TEST_FILE_RELATIVE="${TEST_FILE#$PACKAGE_DIR/}"
    echo "Test file relative path: $TEST_FILE_RELATIVE"
    echo "Device ID: $DEVICE_ID"
    
    # Verify device is still connected
    echo "Connected devices:"
    adb devices
    flutter devices
    
    # Reconnect to emulator if needed (cd may have disrupted adb)
    adb connect "$DEVICE_ID" 2>/dev/null || true
    
    flutter test -d "$DEVICE_ID" "$TEST_FILE_RELATIVE"
    TEST_RESULT=$?
    
    # Return to original directory
    cd - > /dev/null || exit 1
    
    if [ $TEST_RESULT -ne 0 ]; then
      exit $TEST_RESULT
    fi
  else
    echo "ERROR: Could not find package directory for test: $TEST_FILE"
    exit 1
  fi
elif [ -n "$PACKAGE_FILTER" ]; then
  echo "Running tests for packages matching: *${PACKAGE_FILTER}*"
  melos exec --scope="*${PACKAGE_FILTER}*" --dir-exists="integration_test" --concurrency=1 -- \
    flutter test integration_test -d "$DEVICE_ID"
else
  echo "Running all tests"
  DEVICE_ID="$DEVICE_ID" melos run test-headless --no-select
fi

# Take a screenshot of the Flutter app.
# mkdir -p 'screenshots' || exit 1
# adb shell screencap /sdcard/screenshot.png

# adb pull /sdcard/screenshot.png screenshots/flutter-screen.png

# sleep infinity
