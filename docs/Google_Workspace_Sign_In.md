# Google Workspace Sign in

Tenants connect Google Drive, Gmail and Google Calendar from the **Connect Google
Workspace** dialog (Agent Control → MCP servers → Google). Each service has a **Sign in**
button; **Connect all** asks for all three at once. Google's consent page opens in the
browser. After consent, Google redirects to the backend, which stores the refresh token.
The dialog checks every 2 seconds and shows the service as connected.

| Service  | Scope                                              | Used for                                         |
|----------|----------------------------------------------------|--------------------------------------------------|
| Drive    | `https://www.googleapis.com/auth/drive.readonly`   | Gemini meeting notes attached to lead activities |
| Gmail    | `https://mail.google.com/`                         | Mail server (SMTP/IMAP) with OAuth2 (XOAUTH2)    |
| Calendar | `https://www.googleapis.com/auth/calendar.readonly`| Meet bookings imported as lead activities        |

`openid email` is always requested, so the dialog can show which account is connected.

## Installation: the GrowERP OAuth client

You need one OAuth client for the whole GrowERP installation. Every backend (prod, test,
review, local) uses it. Tenants never see it; they only click **Sign in**.

The client lives in Google Cloud project **`growerp`**. Only the API step can be done from
the command line. Google has no API for creating the consent screen or a Web OAuth client,
so steps 2–5 are done in the Cloud Console.

### 1. Enable the APIs (done 2026-10-24)

```bash
gcloud services enable gmail.googleapis.com drive.googleapis.com \
    calendar-json.googleapis.com --project=growerp
```

### 2. Branding (consent screen)

Console → **Google Auth Platform → Branding**
(https://console.cloud.google.com/auth/branding?project=growerp):

- App name: `GrowERP`
- User support email: a GrowERP support address
- App logo: optional. Uploading a logo makes Google review the branding first.
- App home page `https://www.growerp.com`; privacy policy and terms of service links on
  growerp.com (both are required to publish the app later)
- Authorized domains: `growerp.com`, `growerp.org`, `growerp.net`
- Developer contact email

### 3. Audience

**Google Auth Platform → Audience**:

- User type: **External**
- Publishing status: **Testing**
- **Test users**: add every Google account that may sign in while in Testing (max 100). Any
  other account gets `access_denied`.

### 4. Data access (scopes)

**Google Auth Platform → Data access → Add or remove scopes**. Add:

- `openid`
- `.../auth/userinfo.email`
- `https://www.googleapis.com/auth/drive.readonly`
- `https://mail.google.com/`
- `https://www.googleapis.com/auth/calendar.readonly`

### 5. Create the client

**Google Auth Platform → Clients → Create client**:

- Application type: **Web application**
- Name: `GrowERP Sign in`
- Authorized JavaScript origins: leave empty (the browser never calls Google directly)
- **Authorized redirect URIs**, one per backend:
  - `https://backend.growerp.com/googleOAuth/callback` (production)
  - `https://backend.growerp.org/googleOAuth/callback` (test)
  - `https://backend.growerp.net/googleOAuth/callback` (review)
  - `http://localhost:8080/googleOAuth/callback` (local development)

Click **Create** and copy the **Client ID** and the **Client secret**. Google shows the
secret only now; store it in the password manager. The ID is not secret.

### 6. Configure the backends

The backend reads:

| Variable | Meaning |
|----------|---------|
| `GOOGLE_OAUTH_CLIENT_ID` | client id (or system property `google_oauth_client_id`) |
| `GOOGLE_OAUTH_CLIENT_SECRET` | client secret (or system property `google_oauth_client_secret`) |
| `GOOGLE_OAUTH_REDIRECT_URI` | optional: the full callback URL. Without it the backend builds the URL from the request, which can come out as `http://` or as a tenant domain behind the proxy. |

If the id or secret is missing, the dialog does not offer Sign in and shows only the fields
for the tenant's own client.

**Local development**

```bash
cd moqui
GOOGLE_OAUTH_CLIENT_ID=<id> GOOGLE_OAUTH_CLIENT_SECRET=<secret> java -jar moqui.war no-run-es
```

**Servers (Docker Swarm, `/data/server/swarm`)**

The stacks already pass the variables to Moqui. `GOOGLE_OAUTH_REDIRECT_URI` is set per
stack to `backend.growerp.com`, `.org` or `.net`. The secret is the Docker secret
`google_oauth_client_secret`. Do this on every host:

```bash
cd ~/server/swarm && git pull
echo 'GOOGLE_OAUTH_CLIENT_ID=<id>' >> .env
./deploy.sh secrets add google_oauth_client_secret   # paste the secret
./deploy.sh deploy
```

Create the secret **before** you deploy the updated stack files. The stacks declare it as
external, so a deploy without it fails.

### 7. Check it

1. Admin app → Agent Control → MCP servers → Google → **Sign in** at Google Calendar.
2. Sign in with a test user and allow access. The browser shows "Google connected" and the
   dialog changes to "Connected as …".
3. The tenant's `growerp.general.SystemSettings` row now has `googleGrantedScopes` and
   `googleAccountEmail`.

### Going to production (verification)

While the app is in **Testing**, only test users can sign in, and refresh tokens **expire
after 7 days**: users must sign in again weekly. To lift both limits, go to **Audience →
Publish app**. Google then reviews the app:

- `calendar.readonly` is a *sensitive* scope: Google verifies the app (demo video, scope
  justification).
- `https://mail.google.com/` and `drive.readonly` are *restricted* scopes: they also need a
  yearly CASA security assessment by an approved assessor.

This can take weeks. Until it is done, keep Testing and list the users who need access.

### Troubleshooting

| Symptom | Cause |
|---------|-------|
| Google shows `redirect_uri_mismatch` | the callback URL is not listed exactly (scheme, host, path) in step 5, or `GOOGLE_OAUTH_REDIRECT_URI` is wrong |
| Google shows `access_denied` / "app has not completed verification" | the account is not a test user (step 3) |
| Browser shows "Google sign in failed … Sign in expired" | more than 10 minutes between Sign in and consent, or Moqui restarted in between; sign in again |
| Dialog says sign in is not available | `GOOGLE_OAUTH_CLIENT_ID` or `GOOGLE_OAUTH_CLIENT_SECRET` is not set for Moqui |
| Calendar import works for a week, then fails | app still in Testing: the refresh token expired. Sign in again or publish the app |

## Backend flow

- `POST SystemSettings/googleSignIn {services}` (`start#GoogleSignIn`): stores a random
  state for 10 minutes in the cache `growerp.google.oauthState`, together with the tenant,
  the user, the services and the redirect URI. It returns the Google `authUrl`.
- `GET /googleOAuth/callback?code&state` (`screen/googleOAuth.xml` →
  `complete#GoogleSignIn`): exchanges the code and stores `googleRefreshToken`,
  `googleGrantedScopes` and `googleAccountEmail` through `update#SystemSettings`, which
  runs as the user who started the sign in. Gmail also switches the mail server to
  smtp.gmail.com / imap.gmail.com with `mailUseOauth=Y`. The tenant's own client
  id/secret are cleared, because a refresh token only works with the client that issued it.
- `POST SystemSettings/googleDisconnect {service}` (`disconnect#GoogleService`): removes
  the service's scope. Disconnecting Gmail sets `mailUseOauth=N`. When no service is left,
  the token is revoked at Google and removed.

Incremental authorization (`include_granted_scopes=true`) keeps one refresh token that
covers every granted scope.

## Own OAuth client (legacy)

A tenant can still enter its own client id, client secret and refresh token under **Use
your own OAuth client**. When they are set, `GoogleWorkspaceUtil.clientCredentials` uses
them instead of the platform client.
