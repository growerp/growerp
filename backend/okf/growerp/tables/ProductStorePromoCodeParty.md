---
type: Moqui Entity
title: ProductStorePromoCodeParty
description: "Product Store Promo Code Party"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.store.ProductStorePromoCodeParty
tags: [mantle, product, store]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ProductStorePromoCodeParty

Product Store Promo Code Party

Full entity name: `mantle.product.store.ProductStorePromoCodeParty`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `promoCodeId` | id | Y |  |
| `partyId` | id | Y |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [ProductStorePromoCode](ProductStorePromoCode.md) via `promoCodeId`
- one [Party](Party.md) via `partyId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.store.ProductStorePromoCodeParty
