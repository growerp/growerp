# upgrading Growerp production

## Automated

The GrowERP release process is a cycle of GitHub workflows. Production always runs
the version the stores approved, the store review backend (backend.growerp.net) the
version in store review, staging the version after the review version. Nothing is
rebuilt on the way: every "update staging" run gets a new version (patch, minor or
major), and production gets exactly the image that was reviewed.

1. "update staging" (any time)
   builds and deploys to staging with a new version
2. Submit to the stores, in this order and without "update staging" in between:
    a. "update staging" with the version to submit
    b. create the userid/password for the store reviewers on staging (the review
       backend is a copy: later staging changes do not reach it)
    c. "freeze for review"
       copies staging to backend.growerp.net, pauses its jobs/agents, records the
       versions in review-versions.conf and, once healthy, routes native apps newer
       than production to it. Refuses while a version of the previous review is
       not on production yet.
    d. "create store screenshots" / "published metadata to stores" (opt)
    e. "publish binary to stores", submit for review
3. Staging continues with the version after the review version ("update staging").
4. When a store approves (apps one by one is fine):
    a. "update production" (source: review)
       promotes the versions the stores reviewed (review-versions.conf), not
       staging. It also points newer apps back at backend.growerp.org: they go to
       staging again until the next freeze. Source staging is refused while
       store review routing is on.
    b. "release approved store submissions"
       releases every app that passed review and is waiting for a manual
       release action (IOS/MACOS/Android/Windows). Snap is off by default.
5. Back to 2 for the next release. The review backend stays running, the next
   freeze replaces it.

## when cleardb production

1. apps-prod.yml set - DB_DATA=INSTALL
2. run ./clearDb.sh prod --apply
3. run https://backend.growerp.com/vapps change password 'SystemSupport'
4. check tools -> entity 'application' -> admin backend.growerp.org latest version assm: business
5. run: https://admin.growerp.com/
    a. register info@growerp.com
    b. login growerp
    c. organisation -> website -> 100000 to www and statistics google G-D7KYT9456Z


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
    
    
    


