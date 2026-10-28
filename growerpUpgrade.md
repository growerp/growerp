# upgrading Growerp production

## Automated

The GrowERP release process is two alternating cycles of GitHub workflows (B → A →
B → A ...). Production always runs the version the stores approved, the store review
backend (backend.growerp.net) the version in store review, staging the version after
the review version. Nothing is rebuilt on the way: every "update staging" run gets a
new version (patch, minor or major), and production gets exactly the image that was
reviewed. "update staging" can run any time, except between B3 and B4.

`./growerpUpgrade.sh` walks these cycles: it runs the workflows with gh, waits for each
run and asks for the human steps. `./growerpUpgrade.sh -n` is a dry run: every prompt,
but the workflows and the GitHub release are only shown. A cycle starts at a chosen step, so
a restart after a failure skips the steps done (after a freeze it suggests the
submit step). In B4, before publishing the binary, it creates the
store screenshots when screens changed since the last screenshots run or its artifact
(kept 7 days) expired (`./growerpUpgrade.sh prepare`). Just before
the freeze (B3) it creates the GitHub release of the version to submit
(`./growerpUpgrade.sh release`):
Claude (`claude -p`) writes the title and notes from the commits since the previous
release, in the form of the previous release notes; checked in the editor before publishing.

### A. Update production

1. Wait for the store approvals (stores can approve at different times).
2. "update production" (source: review), for the approved apps or all at once
   promotes the versions the stores reviewed (review-versions.conf), not staging.
   It also points the promoted apps' newer native builds back at
   backend.growerp.org. Source staging is refused while store review routing is on.
3. "release approved store submissions", for the same apps
   releases every app that passed review and is waiting for a manual release
   action (IOS/MACOS/Android/Windows). Snap is off by default.

### B. Prepare a new version for review

1. Prepare the new release in staging: "update staging" on master, where all
   development happens: that run is the version to submit. Create the
   userid/password for the store reviewers on staging (the review backend is a copy:
   later staging changes do not reach it).
2. Wait until review is empty: every version in review is on production (cycle A).
   Step 3 refuses until then. The script lists the apps still in review with their
   store approvals (status workflow, refreshed on request) and lets
   steps 1 and 2 run meanwhile.
3. "freeze for review"
   copies staging to backend.growerp.net, pauses its jobs/agents, records the
   versions in review-versions.conf and, once healthy, routes native apps newer
   than production to it. The review backend stays running between cycles, the
   next freeze replaces it. The script then creates the review branch (e.g. 1.22)
   at the frozen version tag: development goes on on master. Review branches are
   never deleted.
4. "create store screenshots" (opt), "publish binary to stores": submit for review,
   then "publish metadata to stores" (opt), all on the review branch (master has
   moved on). The binary creates the new store version, metadata can only write
   into it; the Windows binary submission carries its listing itself, so metadata
   leaves Windows out by default. No "update staging" between step 3 and this step: the binaries must be the frozen version.
   Their commits (build numbers, screenshots) stay on the review branch: the next
   publish takes the build numbers from the stores.

The first "update staging" on master after a freeze is a minor bump (1.22 in review →
master 1.23.0): the patch versions 1.22.N belong to the review branch. The script
proposes it.

### Fix the version in review

1. Fix on master first (test first), then `git cherry-pick` the fix onto the review
   branch and push.
2. `./growerpUpgrade.sh staging` on the review branch: patch bump (1.22.3 → 1.22.4).
   Staging runs the older version until the next "update staging" on master;
   migrations of the newer version stay in the staging database.
3. Freeze again: review is open, so by hand on the server
   `./review.sh freeze --force --apply` (see the warning below), then
   `./growerpUpgrade.sh review` from step 5 to publish the fixed binaries.

### When a store approval takes too long (mostly new apps)

Everything is per app, only the next freeze (B3) waits for every app in review.

1. Promote what is approved: "update production" for the approved apps and moqui
   (the backend has no Application row, so it changes no app's routing). The slow
   app stays in review, its reviewers keep backend.growerp.net.
2. A new app without store users yet: promote it anyway. Nobody can be forced to
   update. Its review build then has the production version and the reviewer
   lands on production: create the reviewer userid/password on production first.
3. Skip the app this cycle (an existing app whose review is stuck): cancel its
   store submission, then on the server `./review.sh drop <app> --apply`: removes it
   from review-versions.conf (the freeze no longer waits for it) and points its
   Application row back at staging. Resubmit it with the next version (cycle B).

Don't use `./review.sh freeze --force` while an app is still in review: it replaces
the review backend and the recorded versions, its reviewers lose their backend.

## when cleardb production

1. apps-prod.yml set - DB_DATA=INSTALL
2. run ./clearDb.sh prod --apply
3. run https://backend.growerp.com/vapps change password 'SystemSupport'
4. write the Application versions + backend url again (the clear reloads the rows
   from seed data without them, so routing and forced updates stop working):
   on the server `cd ~/server/swarm && ./sync-to-prod.sh --versions-only`
   (writes right away, no --apply: version of each running prod app, backend url
   backend.growerp.org). During a store review run `./review.sh on --apply` after it.
   Check: tools -> entity 'application' -> admin assm: business
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
    c. run the data migrations of the new version(s): see migration/README.md

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
    
    
    


