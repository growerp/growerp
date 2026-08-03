---
type: Moqui Entity
title: ProductStoreProduct
description: "Product Store Product"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.store.ProductStoreProduct
tags: [mantle, product, store]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ProductStoreProduct

Product Store Product

Full entity name: `mantle.product.store.ProductStoreProduct`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `productStoreId` | id | Y |  |
| `productId` | id | Y |  |
| `signatureRequiredEnumId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [ProductStore](ProductStore.md) via `productStoreId`
- one [Product](Product.md) via `productId`
- one `moqui.basic.Enumeration` via `signatureRequiredEnumId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.store.ProductStoreProduct
