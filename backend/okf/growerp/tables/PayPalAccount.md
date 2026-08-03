---
type: Moqui Entity
title: PayPalAccount
description: "Pay Pal Account"
resource: http://127.0.0.1:8080/rest/e1/mantle.account.method.PayPalAccount
tags: [mantle, account, method]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# PayPalAccount

Pay Pal Account

Full entity name: `mantle.account.method.PayPalAccount`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `paymentMethodId` | id | Y |  |
| `payerId` | id |  |  |
| `expressCheckoutToken` | text-short |  |  |
| `payerStatus` | text-short |  |  |
| `avsAddr` | text-indicator |  |  |
| `avsZip` | text-indicator |  |  |
| `correlationId` | text-short |  |  |
| `transactionId` | text-short |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [PaymentMethod](PaymentMethod.md) via `paymentMethodId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.account.method.PayPalAccount
