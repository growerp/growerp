#! /bin/bash
set -x
sleep 50

dart pub global activate melos 3.4.0
export PATH="$PATH":"$HOME/.pub-cache/bin"

adb connect emulator:5557
flutter devices
adb wait-for-device shell 'while [[ -z $(getprop sys.boot_completed) ]]; do sleep 1; done; input keyevent 82'

# hack just for  automated testing
sed -i -e 's\overrideUrl: null\overrideUrl: "http://moqui"\g' packages/growerp_core/lib/src/domains/common/integration_test/common_test.dart

cd packages

# sed -i -e 's\"databaseUrlDebug": "",\"databaseUrlDebug": "http://moqui",\g' assets/cfg/app_settings.json
# sed -i -e 's\"chatUrlDebug": "",\"chatUrlDebug": "ws://chat:8080",\g' assets/cfg/app_settings.json

# flutter test integration_test -d emulator:5557
melos test-headless --no-select

# Take a screenshot of the Flutter app.
# mkdir -p 'screenshots' || exit 1
# adb shell screencap /sdcard/screenshot.png

# adb pull /sdcard/screenshot.png screenshots/flutter-screen.png

# sleep infinity
