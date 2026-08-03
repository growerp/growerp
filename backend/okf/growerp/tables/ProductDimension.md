---
type: Moqui Entity
title: ProductDimension
description: "WARNING: to be deprecated by mantle.product.ProductUomDimension"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.ProductDimension
tags: [mantle, product]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ProductDimension

WARNING: to be deprecated by mantle.product.ProductUomDimension

Full entity name: `mantle.product.ProductDimension`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `productId` | id | Y |  |
| `dimensionTypeId` | id | Y |  |
| `value` | number-decimal |  |  |
| `valueUomId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Product](Product.md) via `productId`
- one [ProductDimensionType](ProductDimensionType.md) via `dimensionTypeId`
- one `moqui.basic.Uom` via `valueUomId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.ProductDimension
