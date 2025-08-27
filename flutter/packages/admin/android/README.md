# Simplified submittance to the playstore

in The app directory:
1. increment version code(0.0.0+??) in pubspec.yaml
flutter build appbundle

after creation of a release:
upload bundle in the browser at: https://play.google.com/console


# Running fastlane to upload in Playstore

### create these emulators:

Nexus_10_API_30         • Nexus 10 API 30           • Google • android
Nexus_7_2012_API_30     • Nexus 7 (2012) API 30     • Google • android
Pixel_4_Edited_1_API_30 • Pixel 4 (Edited) 1 API 30 • User   • android

launch these for the first time:
flutter emulators --lanch nexus_7
flutter emulators --lanch nexus_10
flutter emulators --lanch pixel

For the tablets change to horizontal view.

Install frameit_chrome: dart pub global activate frameit_chrome

### create screen shots:
create title.strings and key.word.strings with screenshots
make sure the first debug company is created.

In growerp/packages/admin dir:  
flutter pub run utils:screenshots

Only framing:
flutter pub global run frameit_chrome \
    --base-dir=android/fastlane/metadata/android \
    --frames-dir=android/fastlane/frames \
    --chrome-binary="/usr/bin/google-chrome-stable" \
    --pixel-ratio=1

### further
1. Move the framed images in fastlane/metadata/framed/en-US to the respective directories under: metadata/android/en-US/images: phoneScreenshots, seveninchScreenshots,teninchScreenshots 
2. increase in pubspec.yaml version+buildnr
    buildnr should always increase, version is shown to the user
3. adjust the backend urls (test or production)
    in assets/cfg/app_settings.json
4. create app bundle in admin home:
    flutter build appbundle
5. Upload in Play store: (in android dir)
    (everything including build/meta/screenshots)
    fastlane supply \
        --aab ../build/app/outputs/bundle/release/app-release.aab \
        --track production --in_app_update_priority 3

6. Upload just binary:
    fastlane supply \
        --aab ../build/app/outputs/bundle/release/app-release.aab \
        --skip_upload_screenshots

check [fastfile](https://docs.fastlane.tools/actions/supply/) for another actions.


### Other requirements:

#### create a <projdir>/android/key.properties link to a local file
which contains the following info:
storePassword=xxxxx
keyPassword=xxxxx
keyAlias=xxxxx
storeFile=xxxxxxx

(do NOT upload the actual file into git!)
to create a link in linux in the android directory:
    ln -s ~/here/your/actual/file key.properties

#### should have local.properties file
which contains the following info:
sdk.dir=/home/dell/Android/Sdk
flutter.sdk=/home/dell/snap/flutter/common/flutter
flutter.buildMode=release
flutter.versionName=0.0.1   
flutter.versionCode=5

make sure this file is referenced in build.gradle:
def flutterRoot = localProperties.getProperty('flutter.sdk')
if (flutterRoot == null) {
    throw new GradleException("Flutter SDK not found. Define location with flutter.sdk in the local.properties file.")
}

def flutterVersionCode = localProperties.getProperty('flutter.versionCode')
if (flutterVersionCode == null) {
    flutterVersionCode = '3'
}

def flutterVersionName = localProperties.getProperty('flutter.versionName')
if (flutterVersionName == null) {
    flutterVersionName = '1.0'

#### build the aab bundle:
make sure flutter/packages/admin/assets/cfg/app_settings.json backend url is set correctly
reverse the change afterwards!

flutter build appbundle

#### First time upload by hand, make sure bundle id is set correctly:
flutter create --org org/growerp/admin .
init: fastlane supply init

#### Upload in Play store: (android dir)
(everything including build/meta/screenshots)
fastlane supply \
    --aab /home/hans/growerp/flutter/packages/admin/build/app/outputs/bundle/release/app-release.aab \
    --track release --in_app_update_priority 3 

(upload just binary)
    fastlane upload

## set up fastlane first time:
in the android dir:
    fastlane supply init
and the system will prompt you for required data
