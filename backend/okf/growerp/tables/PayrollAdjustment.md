---
type: Moqui Entity
title: PayrollAdjustment
description: "Payroll Adjustment"
resource: http://127.0.0.1:8080/rest/e1/mantle.humanres.employment.PayrollAdjustment
tags: [mantle, humanres, employment]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# PayrollAdjustment

Payroll Adjustment

Full entity name: `mantle.humanres.employment.PayrollAdjustment`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `payrollAdjustmentId` | id | Y |  |
| `description` | text-medium |  |  |
| `organizationPartyId` | id |  | If null applies to all organizations |
| `partyRelationshipId` | id |  | If null applies to all employees |
| `itemTypeEnumId` | id |  |  |
| `exclusiveByItemType` | text-indicator |  | Overrides less specific payroll adjusmtents if employment or employer is set. Employment > Employer > open if set to Y. |
| `overrideGlAccountId` | id |  |  |
| `payrollPhaseEnumId` | id |  |  |
| `timePeriodTypeId` | id |  |  |
| `fromDate` | date-time |  |  |
| `thruDate` | date-time |  |  |
| `isTax` | text-indicator |  |  |
| `isTaxable` | text-indicator |  | For taxable positive adjustments and tax deductible negative adjustments. |
| `isSocialTax` | text-indicator |  |  |
| `isSocialTaxable` | text-indicator |  | For social (in USA: Social Security OASDI program) taxable positive adjustments and deductible negative adjustments. |
| `isMedicalTax` | text-indicator |  |  |
| `isMedicalTaxable` | text-indicator |  | For medical (in USA: Medicare program) taxable positive adjustments and deductible negative adjustments. |
| `rateBasisEnumId` | id |  |  |
| `riskClassEnumId` | text-short |  |  |
| `taxAuthorityId` | id |  |  |
| `taxBox` | text-short |  | For tax forms, the alphanumeric box |
| `taxBoxCode` | text-short |  | For tax forms, the code/type |
| `isEmployerPaid` | text-indicator |  | If Y is paid by the employer and not included in employee pay invoices. |
| `applyStdDeduction` | text-indicator |  |  |
| `applyAllowanceDeduction` | text-indicator |  |  |
| `applyAllowanceExemption` | text-indicator |  |  |
| `payeePartyId` | id |  |  |
| `payeeReference` | text-short |  |  |
| `payeeDueDays` | number-integer |  |  |
| `garnishDisposablePercent` | number-decimal |  |  |
| `garnishMinWageApplies` | text-indicator |  |  |
| `garnishPriority` | number-integer |  |  |
| `deductFromDisposable` | text-indicator |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Organization Party](Party.md) via `organizationPartyId`
- one [Employment](Employment.md) via `partyRelationshipId`
- one `moqui.basic.Enumeration` via `itemTypeEnumId`
- one [Override GlAccount](GlAccount.md) via `overrideGlAccountId`
- one `moqui.basic.Enumeration` via `payrollPhaseEnumId`
- one [TimePeriodType](TimePeriodType.md) via `timePeriodTypeId`
- one `moqui.basic.Enumeration` via `rateBasisEnumId`
- one [TaxAuthority](TaxAuthority.md) via `taxAuthorityId`
- one [Payee Party](Party.md) via `payeePartyId`
- many [PayrollAdjustmentDetail](PayrollAdjustmentDetail.md) via `payrollAdjustmentId`
- many [PayrollAdjustmentExempt](PayrollAdjustmentExempt.md) via `payrollAdjustmentId`
- many [PayrollAdjustmentFedStts](PayrollAdjustmentFedStts.md) via `payrollAdjustmentId`
- many [PayrollAdjustmentStateStts](PayrollAdjustmentStateStts.md) via `payrollAdjustmentId`
- many [InvoiceItem](InvoiceItem.md) via `payrollAdjustmentId`
- many [EmploymentPayDetail](EmploymentPayDetail.md) via `payrollAdjustmentId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.humanres.employment.PayrollAdjustment
