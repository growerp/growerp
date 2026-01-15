
submitting macos app to the appstore

make sure you have a distribution certificate and it is set in:
in the macos dir:  open Runner.xcodeproj 


compile in the flutter app dir:
  flutter clean
  flutter build macos --config-only

open xcode:
  open macos/Runner.xcworkspace

in xcode: 
  product => archive
          validate
          distribute

if you want to run the macos app locally, you have to remove the distribution certificate in xcode and to development mode

## No such module file picker problem
flutter clean
rm -rf macos/Flutter/ephemeral
rm -rf macos/Pods
rm macos/Podfile.lock
flutter pub get
cd macos
pod repo update
pod install --verbose
cd ..
flutter build macos --config-only
open macos/Runner.xcodeproj

