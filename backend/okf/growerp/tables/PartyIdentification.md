---
type: Moqui Entity
title: PartyIdentification
description: "Party Identification"
resource: http://127.0.0.1:8080/rest/e1/mantle.party.PartyIdentification
tags: [mantle, party]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# PartyIdentification

Party Identification

Full entity name: `mantle.party.PartyIdentification`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `partyId` | id | Y |  |
| `partyIdTypeEnumId` | id | Y |  |
| `idValue` | text-medium |  |  |
| `issuedBy` | text-medium |  |  |
| `issuedByPartyId` | id |  |  |
| `expireDate` | date |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.basic.Enumeration` via `partyIdTypeEnumId`
- one [Party](Party.md) via `partyId`
- one [IssuedBy Party](Party.md) via `issuedByPartyId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.party.PartyIdentification
