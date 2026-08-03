---
type: Moqui Entity
title: WorkEffortDeliverableProd
description: "Work Effort Deliverable Prod"
resource: http://127.0.0.1:8080/rest/e1/mantle.work.effort.WorkEffortDeliverableProd
tags: [mantle, work, effort]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# WorkEffortDeliverableProd

Work Effort Deliverable Prod

Full entity name: `mantle.work.effort.WorkEffortDeliverableProd`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `workEffortId` | id | Y |  |
| `deliverableId` | id | Y |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [WorkEffort](WorkEffort.md) via `workEffortId`
- one [Deliverable](Deliverable.md) via `deliverableId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.work.effort.WorkEffortDeliverableProd
