---
type: Moqui Entity
title: AgreementItemGeo
description: "Agreement Item Geo"
resource: http://127.0.0.1:8080/rest/e1/mantle.party.agreement.AgreementItemGeo
tags: [mantle, party, agreement]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# AgreementItemGeo

Agreement Item Geo

Full entity name: `mantle.party.agreement.AgreementItemGeo`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `agreementId` | id | Y |  |
| `agreementItemSeqId` | id | Y |  |
| `geoId` | id | Y |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [AgreementItem](AgreementItem.md) via `agreementId`, `agreementItemSeqId`
- one `moqui.basic.Geo` via `geoId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.party.agreement.AgreementItemGeo
