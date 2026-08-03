---
type: Moqui Entity
title: TaxAuthorityParty
description: "Tax Authority Party"
resource: http://127.0.0.1:8080/rest/e1/mantle.other.tax.TaxAuthorityParty
tags: [mantle, other, tax]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# TaxAuthorityParty

Tax Authority Party

Full entity name: `mantle.other.tax.TaxAuthorityParty`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `partyId` | id | Y |  |
| `taxAuthorityId` | id | Y |  |
| `fromDate` | date-time | Y |  |
| `thruDate` | date-time |  |  |
| `partyTaxId` | text-short |  |  |
| `isExempt` | text-indicator |  |  |
| `isNexus` | text-indicator |  | If Party has a sufficient presence in the area to have to charge tax set to Y. |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Party](Party.md) via `partyId`
- one [TaxAuthority](TaxAuthority.md) via `taxAuthorityId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.other.tax.TaxAuthorityParty
