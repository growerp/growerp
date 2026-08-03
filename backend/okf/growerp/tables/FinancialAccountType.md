---
type: Moqui Entity
title: FinancialAccountType
description: "Financial Account Type"
resource: http://127.0.0.1:8080/rest/e1/mantle.account.financial.FinancialAccountType
tags: [mantle, account, financial]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# FinancialAccountType

Financial Account Type

Full entity name: `mantle.account.financial.FinancialAccountType`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `finAccountTypeId` | id | Y |  |
| `parentTypeId` | id |  |  |
| `description` | text-medium |  |  |
| `isRefundable` | text-indicator |  |  |
| `accountCodeLength` | number-integer |  |  |
| `requirePinCode` | text-indicator |  |  |
| `pinCodeLength` | number-integer |  |  |
| `accountValidDays` | number-integer |  |  |
| `authValidDays` | number-integer |  |  |
| `replenishMinBalance` | currency-amount |  |  |
| `replenishThreshold` | currency-amount |  |  |
| `replenishMethodEnumId` | id |  |  |
| `replenishTypeEnumId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Parent FinancialAccountType](FinancialAccountType.md) via `parentTypeId`
- one `moqui.basic.Enumeration` via `replenishMethodEnumId`
- one `moqui.basic.Enumeration` via `replenishTypeEnumId`
- many [FinancialAccount](FinancialAccount.md) via `finAccountTypeId`
- many [FinancialAccountTypeGlAccount](FinancialAccountTypeGlAccount.md) via `finAccountTypeId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.account.financial.FinancialAccountType
