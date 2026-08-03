---
type: Moqui Entity
title: PayGrade
description: "Pay Grade"
resource: http://127.0.0.1:8080/rest/e1/mantle.humanres.rate.PayGrade
tags: [mantle, humanres, rate]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# PayGrade

Pay Grade

Full entity name: `mantle.humanres.rate.PayGrade`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `payGradeId` | id | Y |  |
| `description` | text-medium |  |  |
| `comments` | text-medium |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- many [EmploymentSalary](EmploymentSalary.md) via `payGradeId`
- many [EmplPosition](EmplPosition.md) via `payGradeId`
- many [PayGradeSalary](PayGradeSalary.md) via `payGradeId`
- many [RateAmount](RateAmount.md) via `payGradeId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.humanres.rate.PayGrade
