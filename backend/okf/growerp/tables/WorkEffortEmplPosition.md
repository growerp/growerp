---
type: Moqui Entity
title: WorkEffortEmplPosition
description: "Work Effort Empl Position"
resource: http://127.0.0.1:8080/rest/e1/mantle.work.effort.WorkEffortEmplPosition
tags: [mantle, work, effort]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# WorkEffortEmplPosition

Work Effort Empl Position

Full entity name: `mantle.work.effort.WorkEffortEmplPosition`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `workEffortId` | id | Y |  |
| `emplPositionId` | id | Y |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [WorkEffort](WorkEffort.md) via `workEffortId`
- one [EmplPosition](EmplPosition.md) via `emplPositionId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.work.effort.WorkEffortEmplPosition
