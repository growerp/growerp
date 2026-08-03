---
type: Moqui Entity
title: TaxAuthorityAssoc
description: "Tax Authority Assoc"
resource: http://127.0.0.1:8080/rest/e1/mantle.other.tax.TaxAuthorityAssoc
tags: [mantle, other, tax]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# TaxAuthorityAssoc

Tax Authority Assoc

Full entity name: `mantle.other.tax.TaxAuthorityAssoc`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `taxAuthorityId` | id | Y |  |
| `toTaxAuthorityId` | id | Y |  |
| `fromDate` | date-time | Y |  |
| `thruDate` | date-time |  |  |
| `assocTypeEnumId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [TaxAuthority](TaxAuthority.md) via `taxAuthorityId`
- one [To TaxAuthority](TaxAuthority.md) via `toTaxAuthorityId`
- one `moqui.basic.Enumeration` via `assocTypeEnumId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.other.tax.TaxAuthorityAssoc
