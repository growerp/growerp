# GrowERP GitHub Actions Guide

This document describes all GitHub Actions workflows used in the GrowERP repository, including trigger conditions, input variables, required secrets, and where to find or generate each secret value.

---

## Table of Contents

1. [Overview](#overview)
2. [Workflow Summary](#workflow-summary)
3. [Workflows](#workflows)
   - [Status (`status.yml`)](#1-status-statusyml)
   - [Update Staging (`update-staging.yml`)](#2-update-staging-update-stagingyml)
   - [Publish to Stores (`publish-binary.yml`)](#3-publish-to-stores-publish-binaryyml)
   - [Release Approved Submissions (`release-approved.yml`)](#4-release-approved-submissions-release-approvedyml)
   - [Stage to Production (`stage-to-production.yml`)](#5-stage-to-production-stage-to-productionyml)
   - [Revert Production Update (`revert-last-sync.yml`)](#6-revert-production-update-revert-last-syncyml)
4. [Secrets Reference](#secrets-reference)
   - [Automatic Secrets](#automatic-secrets)
   - [Production Server Secrets](#production-server-secrets)
   - [Apple / App Store Connect Secrets](#apple--app-store-connect-secrets)
   - [iOS Code-Signing via Fastlane Match](#ios-code-signing-via-fastlane-match)
   - [macOS Code-Signing Secrets](#macos-code-signing-secrets)
   - [Android Signing Secrets](#android-signing-secrets)
   - [Google Play Secrets](#google-play-secrets)
   - [Windows Store Secrets](#windows-store-secrets)
   - [Snap Store Secrets](#snap-store-secrets)
5. [Setting Secrets in GitHub](#setting-secrets-in-github)
6. [Permissions Required](#permissions-required)

---

## Overview

GrowERP uses ten GitHub Actions workflows to automate testing, releasing Docker images, and publishing to platform stores. All workflows live in `.github/workflows/`. The six documented in detail below are the release path; the remaining four support it.

```
.github/workflows/
├── status.yml                            # Integration tests + store status (scheduled + manual)
├── update-staging.yml                    # Docker image build + version bump (manual)
├── publish-binary.yml                    # Build & submit binaries to stores (manual)
├── release-approved.yml                  # Release store-approved versions to public (manual)
├── stage-to-production.yml               # Promote staging Docker stack to production (manual)
├── revert-last-sync.yml                  # Revert last production promotion (manual)
├── publish-metadata.yml                  # Upload listing text + screenshots to stores (manual)
├── screenshots.yml                       # Capture + frame store screenshots (manual)
├── download-store-metadata.yml           # Pull live listings back into the repo (manual)
└── match-bootstrap.yml                   # One-time Apple signing bootstrap (manual)
```

---

## Workflow Summary

| Workflow | Trigger | Runner | Secrets needed |
|----------|---------|--------|----------------|
| status | Schedule (daily) + manual | `ubuntu-latest` | Store API secrets (see [Secrets Reference](#secrets-reference)) for the store-status jobs; `PROD_SSH_USER`, `PROD_SSH_KEY` for the swarm status; tests need none |
| Update Staging | Manual | `ubuntu-latest` | `GITHUB_TOKEN` |
| Publish to Stores | Manual | macOS / Ubuntu / Windows | See [Secrets Reference](#secrets-reference) |
| Release Approved Submissions | Manual | macOS / Ubuntu / Windows | See [Secrets Reference](#secrets-reference) |
| Stage to Production | Manual | `ubuntu-latest` | `PROD_SSH_USER`, `PROD_SSH_KEY` |
| Revert Production Update | Manual | `ubuntu-latest` | `PROD_SSH_USER`, `PROD_SSH_KEY` |

---

## Workflows

### 1. Status (`status.yml`)

**Purpose:** One nightly status run — the full Flutter integration test suite plus the backend Spock tests against a locally-built Moqui backend, the publish state of every app in every store, *and* the state of the production Docker swarm. All results are published as a single GitHub Pages page: <https://growerp.github.io/growerp/>.

**Triggers:**
- **Schedule:** Daily at 10 PM Bangkok time (15:00 UTC); GitHub queues scheduled runs, so the actual start is usually 1-2 hours later. The store-status jobs run every time; the test jobs only run when there were commits in the last 24 hours affecting `flutter/**` or `moqui/runtime/component/**`.
- **Manual (`workflow_dispatch`):** Run at any time from the Actions tab.

**Concurrency:** Only one status run per branch at a time; new runs cancel in-progress runs. Pages deployment uses its own `pages` concurrency group and is never cancelled.

**Manual Input Variables:**

| Input | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `package_filter` | string | No | *(empty)* | Filter to a single package name (e.g. `catalog`). When empty, all 4 parallel slices run. |
| `skip_integration_tests` | boolean | No | `false` | Only refresh the store status — skips the test runners. |

**Job Flow:**

```
check-changes                       resolve-matrix              swarm-status
    ├── backend-tests                   ├── status-ios          (ssh growerp.com:
    └── integration-tests               ├── status-macos         deploy.sh status +
        (matrix: 4 slices × mobile/     ├── status-android       image versions)
         desktop, or 1 slice when       ├── status-windows
         package_filter is set)         └── status-snap
                       ↓                       ↓                       ↓
                                     report
                                       ↓
                                  deploy-pages
```

**What it does — tests:**
1. Checks if there are any relevant recent commits (skips the test jobs if none on a scheduled run).
2. Runs the backend Spock tests of the `growerp` component against an embedded Moqui + H2.
3. Frees disk space on the runner, checks out the repo and initialises all git submodules.
4. Builds the Moqui backend Docker image from local source using Gradle + Java 21.
5. Builds a Flutter test runner Docker image (cached via GitHub Actions cache).
6. Starts the Moqui backend + PostgreSQL via Docker Compose.
7. Runs the integration tests, splitting across 4 parallel matrix slices × mobile/desktop layouts (or filtering to one package).
8. Uploads test logs as artifacts (retained 7 days).

**What it does — stores:**
1. `resolve-matrix` builds the app × store matrix from `storeApps` in `flutter/release/release_config.json`.
2. Each store job queries its API (App Store Connect, Google Play, Partner Center, Snap Store) and uploads a JSON fragment.

**What it does — report:**
1. Merges the store fragments into one matrix table (app rows × store columns) and lists apps waiting for approval.
2. Sums the test totals (backend Spock, Flutter mobile/desktop packages and tests). When the tests were skipped, the last published totals are carried over from `tests-data.json` on the Pages site and labelled with their original date.
3. Renders the swarm section from the `status-swarm` fragment: the `docker stack ps` tasks, plus a **Staging images** and a **Production images** table listing every app's running version, image, replica count and last-deployed time. Non-running tasks and incomplete replica counts (`0/1`) are red; a production version behind staging is amber. The staging/production comparison is per app — since both `Update Staging` and `Copy Staging to Production` can be run for one app at a time, apps within the same environment routinely sit at different versions.
4. Writes `index.html`, `failures.html`, `tests-data.json` for GitHub Pages, a PDF artifact (`status-report`, retained 30 days) and the run's step summary. All timestamps on the page are converted from the runner's UTC to Bangkok local time.
5. Fails the run when more than one individual test failed on a layout, or when the backend tests failed — the page is still published in that case.

**What it does — swarm:** `swarm-status` SSHes into `growerp.com` twice, both read-only. First `cd ~/server/swarm && ./deploy.sh status` (`docker stack ps` + `docker service ls`) → `status.txt`. Then an inline loop over the stack's `<app>-test` (staging) and `<app>-prod` (production) services, recording `app|env|version|image|replicas|updated` → `images.txt`. The version comes from the image's `version` label (set at build time by `release_tool.dart`), because staging is deployed from `:latest` and its tag carries no version. Both files are uploaded as the `status-swarm` fragment and are independent — one failing SSH call does not blank the other's table. The job never blocks the run; when the credentials are missing or the host is unreachable the page says the swarm status is unavailable.

**Failure drill-down:** every non-zero `Failed` count on the page links to `failures.html` on the same site, listing the failed packages, the failed test lines and the exceptions caught by the Flutter test framework, plus a link back to the workflow run for the raw logs. That detail is stored inside `tests-data.json`, so a run that skipped the tests rebuilds the same failures page from the carried-over data.

**Secrets required:** none for the test jobs; the store jobs use the App Store Connect, Google Play, Partner Center and Snap Store secrets listed in the [Secrets Reference](#secrets-reference); the swarm job uses `PROD_SSH_USER` / `PROD_SSH_KEY`.

---

### 2. Update Staging (`update-staging.yml`)

**Purpose:** Bumps app versions, builds Docker images, and pushes them to `ghcr.io/growerp`. Optionally commits a version bump and pushes a git tag.

**Trigger:** Manual only (`workflow_dispatch`).

**Concurrency:** Only one release at a time; running releases are never cancelled.

**Manual Input Variables:**

| Input | Type | Required | Default | Options | Description |
|-------|------|----------|---------|---------|-------------|
| `bump` | choice | Yes | `patch` | `patch`, `minor`, `major`, `none` | Version bump type. Use `none` to build images at the current version without committing a bump. |
| `apps` | string | No | *(empty)* | — | Comma-separated list of apps to release (e.g. `admin,hotel`). Leave empty to release all apps. |
| `comment` | string | No | *(empty)* | — | Optional comment appended to the git commit message (ignored when `bump` is `none`). |

**Job Flow:**

```
release  (single job)
```

**What it does:**
1. Checks out the repo with full history and all submodules.
2. Sets up Dart SDK and installs `dcli` + release tool dependencies.
3. Sets up Docker Buildx with layer caching.
4. Logs in to GitHub Container Registry (`ghcr.io`) using `GITHUB_TOKEN`.
5. Configures git to allow push-back over HTTPS via `GITHUB_TOKEN`.
6. Runs `dart release/release_tool.dart` with CI flags:
   - `--ci` — non-interactive mode
   - `--bump=<type>` — version bump
   - `--parallel` — build all selected apps in parallel
   - `--workspace=local` — use current checkout, no extra clone
   - `--push-docker` — push images to `ghcr.io/growerp`
   - `--push-github` — commit bump + tag and push (omitted when `bump=none`)

**Secrets required:**

| Secret | Auto-provided | Used for |
|--------|---------------|---------|
| `GITHUB_TOKEN` | Yes | Git push, ghcr.io login |

**Repository settings required:**
- Settings → Actions → General → Workflow permissions → **Read and write permissions**
- Settings → Packages → **Inherit access from repository**

---

### 3. Publish to Stores (`publish-binary.yml`)

**Purpose:** Builds and publishes GrowERP apps to one or more app stores. Each platform runs as an independent parallel job. iOS, macOS, and Android also bump the build number (stored in `pubspec.yaml`) and commit it back.

**Trigger:** Manual only (`workflow_dispatch`).

**Concurrency:** Only one store deploy at a time; running deploys are never cancelled.

**Manual Input Variables:**

| Input | Type | Default | Options | Description |
|-------|------|---------|---------|-------------|
| `app_admin` … `app_marketing` | boolean | all on | — | One checkbox per app (admin, hotel, freelance, support, agents, rental, marketing). |
| `store_ios` / `store_macos` / `store_android` / `store_windows` / `store_snap` | boolean | all on | — | Stores to deploy to. |
| `track` | choice | `beta` | `beta`, `stable` | Release track. `beta` = TestFlight only (no review submission). `stable` = submit to App Store review / production. |
| `android_release_status` | choice | `auto` | `auto`, `draft`, `completed` | Google Play release status. `auto` = `draft` on the production track (manual release gate), resolved from prior releases on beta. `completed` overrides the gate and rolls out on approval. |

**Release gate:** submitting a binary never makes it go live by itself. Every store that
has a release-mode setting is checked on each submit and forced to manual, so
[`release-approved.yml`](#4-release-approved-submissions-release-approvedyml) stays the single
place where an app goes public:

| Store | Setting checked | Forced to |
|-------|-----------------|-----------|
| iOS / macOS | App Store version `releaseType` | `MANUAL` — Fastfile passes `automatic_release: false`, then `ensure_manual_release` re-reads every unreleased version and patches any that is still `AFTER_APPROVAL` |
| Android | production-track release `status` | `draft` — Play exposes no API for the app-level managed-publishing switch, so a staged draft is the equivalent. Beta is left alone so testers still get builds immediately |
| Windows | submission `targetPublishMode` | `Manual` — a cloned submission inherits `Immediate` from the last published one, which would go live straight out of certification |
| Snap | — | Nothing to force: the Snap Store has no review or hold state, so `track` alone decides the channel. `beta` is the safe default; `stable` is live on upload |

**Job Flow:**

```
resolve-matrix ──┬──> bootstrap ──┬──> deploy-ios     ─┐
                 │                ├──> deploy-macos    ─┤──> commit-version
                 │                ├──> deploy-android  ─┘
                 │                ├──> deploy-windows
                 └────────────────┴──> deploy-snap
                 └──> bump-version ──> deploy-ios / deploy-macos / deploy-android
```

**Job: `resolve-matrix`** — Converts the comma-separated `apps` and `stores` inputs into JSON matrix arrays for downstream jobs. Sets `run_<platform>` flags.

**Job: `bootstrap`** — Runs once on Ubuntu. Bootstraps the Melos workspace, runs code generation (Freezed, Retrofit, l10n), and uploads the generated sources as an artifact so no other job needs to regenerate them.

**Job: `bump-version`** — Increments the `+<build_number>` in each selected app's `pubspec.yaml`. Uploads the bumped pubspecs as an artifact. Only runs when iOS, macOS, or Android is targeted.

**Job: `deploy-ios`** — Runs on `macos-latest`.
1. Validates all required iOS secrets are present.
2. Restores bumped pubspecs and generated sources.
3. Sets up Flutter (stable) and Ruby 3.2.
4. Builds the Flutter iOS app (no codesign).
5. Runs `pod install`.
6. Validates access to the Match certificate repository.
7. Runs Fastlane lanes: `codesign`, `ci_build`, `upload`. On `stable`, `upload` submits for review and then forces the version's release type to `MANUAL`.

**Job: `deploy-macos`** — Runs on `macos-latest`.
1. Validates all required macOS secrets are present (including the app-specific provisioning profile).
2. Imports the signing certificate into a temporary keychain.
3. Installs the provisioning profile.
4. Runs `pod install` and `flutter build macos --release`.
5. Archives with `xcodebuild`, generates export options, exports the `.pkg`.
6. Uploads the `.pkg` to App Store Connect using `xcrun altool`.

**Job: `deploy-android`** — Runs on `ubuntu-latest`.
1. Writes the keystore file and `key.properties` from secrets.
2. Builds the Flutter app bundle (`flutter build appbundle --release`).
3. Resolves the release status — `draft` on the production track so the release is staged, not rolled out.
4. Uploads the `.aab` to Google Play via `r0adkll/upload-google-play@v1`.

**Job: `deploy-windows`** — Runs on `windows-latest`.
1. Imports the PFX signing certificate into the Windows certificate store.
2. Builds the MSIX package (`flutter pub run msix:create`).
3. Authenticates with Azure AD and submits to Microsoft Partner Center via the Ingestion API, forcing `targetPublishMode` to `Manual`.

**Job: `deploy-snap`** — Runs on `ubuntu-22.04`.
1. Installs `snapcraft` (with retry logic for flaky snap daemon).
2. Pre-installs `core22` base snap.
3. Builds the Flutter Linux release.
4. Syncs the version from `pubspec.yaml` into `snapcraft.yaml`.
5. Packs and uploads the snap to the Snap Store.

**Job: `commit-version`** — Commits the bumped `pubspec.yaml` files back to the branch after at least one of iOS / macOS / Android succeeds.

---

### 4. Release Approved Submissions (`release-approved.yml`)

**Purpose:** Checks each store for versions that have passed review but are held pending a manual developer release action, then releases them to the public. No build step — this workflow only calls store APIs.

**Trigger:** Manual only (`workflow_dispatch`).

**Concurrency:** Only one release run at a time; never cancelled.

**Manual Input Variables:**

| Input | Type | Default | Description |
|-------|------|---------|-------------|
| `app_admin` … `app_marketing` | boolean | `true` | One checkbox per app (admin, hotel, freelance, support, agents, rental, marketing). |
| `store_ios` / `store_macos` / `store_android` / `store_windows` | boolean | `true` | Stores to check for approved-but-held versions. |
| `store_snap` | boolean | `false` | Promote `latest/beta` to `stable`. Off by default: the Snap Store has no review gate, so every run would push whatever sits in beta straight to stable users. |

Apps are intersected with `storeApps` in `flutter/release/release_config.json`, so an app is only
checked on the stores it is actually published on (e.g. `support` is android + snap only).

**What each platform checks and how it releases:**

| Platform | "Held" state | Release action |
|----------|-------------|----------------|
| iOS | `PENDING_DEVELOPER_RELEASE` on App Store Connect | Fastlane Spaceship `AppStoreVersionReleaseRequest` |
| macOS | `PENDING_DEVELOPER_RELEASE` on App Store Connect | Same as iOS |
| Android | `draft` release on production track | Google Play API: set release status to `completed` and commit the edit. If Play refuses to send the changes for review automatically, it commits with `changesNotSentForReview` and prints a notice to finish in Play Console → Publishing overview → **Send changes for review**. |
| Windows | `ReadyToPublish` pending submission in Partner Center | Partner Center Ingestion API publish call |
| Snap | Any revision present in `latest/beta` channel | `snapcraft release <snap> <revision> stable` |

If no held version is found for a given app/platform combination, the job exits cleanly with a message — it is not an error.

**Secrets required:** Same as Publish to Stores — no additional secrets needed.

---

### 5. Stage to Production (`stage-to-production.yml`)

**Purpose:** SSHs into the production server (`growerp.com`) and runs `swarm/sync-to-prod.sh` to promote the staging Docker stack to production.

**Trigger:** Manual only (`workflow_dispatch`).

**Concurrency:** Only one sync at a time; never cancelled.

**Manual Input Variables:** None.

**Secrets required:**

| Secret | Description |
|--------|-------------|
| `PROD_SSH_USER` | SSH username on `growerp.com` |
| `PROD_SSH_KEY` | SSH private key for the production server |

---

### 6. Revert Production Update (`revert-last-sync.yml`)

**Purpose:** SSHs into the production server and runs `swarm/revert-prod.sh` to roll back the last production promotion.

**Trigger:** Manual only (`workflow_dispatch`).

**Concurrency:** Only one revert at a time; never cancelled.

**Manual Input Variables:** None.

**Secrets required:** Same as Stage to Production.

| Secret | Description |
|--------|-------------|
| `PROD_SSH_USER` | SSH username on `growerp.com` |
| `PROD_SSH_KEY` | SSH private key for the production server |

---

## Secrets Reference

All secrets are stored under **Settings → Secrets and variables → Actions** in the GitHub repository (or organisation-level secrets).

### Automatic Secrets

| Secret | Source | Description |
|--------|--------|-------------|
| `GITHUB_TOKEN` | Auto-injected by GitHub | Used for git push, tagging, and `ghcr.io` login. No setup required. |

---

### Production Server Secrets

Used by: `stage-to-production.yml`, `revert-last-sync.yml`

| Secret | Format | Where to find / how to generate |
|--------|--------|----------------------------------|
| `PROD_SSH_USER` | Plain string | The Linux username used to SSH into `growerp.com` (e.g. `deploy` or `ubuntu`). Ask your infrastructure team. |
| `PROD_SSH_KEY` | PEM private key (plain text, including `-----BEGIN ... KEY-----` headers) | Generate with `ssh-keygen -t ed25519 -C "github-actions"`. Add the public key to `~/.ssh/authorized_keys` on the production server. Paste the private key as the secret value. |

---

### Apple / App Store Connect Secrets

Used by: `deploy-ios`, `deploy-macos`

These three secrets authenticate CI against the App Store Connect API. A single API key can be shared between iOS and macOS jobs.

| Secret | Format | Where to find / how to generate |
|--------|--------|----------------------------------|
| `APP_STORE_CONNECT_API_KEY_ID` | String (e.g. `ABC123DEFG`) | App Store Connect → Users and Access → Integrations → App Store Connect API → **Key ID** column. |
| `APP_STORE_CONNECT_API_ISSUER_ID` | UUID string | Same page as above → **Issuer ID** (shown at the top of the Keys table). |
| `APP_STORE_CONNECT_API_KEY_CONTENT` | Base64-encoded `.p8` file | 1. Generate a new API key on App Store Connect (or download an existing one — it can only be downloaded once). 2. Encode: `base64 -i AuthKey_XXXXXXX.p8 | tr -d '\n'`. 3. Paste the result as the secret. |

> **Note:** The `.p8` file can only be downloaded once. Store it securely (e.g. 1Password). If lost, generate a new key.

---

### iOS Code-Signing via Fastlane Match

Used by: `deploy-ios`

GrowERP uses [Fastlane Match](https://docs.fastlane.tools/actions/match/) to sync iOS certificates and provisioning profiles from a private Git repository.

| Secret | Format | Where to find / how to generate |
|--------|--------|----------------------------------|
| `MATCH_GIT_URL` | Git URL (HTTPS, e.g. `https://github.com/org/certs-repo.git`) | The URL of the private Git repository that stores your Match certificates. This is the repo you passed to `fastlane match init`. |
| `MATCH_GIT_BASIC_AUTHORIZATION` | Base64-encoded `username:token` | Run: `printf '%s' 'github_user:ghp_your_pat' \| base64`. The PAT needs `repo` scope on the certs repository. Paste the base64 output as the secret. |
| `MATCH_PASSWORD` | Plain string (passphrase) | The encryption passphrase used when the Match repository was first set up (`fastlane match init` prompted for it). Store it securely — it was chosen by whoever ran `fastlane match` the first time. |

---

### macOS Code-Signing Secrets

Used by: `deploy-macos`

macOS now uses [Fastlane Match](https://docs.fastlane.tools/actions/match/), the same certificate repository flow used by iOS.

| Secret | Format | Where to find / how to generate |
|--------|--------|----------------------------------|
| `MATCH_GIT_URL` | Git URL (HTTPS, e.g. `https://github.com/org/certs-repo.git`) | The private Match repository that stores Apple signing assets for both iOS and macOS. |
| `MATCH_GIT_BASIC_AUTHORIZATION` | Base64-encoded `username:token` | Run: `printf '%s' 'github_user:ghp_your_pat' \| base64`. The token must have access to the Match repo. |
| `MATCH_PASSWORD` | Plain string (passphrase) | The Match encryption password chosen when the certificates repo was initialized. |

To create or refresh macOS signing assets on a Mac:

```bash
cd flutter
bundle install --gemfile fastlane/Gemfile
fastlane match appstore --platform macos --app_identifier org.growerp.admin,org.growerp.hotel
```

To verify the shared Match repo contents locally:

```bash
cd flutter
BUNDLE_ID=org.growerp.admin bundle exec fastlane codesign_macos
BUNDLE_ID=org.growerp.hotel bundle exec fastlane codesign_macos
```

The workflow resolves the installed Match provisioning profile by bundle ID and archives with the `Apple Distribution` identity for Mac App Store upload.

> **Apple Developer Portal:** [developer.apple.com](https://developer.apple.com) → Account → Certificates, Identifiers & Profiles.
> The Development Team ID used in the workflow is `P64T65C668`.

---

### Android Signing Secrets

Used by: `deploy-android`

| Secret | Format | Where to find / how to generate |
|--------|--------|----------------------------------|
| `ANDROID_KEYSTORE_BASE64` | Base64-encoded `.jks` / `.keystore` file | 1. Generate: `keytool -genkey -v -keystore release.jks -alias <alias> -keyalg RSA -keysize 2048 -validity 10000`. 2. Encode: `base64 -i release.jks \| tr -d '\n'`. If you already have a keystore, just encode the existing file. |
| `ANDROID_KEY_ALIAS` | Plain string | The alias you used when generating the keystore (e.g. `release`). |
| `ANDROID_KEY_PASSWORD` | Plain string | The password for the key entry inside the keystore. |
| `ANDROID_STORE_PASSWORD` | Plain string | The password for the keystore file itself (may be the same as `ANDROID_KEY_PASSWORD`). |

> **Important:** The keystore is permanent — if lost, you cannot update your Play Store listing. Store the `.jks` file and its passwords in a secure location (e.g. 1Password, a private encrypted repo).

---

### Google Play Secrets

Used by: `deploy-android`

| Secret | Format | Where to find / how to generate |
|--------|--------|----------------------------------|
| `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` | Raw JSON string | 1. Open [Google Play Console](https://play.google.com/console). 2. Setup → API access → Link to a Google Cloud project. 3. In Google Cloud Console → IAM & Admin → Service Accounts → Create a service account. 4. Grant it the **Release Manager** role in Play Console. 5. Create a JSON key for the service account. 6. Paste the entire JSON file contents as the secret value (not base64-encoded — the action reads it as plain text). |

---

### Windows Store Secrets

Used by: `deploy-windows`

#### Code-Signing Certificate

| Secret | Format | Where to find / how to generate |
|--------|--------|----------------------------------|
| `WINDOWS_CERTIFICATE_BASE64` | Base64-encoded `.pfx` file | Purchase or obtain a **code-signing certificate** from a CA (e.g. DigiCert, Sectigo). Export as `.pfx`. Encode: `[Convert]::ToBase64String([IO.File]::ReadAllBytes('cert.pfx'))` (PowerShell) or `base64 -i cert.pfx \| tr -d '\n'` (bash). |
| `WINDOWS_CERTIFICATE_PASSWORD` | Plain string | The password set when exporting the `.pfx`. |

#### Microsoft Partner Center (Ingestion API)

Authentication uses an Azure AD app registration with the Partner Center API.

| Secret | Format | Where to find / how to generate |
|--------|--------|----------------------------------|
| `WINDOWS_TENANT_ID` | UUID | [Azure Portal](https://portal.azure.com) → Azure Active Directory → Overview → **Tenant ID**. |
| `WINDOWS_CLIENT_ID` | UUID | Azure Portal → Azure AD → App registrations → your app → **Application (client) ID**. To create: register a new app, then go to [Partner Center](https://partner.microsoft.com/en-us/dashboard) → Account settings → User management → Azure AD applications → Associate the app and grant it the **Manager** role. |
| `WINDOWS_CLIENT_SECRET` | Plain string | Azure Portal → App registrations → your app → Certificates & secrets → New client secret. Copy the **Value** immediately (shown only once). |
| `WINDOWS_ADMIN_PRODUCT_ID` | Store ID string (e.g. `9NWX6KFTJNQL`) | [Partner Center](https://partner.microsoft.com/en-us/dashboard) → Apps and games → select the **admin** app → Product identity → **Store ID**. Must be the published Store ID, not a draft. |
| `WINDOWS_HOTEL_PRODUCT_ID` | Store ID string | Same as above for the **hotel** app. |
| `WINDOWS_FREELANCE_PRODUCT_ID` | Store ID string | Same as above for the **freelance** app. |
| `WINDOWS_RENTAL_PRODUCT_ID` | Store ID string | Same as above for the **rental** app. |
| `WINDOWS_AGENTS_PRODUCT_ID` | Store ID string | Same as above for the **agents** app. |
| `WINDOWS_MARKETING_PRODUCT_ID` | Store ID string | Same as above for the **marketing** app. |

---

### Snap Store Secrets

Used by: `deploy-snap`, `upload-metadata-snap`

| Secret | Format | Where to find / how to generate |
|--------|--------|----------------------------------|
| `SNAPCRAFT_STORE_CREDENTIALS` | Snapcraft credentials token | On a machine with `snapcraft` installed and logged in, run: `snapcraft export-login --snaps growerp-admin,growerp-hotel --channels beta,stable,edge --acls package_upload,package_release - 2>/dev/null`. This prints a credentials token to stdout. Paste that token as the secret value. `package_upload` is needed by Publish to Stores (binary uploads and, via `upload-metadata-snap`, listing text/screenshots); `package_release` is additionally needed by Release Approved Submissions to promote beta → stable. Credentials expire — regenerate periodically. |

> **Snapcraft login:** `snapcraft login` uses your [Ubuntu One](https://login.ubuntu.com) / Snap Store developer account.

---

## Setting Secrets in GitHub

1. Go to your repository on GitHub.
2. Click **Settings** → **Secrets and variables** → **Actions**.
3. Click **New repository secret**.
4. Enter the secret **Name** (exactly as listed in this document) and its **Value**.
5. Click **Add secret**.

For organisation-wide secrets (shared across repos):
- Go to your **Organisation** → **Settings** → **Secrets and variables** → **Actions** → **New organisation secret**.
- Choose which repositories can access it.

---

## Permissions Required

### Repository Settings

| Setting | Value | Required by |
|---------|-------|-------------|
| Actions → General → Workflow permissions | **Read and write permissions** | `update-staging.yml` (git push, tagging) |
| Packages → Inherit access from repository | **Enabled** | `update-staging.yml` (ghcr.io image publishing) |

### External Service Roles

| Service | Role / Permission | Required by |
|---------|------------------|-------------|
| App Store Connect | API key with **App Manager** role | iOS + macOS deploy |
| Google Play Console | Service account with **Release Manager** role | Android deploy |
| Microsoft Partner Center | Azure AD app with **Manager** role | Windows deploy |
| Snap Store | `package_upload` ACL for the relevant snaps | Snap deploy + Snap metadata upload |
| Production server | SSH access for `PROD_SSH_USER` | Stage-to-production + Revert + swarm status |
| Match certs repository | GitHub PAT with `repo` scope | iOS deploy |
