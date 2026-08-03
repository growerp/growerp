---
type: Moqui Entity
title: GlAccountOrgTimePeriod
description: "Gl Account Org Time Period"
resource: http://127.0.0.1:8080/rest/e1/mantle.ledger.account.GlAccountOrgTimePeriod
tags: [mantle, ledger, account]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# GlAccountOrgTimePeriod

Gl Account Org Time Period

Full entity name: `mantle.ledger.account.GlAccountOrgTimePeriod`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `glAccountId` | id | Y |  |
| `organizationPartyId` | id | Y |  |
| `timePeriodId` | id | Y |  |
| `postedDebits` | currency-amount |  |  |
| `postedCredits` | currency-amount |  |  |
| `postedDebitsNoClosing` | currency-amount |  |  |
| `postedCreditsNoClosing` | currency-amount |  |  |
| `beginningBalance` | currency-amount |  |  |
| `endingBalance` | currency-amount |  |  |
| `balanceLastUpdated` | date-time |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [GlAccount](GlAccount.md) via `glAccountId`
- one [Organization Party](Party.md) via `organizationPartyId`
- one [TimePeriod](TimePeriod.md) via `timePeriodId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.ledger.account.GlAccountOrgTimePeriod
