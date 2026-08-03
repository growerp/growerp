---
type: Moqui Entity
title: AgreementAssoc
description: "Agreement Assoc"
resource: http://127.0.0.1:8080/rest/e1/mantle.party.agreement.AgreementAssoc
tags: [mantle, party, agreement]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# AgreementAssoc

Agreement Assoc

Full entity name: `mantle.party.agreement.AgreementAssoc`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `agreementAssocId` | id | Y |  |
| `agreementId` | id |  |  |
| `toAgreementId` | id |  |  |
| `agreementAssocTypeEnumId` | id |  |  |
| `geoId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Agreement](Agreement.md) via `agreementId`
- one [To Agreement](Agreement.md) via `toAgreementId`
- one `moqui.basic.Geo` via `geoId`
- one `moqui.basic.Enumeration` via `agreementAssocTypeEnumId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.party.agreement.AgreementAssoc
