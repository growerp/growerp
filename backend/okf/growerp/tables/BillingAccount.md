---
type: Moqui Entity
title: BillingAccount
description: "Billing Account"
resource: http://127.0.0.1:8080/rest/e1/mantle.account.billing.BillingAccount
tags: [mantle, account, billing]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# BillingAccount

Billing Account

Full entity name: `mantle.account.billing.BillingAccount`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `billingAccountId` | id | Y |  |
| `billToPartyId` | id |  |  |
| `billFromPartyId` | id |  |  |
| `accountLimit` | currency-amount |  |  |
| `accountLimitUomId` | id |  |  |
| `postalContactMechId` | id |  |  |
| `fromDate` | date-time |  |  |
| `thruDate` | date-time |  |  |
| `description` | text-medium |  |  |
| `externalAccountId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [BillTo Party](Party.md) via `billToPartyId`
- one `moqui.basic.Uom` via `accountLimitUomId`
- one [Postal ContactMech](ContactMech.md) via `postalContactMechId`
- one [PostalAddress](PostalAddress.md) via `postalContactMechId`
- many [BillingAccountParty](BillingAccountParty.md) via `billingAccountId`
- many [BillingAccountTerm](BillingAccountTerm.md) via `billingAccountId`
- many [Invoice](Invoice.md) via `billingAccountId`
- many [PaymentApplication](PaymentApplication.md) via `billingAccountId`
- many [OrderHeader](OrderHeader.md) via `billingAccountId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.account.billing.BillingAccount
