---
type: Moqui Entity
title: WorkEffortAssetNeeded
description: "For equipment, inventory, etc needed in the work effort."
resource: http://127.0.0.1:8080/rest/e1/mantle.work.effort.WorkEffortAssetNeeded
tags: [mantle, work, effort]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# WorkEffortAssetNeeded

For equipment, inventory, etc needed in the work effort.

Full entity name: `mantle.work.effort.WorkEffortAssetNeeded`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `workEffortId` | id | Y |  |
| `assetProductId` | id | Y |  |
| `estimatedQuantity` | number-decimal |  |  |
| `estimatedDuration` | number-decimal |  |  |
| `estimatedCost` | currency-amount |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [WorkEffort](WorkEffort.md) via `workEffortId`
- one [Asset Product](Product.md) via `assetProductId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.work.effort.WorkEffortAssetNeeded
