---
type: Moqui Entity
title: EmploymentPayHistory
description: "Employment Pay History"
resource: http://127.0.0.1:8080/rest/e1/mantle.humanres.employment.EmploymentPayHistory
tags: [mantle, humanres, employment]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# EmploymentPayHistory

Employment Pay History

Full entity name: `mantle.humanres.employment.EmploymentPayHistory`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `partyRelationshipId` | id | Y |  |
| `payDate` | date | Y |  |
| `timePeriodId` | id |  |  |
| `invoiceId` | id |  |  |
| `internalPayroll` | text-indicator |  | If Y is included in year end tax reporting, otherwise considered external pay used only for YTD calculations in payroll adjustments |
| `payAmount` | number-decimal |  |  |
| `taxablePayAmount` | number-decimal |  |  |
| `socialTaxablePayAmount` | number-decimal |  |  |
| `medicalTaxablePayAmount` | number-decimal |  |  |
| `netPayAmount` | number-decimal |  |  |
| `disposablePayAmount` | number-decimal |  |  |
| `taxableYtdIncome` | number-decimal |  |  |
| `socialTaxableYtdIncome` | number-decimal |  |  |
| `medicalTaxableYtdIncome` | number-decimal |  |  |
| `currencyUomId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Employment](Employment.md) via `partyRelationshipId`
- one [TimePeriod](TimePeriod.md) via `timePeriodId`
- one [Invoice](Invoice.md) via `invoiceId`
- one `moqui.basic.Uom` via `currencyUomId`
- many [EmploymentPayDetail](EmploymentPayDetail.md) via `partyRelationshipId`, `payDate`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.humanres.employment.EmploymentPayHistory
