---
type: Moqui Entity
title: PaymentBudgetAllocation
description: "Payment Budget Allocation"
resource: http://127.0.0.1:8080/rest/e1/mantle.account.payment.PaymentBudgetAllocation
tags: [mantle, account, payment]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# PaymentBudgetAllocation

Payment Budget Allocation

Full entity name: `mantle.account.payment.PaymentBudgetAllocation`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `paymentId` | id | Y |  |
| `budgetId` | id | Y |  |
| `budgetItemSeqId` | id | Y |  |
| `amount` | currency-amount |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [BudgetItem](BudgetItem.md) via `budgetId`, `budgetItemSeqId`
- one [Payment](Payment.md) via `paymentId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.account.payment.PaymentBudgetAllocation
