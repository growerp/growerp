# upgrading Growerp production

## Automated

The GrowERP release process consist out of the following workflows:
1. "update staging" 
   will update staging server and can increment version
2. "create store screenshots" (opt)
   will create framed screenshots of apps in the stores
3. "publish binary to stores"
   with new version from 'update staging'
   using the staging backend for the store review to test
4. "published metadata to stores" (opt)
   will send meta dat in apps dirs to the stores
5. Create userid/password for stores to check app on staging
   submit for review
6. When review ok,
    a. "Copy staging to production"
       Backend upgrade from Staging
    b. Manually release apps in the IOS/MACOS/Android.Windows store
       No api available for this!

## Manual

1. have a tested version available in growerp.org
2. send all new apps to the various stores with manageble release
3. wait for all stores to approve (but not release)
4. upgrade the backend and apps and set new version Check the backend version is really new5. release all apps at the stores.
    windows: https://partner.microsoft.com/en-us/dashboard/home
    playstore: https://play.google.com/console/u/0/developers/8169559093702942817/app-list?pli=1
    linux: 
    appstore


# BACKEND new backends should work with the old versions of the apps.

1. upgrade the backend from test version 
    a. login: gcloud compute ssh growerpcom
    b. run script

increment version code(0.0.0+??) in pubspec.yaml

# APPSTORE (on MAC computer)
1. create new version in the appstore https://appstoreconnect.apple.com/apps
    same as app version in pubspec
1. flutter upgrade
2. cd growerp
2. git pull
3. melos clean
4. melos bootstrap
5. melos build
6. melos l10n

## IOS
    increase the version extension
    in app dir: flutter build ipa -> upload in transporterq
    update screenshots where required
    change userId/password
## MACOS
    increase the version extension (mac and ios cannot have the same
    in app dir:
        flutter clean
        flutter build macos --config-only
        open macos/Runner.xcworkspace 
    in xcode: product => archive (wait for build to finish)
          validate
          distribute
    create new company/user, so payment is not shown

# PLAYSTORE
1. Update screenshots if required
2. create new version + extension
3. flutter clean && flutter build appbundle
4. create new release:  https://play.google.com/console &&
     upload bundle in the browser OR
         upload bundle and screenshots:
           cd android
           fastlane supply \
            --aab ../build/app/outputs/bundle/release/app-release.aab \
            --track production --in_app_update_priority 3

#WINSTORE (on windows computer)
1. flutter upgrade
2. cd growerp
2. git pull
3. melos clean
4. melos bootstrap
5. melos build
6. melos l10n
    in pubspec: update msix version
    in app dir: dart run msix:create
goto upload:
  https://partner.microsoft.com/en-us/dashboard/apps-and-games/overview
  change userId/password in: additional testing information

#SNAPSTORE
in the appdir:
    in snapcraft.yaml update version!
    ./build-snap.sh
    snapcraft upload growerp-admin_1.14.0_amd64.snap --release=stable|
    
    
    


