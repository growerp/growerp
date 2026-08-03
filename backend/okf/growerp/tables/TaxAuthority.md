---
type: Moqui Entity
title: TaxAuthority
description: "For tax and other government authorities in any domain (sales/VAT, income, labor, etc)"
resource: http://127.0.0.1:8080/rest/e1/mantle.other.tax.TaxAuthority
tags: [mantle, other, tax]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# TaxAuthority

For tax and other government authorities in any domain (sales/VAT, income, labor, etc)

Full entity name: `mantle.other.tax.TaxAuthority`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `taxAuthorityId` | id | Y |  |
| `taxAuthorityTypeEnumId` | id |  |  |
| `description` | text-medium |  |  |
| `taxAuthGeoId` | id |  |  |
| `taxAuthPartyId` | id |  |  |
| `requireTaxIdForExemption` | text-indicator |  |  |
| `taxIdFormatPattern` | text-medium |  |  |
| `includeTaxInPrice` | text-indicator |  | This is mainly for VAT tax authorities |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.basic.Enumeration` via `taxAuthorityTypeEnumId`
- one `moqui.basic.Geo` via `taxAuthGeoId`
- one [TaxAuth Party](Party.md) via `taxAuthPartyId`
- many [InvoiceItem](InvoiceItem.md) via `taxAuthorityId`
- many [EmploymentPayDetail](EmploymentPayDetail.md) via `taxAuthorityId`
- many [PayrollAdjustment](PayrollAdjustment.md) via `taxAuthorityId`
- many [PayrollAllowance](PayrollAllowance.md) via `taxAuthorityId`
- many [PayrollStdDeduction](PayrollStdDeduction.md) via `taxAuthorityId`
- many [TaxAuthorityGlAccount](TaxAuthorityGlAccount.md) via `taxAuthorityId`
- many [OrderItem](OrderItem.md) via `taxAuthorityId`
- many [TaxAuthorityAssoc](TaxAuthorityAssoc.md) via `taxAuthorityId`
- many [To TaxAuthorityAssoc](TaxAuthorityAssoc.md) via `taxAuthorityId`
- many [TaxAuthorityCategory](TaxAuthorityCategory.md) via `taxAuthorityId`
- many [TaxAuthorityParty](TaxAuthorityParty.md) via `taxAuthorityId`
- many [TaxStatement](TaxStatement.md) via `taxAuthorityId`
- many [ProductPrice](ProductPrice.md) via `taxAuthorityId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.other.tax.TaxAuthority
