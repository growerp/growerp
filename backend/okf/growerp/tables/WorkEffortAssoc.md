---
type: Moqui Entity
title: WorkEffortAssoc
description: "Work Effort Assoc"
resource: http://127.0.0.1:8080/rest/e1/mantle.work.effort.WorkEffortAssoc
tags: [mantle, work, effort]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# WorkEffortAssoc

Work Effort Assoc

Full entity name: `mantle.work.effort.WorkEffortAssoc`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `workEffortId` | id | Y |  |
| `toWorkEffortId` | id | Y |  |
| `workEffortAssocTypeEnumId` | id | Y |  |
| `fromDate` | date-time | Y |  |
| `thruDate` | date-time |  |  |
| `sequenceNum` | number-integer |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [WorkEffort](WorkEffort.md) via `workEffortId`
- one [To WorkEffort](WorkEffort.md) via `toWorkEffortId`
- one `moqui.basic.Enumeration` via `workEffortAssocTypeEnumId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.work.effort.WorkEffortAssoc
