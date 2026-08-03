---
type: Moqui Entity
title: ProductAssoc
description: "Product Assoc"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.ProductAssoc
tags: [mantle, product]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ProductAssoc

Product Assoc

Full entity name: `mantle.product.ProductAssoc`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `productId` | id | Y |  |
| `toProductId` | id | Y |  |
| `productAssocTypeEnumId` | id | Y |  |
| `fromDate` | date-time | Y |  |
| `thruDate` | date-time |  |  |
| `sequenceNum` | number-integer |  |  |
| `reason` | text-medium |  |  |
| `quantity` | number-decimal |  |  |
| `scrapFactor` | number-decimal |  |  |
| `instruction` | text-medium |  |  |
| `routingWorkEffortId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.basic.Enumeration` via `productAssocTypeEnumId`
- one [Product](Product.md) via `productId`
- one [To Product](Product.md) via `toProductId`
- one [Routing WorkEffort](WorkEffort.md) via `routingWorkEffortId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.ProductAssoc
