---
type: Moqui Entity
title: Timesheet
description: "Timesheet"
resource: http://127.0.0.1:8080/rest/e1/mantle.work.time.Timesheet
tags: [mantle, work, time]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# Timesheet

Timesheet

Full entity name: `mantle.work.time.Timesheet`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `timesheetId` | id | Y |  |
| `partyId` | id |  |  |
| `clientPartyId` | id |  |  |
| `fromDate` | date-time |  |  |
| `thruDate` | date-time |  |  |
| `statusId` | id |  |  |
| `comments` | text-medium |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Party](Party.md) via `partyId`
- one [Client Party](Party.md) via `clientPartyId`
- one `moqui.basic.StatusItem` via `statusId`
- many [TimeEntry](TimeEntry.md) via `timesheetId`
- many [TimesheetParty](TimesheetParty.md) via `timesheetId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.work.time.Timesheet
