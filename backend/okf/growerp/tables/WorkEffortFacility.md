---
type: Moqui Entity
title: WorkEffortFacility
description: "Work Effort Facility"
resource: http://127.0.0.1:8080/rest/e1/mantle.work.effort.WorkEffortFacility
tags: [mantle, work, effort]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# WorkEffortFacility

Work Effort Facility

Full entity name: `mantle.work.effort.WorkEffortFacility`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `workEffortId` | id | Y |  |
| `facilityId` | id | Y |  |
| `typeEnumId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [WorkEffort](WorkEffort.md) via `workEffortId`
- one [Facility](Facility.md) via `facilityId`
- one `moqui.basic.Enumeration` via `typeEnumId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.work.effort.WorkEffortFacility
