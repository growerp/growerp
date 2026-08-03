---
type: Moqui Entity
title: EmploymentBenefit
description: "Employment Benefit"
resource: http://127.0.0.1:8080/rest/e1/mantle.humanres.employment.EmploymentBenefit
tags: [mantle, humanres, employment]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# EmploymentBenefit

Employment Benefit

Full entity name: `mantle.humanres.employment.EmploymentBenefit`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `partyRelationshipId` | id | Y |  |
| `benefitTypeId` | id | Y |  |
| `fromDate` | date-time | Y |  |
| `thruDate` | date-time |  |  |
| `cost` | currency-amount |  |  |
| `actualEmployerPaidPercent` | number-float |  |  |
| `availableTime` | number-integer |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Employment](Employment.md) via `partyRelationshipId`
- one [BenefitType](BenefitType.md) via `benefitTypeId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.humanres.employment.EmploymentBenefit
