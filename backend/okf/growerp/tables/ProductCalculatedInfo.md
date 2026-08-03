---
type: Moqui Entity
title: ProductCalculatedInfo
description: "Product Calculated Info"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.ProductCalculatedInfo
tags: [mantle, product]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ProductCalculatedInfo

Product Calculated Info

Full entity name: `mantle.product.ProductCalculatedInfo`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `productId` | id | Y |  |
| `totalQuantityOrdered` | number-decimal |  |  |
| `totalTimesViewed` | number-integer |  |  |
| `averageCustomerRating` | number-decimal |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Product](Product.md) via `productId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.ProductCalculatedInfo
