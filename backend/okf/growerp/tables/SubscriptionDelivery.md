---
type: Moqui Entity
title: SubscriptionDelivery
description: "Subscription Delivery"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.subscription.SubscriptionDelivery
tags: [mantle, product, subscription]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# SubscriptionDelivery

Subscription Delivery

Full entity name: `mantle.product.subscription.SubscriptionDelivery`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `subscriptionId` | id | Y |  |
| `dateSent` | date-time | Y |  |
| `communicationEventId` | id |  |  |
| `comments` | text-medium |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Subscription](Subscription.md) via `subscriptionId`
- one [CommunicationEvent](CommunicationEvent.md) via `communicationEventId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.subscription.SubscriptionDelivery
