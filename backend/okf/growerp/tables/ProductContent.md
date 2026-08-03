---
type: Moqui Entity
title: ProductContent
description: "Product Content"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.ProductContent
tags: [mantle, product]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ProductContent

Product Content

Full entity name: `mantle.product.ProductContent`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `productContentId` | id | Y |  |
| `productId` | id |  |  |
| `contentLocation` | text-medium |  |  |
| `productContentTypeEnumId` | id |  |  |
| `locale` | text-short |  |  |
| `productFeatureId` | id |  | For virtual products to limit images/etc displayed by selectable feature, if null always display |
| `productStoreId` | id |  | For content limited to a specific store |
| `fromDate` | date-time |  |  |
| `thruDate` | date-time |  |  |
| `description` | text-long |  |  |
| `sequenceNum` | number-integer |  |  |
| `userId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Product](Product.md) via `productId`
- one `moqui.basic.Enumeration` via `productContentTypeEnumId`
- one [ProductFeature](ProductFeature.md) via `productFeatureId`
- one [ProductStore](ProductStore.md) via `productStoreId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.ProductContent
