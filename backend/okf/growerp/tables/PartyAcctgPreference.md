---
type: Moqui Entity
title: PartyAcctgPreference
description: "Party Acctg Preference"
resource: http://127.0.0.1:8080/rest/e1/mantle.ledger.config.PartyAcctgPreference
tags: [mantle, ledger, config]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# PartyAcctgPreference

Party Acctg Preference

Full entity name: `mantle.ledger.config.PartyAcctgPreference`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `organizationPartyId` | id | Y |  |
| `fiscalYearStartMonth` | number-integer |  |  |
| `fiscalYearStartDay` | number-integer |  |  |
| `realTimeGlSummary` | text-indicator |  | Defaults to N. If set to Y GlAccountOrganization and GlAccountOrgTimePeriod are updated with each AcctgTrans post. |
| `hourlyTimePeriodTypeId` | id |  |  |
| `salaryTimePeriodTypeId` | id |  |  |
| `taxFormEnumId` | id |  |  |
| `payrollTaxFormEnumId` | id |  |  |
| `taxClassificationEnumId` | id |  |  |
| `employerClassEnumId` | id |  |  |
| `cogsMethodEnumId` | id |  |  |
| `baseCurrencyUomId` | id |  | The unit of account currency for the Internal Organization |
| `localCurrencyUomId` | id |  | For unstable local currencies when different from a more stable base currency |
| `invoiceSequenceEnumId` | id |  |  |
| `invoiceIdPrefix` | text-short |  |  |
| `useInvoiceIdForReturns` | text-indicator |  |  |
| `orderSequenceEnumId` | id |  |  |
| `orderIdPrefix` | text-short |  |  |
| `refundPaymentMethodId` | id |  |  |
| `errorGlJournalId` | id |  | Journal to which all the failed automatic transaction are assigned. If the error journal is set, if the GL posting fails for some reason the triggering operation (finalizing an invoice or payment or whatever) would NOT roll back, instead the partial GL post would be placed into the error journal. |
| `glAccountCodeMask` | text-short |  |  |
| `settlementTermId` | id |  | The default SettlementTerm to use on receivable (outgoing) invoices if there is none from agreement, order, etc |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Organization Party](Party.md) via `organizationPartyId`
- one [Hourly TimePeriodType](TimePeriodType.md) via `hourlyTimePeriodTypeId`
- one [Salary TimePeriodType](TimePeriodType.md) via `salaryTimePeriodTypeId`
- one `moqui.basic.Enumeration` via `taxFormEnumId`
- one `moqui.basic.Enumeration` via `payrollTaxFormEnumId`
- one `moqui.basic.Enumeration` via `taxClassificationEnumId`
- one `moqui.basic.Enumeration` via `employerClassEnumId`
- one `moqui.basic.Enumeration` via `cogsMethodEnumId`
- one `moqui.basic.Uom` via `baseCurrencyUomId`
- one `moqui.basic.Uom` via `localCurrencyUomId`
- one [Refund PaymentMethod](PaymentMethod.md) via `refundPaymentMethodId`
- one [GlJournal](GlJournal.md) via `errorGlJournalId`
- one `moqui.basic.Enumeration` via `invoiceSequenceEnumId`
- one `moqui.basic.Enumeration` via `orderSequenceEnumId`
- one [SettlementTerm](SettlementTerm.md) via `settlementTermId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.ledger.config.PartyAcctgPreference
