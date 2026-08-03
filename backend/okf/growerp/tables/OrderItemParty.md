---
type: Moqui Entity
title: OrderItemParty
description: "Order Item Party"
resource: http://127.0.0.1:8080/rest/e1/mantle.order.OrderItemParty
tags: [mantle, order]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# OrderItemParty

Order Item Party

Full entity name: `mantle.order.OrderItemParty`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `orderId` | id | Y |  |
| `orderItemSeqId` | id | Y |  |
| `partyId` | id | Y |  |
| `roleTypeId` | id | Y |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [OrderItem](OrderItem.md) via `orderId`, `orderItemSeqId`
- one [Party](Party.md) via `partyId`
- one-nofk [Person](Person.md) via `partyId`
- one-nofk [Organization](Organization.md) via `partyId`
- one [RoleType](RoleType.md) via `roleTypeId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.order.OrderItemParty
