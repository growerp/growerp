---
type: Moqui Entity
title: OrderPartContactMech
description: "Order Part Contact Mech"
resource: http://127.0.0.1:8080/rest/e1/mantle.order.OrderPartContactMech
tags: [mantle, order]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# OrderPartContactMech

Order Part Contact Mech

Full entity name: `mantle.order.OrderPartContactMech`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `orderId` | id | Y |  |
| `orderPartSeqId` | id | Y |  |
| `contactMechPurposeId` | id | Y |  |
| `contactMechId` | id | Y |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [OrderPart](OrderPart.md) via `orderId`, `orderPartSeqId`
- one [ContactMechPurpose](ContactMechPurpose.md) via `contactMechPurposeId`
- one [ContactMech](ContactMech.md) via `contactMechId`
- one-nofk [TelecomNumber](TelecomNumber.md) via `contactMechId`
- one-nofk [PostalAddress](PostalAddress.md) via `contactMechId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.order.OrderPartContactMech
