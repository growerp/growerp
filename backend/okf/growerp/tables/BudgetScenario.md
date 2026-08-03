---
type: Moqui Entity
title: BudgetScenario
description: "Budget Scenario"
resource: http://127.0.0.1:8080/rest/e1/mantle.other.budget.BudgetScenario
tags: [mantle, other, budget]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# BudgetScenario

Budget Scenario

Full entity name: `mantle.other.budget.BudgetScenario`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `budgetScenarioId` | id | Y |  |
| `description` | text-medium |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- many [BudgetScenarioApplication](BudgetScenarioApplication.md) via `budgetScenarioId`
- many [BudgetScenarioRule](BudgetScenarioRule.md) via `budgetScenarioId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.other.budget.BudgetScenario
