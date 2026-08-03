---
type: Moqui Entity
title: OrderPromoCode
description: "Order Promo Code"
resource: http://127.0.0.1:8080/rest/e1/mantle.order.OrderPromoCode
tags: [mantle, order]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# OrderPromoCode

Order Promo Code

Full entity name: `mantle.order.OrderPromoCode`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `orderId` | id | Y |  |
| `promoCodeId` | id | Y |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [OrderHeader](OrderHeader.md) via `orderId`
- one [ProductStorePromoCode](ProductStorePromoCode.md) via `promoCodeId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.order.OrderPromoCode
