---
type: Moqui Entity
title: SubscriptionResource
description: "Subscription Resource"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.subscription.SubscriptionResource
tags: [mantle, product, subscription]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# SubscriptionResource

Subscription Resource

Full entity name: `mantle.product.subscription.SubscriptionResource`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `subscriptionResourceId` | id | Y |  |
| `parentResourceId` | id |  |  |
| `description` | text-medium |  |  |
| `contentLocation` | text-medium |  |  |
| `remoteResourceId` | text-medium |  |  |
| `initServiceName` | text-medium |  | Service called when a new subscription to a resource begins. Must implement the mantle.product.SubscriptionServices.init#SubscriptionResource service interface. |
| `renewServiceName` | text-medium |  | Service called when an existing subscription is renewed. Can be empty or do nothing, using revoke after expire instead. Must implement the mantle.product.SubscriptionServices.renew#SubscriptionResource service interface. |
| `revokeAccessTime` | number-integer |  |  |
| `revokeAccessTimeUomId` | id |  |  |
| `revokeAccessServiceName` | text-medium |  | Service called when inactive subscription goes past revokeAccessTime. Must implement the mantle.product.SubscriptionServices.revoke#SubscriptionResourceAccess service interface. |
| `restoreAccessServiceName` | text-medium |  | Service called on special events (manual or otherwise) to resore access. Must implement the mantle.product.SubscriptionServices.restore#SubscriptionResourceAccess service interface. |
| `destroyTime` | number-integer |  |  |
| `destroyTimeUomId` | id |  |  |
| `destroyServiceName` | text-medium |  | Service called when inactive subscription goes past destroyTime. Must implement the mantle.product.SubscriptionServices.destroy#SubscriptionResource service interface. |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Parent SubscriptionResource](SubscriptionResource.md) via `parentResourceId`
- many [ProductSubscriptionResource](ProductSubscriptionResource.md) via `subscriptionResourceId`
- many [Subscription](Subscription.md) via `subscriptionResourceId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.subscription.SubscriptionResource
