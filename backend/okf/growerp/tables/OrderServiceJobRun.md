---
type: Moqui Entity
title: OrderServiceJobRun
description: "Order Service Job Run"
resource: http://127.0.0.1:8080/rest/e1/mantle.order.OrderServiceJobRun
tags: [mantle, order]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# OrderServiceJobRun

Order Service Job Run

Full entity name: `mantle.order.OrderServiceJobRun`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `orderId` | id | Y |  |
| `jobRunId` | id | Y |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [OrderHeader](OrderHeader.md) via `orderId`
- one `moqui.service.job.ServiceJobRun` via `jobRunId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.order.OrderServiceJobRun
