---
type: Moqui Entity
title: TimesheetParty
description: "Timesheet Party"
resource: http://127.0.0.1:8080/rest/e1/mantle.work.time.TimesheetParty
tags: [mantle, work, time]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# TimesheetParty

Timesheet Party

Full entity name: `mantle.work.time.TimesheetParty`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `timesheetId` | id | Y |  |
| `partyId` | id | Y |  |
| `roleTypeId` | id | Y |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Timesheet](Timesheet.md) via `timesheetId`
- one [Party](Party.md) via `partyId`
- one [RoleType](RoleType.md) via `roleTypeId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.work.time.TimesheetParty
