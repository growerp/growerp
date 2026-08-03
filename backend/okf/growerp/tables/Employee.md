---
type: Moqui Entity
title: Employee
description: "Employee"
resource: http://127.0.0.1:8080/rest/e1/mantle.humanres.employment.Employee
tags: [mantle, humanres, employment]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# Employee

Employee

Full entity name: `mantle.humanres.employment.Employee`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `partyId` | id | Y |  |
| `distGroupEnumId` | id |  |  |
| `taxFormId` | id |  |  |
| `taxClassificationEnumId` | id |  |  |
| `taxName` | text-medium |  | Defaults to Person or Organization name fields |
| `taxMiddleName` | text-medium |  | Defaults to Person.middleName if applicable |
| `taxLastName` | text-medium |  | Defaults to Person.lastName if applicable |
| `taxNameSuffix` | text-medium |  | Defaults to Person.suffix if applicable |
| `taxBusinessName` | text-medium |  |  |
| `taxHomeContactMechId` | id |  |  |
| `taxExemptPayeeCode` | text-short |  |  |
| `taxExemptFatcaCode` | text-short |  |  |
| `taxAccountNumbers` | text-medium |  |  |
| `taxFederalStatusEnumId` | id |  |  |
| `taxStateStatusEnumId` | id |  |  |
| `taxYtdPriorIncome` | currency-amount |  | Added to YTD income for starting year only (for taxes limited by YTD income) |
| `taxFederalAllowances` | number-integer |  |  |
| `taxStateAllowances` | number-integer |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Party](Party.md) via `partyId`
- one `moqui.basic.Enumeration` via `distGroupEnumId`
- one `moqui.screen.form.DbForm` via `taxFormId`
- one `moqui.basic.Enumeration` via `taxClassificationEnumId`
- one [TaxHome PostalAddress](PostalAddress.md) via `taxHomeContactMechId`
- one `moqui.basic.Enumeration` via `taxFederalStatusEnumId`
- one `moqui.basic.Enumeration` via `taxStateStatusEnumId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.humanres.employment.Employee
