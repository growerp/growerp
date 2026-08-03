---
type: Moqui Entity
title: SalesForecastDetail
description: "Sales Forecast Detail"
resource: http://127.0.0.1:8080/rest/e1/mantle.sales.forecast.SalesForecastDetail
tags: [mantle, sales, forecast]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# SalesForecastDetail

Sales Forecast Detail

Full entity name: `mantle.sales.forecast.SalesForecastDetail`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `salesForecastId` | id | Y |  |
| `salesForecastDetailSeqId` | id | Y |  |
| `amount` | currency-amount |  |  |
| `quantity` | number-decimal |  |  |
| `quantityUomId` | id |  |  |
| `productId` | id |  |  |
| `productCategoryId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [SalesForecast](SalesForecast.md) via `salesForecastId`
- one `moqui.basic.Uom` via `quantityUomId`
- one [Product](Product.md) via `productId`
- one [ProductCategory](ProductCategory.md) via `productCategoryId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.sales.forecast.SalesForecastDetail
