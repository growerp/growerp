---
type: Moqui Entity
title: OrderPartParty
description: "Order Part Party"
resource: http://127.0.0.1:8080/rest/e1/mantle.order.OrderPartParty
tags: [mantle, order]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# OrderPartParty

Order Part Party

Full entity name: `mantle.order.OrderPartParty`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `orderId` | id | Y |  |
| `orderPartSeqId` | id | Y |  |
| `partyId` | id | Y |  |
| `roleTypeId` | id | Y |  |
| `sequenceNum` | number-integer |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [OrderPart](OrderPart.md) via `orderId`, `orderPartSeqId`
- one [Party](Party.md) via `partyId`
- one-nofk [Person](Person.md) via `partyId`
- one-nofk [Organization](Organization.md) via `partyId`
- one [RoleType](RoleType.md) via `roleTypeId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.order.OrderPartParty
