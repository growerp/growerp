---
type: Moqui Entity
title: PartyClassificationAppl
description: "Party Classification Appl"
resource: http://127.0.0.1:8080/rest/e1/mantle.party.PartyClassificationAppl
tags: [mantle, party]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# PartyClassificationAppl

Party Classification Appl

Full entity name: `mantle.party.PartyClassificationAppl`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `partyId` | id | Y |  |
| `partyClassificationId` | id | Y |  |
| `fromDate` | date-time | Y |  |
| `thruDate` | date-time |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Party](Party.md) via `partyId`
- one [PartyClassification](PartyClassification.md) via `partyClassificationId`
- many [To Invoice](Invoice.md) via `partyId`
- many [Customer OrderPart](OrderPart.md) via `partyId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.party.PartyClassificationAppl
