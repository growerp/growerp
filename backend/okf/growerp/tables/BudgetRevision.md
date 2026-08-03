---
type: Moqui Entity
title: BudgetRevision
description: "Budget Revision"
resource: http://127.0.0.1:8080/rest/e1/mantle.other.budget.BudgetRevision
tags: [mantle, other, budget]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# BudgetRevision

Budget Revision

Full entity name: `mantle.other.budget.BudgetRevision`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `budgetId` | id | Y |  |
| `revisionSeqId` | id | Y |  |
| `dateRevised` | date-time |  |  |
| `description` | text-medium |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Budget](Budget.md) via `budgetId`
- many [BudgetRevisionImpact](BudgetRevisionImpact.md) via `budgetId`, `revisionSeqId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.other.budget.BudgetRevision
