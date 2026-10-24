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

import java.sql.Timestamp
import java.time.Instant
import java.time.LocalDate
import java.time.OffsetDateTime

/**
 * Google Calendar adapter for CalendarSyncServices100 (see docs/Calendar_Sync.md).
 *
 * The sync core only uses neutral events:
 *   [eventId, title, description, startDate, endDate (exclusive, yyyy-MM-dd), allDay,
 *    deleted, updated (Timestamp), sourceType, sourceId]
 * A provider adapter maps them to its own API. Another provider (e.g. Microsoft Graph)
 * implements the same static methods and is added to the registry in get#CalendarProvider.
 */
class GoogleCalendarProvider {

    static def util(def ec) {
        return ec.resource.script('component://growerp/service/GoogleWorkspaceUtil.groovy', null)
    }

    /** True when the tenant is connected with the scopes to write calendars. */
    static boolean isWritable(def ec, String ownerPartyId) {
        def ss = ec.entity.find('growerp.general.SystemSettings')
            .condition('ownerPartyId', ownerPartyId).useCache(true).one()
        return util(ec).calendarWritable(ss)
    }

    static String createCalendar(def ec, String ownerPartyId, String name, String timeZone) {
        return util(ec).createCalendar(ec, ownerPartyId, name, timeZone)
    }

    static void shareCalendar(def ec, String ownerPartyId, String calendarId, String email) {
        util(ec).shareCalendar(ec, ownerPartyId, calendarId, email)
    }

    /** Event id for a new event of a GrowERP record: Google only allows [a-v0-9]. */
    static String newEventId(String sourceType, String sourceId) {
        return 'gerp' + "${sourceType}:${sourceId}".getBytes('UTF-8').encodeHex().toString()
    }

    /** Create or replace the event, returns [eventId, updated]. */
    static Map upsertEvent(def ec, String ownerPartyId, String calendarId, String eventId, Map ev) {
        def body = [
            summary: ev.title ?: '',
            description: ev.description ?: '',
            start: [date: ev.startDate],
            end: [date: ev.endDate],
            transparency: 'transparent',
            extendedProperties: [private: [growerpSourceType: ev.sourceType, growerpSourceId: ev.sourceId]],
        ]
        def resp = util(ec).upsertEvent(ec, ownerPartyId, calendarId, eventId, body)
        return [eventId: resp.id, updated: parseUpdated(resp.updated)]
    }

    static void deleteEvent(def ec, String ownerPartyId, String calendarId, String eventId) {
        util(ec).deleteEvent(ec, ownerPartyId, calendarId, eventId)
    }

    /** Changed events since syncToken (all when null), returns [events, nextSyncToken]. */
    static Map listChanges(def ec, String ownerPartyId, String calendarId, String syncToken) {
        def resp = util(ec).listChanges(ec, ownerPartyId, calendarId, syncToken)
        return [events: resp.items.collect { toNeutral(it) }, nextSyncToken: resp.nextSyncToken]
    }

    static Map toNeutral(Map item) {
        boolean allDay = item.start?.date != null
        String startDate = allDay ? item.start.date : dateOf(item.start?.dateTime)
        String endDate = item.end?.date
        if (!endDate && item.end?.dateTime) // timed: the day after the end day (exclusive)
            endDate = LocalDate.parse(dateOf(item.end.dateTime)).plusDays(1).toString()
        def priv = item.extendedProperties?.private ?: [:]
        return [eventId: item.id, title: item.summary ?: '', description: item.description ?: '',
            startDate: startDate, endDate: endDate, allDay: allDay,
            deleted: item.status == 'cancelled', updated: parseUpdated(item.updated),
            sourceType: priv.growerpSourceType, sourceId: priv.growerpSourceId]
    }

    private static String dateOf(String dateTime) {
        return dateTime ? OffsetDateTime.parse(dateTime).toLocalDate().toString() : null
    }

    private static Timestamp parseUpdated(def updated) {
        return updated ? Timestamp.from(Instant.parse((String) updated)) : null
    }
}

return GoogleCalendarProvider
