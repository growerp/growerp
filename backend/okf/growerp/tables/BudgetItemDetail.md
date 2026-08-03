---
type: Moqui Entity
title: BudgetItemDetail
description: "Budget Item Detail"
resource: http://127.0.0.1:8080/rest/e1/mantle.other.budget.BudgetItemDetail
tags: [mantle, other, budget]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# BudgetItemDetail

Budget Item Detail

Full entity name: `mantle.other.budget.BudgetItemDetail`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `budgetItemDetailId` | id | Y |  |
| `budgetId` | id |  |  |
| `budgetItemSeqId` | id |  |  |
| `facilityId` | id |  |  |
| `assetId` | id |  |  |
| `amount` | currency-precise |  |  |
| `productId` | id |  |  |
| `quantity` | number-decimal |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one-nofk [Budget](Budget.md) via `budgetId`
- one [BudgetItem](BudgetItem.md) via `budgetId`, `budgetItemSeqId`
- one [Facility](Facility.md) via `facilityId`
- one [Asset](Asset.md) via `assetId`
- one [Product](Product.md) via `productId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.other.budget.BudgetItemDetail
