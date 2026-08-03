---
type: Moqui Entity
title: ProductStorePromoParameter
description: "Product Store Promo Parameter"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.store.ProductStorePromoParameter
tags: [mantle, product, store]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ProductStorePromoParameter

Product Store Promo Parameter

Full entity name: `mantle.product.store.ProductStorePromoParameter`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `storePromotionId` | id | Y |  |
| `parameterName` | text-short | Y |  |
| `parameterValue` | text-medium |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [ProductStorePromotion](ProductStorePromotion.md) via `storePromotionId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.store.ProductStorePromoParameter
