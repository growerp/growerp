---
type: Moqui Entity
title: CalendarEventSync
description: "Maps an imported Google Calendar event to its WorkEffort activity; also carries incremental-sync and minutes-attachment state per tenant."
resource: http://127.0.0.1:8080/rest/e1/growerp.crm.CalendarEventSync
tags: [growerp, crm]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# CalendarEventSync

Maps an imported Google Calendar event to its WorkEffort activity; also carries incremental-sync and minutes-attachment state per tenant.

Full entity name: `growerp.crm.CalendarEventSync`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `calendarEventSyncId` | id | Y |  |
| `ownerPartyId` | id |  |  |
| `googleEventId` | text-medium |  |  |
| `workEffortId` | id |  |  |
| `googleUpdated` | date-time |  |  |
| `eventEnd` | date-time |  |  |
| `minutesDocId` | text-medium |  |  |
| `minutesAttached` | text-indicator |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [WorkEffort](WorkEffort.md) via `workEffortId`

# Citations

- http://127.0.0.1:8080/rest/e1/growerp.crm.CalendarEventSync
