---
type: Moqui Entity
title: Deduction
description: "Deduction"
resource: http://127.0.0.1:8080/rest/e1/mantle.account.payment.Deduction
tags: [mantle, account, payment]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# Deduction

Deduction

Full entity name: `mantle.account.payment.Deduction`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `deductionId` | id | Y |  |
| `deductionTypeEnumId` | id |  |  |
| `paymentId` | id |  |  |
| `amount` | currency-amount |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.basic.Enumeration` via `deductionTypeEnumId`
- one [Payment](Payment.md) via `paymentId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.account.payment.Deduction
