---
type: Moqui Entity
title: ProductMeterType
description: "Product Meter Type"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.maintenance.ProductMeterType
tags: [mantle, product, maintenance]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ProductMeterType

Product Meter Type

Full entity name: `mantle.product.maintenance.ProductMeterType`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `productMeterTypeId` | id | Y |  |
| `description` | text-medium |  |  |
| `defaultUomId` | id |  | This is optional and if applicable can describe the meter better |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.basic.Uom` via `defaultUomId`
- many [AssetMeter](AssetMeter.md) via `productMeterTypeId`
- many [ProductMeter](ProductMeter.md) via `productMeterTypeId`
- many [MeasurementType](MeasurementType.md) via `productMeterTypeId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.maintenance.ProductMeterType
