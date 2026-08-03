---
type: Moqui Entity
title: BudgetItem
description: "Budget Item"
resource: http://127.0.0.1:8080/rest/e1/mantle.other.budget.BudgetItem
tags: [mantle, other, budget]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# BudgetItem

Budget Item

Full entity name: `mantle.other.budget.BudgetItem`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `budgetId` | id | Y |  |
| `budgetItemSeqId` | id | Y |  |
| `budgetItemTypeEnumId` | id |  |  |
| `itemTypeEnumId` | id |  |  |
| `glAccountId` | id |  |  |
| `amount` | currency-amount |  |  |
| `productId` | id |  |  |
| `quantity` | number-decimal |  |  |
| `quantityUomId` | id |  |  |
| `purpose` | text-medium |  |  |
| `justification` | text-medium |  |  |
| `subTimePeriodId` | id |  | A TimePeriod for the item within the TimePeriod for the entire budget |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Budget](Budget.md) via `budgetId`
- one `moqui.basic.Enumeration` via `budgetItemTypeEnumId`
- one `moqui.basic.Enumeration` via `itemTypeEnumId`
- one [GlAccount](GlAccount.md) via `glAccountId`
- one [Product](Product.md) via `productId`
- one `moqui.basic.Uom` via `quantityUomId`
- one [Sub TimePeriod](TimePeriod.md) via `subTimePeriodId`
- many [BudgetItemDetail](BudgetItemDetail.md) via `budgetId`, `budgetItemSeqId`
- many [PaymentBudgetAllocation](PaymentBudgetAllocation.md) via `budgetId`, `budgetItemSeqId`
- many [EmplPosition](EmplPosition.md) via `budgetId`, `budgetItemSeqId`
- many [BudgetRevisionImpact](BudgetRevisionImpact.md) via `budgetId`, `budgetItemSeqId`
- many [BudgetScenarioApplication](BudgetScenarioApplication.md) via `budgetId`, `budgetItemSeqId`
- many [RequirementBudgetAllocation](RequirementBudgetAllocation.md) via `budgetId`, `budgetItemSeqId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.other.budget.BudgetItem
