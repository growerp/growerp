---
type: Moqui Entity
title: RequestItemOrder
description: "Request Item Order"
resource: http://127.0.0.1:8080/rest/e1/mantle.request.RequestItemOrder
tags: [mantle, request]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# RequestItemOrder

Request Item Order

Full entity name: `mantle.request.RequestItemOrder`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `requestItemOrderId` | id | Y |  |
| `requestId` | id |  |  |
| `requestItemSeqId` | id |  |  |
| `orderId` | id |  |  |
| `orderItemSeqId` | id |  |  |
| `quantity` | number-decimal |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [RequestItem](RequestItem.md) via `requestId`, `requestItemSeqId`
- one [OrderItem](OrderItem.md) via `orderId`, `orderItemSeqId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.request.RequestItemOrder
