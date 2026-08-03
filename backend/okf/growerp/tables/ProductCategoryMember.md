---
type: Moqui Entity
title: ProductCategoryMember
description: "Product Category Member"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.category.ProductCategoryMember
tags: [mantle, product, category]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ProductCategoryMember

Product Category Member

Full entity name: `mantle.product.category.ProductCategoryMember`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `productCategoryId` | id | Y |  |
| `productId` | id | Y |  |
| `fromDate` | date-time | Y |  |
| `thruDate` | date-time |  |  |
| `comments` | text-medium |  |  |
| `sequenceNum` | number-integer |  |  |
| `quantity` | number-decimal |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Product](Product.md) via `productId`
- one [ProductCategory](ProductCategory.md) via `productCategoryId`
- many [ProductStoreCategory](ProductStoreCategory.md) via `productCategoryId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.category.ProductCategoryMember
