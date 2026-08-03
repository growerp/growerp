---
type: Moqui Entity
title: BudgetRevisionImpact
description: "Budget Revision Impact"
resource: http://127.0.0.1:8080/rest/e1/mantle.other.budget.BudgetRevisionImpact
tags: [mantle, other, budget]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# BudgetRevisionImpact

Budget Revision Impact

Full entity name: `mantle.other.budget.BudgetRevisionImpact`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `budgetId` | id | Y |  |
| `budgetItemSeqId` | id | Y |  |
| `revisionSeqId` | id | Y |  |
| `revisedAmount` | currency-amount |  |  |
| `addDeleteFlag` | text-indicator |  |  |
| `revisionReason` | text-medium |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Budget](Budget.md) via `budgetId`
- one [BudgetItem](BudgetItem.md) via `budgetId`, `budgetItemSeqId`
- one [BudgetRevision](BudgetRevision.md) via `budgetId`, `revisionSeqId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.other.budget.BudgetRevisionImpact
