/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 *
 * To the extent possible under law, the author(s) have dedicated all
 * copyright and related and neighboring rights to this software to the
 * public domain worldwide. This software is distributed without any
 * warranty.
 *
 * You should have received a copy of the CC0 Public Domain Dedication
 * along with this software (see the LICENSE.md file). If not, see
 * <http://creativecommons.org/publicdomain/zero/1.0/>.
 */

import groovy.json.JsonSlurper
import groovy.json.JsonOutput

import java.util.concurrent.ConcurrentHashMap

/**
 * Google Workspace (Calendar v3 + Drive v3) API utility for GrowERP.
 *
 * Auth: per-tenant OAuth 2.0 refresh token stored in growerp.general.SystemSettings
 * (googleClientId, googleClientSecret, googleRefreshToken). Scopes needed:
 * calendar.readonly drive.readonly.
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
    static final String CALENDAR_BASE = "https://www.googleapis.com/calendar/v3"
    static final String DRIVE_BASE = "https://www.googleapis.com/drive/v3"

    // ownerPartyId -> [token: String, expires: long millis]
    private static final Map<String, Map> tokenCache = new ConcurrentHashMap<>()

    /** Get (and cache) an OAuth access token for the tenant's refresh token. */
    static String getAccessToken(def ec, String ownerPartyId) {
        def cached = tokenCache.get(ownerPartyId)
        if (cached && cached.expires > System.currentTimeMillis()) return cached.token

        def ss = ec.entity.find('growerp.general.SystemSettings')
            .condition('ownerPartyId', ownerPartyId).useCache(false).one()
        if (!ss?.googleRefreshToken || !ss?.googleClientId || !ss?.googleClientSecret) {
            throw new Exception("Google credentials not configured for owner ${ownerPartyId}")
        }

        def body = "grant_type=refresh_token" +
            "&client_id=" + URLEncoder.encode((String) ss.googleClientId, 'UTF-8') +
            "&client_secret=" + URLEncoder.encode((String) ss.googleClientSecret, 'UTF-8') +
            "&refresh_token=" + URLEncoder.encode((String) ss.googleRefreshToken, 'UTF-8')

        def connection = new URL(TOKEN_URL).openConnection() as HttpURLConnection
        connection.setRequestMethod("POST")
        connection.setRequestProperty("Content-Type", "application/x-www-form-urlencoded")
        connection.setDoOutput(true)
        connection.setConnectTimeout(30000)
        connection.setReadTimeout(30000)
        connection.outputStream.withWriter("UTF-8") { it.write(body) }

        if (connection.responseCode != 200) {
            def errorText = connection.errorStream ? connection.errorStream.text : ''
            throw new Exception("Google token refresh failed (${connection.responseCode}): ${errorText}")
        }
        def resp = new JsonSlurper().parseText(connection.inputStream.text)
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
