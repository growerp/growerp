---
type: Moqui Entity
title: ProductPriceModifyParameter
description: "Product Price Modify Parameter"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.ProductPriceModifyParameter
tags: [mantle, product]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ProductPriceModifyParameter

Product Price Modify Parameter

Full entity name: `mantle.product.ProductPriceModifyParameter`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `priceModifyId` | id | Y |  |
| `parameterName` | text-short | Y |  |
| `parameterValue` | text-medium |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [ProductPriceModify](ProductPriceModify.md) via `priceModifyId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.ProductPriceModifyParameter
