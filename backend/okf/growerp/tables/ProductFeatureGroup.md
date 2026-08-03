---
type: Moqui Entity
title: ProductFeatureGroup
description: "Product Feature Group"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.feature.ProductFeatureGroup
tags: [mantle, product, feature]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ProductFeatureGroup

Product Feature Group

Full entity name: `mantle.product.feature.ProductFeatureGroup`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `productFeatureGroupId` | id | Y |  |
| `description` | text-medium |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- many [ProductFeatureGroupAppl](ProductFeatureGroupAppl.md) via `productFeatureGroupId`
- many [ProductCategoryFeatGrpAppl](ProductCategoryFeatGrpAppl.md) via `productFeatureGroupId`
- many [ProductClassFeatureGroup](ProductClassFeatureGroup.md) via `productFeatureGroupId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.feature.ProductFeatureGroup
