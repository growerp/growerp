---
type: Moqui Entity
title: ProductUomDimension
description: "Product Uom Dimension"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.ProductUomDimension
tags: [mantle, product]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ProductUomDimension

Product Uom Dimension

Full entity name: `mantle.product.ProductUomDimension`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `productUomDimensionId` | id | Y |  |
| `productId` | id |  |  |
| `uomDimensionTypeId` | id |  |  |
| `marketSegmentId` | id |  |  |
| `value` | number-decimal |  |  |
| `uomId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Product](Product.md) via `productId`
- one `moqui.basic.UomDimensionType` via `uomDimensionTypeId`
- one [MarketSegment](MarketSegment.md) via `marketSegmentId`
- one `moqui.basic.Uom` via `uomId`
- many [ProductParameterOption](ProductParameterOption.md) via `productUomDimensionId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.ProductUomDimension
