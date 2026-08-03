---
type: Moqui Entity
title: BankAccountCheck
description: "A simple check register (for Checking type BankAccount) with details on the Payment entity"
resource: http://127.0.0.1:8080/rest/e1/mantle.account.method.BankAccountCheck
tags: [mantle, account, method]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# BankAccountCheck

A simple check register (for Checking type BankAccount) with details on the Payment entity

Full entity name: `mantle.account.method.BankAccountCheck`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `paymentMethodId` | id | Y |  |
| `checkNumber` | number-integer | Y |  |
| `paymentId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [PaymentMethod](PaymentMethod.md) via `paymentMethodId`
- one [Payment](Payment.md) via `paymentId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.account.method.BankAccountCheck
