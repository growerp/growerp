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
   backend.growerp.org. Source staging skips (and refuses by name) the apps still in
   store review; moqui and apps already promoted from review may come from staging.
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
   leaves Windows out by default.
   "Update staging" on master may run meanwhile: the binaries are built from the
   review branch.
   Their commits (build numbers, screenshots) stay on the review branch: the next
   publish takes the build numbers from the stores.

The first "update staging" on master after a freeze is a minor bump (1.22 in review →
master 1.23.0): the patch versions 1.22.N belong to the review branch. The script
proposes it, and the workflow turns a patch bump into a minor bump by itself once
the review backend runs master's minor (so also the weekly scheduled run). Between
cutting the review branch and the freeze, the store builds use staging, so staging
stays on patch bumps of that minor.

### Fix the version in review

A backend fix, like a production hotfix:

1. Fix on master first (test first), then `git cherry-pick` the fix onto the review
   branch and push.
2. `gh workflow run hotfix-review.yml --ref 1.22`, only after staging moved on to the
   next minor (master 1.23.0; it refuses before): builds growerp-moqui 1.22.N+1 from
   the review branch (version tag only, staging keeps its version), points
   moqui-review at it and records it in review-versions.conf, so "update production"
   promotes the fixed backend. Then copy `apps-review.yml` and `review-versions.conf`
   from the server into the server repo.

A fix that needs new binaries:

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

Promoting never forces an app update: `Application.version` only routes a newer app
(the one in review) to the review backend, an older app keeps production. Users are
forced to update only below `Application.minVersion` (major.minor, empty = never).
Raise it per app in the support app (Applications), only when its new version is
live in every store and the backend no longer works with the older one.

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

### Resubmit approved apps from staging while others are still in review

When some apps still wait for their store approval, the approved ones can go to the
stores again with the version staging runs, without a freeze
(`./growerpUpgrade.sh review staging`, menu `2s`):

1. Promote the approved apps from review first (cycle A). The apps still in review are
   not touched: they keep backend.growerp.net and their review version.
2. The script lists the apps still in review and refuses to submit them (a new
   submission would replace their store review). Steps: reviewer login on staging,
   GitHub release of the staging tag, review branch (e.g. 1.22) at the staging tag,
   screenshots/publish binary/publish metadata from that branch, as in B4.
3. The new builds use the staging backend: production's Application row of a
   promoted app points newer versions at backend.growerp.org. The reviewers log in on
   staging, which keeps moving with master (the next "update staging" on master is a
   minor bump, the branch of its minor exists). Don't clear the staging database.
4. Once approved: `./growerpUpgrade.sh production staging` (1b) for these apps and
   moqui. Update production takes what staging runs then (newer patch or minor than
   the submitted build is fine: no forced update below `minVersion`) and skips the
   apps still in review.

## when cleardb production

1. apps-prod.yml set - DB_DATA=INSTALL
2. run ./clearDb.sh prod --apply
3. run https://backend.growerp.com/vapps change password 'SystemSupport'
4. write the Application versions + backend url again (the clear reloads the rows
   from seed data without them, so routing stops working; minVersion is not written,
   set it again in the support app if an app needs a forced update):
   on the server `cd ~/server/swarm && ./sync-to-prod.sh --versions-only`
   (writes right away, no --apply: version of each running prod app, backend url
   backend.growerp.org). During a store review run `./review.sh on --apply` after it.
   Check: tools -> entity 'application' -> admin assm: business
5. run: https://admin.growerp.com/
    a. register info@growerp.com
    b. login growerp
    c. organisation -> website -> 100000 to www and statistics google G-D7KYT9456Z
