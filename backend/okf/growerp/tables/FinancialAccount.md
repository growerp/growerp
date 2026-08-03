---
type: Moqui Entity
title: FinancialAccount
description: "Financial Account"
resource: http://127.0.0.1:8080/rest/e1/mantle.account.financial.FinancialAccount
tags: [mantle, account, financial]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# FinancialAccount

Financial Account

Full entity name: `mantle.account.financial.FinancialAccount`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `finAccountId` | id | Y |  |
| `finAccountTypeId` | id |  |  |
| `statusId` | id |  |  |
| `finAccountName` | text-medium |  |  |
| `finAccountCode` | text-medium |  |  |
| `finAccountPin` | text-medium |  |  |
| `organizationPartyId` | id |  | The internal organization Party that is liable for the account. |
| `ownerPartyId` | id |  |  |
| `postToGlAccountId` | id |  |  |
| `fromDate` | date-time |  |  |
| `thruDate` | date-time |  |  |
| `isRefundable` | text-indicator |  |  |
| `currencyUomId` | id |  |  |
| `negativeBalanceLimit` | currency-amount |  | A positive number restricting how far the account can go negative, defaults to zero. |
| `actualBalance` | currency-amount |  | Calculated as the sum of FinancialAccountTrans.amount |
| `availableBalance` | currency-amount |  | Calculated as actualBalance minus sum of outstanding FinancialAccountAuth.amount |
| `replenishPaymentId` | id |  |  |
| `replenishLevel` | currency-amount |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [FinancialAccountType](FinancialAccountType.md) via `finAccountTypeId`
- one `moqui.basic.StatusItem` via `statusId`
- one [Organization Party](Party.md) via `organizationPartyId`
- one [Owner Party](Party.md) via `ownerPartyId`
- one [PostTo GlAccount](GlAccount.md) via `postToGlAccountId`
- one `moqui.basic.Uom` via `currencyUomId`
- one [Replenish PaymentMethod](PaymentMethod.md) via `replenishPaymentId`
- many [FinancialAccountAuth](FinancialAccountAuth.md) via `finAccountId`
- many [FinancialAccountTrans](FinancialAccountTrans.md) via `finAccountId`
- many [FinancialAccountParty](FinancialAccountParty.md) via `finAccountId`
- many [InvoiceItem](InvoiceItem.md) via `finAccountId`
- many [PaymentGatewayResponse](PaymentGatewayResponse.md) via `finAccountId`
- many [PaymentMethod](PaymentMethod.md) via `finAccountId`
- many [Payment](Payment.md) via `finAccountId`
- many [OrderItem](OrderItem.md) via `finAccountId`
- many [ReturnHeader](ReturnHeader.md) via `finAccountId`
- many [Party](Party.md) via `ownerPartyId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.account.financial.FinancialAccount
