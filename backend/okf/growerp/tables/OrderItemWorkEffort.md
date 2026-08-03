---
type: Moqui Entity
title: OrderItemWorkEffort
description: "Order Item Work Effort"
resource: http://127.0.0.1:8080/rest/e1/mantle.order.OrderItemWorkEffort
tags: [mantle, order]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# OrderItemWorkEffort

Order Item Work Effort

Full entity name: `mantle.order.OrderItemWorkEffort`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `orderId` | id | Y |  |
| `orderItemSeqId` | id | Y |  |
| `workEffortId` | id | Y |  |
| `requiredWork` | text-indicator |  | If Y require WorkEffort Status of Complete, Closed, or Cancelled to consider OrderItem fulfilled |
| `forStatusId` | id |  | Task must be Complete or Closed before change to this status (soft rule, depending on code in place) |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [OrderItem](OrderItem.md) via `orderId`, `orderItemSeqId`
- one [WorkEffort](WorkEffort.md) via `workEffortId`
- one `moqui.basic.StatusItem` via `forStatusId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.order.OrderItemWorkEffort
