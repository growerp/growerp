#! /bin/bash
set -x
echo $PATH
sleep 30
adb connect emulator:5555
flutter devices
adb wait-for-device

# hack just for  automated testing
sed 's\overrideUrl: null\overrideUrl: "http://moqui"\g' packages/growerp_core/lib/src/domains/common/integration_test/common_test.dart

cd packages/growerp_catalog/example

sed -i -e  's\"databaseUrlDebug": "",\"databaseUrlDebug": "http://moqui",\g' assets/cfg/app_settings.json
sed -i -e  's\"chatUrlDebug": "",\"chatUrlDebug": "ws://chat:8080",\g' assets/cfg/app_settings.json

flutter test integration_test/category_test.dart -d emulator:5555

