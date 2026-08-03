---
type: Moqui Entity
title: PartyClassification
description: "Party Classification"
resource: http://127.0.0.1:8080/rest/e1/mantle.party.PartyClassification
tags: [mantle, party]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# PartyClassification

Party Classification

Full entity name: `mantle.party.PartyClassification`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `partyClassificationId` | id | Y |  |
| `classificationTypeEnumId` | id |  |  |
| `parentClassificationId` | id |  |  |
| `description` | text-medium |  |  |
| `standardCode` | text-medium |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.basic.Enumeration` via `classificationTypeEnumId`
- one [Parent PartyClassification](PartyClassification.md) via `parentClassificationId`
- many [MarketSegmentClassification](MarketSegmentClassification.md) via `partyClassificationId`
- many [PartyClassificationAppl](PartyClassificationAppl.md) via `partyClassificationId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.party.PartyClassification
