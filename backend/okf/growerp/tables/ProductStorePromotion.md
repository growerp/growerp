---
type: Moqui Entity
title: ProductStorePromotion
description: "Product Store Promotion"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.store.ProductStorePromotion
tags: [mantle, product, store]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ProductStorePromotion

Product Store Promotion

Full entity name: `mantle.product.store.ProductStorePromotion`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `storePromotionId` | id | Y |  |
| `productStoreId` | id |  |  |
| `itemDescription` | text-medium |  | Description for the OrderItem (itemDescription), promo service should run this through ResourceFacade.expand() with parameters depending on the promo service |
| `serviceRegisterId` | id |  | Registered Service of type ProductStorePromotion that implements the mantle.product.StoreServices.apply#Promotion interface |
| `fromDate` | date-time |  |  |
| `thruDate` | date-time |  |  |
| `sequenceNum` | number-integer |  |  |
| `requireCode` | text-indicator |  |  |
| `useLimitPerOrder` | number-integer |  |  |
| `useLimitPerCustomer` | number-integer |  |  |
| `useLimitPerPromotion` | number-integer |  |  |
| `freeGroundShipping` | text-indicator |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [ProductStore](ProductStore.md) via `productStoreId`
- one `moqui.service.ServiceRegister` via `serviceRegisterId`
- many [ProductStorePromoParameter](ProductStorePromoParameter.md) via `storePromotionId`
- many [ProductStorePromoCode](ProductStorePromoCode.md) via `storePromotionId`
- many [OrderItem](OrderItem.md) via `storePromotionId`
- many [ProductStorePromoProduct](ProductStorePromoProduct.md) via `storePromotionId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.store.ProductStorePromotion
