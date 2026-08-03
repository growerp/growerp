---
type: Moqui Entity
title: EmploymentPayDetail
description: "Employment Pay Detail"
resource: http://127.0.0.1:8080/rest/e1/mantle.humanres.employment.EmploymentPayDetail
tags: [mantle, humanres, employment]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# EmploymentPayDetail

Employment Pay Detail

Full entity name: `mantle.humanres.employment.EmploymentPayDetail`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `employmentPayDetailId` | id | Y |  |
| `partyRelationshipId` | id |  |  |
| `payDate` | date |  |  |
| `payrollAdjustmentId` | id |  |  |
| `adjCalcServiceId` | id |  |  |
| `itemTypeEnumId` | id |  |  |
| `quantity` | number-decimal |  |  |
| `amount` | number-decimal |  |  |
| `isEmployerPaid` | text-indicator |  |  |
| `taxAuthorityId` | id |  |  |
| `payeePartyId` | id |  |  |
| `payeeReference` | text-short |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [EmploymentPayHistory](EmploymentPayHistory.md) via `partyRelationshipId`, `payDate`
- one [PayrollAdjustment](PayrollAdjustment.md) via `payrollAdjustmentId`
- one `moqui.basic.Enumeration` via `itemTypeEnumId`
- one [TaxAuthority](TaxAuthority.md) via `taxAuthorityId`
- one [Garnish Party](Party.md) via `payeePartyId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.humanres.employment.EmploymentPayDetail
