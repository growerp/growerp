---
type: Moqui Entity
title: ProductCategoryContent
description: "Product Category Content"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.category.ProductCategoryContent
tags: [mantle, product, category]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ProductCategoryContent

Product Category Content

Full entity name: `mantle.product.category.ProductCategoryContent`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `productCategoryContentId` | id | Y |  |
| `productCategoryId` | id |  |  |
| `contentLocation` | text-medium |  |  |
| `categoryContentTypeEnumId` | id |  |  |
| `productStoreId` | id |  | For content limited to a specific store |
| `fromDate` | date-time |  |  |
| `thruDate` | date-time |  |  |
| `locale` | text-short |  |  |
| `description` | text-long |  |  |
| `sequenceNum` | number-integer |  |  |
| `userId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [ProductCategory](ProductCategory.md) via `productCategoryId`
- one `moqui.basic.Enumeration` via `categoryContentTypeEnumId`
- one [ProductStore](ProductStore.md) via `productStoreId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.category.ProductCategoryContent
