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

# run all tests
melos test-headless --no-select

# just run order/accounting tests
#cd packages/growerp_order_accounting/example
#../../../test/set_app_settings.sh
#flutter test integration_test

# just run catalog tests
#cd packages/growerp_catalog/example
#../../../test/set_app_settings.sh
#flutter test integration_test

# just run user/company tests
#cd packages/growerp_user_company/example
#../../../test/set_app_settings.sh
#flutter test integration_test

# Take a screenshot of the Flutter app.
# mkdir -p 'screenshots' || exit 1
# adb shell screencap /sdcard/screenshot.png

# adb pull /sdcard/screenshot.png screenshots/flutter-screen.png

# sleep infinity
