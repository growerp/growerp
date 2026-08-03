---
type: Moqui Entity
title: GiftCard
description: "For externally managed gift cards (not locally managed in a FinancialAccount)"
resource: http://127.0.0.1:8080/rest/e1/mantle.account.method.GiftCard
tags: [mantle, account, method]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# GiftCard

For externally managed gift cards (not locally managed in a FinancialAccount)

Full entity name: `mantle.account.method.GiftCard`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `paymentMethodId` | id | Y |  |
| `cardNumber` | text-medium |  |  |
| `pinNumber` | text-medium |  |  |
| `expireDate` | text-short |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [PaymentMethod](PaymentMethod.md) via `paymentMethodId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.account.method.GiftCard
