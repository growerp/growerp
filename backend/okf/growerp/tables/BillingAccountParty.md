---
type: Moqui Entity
title: BillingAccountParty
description: "Billing Account Party"
resource: http://127.0.0.1:8080/rest/e1/mantle.account.billing.BillingAccountParty
tags: [mantle, account, billing]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# BillingAccountParty

Billing Account Party

Full entity name: `mantle.account.billing.BillingAccountParty`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `billingAccountId` | id | Y |  |
| `partyId` | id | Y |  |
| `roleTypeId` | id | Y |  |
| `fromDate` | date-time | Y |  |
| `thruDate` | date-time |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [BillingAccount](BillingAccount.md) via `billingAccountId`
- one [Party](Party.md) via `partyId`
- one [RoleType](RoleType.md) via `roleTypeId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.account.billing.BillingAccountParty
