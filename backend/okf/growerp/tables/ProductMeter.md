---
type: Moqui Entity
title: ProductMeter
description: "Product Meter"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.maintenance.ProductMeter
tags: [mantle, product, maintenance]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ProductMeter

Product Meter

Full entity name: `mantle.product.maintenance.ProductMeter`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `productMeterId` | id | Y |  |
| `productId` | id |  |  |
| `productMeterTypeId` | id |  |  |
| `meterUomId` | id |  |  |
| `meterName` | text-medium |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Product](Product.md) via `productId`
- one [ProductMeterType](ProductMeterType.md) via `productMeterTypeId`
- one `moqui.basic.Uom` via `meterUomId`
- many [Interval AssetMaintenance](AssetMaintenance.md) via `productMeterId`
- many [Interval ProductMaintenance](ProductMaintenance.md) via `productMeterId`
- many [Measurement](Measurement.md) via `productMeterId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.maintenance.ProductMeter
