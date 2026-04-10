# Store Deploy — Secrets & Settings Setup Guide

This document explains every GitHub Actions secret and configuration value required by
`.github/workflows/publish-to-stores.yml` and `.github/workflows/release-approved-submissions.yml`.
Add secrets at: **GitHub repo → Settings → Secrets and variables → Actions → New repository secret**

---

## Workflows overview

### Publish to Stores

Go to **Actions → Publish to Stores → Run workflow** and fill in:

| Input | Description | Example |
|-------|-------------|---------|
| `apps` | Comma-separated app names | `admin,hotel` |
| `stores` | Comma-separated store targets | `ios,macos,android,windows,snap` |
| `track` | Release track | `beta` = TestFlight only · `stable` = submit for App Store review / production |

The `track` input controls iOS review submission: `beta` uploads to TestFlight without submitting for review; `stable` builds, uploads, and submits the build for App Store review.

### Release Approved Submissions

Go to **Actions → Release Approved Store Submissions → Run workflow** and fill in:

| Input | Description | Example |
|-------|-------------|---------|
| `apps` | Comma-separated app names | `admin,hotel` |
| `stores` | Comma-separated stores to check | `ios,macos,android,windows,snap` |

This workflow does **not** build anything. It queries each store API for versions that have passed review and are waiting for a manual developer release, then releases them. Run this after Apple/Google/Microsoft notifies you that your submission has been approved.

---

## Android

### Secrets

| Secret | Description |
|--------|-------------|
| `ANDROID_KEYSTORE_BASE64` | Release keystore, base64-encoded |
| `ANDROID_KEY_ALIAS` | Alias of the key inside the keystore |
| `ANDROID_KEY_PASSWORD` | Password for that key |
| `ANDROID_STORE_PASSWORD` | Password for the keystore file |
| `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` | Google Play service account credentials (JSON, plain text) |

### How to obtain each

**Keystore (`ANDROID_KEYSTORE_BASE64`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`, `ANDROID_STORE_PASSWORD`)**

If you don't have a keystore yet, create one:
```bash
keytool -genkey -v -keystore release.jks \
  -alias <YOUR_ALIAS> \
  -keyalg RSA -keysize 2048 -validity 10000
```
Then base64-encode it:
```bash
base64 -w 0 release.jks   # Linux
base64 -i release.jks     # macOS
```
Copy the output as `ANDROID_KEYSTORE_BASE64`. Store `release.jks` safely — it cannot be regenerated.

**Google Play service account (`GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`)**

1. Open [Google Play Console](https://play.google.com/console) → Setup → API access
2. Link to a Google Cloud project (or create one)
3. Click **Create new service account** → follow the link to Google Cloud Console
4. Create a service account, grant it the **Release manager** role
5. Create a JSON key for it → download the `.json` file
6. Back in Play Console, grant the service account access to the app
7. Paste the full JSON file contents as the secret value

### Version code / build number

The build number (the `+NNN` part of `version:` in `pubspec.yaml`) is automatically
incremented by the `bump-version` job before any platform build runs. A single commit
covering all selected apps is pushed to the branch; iOS and Android use that bumped
number directly. macOS uses a CI-only offset of `pubspec build number + 1`, so it can
be submitted independently while still sharing the same `pubspec.yaml`. Google Play and
App Store Connect both require the number to be strictly increasing — you never need to
bump it manually.

---

## iOS

### Secrets

| Secret | Description |
|--------|-------------|
| `APP_STORE_CONNECT_API_KEY_ID` | Key ID from App Store Connect API key |
| `APP_STORE_CONNECT_API_ISSUER_ID` | Issuer ID from App Store Connect |
| `APP_STORE_CONNECT_API_KEY_CONTENT` | Private key file contents, base64-encoded |
| `MATCH_PASSWORD` | Password used to encrypt the Fastlane Match certificate repo |
| `MATCH_GIT_BASIC_AUTHORIZATION` | Base64-encoded `username:personal_access_token` for the Match git repo |
| `MATCH_GIT_URL` | Clone URL of the private Fastlane Match certificate repo |

### How to obtain each

**App Store Connect API key (`API_KEY_ID`, `API_ISSUER_ID`, `API_KEY_CONTENT`)**

1. Sign in to [App Store Connect](https://appstoreconnect.apple.com)
2. Users and Access → Integrations → App Store Connect API → Team Keys
3. Click **+** → name it, set role to **App Manager**
4. Download the `.p8` file (only available once)
5. Note the **Key ID** and **Issuer ID** shown on that page
6. Base64-encode the `.p8`:
   ```bash
   base64 -w 0 AuthKey_XXXXXXXX.p8   # Linux
   base64 -i AuthKey_XXXXXXXX.p8     # macOS
   ```
7. Set `APP_STORE_CONNECT_API_KEY_ID` = Key ID, `APP_STORE_CONNECT_API_ISSUER_ID` = Issuer ID,
   `APP_STORE_CONNECT_API_KEY_CONTENT` = base64 output

**Fastlane Match (`MATCH_PASSWORD`, `MATCH_GIT_BASIC_AUTHORIZATION`)**

Match stores certificates and provisioning profiles encrypted in a private git repo.

1. Create a **private** GitHub repository to hold the certificates (e.g. `growerp/certificates`)
2. Run `bundle exec fastlane match init` in the iOS directory, point it at that repo
3. Run `bundle exec fastlane match appstore` (and `development` if needed) to generate and store certs
4. `MATCH_PASSWORD` = the passphrase you chose when initialising Match (used to encrypt/decrypt)
5. `MATCH_GIT_BASIC_AUTHORIZATION` = `echo -n "github_username:ghp_token" | base64`
   — use a GitHub Personal Access Token with `repo` scope for the certificates repo
6. `MATCH_GIT_URL` = the repository clone URL, for example `https://github.com/growerp/certificates.git`
7. If either secret is missing in GitHub Actions, Fastlane receives an empty string and the failure looks like `fatal: repository '' does not exist` or `Authorization: Basic ` with no value. That is a secret configuration problem, not a Match bug.

---

## macOS

### Secrets

| Secret | Description |
|--------|-------------|
| `APP_STORE_CONNECT_API_KEY_ID` | Same key as iOS (shared) |
| `APP_STORE_CONNECT_API_ISSUER_ID` | Same issuer as iOS (shared) |
| `APP_STORE_CONNECT_API_KEY_CONTENT` | Same base64 key as iOS (shared) |
| `MATCH_PASSWORD` | Same Match encryption password used for iOS |
| `MATCH_GIT_BASIC_AUTHORIZATION` | Same base64-encoded `username:personal_access_token` used for iOS |
| `MATCH_GIT_URL` | Same private Match certificates repo URL used for iOS |

### How to obtain each

macOS now uses **Fastlane Match**, the same as iOS. Create or refresh the macOS signing assets with:

```bash
cd flutter
BUNDLE_ID=org.growerp.admin bundle exec fastlane codesign_macos
BUNDLE_ID=org.growerp.hotel bundle exec fastlane codesign_macos
```

For first-time setup on a Mac, generate the Mac App Store assets with Match:

```bash
fastlane match appstore --platform macos --app_identifier org.growerp.admin,org.growerp.hotel
```

This stores the Apple Distribution certificate and Mac App Store provisioning profiles in the Match repo, so no separate macOS `.p12` or base64 provisioning profile secrets are needed.

> **Note:** The workflow hardcodes `DEVELOPMENT_TEAM=P64T65C668` in the xcodebuild step.
> Update this value in the workflow if your Apple Team ID differs.

---

## Windows (Microsoft Store)

The Windows deploy workflow assumes the app already has a published Microsoft
Store submission. The submission API creates a new submission by cloning the last
published one. For a brand-new unpublished app, complete the first submission in
Partner Center manually, including category, pricing/availability, and age ratings.

### Secrets

| Secret | Description |
|--------|-------------|
| `WINDOWS_CERTIFICATE_BASE64` | Code-signing certificate (PFX), base64-encoded |
| `WINDOWS_CERTIFICATE_PASSWORD` | Password for the PFX |
| `WINDOWS_TENANT_ID` | Azure AD tenant ID |
| `WINDOWS_CLIENT_ID` | Azure AD app (service principal) client ID |
| `WINDOWS_CLIENT_SECRET` | Client secret for the Azure AD app |
| `WINDOWS_ADMIN_PRODUCT_ID` | Microsoft Store ID for the admin app |
| `WINDOWS_HOTEL_PRODUCT_ID` | Microsoft Store ID for the hotel app |

### How to obtain each

**Code-signing certificate (`WINDOWS_CERTIFICATE_BASE64`, `WINDOWS_CERTIFICATE_PASSWORD`)**

Purchase or obtain a code-signing certificate from a trusted CA (e.g. DigiCert, Sectigo).
Export it as a `.pfx` file with a password, then:
```bash
base64 -w 0 certificate.pfx   # Linux
base64 -i certificate.pfx     # macOS
[Convert]::ToBase64String([IO.File]::ReadAllBytes("certificate.pfx"))  # PowerShell
```

**Azure AD app (`WINDOWS_TENANT_ID`, `WINDOWS_CLIENT_ID`, `WINDOWS_CLIENT_SECRET`)**

1. Open [Azure Portal](https://portal.azure.com) → Azure Active Directory → App registrations → New registration
2. Name it (e.g. `growerp-store-deploy`), single-tenant, no redirect URI
3. Note the **Application (client) ID** → `WINDOWS_CLIENT_ID`
4. Note the **Directory (tenant) ID** → `WINDOWS_TENANT_ID`
5. Certificates & secrets → New client secret → copy the value → `WINDOWS_CLIENT_SECRET`
6. In [Partner Center](https://partner.microsoft.com/dashboard), go to Account settings → User management →
   Azure AD applications → Add Azure AD application → select the app you just created → assign the
   **Manager** role

**Store IDs (`WINDOWS_ADMIN_PRODUCT_ID`, `WINDOWS_HOTEL_PRODUCT_ID`)**

1. In Partner Center, open each app
2. Copy the **Store ID** from App management → App identity
3. This is the same 12-character ID used in the public Microsoft Store URL, for example
   `https://apps.microsoft.com/detail/9NWX6KFTJNQL`
4. Do not use an internal dashboard URL identifier or a draft app record ID here; the
   submission API expects the Store ID of the published app

---

## Snap Store

### Secrets

| Secret | Description |
|--------|-------------|
| `SNAPCRAFT_STORE_CREDENTIALS` | Snapcraft login token |

### How to obtain

```bash
snapcraft export-login --snaps=growerp-admin,growerp-hotel \
  --channels=beta,stable,edge \
  --acls=package_upload,package_release -
```
Copy the printed token as the secret value. The token expires after 1 year by default.

> `package_upload` is required by **Publish to Stores**. `package_release` is additionally required by **Release Approved Submissions** to promote a beta revision to stable.

---

## Summary table

| Secret | Android | iOS | macOS | Windows | Snap |
|--------|:-------:|:---:|:-----:|:-------:|:----:|
| `ANDROID_KEYSTORE_BASE64` | ✓ | | | | |
| `ANDROID_KEY_ALIAS` | ✓ | | | | |
| `ANDROID_KEY_PASSWORD` | ✓ | | | | |
| `ANDROID_STORE_PASSWORD` | ✓ | | | | |
| `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` | ✓ | | | | |
| `APP_STORE_CONNECT_API_KEY_ID` | | ✓ | ✓ | | |
| `APP_STORE_CONNECT_API_ISSUER_ID` | | ✓ | ✓ | | |
| `APP_STORE_CONNECT_API_KEY_CONTENT` | | ✓ | ✓ | | |
| `MATCH_PASSWORD` | | ✓ | ✓ | | |
| `MATCH_GIT_BASIC_AUTHORIZATION` | | ✓ | ✓ | | |
| `MATCH_GIT_URL` | | ✓ | ✓ | | |
| `WINDOWS_CERTIFICATE_BASE64` | | | | ✓ | |
| `WINDOWS_CERTIFICATE_PASSWORD` | | | | ✓ | |
| `WINDOWS_TENANT_ID` | | | | ✓ | |
| `WINDOWS_CLIENT_ID` | | | | ✓ | |
| `WINDOWS_CLIENT_SECRET` | | | | ✓ | |
| `WINDOWS_ADMIN_PRODUCT_ID` | | | | ✓ | |
| `WINDOWS_HOTEL_PRODUCT_ID` | | | | ✓ | |
| `SNAPCRAFT_STORE_CREDENTIALS` | | | | | ✓ |

---

## Troubleshooting: iOS deploy fails with "Repository not found"

**Root cause:** The job fails when validating access to the Fastlane Match repo,
not in Flutter/build steps.

From the failing job log:

```
Unable to access the iOS Match certificate repository:
remote: Repository not found.
fatal: repository '***/' not found
Verify MATCH_GIT_URL and MATCH_GIT_BASIC_AUTHORIZATION.
```

### 1) Fix the repository URL secret

Update `MATCH_GIT_URL` in repo/org secrets to the **exact existing git URL** of
your Match certs repo:

```
https://github.com/<owner>/<cert-repo>.git
```

Most common issues:
- Wrong owner or repo name
- Missing `.git` suffix
- Pointing to a deleted or private repo under another org
- Trailing whitespace/newlines pasted into the secret value

### 2) Fix auth secret format and token scope

`MATCH_GIT_BASIC_AUTHORIZATION` must be the base64 encoding of
`username:personal_access_token`:

```bash
printf '%s' 'github_user:github_token' | base64
```

Store that base64 output as the secret value (no newlines, no whitespace).

The token must have access to the Match repo:
- **Fine-grained PAT:** repository access to the cert repo + Contents: Read
- **Classic PAT:** `repo` scope (for private repo access)

### 3) Validate locally before re-running

Run exactly what the workflow runs:

```bash
git -c credential.helper= \
  -c http.extraheader="Authorization: Basic $MATCH_GIT_BASIC_AUTHORIZATION" \
  ls-remote "$MATCH_GIT_URL"
```

If this fails locally, CI will fail too. Fix the URL or token first.
