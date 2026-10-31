# LinkedIn Connect

Every tenant publishes Social Posts to LinkedIn through the one **GrowERP LinkedIn app**.
In **Outreach → Platform Configuration → LINKEDIN** the user presses **Connect with
LinkedIn**, signs in to LinkedIn and allows GrowERP to post on their behalf. Tenants do
not create a LinkedIn developer app and do not type a token.

The connect stores two values on the tenant's LINKEDIN PlatformConfiguration, where
`publish#SocialPostToLinkedIn` reads them:

| Field | Value | Purpose |
|---|---|---|
| `apiKey` | the member's access token | proves the member allowed GrowERP to post for them |
| `username` | person URN `urn:li:person:{sub}` | the author of the post |
| `apiKeyExpireDate` | now + `expires_in` (60 days) | shown in the dialog; LinkedIn gives no refresh token |

After the expiry date publishing fails with "LinkedIn connection expired" and the user
presses **Reconnect LinkedIn**. Posts go to the member's personal profile; posting as a
company page needs LinkedIn's Community Management API (`w_organization_social`) and is
not supported.

## Installation: the GrowERP LinkedIn app

Done once by the system administrator at [linkedin.com/developers](https://www.linkedin.com/developers/apps).

1. **App**: linked to the GrowERP company page, with name, logo and privacy policy URL
   (these show on the LinkedIn consent screen).
2. **Products**: "Share on LinkedIn" (`w_member_social`) and "Sign In with LinkedIn using
   OpenID Connect" (`openid`, `profile`).
3. **Auth → Authorized redirect URLs** (exact match, no trailing slash):
   - `https://backend.growerp.com/linkedinOAuth/callback` (production)
   - `https://backend.growerp.org/linkedinOAuth/callback` (test)
   - `https://backend.growerp.net/linkedinOAuth/callback` (review)
   - `http://localhost:8080/linkedinOAuth/callback` (local development)
4. **Settings → Additional settings (widgets / SDK domains)**: leave empty.

### Configure the backends

| Variable | Value |
|---|---|
| `LINKEDIN_OAUTH_CLIENT_ID` | Client ID from the Auth tab |
| `LINKEDIN_OAUTH_CLIENT_SECRET` | Primary Client Secret from the Auth tab |
| `LINKEDIN_OAUTH_REDIRECT_URI` | optional: the full callback URL. Without it the backend builds the URL from the request, which can come out as `http://` or as a tenant domain behind the proxy. |

Without the client id and secret the Connect button answers "LinkedIn connect not
available: the GrowERP LinkedIn app is not configured on this server".

**Local development**

```bash
cd moqui
LINKEDIN_OAUTH_CLIENT_ID=<id> LINKEDIN_OAUTH_CLIENT_SECRET=<secret> java -jar moqui.war no-run-es
```

**Servers (Docker Swarm, `/data/server/swarm`)**

The client id and redirect URL are written in the stack files (`apps-*.yml`, there is
no `.env`); the secret is the Docker secret `linkedin_oauth_client_secret`. On every host:

```bash
cd ~/server/swarm && git pull
./deploy.sh secrets add linkedin_oauth_client_secret   # paste the secret
./deploy.sh deploy
```

Create the secret **before** you deploy the updated stack files: the stacks declare it as
external, so a deploy without it fails.

### Troubleshooting

| Symptom | Cause |
|---|---|
| LinkedIn shows `redirect_uri_mismatch` / "The redirect_uri does not match" | the callback URL is not listed exactly on the Auth tab, or `LINKEDIN_OAUTH_REDIRECT_URI` is wrong |
| LinkedIn shows `unauthorized_scope_error` | a product (Share on LinkedIn / OpenID Connect) is missing on the app |
| Callback page "LinkedIn connect failed" | see the Moqui log line `LinkedIn connect failed: ...` (token exchange or `/v2/userinfo` answer) |
| "LinkedIn connect expired, please try again" | the sign in took longer than 10 minutes or the backend restarted in between |

## Backend flow

1. `start#LinkedInSignIn` (REST `POST PlatformConfiguration/linkedinSignIn`) puts a random
   state in cache `growerp.linkedin.oauthState` (10 min) with tenant, user and redirect
   URL, and returns the LinkedIn consent URL.
2. LinkedIn redirects to `/linkedinOAuth/callback` (`screen/linkedinOAuth.xml`), which
   calls `complete#LinkedInSignIn`: it exchanges the code at
   `www.linkedin.com/oauth/v2/accessToken`, reads `sub` from `api.linkedin.com/v2/userinfo`
   (`/v2/me` answers 403 for new apps) and stores token, URN and expiry on the tenant's
   LINKEDIN row, enabled, keeping its daily limit.
3. The app polls the platform configurations until the row has a new expiry date.

Tests: `backend/src/test/groovy/OutreachServicesTests.groovy` (stubbed LinkedIn endpoints
via the system properties `growerp.linkedin.authBaseUrl` / `growerp.linkedin.apiBaseUrl`).
