---
type: Moqui Entity
title: OrderCommunicationEvent
description: "Order Communication Event"
resource: http://127.0.0.1:8080/rest/e1/mantle.order.OrderCommunicationEvent
tags: [mantle, order]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# OrderCommunicationEvent

Order Communication Event

Full entity name: `mantle.order.OrderCommunicationEvent`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `orderId` | id | Y |  |
| `communicationEventId` | id | Y |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [OrderHeader](OrderHeader.md) via `orderId`
- one [CommunicationEvent](CommunicationEvent.md) via `communicationEventId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.order.OrderCommunicationEvent
