---
type: Moqui Entity
title: OrderPartTerm
description: "Order Part Term"
resource: http://127.0.0.1:8080/rest/e1/mantle.order.OrderPartTerm
tags: [mantle, order]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# OrderPartTerm

Order Part Term

Full entity name: `mantle.order.OrderPartTerm`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `orderId` | id | Y |  |
| `orderPartSeqId` | id | Y |  |
| `settlementTermId` | id | Y |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [OrderPart](OrderPart.md) via `orderId`, `orderPartSeqId`
- one [SettlementTerm](SettlementTerm.md) via `settlementTermId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.order.OrderPartTerm
