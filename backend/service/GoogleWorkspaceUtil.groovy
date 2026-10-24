/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import groovy.json.JsonSlurper
import groovy.json.JsonOutput

import java.util.concurrent.ConcurrentHashMap

/**
 * Google Workspace (Calendar v3 + Drive v3) API utility for GrowERP.
 *
 * Auth: per-tenant OAuth 2.0 refresh token stored in growerp.general.SystemSettings
 * (googleRefreshToken), obtained with the Sign in flow (authUrl/exchangeCode) against the
 * GrowERP platform OAuth client (env GOOGLE_OAUTH_CLIENT_ID/GOOGLE_OAUTH_CLIENT_SECRET).
 * A tenant may still use its own client (googleClientId/googleClientSecret), which then
 * takes precedence. Scopes per service: see SERVICE_SCOPES.
 *
 * Usage from service XML:
 *   <script location="component://growerp/service/GoogleWorkspaceUtil.groovy"/>
 *   <script>
 *       def GoogleWorkspaceUtil = _scriptResult
 *       events = GoogleWorkspaceUtil.listEvents(ec, ownerPartyId, calendarId, updatedMinIso)
 *   </script>
 */

class GoogleWorkspaceUtil {

    static final String TOKEN_URL = "https://oauth2.googleapis.com/token"
    static final String AUTH_URL = "https://accounts.google.com/o/oauth2/v2/auth"
    static final String REVOKE_URL = "https://oauth2.googleapis.com/revoke"
    static final String USERINFO_URL = "https://openidconnect.googleapis.com/v1/userinfo"
    static final Map<String, String> SERVICE_SCOPES = [
        drive: 'https://www.googleapis.com/auth/drive.readonly',
        gmail: 'https://mail.google.com/',
        calendar: 'https://www.googleapis.com/auth/calendar.readonly',
    ]
    /** Scopes asked together with the service scope: calendar also writes the per-user
     *  GrowERP calendars (created by the app) and shares them (CalendarSyncServices100). */
    static final Map<String, List<String>> EXTRA_SCOPES = [
        calendar: ['https://www.googleapis.com/auth/calendar.app.created',
                   'https://www.googleapis.com/auth/calendar.acls'],
    ]
    static final String CALENDAR_BASE = "https://www.googleapis.com/calendar/v3"
    static final String DRIVE_BASE = "https://www.googleapis.com/drive/v3"

    // ownerPartyId -> [token: String, expires: long millis]
    private static final Map<String, Map> tokenCache = new ConcurrentHashMap<>()

    /** Platform OAuth client [id, secret] from env or system property; null when not set. */
    static List<String> platformClient() {
        String id = System.getenv('GOOGLE_OAUTH_CLIENT_ID') ?: System.getProperty('google_oauth_client_id')
        String secret = System.getenv('GOOGLE_OAUTH_CLIENT_SECRET') ?: System.getProperty('google_oauth_client_secret')
        return id && secret ? [id, secret] : null
    }

    /** Client [id, secret] for a tenant: its own client when set, else the platform client. */
    static List<String> clientCredentials(def ss) {
        if (ss?.googleClientId && ss?.googleClientSecret)
            return [(String) ss.googleClientId, (String) ss.googleClientSecret]
        return platformClient()
    }

    static void clearCache(String ownerPartyId) { tokenCache.remove(ownerPartyId) }

    /** Google consent URL for the platform client asking for the scopes of the services. */
    static String authUrl(List<String> services, String redirectUri, String state) {
        def client = platformClient()
        if (!client) throw new Exception("Google sign in not available: platform OAuth client not configured")
        def scopes = ['openid', 'email'] + services.collect { SERVICE_SCOPES[it] }.findAll { it } +
            services.collectMany { EXTRA_SCOPES[it] ?: [] }
        return AUTH_URL + "?response_type=code&access_type=offline&prompt=consent" +
            "&include_granted_scopes=true" +
            "&client_id=" + URLEncoder.encode(client[0], 'UTF-8') +
            "&redirect_uri=" + URLEncoder.encode(redirectUri, 'UTF-8') +
            "&scope=" + URLEncoder.encode(scopes.join(' '), 'UTF-8') +
            "&state=" + URLEncoder.encode(state, 'UTF-8')
    }

    /** Exchange an authorization code; returns the token response plus 'email'. */
    static Map exchangeCode(String code, String redirectUri) {
        def client = platformClient()
        if (!client) throw new Exception("Google sign in not available: platform OAuth client not configured")
        def resp = postForm(TOKEN_URL, "grant_type=authorization_code" +
            "&code=" + URLEncoder.encode(code, 'UTF-8') +
            "&client_id=" + URLEncoder.encode(client[0], 'UTF-8') +
            "&client_secret=" + URLEncoder.encode(client[1], 'UTF-8') +
            "&redirect_uri=" + URLEncoder.encode(redirectUri, 'UTF-8'))
        def connection = new URL(USERINFO_URL).openConnection() as HttpURLConnection
        connection.setRequestProperty("Authorization", "Bearer ${resp.access_token}")
        connection.setConnectTimeout(30000)
        connection.setReadTimeout(30000)
        if (connection.responseCode == 200)
            resp.email = new JsonSlurper().parseText(connection.inputStream.text).email
        return resp
    }

    /** Revoke a refresh token at Google; failures are logged only. */
    static void revoke(def ec, String refreshToken) {
        try { postForm(REVOKE_URL, "token=" + URLEncoder.encode(refreshToken, 'UTF-8')) }
        catch (Exception e) { ec.logger.warn("Google token revoke failed: ${e.message}") }
    }

    private static Map postForm(String url, String body) {
        def connection = new URL(url).openConnection() as HttpURLConnection
        connection.setRequestMethod("POST")
        connection.setRequestProperty("Content-Type", "application/x-www-form-urlencoded")
        connection.setDoOutput(true)
        connection.setConnectTimeout(30000)
        connection.setReadTimeout(30000)
        connection.outputStream.withWriter("UTF-8") { it.write(body) }
        if (connection.responseCode != 200) {
            def errorText = connection.errorStream ? connection.errorStream.text : ''
            throw new Exception("Google ${url} failed (${connection.responseCode}): ${errorText}")
        }
        def text = connection.inputStream.text
        return text ? (Map) new JsonSlurper().parseText(text) : [:]
    }

    /** Get (and cache) an OAuth access token for the tenant's refresh token. */
    static String getAccessToken(def ec, String ownerPartyId) {
        def cached = tokenCache.get(ownerPartyId)
        if (cached && cached.expires > System.currentTimeMillis()) return cached.token

        def ss = ec.entity.find('growerp.general.SystemSettings')
            .condition('ownerPartyId', ownerPartyId).useCache(false).one()
        def client = clientCredentials(ss)
        if (!ss?.googleRefreshToken || !client) {
            throw new Exception("Google credentials not configured for owner ${ownerPartyId}")
        }

        def resp = postForm(TOKEN_URL, "grant_type=refresh_token" +
            "&client_id=" + URLEncoder.encode(client[0], 'UTF-8') +
            "&client_secret=" + URLEncoder.encode(client[1], 'UTF-8') +
            "&refresh_token=" + URLEncoder.encode((String) ss.googleRefreshToken, 'UTF-8'))
        long expires = System.currentTimeMillis() + (((resp.expires_in ?: 3600) as long) - 60) * 1000L
        tokenCache.put(ownerPartyId, [token: resp.access_token, expires: expires])
        return resp.access_token
    }

    /** GET a Google API URL, return parsed JSON map. */
    private static Map apiGet(def ec, String ownerPartyId, String url) {
        def token = getAccessToken(ec, ownerPartyId)
        def connection = new URL(url).openConnection() as HttpURLConnection
        connection.setRequestMethod("GET")
        connection.setRequestProperty("Authorization", "Bearer ${token}")
        connection.setConnectTimeout(30000)
        connection.setReadTimeout(60000)
        if (connection.responseCode != 200) {
            def errorText = connection.errorStream ? connection.errorStream.text : ''
            throw new Exception("Google API error (${connection.responseCode}) for ${url}: ${errorText}")
        }
        return (Map) new JsonSlurper().parseText(connection.inputStream.text)
    }

    /** GET a Google API URL, return the raw body text (for Drive export). */
    private static String apiGetText(def ec, String ownerPartyId, String url) {
        def token = getAccessToken(ec, ownerPartyId)
        def connection = new URL(url).openConnection() as HttpURLConnection
        connection.setRequestMethod("GET")
        connection.setRequestProperty("Authorization", "Bearer ${token}")
        connection.setConnectTimeout(30000)
        connection.setReadTimeout(60000)
        if (connection.responseCode != 200) {
            def errorText = connection.errorStream ? connection.errorStream.text : ''
            throw new Exception("Google API error (${connection.responseCode}) for ${url}: ${errorText}")
        }
        return connection.inputStream.getText('UTF-8')
    }

    /** All scopes of a service: the service scope plus its extra scopes. */
    static List<String> serviceScopes(String service) {
        return ([SERVICE_SCOPES[service]] + (EXTRA_SCOPES[service] ?: [])).findAll { it }
    }

    /** True when the tenant may write calendars: connected with the extra calendar scopes. */
    static boolean calendarWritable(def ss) {
        if (!ss?.googleRefreshToken) return false
        def granted = ((String) ss.googleGrantedScopes ?: '').split(' ') as List
        return EXTRA_SCOPES.calendar.every { granted.contains(it) }
    }

    /**
     * POST/PUT/PATCH/DELETE a Google API URL with a JSON body, return the parsed JSON map.
     * Returns null for 404/410 on DELETE (already gone) and for 404 otherwise when
     * notFoundNull is true.
     */
    static Map apiSend(def ec, String ownerPartyId, String method, String url, Map body,
            boolean notFoundNull = false) {
        def token = getAccessToken(ec, ownerPartyId)
        def connection = new URL(url).openConnection() as HttpURLConnection
        if (method == 'PATCH') {
            connection.setRequestMethod('POST')
            connection.setRequestProperty('X-HTTP-Method-Override', 'PATCH')
        } else connection.setRequestMethod(method)
        connection.setRequestProperty("Authorization", "Bearer ${token}")
        connection.setConnectTimeout(30000)
        connection.setReadTimeout(60000)
        if (body != null) {
            connection.setRequestProperty("Content-Type", "application/json; charset=UTF-8")
            connection.setDoOutput(true)
            connection.outputStream.withWriter("UTF-8") { it.write(JsonOutput.toJson(body)) }
        }
        int code = connection.responseCode
        if ((code == 404 || code == 410) && (method == 'DELETE' || notFoundNull)) return null
        if (code < 200 || code > 299) {
            def errorText = connection.errorStream ? connection.errorStream.text : ''
            throw new Exception("Google API error (${code}) for ${method} ${url}: ${errorText}")
        }
        def text = connection.inputStream.getText('UTF-8')
        return text ? (Map) new JsonSlurper().parseText(text) : [:]
    }

    /** Create a secondary calendar in the connected account, return its id. */
    static String createCalendar(def ec, String ownerPartyId, String summary, String timeZone) {
        def resp = apiSend(ec, ownerPartyId, 'POST', "${CALENDAR_BASE}/calendars",
            [summary: summary, timeZone: timeZone ?: 'UTC'])
        return resp.id
    }

    /** Share a calendar with an email address (role writer: the user may edit events). */
    static void shareCalendar(def ec, String ownerPartyId, String calendarId, String email) {
        def calId = URLEncoder.encode(calendarId, 'UTF-8')
        apiSend(ec, ownerPartyId, 'POST', "${CALENDAR_BASE}/calendars/${calId}/acl?sendNotifications=true",
            [role: 'writer', scope: [type: 'user', value: email]])
    }

    /** Replace an event with a client chosen id, insert it when it does not exist yet. */
    static Map upsertEvent(def ec, String ownerPartyId, String calendarId, String eventId, Map event) {
        def calId = URLEncoder.encode(calendarId, 'UTF-8')
        def body = event + [id: eventId, status: 'confirmed']
        def resp = apiSend(ec, ownerPartyId, 'PUT',
            "${CALENDAR_BASE}/calendars/${calId}/events/" + URLEncoder.encode(eventId, 'UTF-8'), body, true)
        if (resp == null) resp = apiSend(ec, ownerPartyId, 'POST',
            "${CALENDAR_BASE}/calendars/${calId}/events", body)
        return resp
    }

    static void deleteEvent(def ec, String ownerPartyId, String calendarId, String eventId) {
        def calId = URLEncoder.encode(calendarId, 'UTF-8')
        apiSend(ec, ownerPartyId, 'DELETE',
            "${CALENDAR_BASE}/calendars/${calId}/events/" + URLEncoder.encode(eventId, 'UTF-8'), null)
    }

    /**
     * Incremental change list of a calendar. With a null or expired (410) syncToken all events
     * are listed. Returns [items: List, nextSyncToken: String].
     */
    static Map listChanges(def ec, String ownerPartyId, String calendarId, String syncToken) {
        def calId = URLEncoder.encode(calendarId, 'UTF-8')
        def items = []
        String pageToken = null
        String nextSyncToken = null
        while (true) {
            def url = "${CALENDAR_BASE}/calendars/${calId}/events?singleEvents=true&maxResults=250" +
                (syncToken ? "&syncToken=" + URLEncoder.encode(syncToken, 'UTF-8') : "&showDeleted=true") +
                (pageToken ? "&pageToken=" + URLEncoder.encode(pageToken, 'UTF-8') : '')
            Map resp
            try { resp = apiGet(ec, ownerPartyId, url) }
            catch (Exception e) {
                // 410 Gone: sync token expired, start over with a full list
                if (syncToken && e.message?.contains('(410)'))
                    return listChanges(ec, ownerPartyId, calendarId, null)
                throw e
            }
            if (resp.items) items.addAll(resp.items)
            pageToken = resp.nextPageToken
            if (!pageToken) { nextSyncToken = resp.nextSyncToken; break }
        }
        return [items: items, nextSyncToken: nextSyncToken]
    }

    /**
     * List calendar events updated since updatedMinIso (RFC3339, e.g. 2026-07-01T00:00:00Z).
     * Returns the combined items list across pages.
     */
    static List listEvents(def ec, String ownerPartyId, String calendarId, String updatedMinIso) {
        def calId = URLEncoder.encode(calendarId ?: 'primary', 'UTF-8')
        def items = []
        String pageToken = null
        while (true) {
            def url = "${CALENDAR_BASE}/calendars/${calId}/events" +
                "?singleEvents=true&showDeleted=true&maxResults=250" +
                "&updatedMin=" + URLEncoder.encode(updatedMinIso, 'UTF-8') +
                (pageToken ? "&pageToken=" + URLEncoder.encode(pageToken, 'UTF-8') : '')
            def resp = apiGet(ec, ownerPartyId, url)
            if (resp.items) items.addAll(resp.items)
            pageToken = resp.nextPageToken
            if (!pageToken) break
        }
        return items
    }

    /** Re-fetch a single event (for attachments added after the meeting). */
    static Map getEvent(def ec, String ownerPartyId, String calendarId, String eventId) {
        def calId = URLEncoder.encode(calendarId ?: 'primary', 'UTF-8')
        return apiGet(ec, ownerPartyId,
            "${CALENDAR_BASE}/calendars/${calId}/events/" + URLEncoder.encode(eventId, 'UTF-8'))
    }

    /** Export a Google Doc as plain text via Drive API. */
    static String exportDocText(def ec, String ownerPartyId, String fileId) {
        return apiGetText(ec, ownerPartyId,
            "${DRIVE_BASE}/files/" + URLEncoder.encode(fileId, 'UTF-8') +
            "/export?mimeType=" + URLEncoder.encode('text/plain', 'UTF-8'))
    }

    /**
     * Fallback: find the Gemini notes doc for an event by Drive search when the
     * calendar event has no attachment. Matches docs named
     * "<event title> ... Notes by Gemini". Returns the file id or null.
     */
    static String findNotesDoc(def ec, String ownerPartyId, String eventTitle) {
        def safeTitle = (eventTitle ?: '').replace("'", "\\'")
        def q = "name contains 'Notes by Gemini' and name contains '${safeTitle}'" +
            " and mimeType = 'application/vnd.google-apps.document' and trashed = false"
        def url = "${DRIVE_BASE}/files?pageSize=5&orderBy=createdTime desc" +
            "&fields=" + URLEncoder.encode('files(id,name,createdTime)', 'UTF-8') +
            "&q=" + URLEncoder.encode(q, 'UTF-8')
        def resp = apiGet(ec, ownerPartyId, url)
        return resp.files ? resp.files[0].id : null
    }
}

// Return the utility class for use by other scripts
return GoogleWorkspaceUtil
