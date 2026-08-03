---
type: Moqui Entity
title: BillingAccountTerm
description: "Billing Account Term"
resource: http://127.0.0.1:8080/rest/e1/mantle.account.billing.BillingAccountTerm
tags: [mantle, account, billing]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# BillingAccountTerm

Billing Account Term

Full entity name: `mantle.account.billing.BillingAccountTerm`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `billingAccountTermId` | id | Y |  |
| `billingAccountId` | id |  |  |
| `termTypeEnumId` | id |  |  |
| `termValue` | number-decimal |  |  |
| `termUomId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.basic.Enumeration` via `termTypeEnumId`
- one `moqui.basic.Uom` via `termUomId`
- one [BillingAccount](BillingAccount.md) via `billingAccountId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.account.billing.BillingAccountTerm
