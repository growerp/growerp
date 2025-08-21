
submitting macos app to the appstore

make sure you have a distribution certificate and it is set in:
in the macos dir:  open Runner.xcodeproj 


compile in the flutter app dir: flutter build macos
open xcode in the macos dir: opnen Runner.xcworkspace
in xcode: product => archive
          validate
          distribute


if you want to run the macos app locally, you have to remove the distribution certificate in xcode.
