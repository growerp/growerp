---
type: Moqui Entity
title: BudgetParty
description: "Budget Party"
resource: http://127.0.0.1:8080/rest/e1/mantle.other.budget.BudgetParty
tags: [mantle, other, budget]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# BudgetParty

Budget Party

Full entity name: `mantle.other.budget.BudgetParty`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `budgetId` | id | Y |  |
| `partyId` | id | Y |  |
| `roleTypeId` | id | Y |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Budget](Budget.md) via `budgetId`
- one [Party](Party.md) via `partyId`
- one [RoleType](RoleType.md) via `roleTypeId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.other.budget.BudgetParty
