---
type: Moqui Entity
title: WorkEffortContactMech
description: "Work Effort Contact Mech"
resource: http://127.0.0.1:8080/rest/e1/mantle.work.effort.WorkEffortContactMech
tags: [mantle, work, effort]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# WorkEffortContactMech

Work Effort Contact Mech

Full entity name: `mantle.work.effort.WorkEffortContactMech`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `workEffortId` | id | Y |  |
| `contactMechId` | id | Y |  |
| `contactMechPurposeId` | id | Y |  |
| `fromDate` | date-time | Y |  |
| `thruDate` | date-time |  |  |
| `extension` | text-short |  |  |
| `comments` | text-medium |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [WorkEffort](WorkEffort.md) via `workEffortId`
- one [ContactMech](ContactMech.md) via `contactMechId`
- one [ContactMechPurpose](ContactMechPurpose.md) via `contactMechPurposeId`
- one-nofk [PostalAddress](PostalAddress.md) via `contactMechId`
- one-nofk [TelecomNumber](TelecomNumber.md) via `contactMechId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.work.effort.WorkEffortContactMech
