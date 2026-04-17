# GrowERP GitHub Actions Guide

This document describes all GitHub Actions workflows used in the GrowERP repository, including trigger conditions, input variables, required secrets, and where to find or generate each secret value.

---

## Table of Contents

1. [Overview](#overview)
2. [Workflow Summary](#workflow-summary)
3. [Workflows](#workflows)
   - [Integration Tests (`test.yml`)](#1-integration-tests-testyml)
   - [Update Staging (`release.yml`)](#2-update-staging-releaseyml)
   - [Publish to Stores (`publish-to-stores.yml`)](#3-publish-to-stores-publish-to-storesyml)
   - [Release Approved Submissions (`release-approved-submissions.yml`)](#4-release-approved-submissions-release-approved-submissionsyml)
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

GrowERP uses six GitHub Actions workflows to automate testing, releasing Docker images, and publishing to platform stores. All workflows live in `.github/workflows/`.

```
.github/workflows/
├── test.yml                              # Integration tests (scheduled + manual)
├── release.yml                           # Docker image build + version bump (manual)
├── publish-to-stores.yml                 # Build & submit to stores (manual)
├── release-approved-submissions.yml      # Release store-approved versions to public (manual)
├── stage-to-production.yml              # Promote staging Docker stack to production (manual)
└── revert-last-sync.yml                 # Revert last production promotion (manual)
```

---

## Workflow Summary

| Workflow | Trigger | Runner | Secrets needed |
|----------|---------|--------|----------------|
| Integration Tests | Schedule (daily) + manual | `ubuntu-latest` | None (uses `GITHUB_TOKEN`) |
| Update Staging | Manual | `ubuntu-latest` | `GITHUB_TOKEN` |
| Publish to Stores | Manual | macOS / Ubuntu / Windows | See [Secrets Reference](#secrets-reference) |
| Release Approved Submissions | Manual | macOS / Ubuntu / Windows | See [Secrets Reference](#secrets-reference) |
| Stage to Production | Manual | `ubuntu-latest` | `PROD_SSH_USER`, `PROD_SSH_KEY` |
| Revert Production Update | Manual | `ubuntu-latest` | `PROD_SSH_USER`, `PROD_SSH_KEY` |

---

## Workflows

### 1. Integration Tests (`test.yml`)

**Purpose:** Runs the full Flutter integration test suite against a locally-built Moqui backend.

**Triggers:**
- **Schedule:** Daily at 12:00 PM Bangkok time (05:00 UTC). Only runs if there were commits in the last 24 hours affecting `flutter/**` or `moqui/runtime/component/**`.
- **Manual (`workflow_dispatch`):** Run at any time from the Actions tab.

**Concurrency:** Only one test run per branch at a time; new runs cancel in-progress runs.

**Manual Input Variables:**

| Input | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `package_filter` | string | No | *(empty)* | Filter to a single package name (e.g. `catalog`). When empty, all 4 parallel slices run. |

**Job Flow:**

```
check-changes
    └── integration-tests (matrix: 4 slices, or 1 if package_filter set)
            └── summarize
```

**What it does:**
1. Checks if there are any relevant recent commits (skips if none on a scheduled run).
2. Frees disk space on the runner (removes Android SDK, .NET, Haskell etc.).
3. Checks out the repo and initialises all git submodules.
4. Builds the Moqui backend Docker image from local source using Gradle + Java 21.
5. Builds a Flutter test runner Docker image (cached via GitHub Actions cache).
6. Starts the Moqui backend + PostgreSQL via Docker Compose.
7. Runs the integration tests, splitting across 4 parallel matrix slices (or filtering to one package).
8. Uploads test logs as artifacts (retained 7 days).
9. Produces a combined summary of all slices.

**Secrets required:** None beyond the automatic `GITHUB_TOKEN`.

---

### 2. Update Staging (`release.yml`)

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

### 3. Publish to Stores (`publish-to-stores.yml`)

**Purpose:** Builds and publishes GrowERP apps to one or more app stores. Each platform runs as an independent parallel job. iOS, macOS, and Android also bump the build number (stored in `pubspec.yaml`) and commit it back.

**Trigger:** Manual only (`workflow_dispatch`).

**Concurrency:** Only one store deploy at a time; running deploys are never cancelled.

**Manual Input Variables:**

| Input | Type | Required | Default | Options | Description |
|-------|------|----------|---------|---------|-------------|
| `apps` | string | Yes | `admin,hotel` | — | Comma-separated app names to submit (e.g. `admin,hotel,freelance,health`). |
| `stores` | string | Yes | `ios,macos,android,windows,snap` | — | Comma-separated stores to deploy to. |
| `track` | choice | Yes | `beta` | `beta`, `stable` | Release track. `beta` = TestFlight only (no review submission). `stable` = submit to App Store review / production. |

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
7. Runs Fastlane lanes: `codesign`, `ci_build`, `upload`.

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
3. Uploads the `.aab` to Google Play via `r0adkll/upload-google-play@v1`.

**Job: `deploy-windows`** — Runs on `windows-latest`.
1. Imports the PFX signing certificate into the Windows certificate store.
2. Builds the MSIX package (`flutter pub run msix:create`).
3. Authenticates with Azure AD and submits to Microsoft Partner Center via the Ingestion API.

**Job: `deploy-snap`** — Runs on `ubuntu-22.04`.
1. Installs `snapcraft` (with retry logic for flaky snap daemon).
2. Pre-installs `core22` base snap.
3. Builds the Flutter Linux release.
4. Syncs the version from `pubspec.yaml` into `snapcraft.yaml`.
5. Packs and uploads the snap to the Snap Store.

**Job: `commit-version`** — Commits the bumped `pubspec.yaml` files back to the branch after at least one of iOS / macOS / Android succeeds.

---

### 4. Release Approved Submissions (`release-approved-submissions.yml`)

**Purpose:** Checks each store for versions that have passed review but are held pending a manual developer release action, then releases them to the public. No build step — this workflow only calls store APIs.

**Trigger:** Manual only (`workflow_dispatch`).

**Concurrency:** Only one release run at a time; never cancelled.

**Manual Input Variables:**

| Input | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `apps` | string | Yes | `admin,hotel` | Comma-separated app names to check. |
| `stores` | string | Yes | `ios,macos,android,windows,snap` | Comma-separated stores to check. |

**What each platform checks and how it releases:**

| Platform | "Held" state | Release action |
|----------|-------------|----------------|
| iOS | `PENDING_DEVELOPER_RELEASE` on App Store Connect | Fastlane Spaceship `AppStoreVersionReleaseRequest` |
| macOS | `PENDING_DEVELOPER_RELEASE` on App Store Connect | Same as iOS |
| Android | `draft` release on production track (Google Play managed publishing) | Google Play API: update release status to `completed` and commit edit |
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

---

### Snap Store Secrets

Used by: `deploy-snap`

| Secret | Format | Where to find / how to generate |
|--------|--------|----------------------------------|
| `SNAPCRAFT_STORE_CREDENTIALS` | Snapcraft credentials token | On a machine with `snapcraft` installed and logged in, run: `snapcraft export-login --snaps growerp-admin,growerp-hotel --channels beta,stable,edge --acls package_upload,package_release - 2>/dev/null`. This prints a credentials token to stdout. Paste that token as the secret value. `package_upload` is needed by Publish to Stores; `package_release` is additionally needed by Release Approved Submissions to promote beta → stable. Credentials expire — regenerate periodically. |

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
| Actions → General → Workflow permissions | **Read and write permissions** | `release.yml` (git push, tagging) |
| Packages → Inherit access from repository | **Enabled** | `release.yml` (ghcr.io image publishing) |

### External Service Roles

| Service | Role / Permission | Required by |
|---------|------------------|-------------|
| App Store Connect | API key with **App Manager** role | iOS + macOS deploy |
| Google Play Console | Service account with **Release Manager** role | Android deploy |
| Microsoft Partner Center | Azure AD app with **Manager** role | Windows deploy |
| Snap Store | `package_upload` ACL for the relevant snaps | Snap deploy |
| Production server | SSH access for `PROD_SSH_USER` | Stage-to-production + Revert |
| Match certs repository | GitHub PAT with `repo` scope | iOS deploy |
