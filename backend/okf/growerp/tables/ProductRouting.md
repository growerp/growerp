---
type: Moqui Entity
title: ProductRouting
description: "Product Routing"
resource: http://127.0.0.1:8080/rest/e1/growerp.manufacturing.ProductRouting
tags: [growerp, manufacturing]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ProductRouting

Product Routing

Full entity name: `growerp.manufacturing.ProductRouting`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `productId` | id | Y |  |
| `routingId` | id | Y |  |
| `fromDate` | date-time | Y |  |
| `thruDate` | date-time |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Product](Product.md) via `productId`
- one [Routing](Routing.md) via `routingId`

# Citations

- http://127.0.0.1:8080/rest/e1/growerp.manufacturing.ProductRouting
