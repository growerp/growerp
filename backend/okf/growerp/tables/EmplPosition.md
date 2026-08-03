---
type: Moqui Entity
title: EmplPosition
description: "Empl Position"
resource: http://127.0.0.1:8080/rest/e1/mantle.humanres.position.EmplPosition
tags: [mantle, humanres, position]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# EmplPosition

Empl Position

Full entity name: `mantle.humanres.position.EmplPosition`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `emplPositionId` | id | Y |  |
| `pseudoId` | text-short |  |  |
| `organizationPartyId` | id |  |  |
| `emplPositionClassId` | id |  |  |
| `description` | text-medium |  |  |
| `statusId` | id |  |  |
| `payGradeId` | id |  |  |
| `budgetId` | id |  |  |
| `budgetItemSeqId` | id |  |  |
| `salaryFlag` | text-indicator |  | If Y employees are salaried, otherwise paid hourly from time entries |
| `fullTimeFlag` | text-indicator |  |  |
| `temporaryFlag` | text-indicator |  |  |
| `overtimeFlag` | text-indicator |  | If Y employees are paid overtime/doubletime |
| `minimumHourlyWage` | number-decimal |  |  |
| `taxExemptEnumId` | id |  |  |
| `taxFormId` | id |  |  |
| `fromDate` | date-time |  |  |
| `thruDate` | date-time |  |  |
| `standardHoursPerWeek` | number-integer |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Organization Party](Party.md) via `organizationPartyId`
- one [EmplPositionClass](EmplPositionClass.md) via `emplPositionClassId`
- one `moqui.basic.StatusItem` via `statusId`
- one [PayGrade](PayGrade.md) via `payGradeId`
- one [BudgetItem](BudgetItem.md) via `budgetId`, `budgetItemSeqId`
- one `moqui.basic.Enumeration` via `taxExemptEnumId`
- one `moqui.screen.form.DbForm` via `taxFormId`
- many [Employment](Employment.md) via `emplPositionId`
- many [EmploymentApplication](EmploymentApplication.md) via `emplPositionId`
- many [EmplPositionParty](EmplPositionParty.md) via `emplPositionId`
- many [EmplPositionResponsibility](EmplPositionResponsibility.md) via `emplPositionId`
- many [WorkEffortEmplPosition](WorkEffortEmplPosition.md) via `emplPositionId`
- many [WorkEffortParty](WorkEffortParty.md) via `emplPositionId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.humanres.position.EmplPosition
