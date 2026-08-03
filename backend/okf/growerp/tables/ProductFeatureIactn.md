---
type: Moqui Entity
title: ProductFeatureIactn
description: "Product Feature Iactn"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.feature.ProductFeatureIactn
tags: [mantle, product, feature]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ProductFeatureIactn

Product Feature Iactn

Full entity name: `mantle.product.feature.ProductFeatureIactn`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `productFeatureId` | id | Y |  |
| `toProductFeatureId` | id | Y |  |
| `iactnTypeEnumId` | id |  |  |
| `productId` | id |  |  |
| `quantity` | number-decimal |  |  |
| `amount` | number-decimal |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.basic.Enumeration` via `iactnTypeEnumId`
- one [ProductFeature](ProductFeature.md) via `productFeatureId`
- one [To ProductFeature](ProductFeature.md) via `toProductFeatureId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.feature.ProductFeatureIactn
