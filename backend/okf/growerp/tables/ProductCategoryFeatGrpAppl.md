---
type: Moqui Entity
title: ProductCategoryFeatGrpAppl
description: "Product Category Feat Grp Appl"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.feature.ProductCategoryFeatGrpAppl
tags: [mantle, product, feature]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ProductCategoryFeatGrpAppl

Product Category Feat Grp Appl

Full entity name: `mantle.product.feature.ProductCategoryFeatGrpAppl`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `productCategoryId` | id | Y |  |
| `productFeatureGroupId` | id | Y |  |
| `fromDate` | date-time | Y |  |
| `thruDate` | date-time |  |  |
| `applTypeEnumId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [ProductCategory](ProductCategory.md) via `productCategoryId`
- one [ProductFeatureGroup](ProductFeatureGroup.md) via `productFeatureGroupId`
- one `moqui.basic.Enumeration` via `applTypeEnumId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.feature.ProductCategoryFeatGrpAppl
