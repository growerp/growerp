---
type: Moqui Entity
title: OrderEmailMessage
description: "Order Email Message"
resource: http://127.0.0.1:8080/rest/e1/mantle.order.OrderEmailMessage
tags: [mantle, order]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# OrderEmailMessage

Order Email Message

Full entity name: `mantle.order.OrderEmailMessage`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `orderId` | id | Y |  |
| `emailMessageId` | id | Y |  |
| `orderRevision` | number-integer |  |  |
| `partyId` | id |  | The Party the email was sent to, for different emails sent to different parties associated with an order |
| `roleTypeId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [OrderHeader](OrderHeader.md) via `orderId`
- one `moqui.basic.email.EmailMessage` via `emailMessageId`
- one [Party](Party.md) via `partyId`
- one [RoleType](RoleType.md) via `roleTypeId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.order.OrderEmailMessage
