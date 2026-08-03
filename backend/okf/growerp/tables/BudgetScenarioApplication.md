---
type: Moqui Entity
title: BudgetScenarioApplication
description: "Budget Scenario Application"
resource: http://127.0.0.1:8080/rest/e1/mantle.other.budget.BudgetScenarioApplication
tags: [mantle, other, budget]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# BudgetScenarioApplication

Budget Scenario Application

Full entity name: `mantle.other.budget.BudgetScenarioApplication`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `budgetScenarioApplicId` | id | Y |  |
| `budgetScenarioId` | id | Y |  |
| `budgetId` | id |  |  |
| `budgetItemSeqId` | id |  |  |
| `amountChange` | currency-amount |  |  |
| `percentageChange` | number-decimal |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [BudgetScenario](BudgetScenario.md) via `budgetScenarioId`
- one [Budget](Budget.md) via `budgetId`
- one [BudgetItem](BudgetItem.md) via `budgetId`, `budgetItemSeqId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.other.budget.BudgetScenarioApplication
