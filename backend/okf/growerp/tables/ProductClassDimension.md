---
type: Moqui Entity
title: ProductClassDimension
description: "Product Class Dimension"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.ProductClassDimension
tags: [mantle, product]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ProductClassDimension

Product Class Dimension

Full entity name: `mantle.product.ProductClassDimension`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `productClassEnumId` | id | Y |  |
| `dimensionTypeId` | id | Y |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.basic.Enumeration` via `productClassEnumId`
- one [ProductDimensionType](ProductDimensionType.md) via `dimensionTypeId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.ProductClassDimension
