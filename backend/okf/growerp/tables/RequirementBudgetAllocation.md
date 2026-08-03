---
type: Moqui Entity
title: RequirementBudgetAllocation
description: "Requirement Budget Allocation"
resource: http://127.0.0.1:8080/rest/e1/mantle.request.requirement.RequirementBudgetAllocation
tags: [mantle, request, requirement]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# RequirementBudgetAllocation

Requirement Budget Allocation

Full entity name: `mantle.request.requirement.RequirementBudgetAllocation`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `requirementId` | id | Y |  |
| `budgetId` | id | Y |  |
| `budgetItemSeqId` | id | Y |  |
| `amount` | currency-amount |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [BudgetItem](BudgetItem.md) via `budgetId`, `budgetItemSeqId`
- one [Requirement](Requirement.md) via `requirementId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.request.requirement.RequirementBudgetAllocation
