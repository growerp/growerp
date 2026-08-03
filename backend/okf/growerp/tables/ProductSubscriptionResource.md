---
type: Moqui Entity
title: ProductSubscriptionResource
description: "Product Subscription Resource"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.subscription.ProductSubscriptionResource
tags: [mantle, product, subscription]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ProductSubscriptionResource

Product Subscription Resource

Full entity name: `mantle.product.subscription.ProductSubscriptionResource`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `productId` | id | Y |  |
| `subscriptionResourceId` | id | Y |  |
| `fromDate` | date-time | Y |  |
| `thruDate` | date-time |  |  |
| `purchaseFromDate` | date-time |  |  |
| `purchaseThruDate` | date-time |  |  |
| `availableTime` | number-integer |  |  |
| `availableTimeUomId` | id |  |  |
| `useCountLimit` | number-integer |  |  |
| `useTime` | number-integer |  |  |
| `useTimeUomId` | id |  |  |
| `useRoleTypeId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Product](Product.md) via `productId`
- one [SubscriptionResource](SubscriptionResource.md) via `subscriptionResourceId`
- one [Use RoleType](RoleType.md) via `useRoleTypeId`
- one `moqui.basic.Uom` via `useTimeUomId`
- one `moqui.basic.Uom` via `availableTimeUomId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.subscription.ProductSubscriptionResource
