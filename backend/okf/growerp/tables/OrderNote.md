---
type: Moqui Entity
title: OrderNote
description: "Order Note"
resource: http://127.0.0.1:8080/rest/e1/mantle.order.OrderNote
tags: [mantle, order]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# OrderNote

Order Note

Full entity name: `mantle.order.OrderNote`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `orderId` | id | Y |  |
| `noteDate` | date-time | Y |  |
| `noteText` | text-long |  |  |
| `internalNote` | text-indicator |  |  |
| `userId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [OrderHeader](OrderHeader.md) via `orderId`
- one `moqui.security.UserAccount` via `userId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.order.OrderNote
