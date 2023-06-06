# Upload a new version to the appstore:

start emulators from command line:
flutter emulators --launch pixel

<b>to create a missing emulator ipad</b>: (adjust ios version and ipad version)
xcrun simctl create "iPad Pro (12.9-inch) (3rd generation)" "com.apple.CoreSimulator.SimDeviceType.iPad-Pro--12-9-inch---3rd-generation-" "com.apple.CoreSimulator.SimRuntime.iOS-15-4"

1. Start all emulators you need screen shots from
    iPhone 12 pro max, iPhone 8 Plus, iPad Pro 12.9 (2nd gen), iPad Pro 12.9 (3rd gen)
2. switch Ipad to horizontal layout

install frameit-chrome:
flutter pub global activate frameit_chrome

dirs should exist: ios/fastlane/unframed/en-US
from app root: flutter pub run utils:screenshots

to only run the frameit-chrome program:(project home)
flutter pub global run frameit_chrome \
        --base-dir=ios/fastlane/unframed \
        --frames-dir=ios/fastlane/frames \
        --chrome-binary=/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome \
        --pixel-ratio=1.0


When generated then move from framed/en-US to metadata/screenshots/en-US

Build and upload Manual:
    https://flutter.dev/docs/deployment/ios
certicate access (rediculus!!)    
    https://stackoverflow.com/questions/10204320/mac-os-x-wants-to-use-system-keychain-when-compiling-the-project

### Fastlane
install: brew install fastlane

1. increase numbers pubspec.yaml version: x.x.x+1
2. build flutter: (project home)
    flutter build ios --release --no-codesign
3. compile and sign (in ios dir)
    fastlane gym
4. upload: (in ios dir)
    binary only: fastlane upload
    all including meta: fastlane deliver --overwrite_screenshots 
    just screenshots: fastlane deliver --overwrite_screenshots \
                         --skip_binary_upload

login to the appstore console:
create new major version, give reason of update and submit for review
