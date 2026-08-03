---
type: Moqui Entity
title: WorkEffortAssetAssign
description: "Work Effort Asset Assign"
resource: http://127.0.0.1:8080/rest/e1/mantle.work.effort.WorkEffortAssetAssign
tags: [mantle, work, effort]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# WorkEffortAssetAssign

Work Effort Asset Assign

Full entity name: `mantle.work.effort.WorkEffortAssetAssign`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `workEffortId` | id | Y |  |
| `assetId` | id | Y |  |
| `fromDate` | date-time | Y |  |
| `thruDate` | date-time |  |  |
| `statusId` | id |  |  |
| `allocatedCost` | currency-amount |  |  |
| `comments` | text-medium |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [WorkEffort](WorkEffort.md) via `workEffortId`
- one [Asset](Asset.md) via `assetId`
- one `moqui.basic.StatusItem` via `statusId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.work.effort.WorkEffortAssetAssign
