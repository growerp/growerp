---
type: Moqui Entity
title: BankAccount
description: "Bank Account"
resource: http://127.0.0.1:8080/rest/e1/mantle.account.method.BankAccount
tags: [mantle, account, method]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# BankAccount

Bank Account

Full entity name: `mantle.account.method.BankAccount`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `paymentMethodId` | id | Y |  |
| `bankName` | text-medium |  |  |
| `bankPartyId` | id |  |  |
| `typeEnumId` | id |  |  |
| `routingNumber` | text-short |  |  |
| `accountNumber` | text-medium |  |  |
| `lastCheckNumber` | number-integer |  |  |
| `nachaImmedDest` | text-short |  | Must be 9 digits, generally assigned by bank, usually bank routing/transit number |
| `nachaImmedOrig` | text-short |  | Must be 9 digits, generally assigned by bank, ID identifying company as source/origin for NACHA files |
| `nachaImmedDestName` | text-short |  | Defaults to bankName, upper-cased; must not be more than 23 characters |
| `nachaImmedOrigName` | text-short |  | Defaults to companyNameOnAccount, upper-cased; must not be more than 23 characters |
| `nachaCompanyName` | text-short |  | Used to identify company in ACH transactions. Defaults to companyNameOnAccount, upper-cased; must not be more than 16 characters for NACHA files |
| `nachaDiscrData` | text-short |  | Discretionary data, may be sub account or other; must not be more than 20 characters |
| `nachaCompanyId` | text-short |  | Bank-assigned Company ID for ACH transactions; must not be more than 10 characters |
| `nachaOdfiId` | text-short |  | Batch ODFI ID (Originating Depository Financial Institution), 8 digits, defaults to first 8 digits of nachaImmedDest (Immediate Destination ID) |
| `nachaEntryDescription` | text-short |  | A description to be added to ACH transactions (such as Payroll, Order); must not be more than 10 characters |
| `nachaAddNewLine` | text-indicator |  |  |
| `nachaAddOffsetRecord` | text-indicator |  |  |
| `posPayBankNumber` | text-short |  | Number specified by bank to identify bank in positive pay files |
| `posPayFormatEnumId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [PaymentMethod](PaymentMethod.md) via `paymentMethodId`
- one [Bank Party](Party.md) via `bankPartyId`
- one `moqui.basic.Enumeration` via `typeEnumId`
- one `moqui.basic.Enumeration` via `posPayFormatEnumId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.account.method.BankAccount
