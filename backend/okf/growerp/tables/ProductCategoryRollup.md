---
type: Moqui Entity
title: ProductCategoryRollup
description: "Product Category Rollup"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.category.ProductCategoryRollup
tags: [mantle, product, category]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ProductCategoryRollup

Product Category Rollup

Full entity name: `mantle.product.category.ProductCategoryRollup`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `productCategoryId` | id | Y |  |
| `parentProductCategoryId` | id | Y |  |
| `fromDate` | date-time | Y |  |
| `thruDate` | date-time |  |  |
| `sequenceNum` | number-integer |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [ProductCategory](ProductCategory.md) via `productCategoryId`
- one [Parent ProductCategory](ProductCategory.md) via `parentProductCategoryId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.category.ProductCategoryRollup
