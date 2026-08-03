---
type: Moqui Entity
title: BitcoinWallet
description: "Bitcoin Wallet"
resource: http://127.0.0.1:8080/rest/e1/mantle.account.method.BitcoinWallet
tags: [mantle, account, method]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# BitcoinWallet

Bitcoin Wallet

Full entity name: `mantle.account.method.BitcoinWallet`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `paymentMethodId` | id | Y |  |
| `walletAddress` | text-medium |  |  |
| `description` | text-medium |  |  |
| `onlineWalletUrl` | text-medium |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [PaymentMethod](PaymentMethod.md) via `paymentMethodId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.account.method.BitcoinWallet
