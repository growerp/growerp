---
type: Moqui Entity
title: ProductCategoryIdent
description: "Based on mantle.product.ProductOtherIdentification to be a one ProductCategory to many ProductCategoryIdent."
resource: http://127.0.0.1:8080/rest/e1/mantle.product.category.ProductCategoryIdent
tags: [mantle, product, category]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ProductCategoryIdent

Based on mantle.product.ProductOtherIdentification to be a one ProductCategory to many ProductCategoryIdent.

Full entity name: `mantle.product.category.ProductCategoryIdent`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `productCategoryIdentId` | id | Y |  |
| `productCategoryId` | id |  |  |
| `identTypeEnumId` | id |  |  |
| `productStoreId` | id |  |  |
| `marketSegmentId` | id |  |  |
| `idValue` | text-medium |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.basic.Enumeration` via `identTypeEnumId`
- one [ProductCategory](ProductCategory.md) via `productCategoryId`
- one [ProductStore](ProductStore.md) via `productStoreId`
- one [MarketSegment](MarketSegment.md) via `marketSegmentId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.category.ProductCategoryIdent
