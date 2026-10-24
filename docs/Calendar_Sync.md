# Calendar sync: a calendar per user

GrowERP keeps a calendar for every internal user (groups GROWERP_M_ADMIN and
GROWERP_M_EMPLOYEE, with an email on the login account) in the tenant's connected calendar
account. Google is the only provider for now. The sync goes both ways.

| GrowERP | Calendar |
|---------|----------|
| Todo (WetTask) with a start date | all-day event in the calendar of each assignee (the originator when there is none), from the start date to the end date |
| Event (WetEvent) | same; the creator is the originator |
| Opportunity next step | todo for the employee, start date today |
| Rental booking (hotel/rental order item) | all-day event in the shared `GrowERP - Bookings` calendar, from the from date to the checkout date |
| Completed activity | title prefixed `Done: ` |
| Cancelled/closed activity, no date, other assignee | event removed |

The calendars are named `GrowERP - <first last>`. They are created in the connected Google
account and shared (role writer) with the user's email, so they show in the user's own
Google Calendar. Bookings is shared with every internal user.

Read back (job `user_calendar_read_back`, every 5 minutes):

- A changed title, description or date in the calendar updates the activity.
- An event deleted in the calendar cancels the activity.
- A new event a user adds to their GrowERP calendar becomes an event activity assigned to
  that user.
- Booking events belong to the order: a change made in the calendar is overwritten by the
  booking again.
- Last write wins: when the activity changed in GrowERP after the calendar edit, GrowERP's
  version is pushed.

Imported Google Meet bookings (`GoogleCalendarServices100`) already live in the company
calendar and are not copied.

## Setup

1. Connect Google Calendar with Sign in. This needs the scopes `calendar.readonly`,
   `calendar.app.created` and `calendar.acls`; see
   [Google_Workspace_Sign_In.md](Google_Workspace_Sign_In.md).
2. After the consent the backend creates the calendars and pushes the open activities of
   the last 30 days and the current bookings (`sync#AllUserCalendars`).
3. **Resync user calendars** in the Connect Google Workspace dialog does the same again,
   for example after adding users.

New users get their calendar at the first activity assigned to them.

## How it works

- `entity/CalendarSync.eecas.xml`: saves of WorkEffort, WorkEffortParty and AssetRental, and
  order cancellation, register `push#Activity` / `push#Rental` to run after commit. A
  calendar failure never breaks the save. Tenants without `googleRefreshToken` are filtered
  out there.
- `service/growerp/100/CalendarSyncServices100.xml`: the provider neutral sync core.
  - `growerp.crm.UserCalendar`: the calendar of a user (or of the company for Bookings),
    with the read back sync token.
  - `growerp.crm.CalendarEventLink`: maps a record to its event per calendar. `contentHash`
    holds the content last pushed or read back. Unchanged content is not pushed, so the
    several ECAs of one save and the echo of a read back cause no extra writes.
- `service/calendar/GoogleCalendarProvider.groovy`: the Google adapter, on top of
  `GoogleWorkspaceUtil.groovy`.

## In-app calendar

The calendar button next to chat in the app bar opens one month/week calendar
(`growerp_core/lib/src/domains/calendar/`) with everything that has a date. It reads
`GET /rest/s1/growerp/100/CalendarItems` (`get#CalendarItems`, open to every signed-in user via
`GROWERP_BASE`):

| Tenant | Shows |
|--------|-------|
| Connected with the calendar scope | the events of the company calendar (`googleCalendarId`, else `primary`); with write access also the user's own `GrowERP - <name>` calendar and Bookings. Events pushed from an activity carry its id. |
| Not connected, or the provider fails | the user's todos and events (assignee or originator) with a start date, all-day, same rule as `push#Activity`, plus a "Connect Google Calendar" link |
| App with marketing (`SocialPostDialog` registered) | also the social posts of the period, and the undated ones as a backlog strip |

Filter chips switch the sources off. Tapping an item opens `ActivityDialog` or `SocialPostDialog`
through the `WidgetRegistry` when the app registers them, otherwise a read-only event view.
Tapping a day, or the add button, creates a todo or a post on that day.

## Adding a provider (e.g. Microsoft 365)

1. Write `service/calendar/<Name>CalendarProvider.groovy` with the same static methods as
   the Google adapter. It works on neutral events:
   `[eventId, title, description, startDate, endDate (exclusive, yyyy-MM-dd), allDay,
   deleted, updated (Timestamp), sourceType, sourceId]`.

   | Method | Does |
   |--------|------|
   | `isWritable(ec, ownerPartyId)` | the tenant is connected with write access |
   | `createCalendar(ec, owner, name, timeZone)` | returns the calendar id |
   | `shareCalendar(ec, owner, calendarId, email)` | lets the user edit the calendar |
   | `newEventId(sourceType, sourceId)` | id for a new event (provider id rules) |
   | `upsertEvent(ec, owner, calendarId, eventId, event)` | returns `[eventId, updated]` |
   | `deleteEvent(ec, owner, calendarId, eventId)` | already gone is fine |
   | `listChanges(ec, owner, calendarId, syncToken)` | returns `[events, nextSyncToken]`; all events when the token is null or expired |
   | `isReadable(ec, ownerPartyId)` | the tenant is connected with read access (in-app calendar) |
   | `companyCalendarId(ec, ownerPartyId)` | the company calendar of the connected account |
   | `listRange(ec, owner, calendarId, from, thru)` | events overlapping the period for display: `[eventId, title, description, start, end, allDay, sourceType, sourceId]` |

   Keep `sourceType`/`sourceId` in the event's private data (Graph: an open extension).
2. Add it to the registry in `get#CalendarProvider`.
3. Add the provider's connect flow (OAuth) and the settings it needs.
