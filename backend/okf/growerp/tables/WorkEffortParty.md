---
type: Moqui Entity
title: WorkEffortParty
description: "Work Effort Party"
resource: http://127.0.0.1:8080/rest/e1/mantle.work.effort.WorkEffortParty
tags: [mantle, work, effort]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# WorkEffortParty

Work Effort Party

Full entity name: `mantle.work.effort.WorkEffortParty`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `workEffortId` | id | Y |  |
| `partyId` | id | Y |  |
| `roleTypeId` | id | Y |  |
| `fromDate` | date-time | Y |  |
| `thruDate` | date-time |  |  |
| `statusId` | id |  |  |
| `availabilityEnumId` | id |  |  |
| `delegateReasonEnumId` | id |  |  |
| `expectationEnumId` | id |  |  |
| `workTypeEnumId` | id |  |  |
| `emplPositionClassId` | id |  |  |
| `emplPositionId` | id |  |  |
| `comments` | text-medium |  |  |
| `mustRsvp` | text-indicator |  |  |
| `receiveNotifications` | text-indicator |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [WorkEffort](WorkEffort.md) via `workEffortId`
- one [Party](Party.md) via `partyId`
- one-nofk [Person](Person.md) via `partyId`
- one-nofk [Organization](Organization.md) via `partyId`
- one [RoleType](RoleType.md) via `roleTypeId`
- one `moqui.basic.StatusItem` via `statusId`
- one `moqui.basic.Enumeration` via `availabilityEnumId`
- one `moqui.basic.Enumeration` via `delegateReasonEnumId`
- one `moqui.basic.Enumeration` via `expectationEnumId`
- one `moqui.basic.Enumeration` via `workTypeEnumId`
- one [EmplPositionClass](EmplPositionClass.md) via `emplPositionClassId`
- one [EmplPosition](EmplPosition.md) via `emplPositionId`
- many `moqui.security.UserAccount` via `partyId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.work.effort.WorkEffortParty
