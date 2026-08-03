---
type: Moqui Entity
title: ProductClassUomDimension
description: "Product Class Uom Dimension"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.ProductClassUomDimension
tags: [mantle, product]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ProductClassUomDimension

Product Class Uom Dimension

Full entity name: `mantle.product.ProductClassUomDimension`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `productClassEnumId` | id | Y |  |
| `uomDimensionTypeId` | id | Y |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.basic.Enumeration` via `productClassEnumId`
- one `moqui.basic.UomDimensionType` via `uomDimensionTypeId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.ProductClassUomDimension
