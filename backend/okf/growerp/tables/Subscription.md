---
type: Moqui Entity
title: Subscription
description: "Subscription"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.subscription.Subscription
tags: [mantle, product, subscription]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# Subscription

Subscription

Full entity name: `mantle.product.subscription.Subscription`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `subscriptionId` | id | Y |  |
| `subscriptionTypeEnumId` | id |  |  |
| `subscriptionResourceId` | id |  |  |
| `subscriberPartyId` | id |  |  |
| `deliverToContactMechId` | id |  |  |
| `orderId` | id |  |  |
| `orderItemSeqId` | id |  |  |
| `productId` | id |  |  |
| `externalSubscriptionId` | text-short |  |  |
| `resourceInstanceId` | text-short |  | ID of an instance of a resource, like a serial number or executing instance ID. |
| `description` | text-medium |  |  |
| `fromDate` | date-time |  |  |
| `thruDate` | date-time |  |  |
| `purchaseFromDate` | date-time |  |  |
| `purchaseThruDate` | date-time |  |  |
| `availableTime` | number-integer |  |  |
| `availableTimeUomId` | id |  |  |
| `useTime` | number-integer |  |  |
| `useTimeUomId` | id |  |  |
| `useCountLimit` | number-integer |  |  |
| `pseudoId` | id |  |  |
| `ownerPartyId` | id |  | The company owner, to separate companies. |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.basic.Enumeration` via `subscriptionTypeEnumId`
- one [SubscriptionResource](SubscriptionResource.md) via `subscriptionResourceId`
- one [Subscriber Party](Party.md) via `subscriberPartyId`
- one [DeliverTo ContactMech](ContactMech.md) via `deliverToContactMechId`
- one [OrderItem](OrderItem.md) via `orderId`, `orderItemSeqId`
- one [Product](Product.md) via `productId`
- one `moqui.basic.Uom` via `availableTimeUomId`
- one `moqui.basic.Uom` via `useTimeUomId`
- one [Owner Party](Party.md) via `ownerPartyId`
- many [SubscriptionDelivery](SubscriptionDelivery.md) via `subscriptionId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.subscription.Subscription
