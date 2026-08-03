---
type: Moqui Entity
title: ProductFeatureGroupAppl
description: "Product Feature Group Appl"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.feature.ProductFeatureGroupAppl
tags: [mantle, product, feature]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ProductFeatureGroupAppl

Product Feature Group Appl

Full entity name: `mantle.product.feature.ProductFeatureGroupAppl`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `productFeatureGroupId` | id | Y |  |
| `productFeatureId` | id | Y |  |
| `fromDate` | date-time | Y |  |
| `thruDate` | date-time |  |  |
| `sequenceNum` | number-integer |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [ProductFeatureGroup](ProductFeatureGroup.md) via `productFeatureGroupId`
- one [ProductFeature](ProductFeature.md) via `productFeatureId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.feature.ProductFeatureGroupAppl
