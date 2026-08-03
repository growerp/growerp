---
type: Moqui Entity
title: Budget
description: "Budget"
resource: http://127.0.0.1:8080/rest/e1/mantle.other.budget.Budget
tags: [mantle, other, budget]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# Budget

Budget

Full entity name: `mantle.other.budget.Budget`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `budgetId` | id | Y |  |
| `budgetTypeEnumId` | id |  |  |
| `timePeriodId` | id |  |  |
| `subTimePeriodTypeId` | id |  |  |
| `statusId` | id |  |  |
| `currencyUomId` | id |  |  |
| `description` | text-medium |  |  |
| `comments` | text-long |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.basic.Enumeration` via `budgetTypeEnumId`
- one [TimePeriod](TimePeriod.md) via `timePeriodId`
- one `moqui.basic.StatusItem` via `statusId`
- one `moqui.basic.Uom` via `currencyUomId`
- many [BudgetItem](BudgetItem.md) via `budgetId`
- many [BudgetItemDetail](BudgetItemDetail.md) via `budgetId`
- many [BudgetParty](BudgetParty.md) via `budgetId`
- many [BudgetReview](BudgetReview.md) via `budgetId`
- many [BudgetRevision](BudgetRevision.md) via `budgetId`
- many [BudgetRevisionImpact](BudgetRevisionImpact.md) via `budgetId`
- many [BudgetScenarioApplication](BudgetScenarioApplication.md) via `budgetId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.other.budget.Budget
