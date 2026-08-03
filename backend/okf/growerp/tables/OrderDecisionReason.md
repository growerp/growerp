---
type: Moqui Entity
title: OrderDecisionReason
description: "Order Decision Reason"
resource: http://127.0.0.1:8080/rest/e1/mantle.order.OrderDecisionReason
tags: [mantle, order]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# OrderDecisionReason

Order Decision Reason

Full entity name: `mantle.order.OrderDecisionReason`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `orderId` | id | Y |  |
| `decisionDate` | date-time | Y |  |
| `decisionReasonEnumId` | id | Y |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [OrderHeader](OrderHeader.md) via `orderId`
- one [OrderDecision](OrderDecision.md) via `orderId`, `decisionDate`
- one `moqui.basic.Enumeration` via `decisionReasonEnumId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.order.OrderDecisionReason
