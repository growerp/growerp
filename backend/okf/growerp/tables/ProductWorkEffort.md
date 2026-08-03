---
type: Moqui Entity
title: ProductWorkEffort
description: "Configure tasks (WorkEffort) that will be cloned when Product is ordered and associated with OrderItem using OrderItemWorkEffort."
resource: http://127.0.0.1:8080/rest/e1/mantle.product.ProductWorkEffort
tags: [mantle, product]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ProductWorkEffort

Configure tasks (WorkEffort) that will be cloned when Product is ordered and associated with OrderItem using OrderItemWorkEffort.

Full entity name: `mantle.product.ProductWorkEffort`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `productId` | id | Y |  |
| `workEffortId` | id | Y |  |
| `fromDate` | date-time | Y |  |
| `thruDate` | date-time |  |  |
| `requiredWork` | text-indicator |  | If Y require WorkEffort Status of Complete, Closed, or Cancelled to consider OrderItem fulfilled |
| `cloneOnStatusId` | id |  | OrderPart or OrderHeader status when the WorkEffort should be cloned and associated with the corresponding OrderItem with an OrderItemWorkEffort record |
| `forStatusId` | id |  | Task must be Complete or Closed before change to this order status (soft rule, depending on code in place) |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Product](Product.md) via `productId`
- one [WorkEffort](WorkEffort.md) via `workEffortId`
- one `moqui.basic.StatusItem` via `forStatusId`
- one `moqui.basic.StatusItem` via `forStatusId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.ProductWorkEffort
