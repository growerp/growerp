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
|          | `https://www.googleapis.com/auth/calendar.app.created` | the per-user `GrowERP - <name>` calendars: create them, write and read their events ([Calendar_Sync.md](Calendar_Sync.md)) |
|          | `https://www.googleapis.com/auth/calendar.acls`    | share each per-user calendar with the user's email |

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
- `https://www.googleapis.com/auth/calendar.app.created`
- `https://www.googleapis.com/auth/calendar.acls`

Tenants that connected Calendar before the per-user calendars existed only granted
`calendar.readonly`. Their Meet import keeps working, and the dialog asks them to sign in
to Calendar again to add the user calendars.

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
stack to `backend.growerp.com`, `.org` or `.net`; the client id is written in the stack
files too (there is no `.env`). The secret is the Docker secret
`google_oauth_client_secret`. Do this on every host:

```bash
cd ~/server/swarm && git pull
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
after 7 days**: users must sign in again weekly. Production lifts both limits, but Google
first verifies the app. Steps in the Google Cloud console (project of the OAuth client):

1. **Google Auth Platform → Branding**: app name `GrowERP`, logo (120x120), user support
   email, developer contact email, application home page `https://www.growerp.com`, privacy
   policy and terms of service URLs. Every URL must be on a domain listed under
   **Authorized domains** (`growerp.com`, `growerp.org`, `growerp.net`).
2. Verify each authorized domain in [Google Search Console](https://search.google.com/search-console)
   with an account that is Owner or Editor of the Cloud project (DNS TXT record).
3. **Data access**: make sure exactly the scopes of step 4 are listed. Each sensitive and
   restricted scope needs a justification: what GrowERP does with it and why a narrower
   scope does not work. For example:
   - `calendar.readonly`: import Meet bookings from the company calendar as CRM activities.
   - `calendar.app.created`: create one calendar per user and keep their todos, events and
     bookings in it both ways; only calendars GrowERP created are touched.
   - `calendar.acls`: share each of those calendars with its user.
4. Record a demo video (unlisted YouTube) in English. It shows the consent screen with the
   app name and the browser URL bar containing the OAuth `client_id`, followed by each scope
   in use in GrowERP: the dialog connecting, a todo appearing in the user calendar, an edit
   in Google coming back, a Meet booking imported, meeting notes attached, mail sent through
   Gmail.
5. **Audience → Publish app**: the publishing status changes from Testing to In production.
   With sensitive or restricted scopes Google then shows **Prepare for verification**
   (also under **Verification Center**). Fill in the justifications and the video link and
   submit.
6. Answer the Google review emails (sent to the developer contact). Until approval users
   see the "unverified app" warning and the 100-user cap applies.

Scope classes:

- The Calendar scopes are *sensitive*: Google verification only (usually days to a few
  weeks).
- `https://mail.google.com/` and `drive.readonly` are *restricted*: on top of that a yearly
  CASA security assessment by an approved assessor is required.

To get Calendar into production fast, submit the calendar scopes first. Take Gmail and Drive
out of the Data access list, or move them to a second OAuth client that stays in Testing
until CASA is done. Check the class of each scope on the **Data access** page (sensitive
and restricted scopes are marked there).

### Troubleshooting

| Symptom | Cause |
|---------|-------|
| Google shows `redirect_uri_mismatch` | the callback URL is not listed exactly (scheme, host, path) in step 5, or `GOOGLE_OAUTH_REDIRECT_URI` is wrong |
| Google shows `access_denied` / "app has not completed verification" | the account is not a test user (step 3) |
| Browser shows "Google sign in failed … Sign in expired" | more than 10 minutes between Sign in and consent, or Moqui restarted in between; sign in again |
| Dialog says sign in is not available | `GOOGLE_OAUTH_CLIENT_ID` or `GOOGLE_OAUTH_CLIENT_SECRET` is not set for Moqui |
| Calendar import works for a week, then fails | app still in Testing: the refresh token expired. Sign in again or publish the app |
| No `GrowERP - <name>` calendars appear | Calendar connected with `calendar.readonly` only: sign in to Calendar again; then **Resync user calendars**. A user needs an email on the login account |

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
- After the sign in, when the calendar write scopes were granted, `sync#AllUserCalendars`
  builds the per-user calendars ([Calendar_Sync.md](Calendar_Sync.md)).
- `POST SystemSettings/googleDisconnect {service}` (`disconnect#GoogleService`): removes
  the service's scopes. Disconnecting Calendar stops the calendar sync; the calendars stay
  in the Google account. Disconnecting Gmail sets `mailUseOauth=N`. When no service is left,
  the token is revoked at Google and removed.

Incremental authorization (`include_granted_scopes=true`) keeps one refresh token that
covers every granted scope.

## Own OAuth client (legacy)

A tenant can still enter its own client id, client secret and refresh token under **Use
your own OAuth client**. When they are set, `GoogleWorkspaceUtil.clientCredentials` uses
them instead of the platform client.
