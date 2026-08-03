---
type: Moqui Entity
title: FinancialAccountAuth
description: "Financial Account Auth"
resource: http://127.0.0.1:8080/rest/e1/mantle.account.financial.FinancialAccountAuth
tags: [mantle, account, financial]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# FinancialAccountAuth

Financial Account Auth

Full entity name: `mantle.account.financial.FinancialAccountAuth`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `finAccountAuthId` | id | Y |  |
| `finAccountId` | id |  |  |
| `amount` | currency-amount |  |  |
| `authorizationDate` | date-time |  |  |
| `expireDate` | date-time |  |  |
| `paymentId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [FinancialAccount](FinancialAccount.md) via `finAccountId`
- one [Payment](Payment.md) via `paymentId`
- many [FinancialAccountTrans](FinancialAccountTrans.md) via `finAccountAuthId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.account.financial.FinancialAccountAuth
