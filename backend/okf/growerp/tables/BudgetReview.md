---
type: Moqui Entity
title: BudgetReview
description: "Budget Review"
resource: http://127.0.0.1:8080/rest/e1/mantle.other.budget.BudgetReview
tags: [mantle, other, budget]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# BudgetReview

Budget Review

Full entity name: `mantle.other.budget.BudgetReview`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `budgetReviewId` | id | Y |  |
| `budgetId` | id |  |  |
| `partyId` | id |  |  |
| `budgetReviewResultEnumId` | id |  |  |
| `reviewDate` | date-time |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Budget](Budget.md) via `budgetId`
- one [Party](Party.md) via `partyId`
- one `moqui.basic.Enumeration` via `budgetReviewResultEnumId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.other.budget.BudgetReview
