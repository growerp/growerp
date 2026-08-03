---
type: Moqui Entity
title: ProductStorePromoProduct
description: "Product Store Promo Product"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.store.ProductStorePromoProduct
tags: [mantle, product, store]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ProductStorePromoProduct

Product Store Promo Product

Full entity name: `mantle.product.store.ProductStorePromoProduct`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `storePromotionId` | id | Y |  |
| `productId` | id | Y |  |
| `excludeProduct` | text-indicator |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [ProductStorePromotion](ProductStorePromotion.md) via `storePromotionId`
- one [Product](Product.md) via `productId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.store.ProductStorePromoProduct
