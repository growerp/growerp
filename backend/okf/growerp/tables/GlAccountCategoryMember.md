---
type: Moqui Entity
title: GlAccountCategoryMember
description: "Gl Account Category Member"
resource: http://127.0.0.1:8080/rest/e1/mantle.ledger.account.GlAccountCategoryMember
tags: [mantle, ledger, account]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# GlAccountCategoryMember

Gl Account Category Member

Full entity name: `mantle.ledger.account.GlAccountCategoryMember`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `glAccountId` | id | Y |  |
| `glAccountCategoryId` | id | Y |  |
| `fromDate` | date-time | Y |  |
| `thruDate` | date-time |  |  |
| `amountPercentage` | number-decimal |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [GlAccount](GlAccount.md) via `glAccountId`
- one [GlAccountCategory](GlAccountCategory.md) via `glAccountCategoryId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.ledger.account.GlAccountCategoryMember
