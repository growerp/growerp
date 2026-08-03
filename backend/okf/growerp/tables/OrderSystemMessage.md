---
type: Moqui Entity
title: OrderSystemMessage
description: "Order System Message"
resource: http://127.0.0.1:8080/rest/e1/mantle.order.OrderSystemMessage
tags: [mantle, order]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# OrderSystemMessage

Order System Message

Full entity name: `mantle.order.OrderSystemMessage`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `orderId` | id | Y |  |
| `systemMessageId` | id | Y |  |
| `externalId` | text-short |  |  |
| `originId` | text-short |  |  |
| `displayId` | text-short |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [OrderHeader](OrderHeader.md) via `orderId`
- one `moqui.service.message.SystemMessage` via `systemMessageId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.order.OrderSystemMessage
