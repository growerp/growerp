# Upload a new version to the appstore:


## flutter method upload:

1. in the app directory: flutter build ipa
2. get Transporter MacOs application
3. drop build/ios/ipa/*.ipa on to the Transporter



## general

missing emulators can be added in xcode : window -> devices and emulators

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
    https://docs.flutter.dev/deployment/cd#fastlane
certicate access (rediculus!!)    
    https://stackoverflow.com/questions/10204320/mac-os-x-wants-to-use-system-keychain-when-compiling-the-project

create certificates inside xcode easy!:
    https://help.twixlmedia.com/hc/en-us/articles/115000790705-iOS-Manage-signing-certificates-for-your-apps

to test for profile and certificate, provide proper messages:
    flutter build ipa

add this ipa to the transport utitlity

short:
export FLUTTER_ROOT=/Users/hans/flutter/bin


### Fastlane
install: brew install fastlane

1. increase numbers pubspec.yaml version: x.x.x+1
2. set the target backend!!!! and back after build again!!!!
3. build flutter: (project home)
    flutter build ios --release --no-codesign
4. compile and sign (in ios dir)
    fastlane gym
5. upload: (in ios dir)
    binary only: fastlane upload
    all including meta: fastlane deliver --overwrite_screenshots 
    just screenshots: fastlane deliver --overwrite_screenshots \
                         --skip_binary_upload

login to the appstore console:
create new major version, give reason of update and submit for review
