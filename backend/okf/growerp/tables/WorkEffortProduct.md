---
type: Moqui Entity
title: WorkEffortProduct
description: "Work Effort Product"
resource: http://127.0.0.1:8080/rest/e1/mantle.work.effort.WorkEffortProduct
tags: [mantle, work, effort]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# WorkEffortProduct

Work Effort Product

Full entity name: `mantle.work.effort.WorkEffortProduct`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `workEffortId` | id | Y |  |
| `productId` | id | Y |  |
| `fromDate` | date-time | Y |  |
| `thruDate` | date-time |  |  |
| `typeEnumId` | id |  |  |
| `statusId` | id |  |  |
| `estimatedQuantity` | number-decimal |  |  |
| `estimatedCost` | currency-amount |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [WorkEffort](WorkEffort.md) via `workEffortId`
- one [Product](Product.md) via `productId`
- one `moqui.basic.Enumeration` via `typeEnumId`
- one `moqui.basic.StatusItem` via `statusId`
- many [AssetReceipt](AssetReceipt.md) via `workEffortId`, `productId`
- many [AssetIssuance](AssetIssuance.md) via `workEffortId`, `productId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.work.effort.WorkEffortProduct
