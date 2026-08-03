---
type: Moqui Entity
title: GlBudgetXref
description: "Gl Budget Xref"
resource: http://127.0.0.1:8080/rest/e1/mantle.ledger.account.GlBudgetXref
tags: [mantle, ledger, account]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# GlBudgetXref

Gl Budget Xref

Full entity name: `mantle.ledger.account.GlBudgetXref`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `glAccountId` | id | Y |  |
| `budgetItemTypeEnumId` | id | Y |  |
| `fromDate` | date-time | Y |  |
| `thruDate` | date-time |  |  |
| `allocationPercentage` | number-decimal |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [GlAccount](GlAccount.md) via `glAccountId`
- one `moqui.basic.Enumeration` via `budgetItemTypeEnumId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.ledger.account.GlBudgetXref
