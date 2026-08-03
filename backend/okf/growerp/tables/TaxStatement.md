---
type: Moqui Entity
title: TaxStatement
description: "Tax Statement"
resource: http://127.0.0.1:8080/rest/e1/mantle.other.tax.TaxStatement
tags: [mantle, other, tax]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# TaxStatement

Tax Statement

Full entity name: `mantle.other.tax.TaxStatement`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `taxStatementId` | id | Y |  |
| `timePeriodId` | id |  |  |
| `partyId` | id |  | The Party the statement is for |
| `partyRelationshipId` | id |  | For employment relationships when a wage/tax statement |
| `taxAuthorityId` | id |  |  |
| `formId` | id |  |  |
| `formResponseId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [TimePeriod](TimePeriod.md) via `timePeriodId`
- one [Employment](Employment.md) via `partyRelationshipId`
- one [TaxAuthority](TaxAuthority.md) via `taxAuthorityId`
- one `moqui.screen.form.DbForm` via `formId`
- one `moqui.screen.form.FormResponse` via `formResponseId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.other.tax.TaxStatement
