---
type: Moqui Entity
title: BenefitType
description: "Benefit Type"
resource: http://127.0.0.1:8080/rest/e1/mantle.humanres.employment.BenefitType
tags: [mantle, humanres, employment]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# BenefitType

Benefit Type

Full entity name: `mantle.humanres.employment.BenefitType`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `benefitTypeId` | id | Y |  |
| `parentTypeId` | id |  |  |
| `description` | text-medium |  |  |
| `employerPaidPercentage` | number-float |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Parent BenefitType](BenefitType.md) via `parentTypeId`
- many [EmploymentBenefit](EmploymentBenefit.md) via `benefitTypeId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.humanres.employment.BenefitType
