---
type: Moqui Entity
title: OrderDecision
description: "Order Decision"
resource: http://127.0.0.1:8080/rest/e1/mantle.order.OrderDecision
tags: [mantle, order]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# OrderDecision

Order Decision

Full entity name: `mantle.order.OrderDecision`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `orderId` | id | Y |  |
| `decisionDate` | date-time | Y |  |
| `decisionByPartyId` | id |  |  |
| `statusId` | id |  | OrderHeader status the decision is meant for |
| `invalidatedDate` | date-time |  |  |
| `approvedAmount` | number-decimal |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [OrderHeader](OrderHeader.md) via `orderId`
- one [DecisionBy Party](Party.md) via `decisionByPartyId`
- one `moqui.basic.StatusItem` via `statusId`
- many [OrderDecisionReason](OrderDecisionReason.md) via `orderId`, `decisionDate`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.order.OrderDecision
