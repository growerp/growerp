---
type: Moqui Entity
title: ProductDimensionType
description: "WARNING: to be deprecated by moqui.basic.UomDimensionType"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.ProductDimensionType
tags: [mantle, product]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ProductDimensionType

WARNING: to be deprecated by moqui.basic.UomDimensionType

Full entity name: `mantle.product.ProductDimensionType`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `dimensionTypeId` | id | Y |  |
| `description` | text-medium |  |  |
| `uomTypeEnumId` | id |  |  |
| `defaultUomId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.basic.Enumeration` via `uomTypeEnumId`
- one `moqui.basic.Uom` via `defaultUomId`
- many [ProductClassDimension](ProductClassDimension.md) via `dimensionTypeId`
- many [ProductDimension](ProductDimension.md) via `dimensionTypeId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.ProductDimensionType
