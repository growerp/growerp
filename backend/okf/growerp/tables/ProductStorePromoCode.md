---
type: Moqui Entity
title: ProductStorePromoCode
description: "Product Store Promo Code"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.store.ProductStorePromoCode
tags: [mantle, product, store]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ProductStorePromoCode

Product Store Promo Code

Full entity name: `mantle.product.store.ProductStorePromoCode`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `promoCodeId` | id | Y |  |
| `promoCode` | text-short |  |  |
| `storePromotionId` | id |  |  |
| `fromDate` | date-time |  |  |
| `thruDate` | date-time |  |  |
| `useLimitPerCode` | number-integer |  |  |
| `useLimitPerCustomer` | number-integer |  |  |
| `userEntered` | text-indicator |  |  |
| `requireParty` | text-indicator |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [ProductStorePromotion](ProductStorePromotion.md) via `storePromotionId`
- many [ProductStorePromoCodeParty](ProductStorePromoCodeParty.md) via `storePromotionId`
- many [OrderItem](OrderItem.md) via `promoCodeId`
- many [OrderPromoCode](OrderPromoCode.md) via `promoCodeId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.store.ProductStorePromoCode
