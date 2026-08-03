---
type: Moqui Entity
title: ProductStoreCategory
description: "Product Store Category"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.store.ProductStoreCategory
tags: [mantle, product, store]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ProductStoreCategory

Product Store Category

Full entity name: `mantle.product.store.ProductStoreCategory`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `productStoreId` | id | Y |  |
| `productCategoryId` | id | Y |  |
| `storeCategoryTypeEnumId` | id | Y |  |
| `fromDate` | date-time | Y |  |
| `thruDate` | date-time |  |  |
| `sequenceNum` | number-integer |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [ProductStore](ProductStore.md) via `productStoreId`
- one [ProductCategory](ProductCategory.md) via `productCategoryId`
- one `moqui.basic.Enumeration` via `storeCategoryTypeEnumId`
- many [ProductCategoryMember](ProductCategoryMember.md) via `productCategoryId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.store.ProductStoreCategory
