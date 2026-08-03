---
type: Moqui Entity
title: FinancialAccountParty
description: "Financial Account Party"
resource: http://127.0.0.1:8080/rest/e1/mantle.account.financial.FinancialAccountParty
tags: [mantle, account, financial]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# FinancialAccountParty

Financial Account Party

Full entity name: `mantle.account.financial.FinancialAccountParty`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `finAccountId` | id | Y |  |
| `partyId` | id | Y |  |
| `roleTypeId` | id | Y |  |
| `fromDate` | date-time | Y |  |
| `thruDate` | date-time |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [FinancialAccount](FinancialAccount.md) via `finAccountId`
- one [Party](Party.md) via `partyId`
- one [RoleType](RoleType.md) via `roleTypeId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.account.financial.FinancialAccountParty
