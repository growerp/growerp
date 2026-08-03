---
type: Moqui Entity
title: BudgetScenarioRule
description: "Budget Scenario Rule"
resource: http://127.0.0.1:8080/rest/e1/mantle.other.budget.BudgetScenarioRule
tags: [mantle, other, budget]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# BudgetScenarioRule

Budget Scenario Rule

Full entity name: `mantle.other.budget.BudgetScenarioRule`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `budgetScenarioId` | id | Y |  |
| `budgetItemTypeEnumId` | id | Y |  |
| `amountChange` | currency-amount |  |  |
| `percentageChange` | number-decimal |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [BudgetScenario](BudgetScenario.md) via `budgetScenarioId`
- one `moqui.basic.Enumeration` via `budgetItemTypeEnumId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.other.budget.BudgetScenarioRule
