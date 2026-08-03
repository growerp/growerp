---
type: Moqui Entity
title: PartyDimension
description: "Party Dimension"
resource: http://127.0.0.1:8080/rest/e1/mantle.party.PartyDimension
tags: [mantle, party]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# PartyDimension

Party Dimension

Full entity name: `mantle.party.PartyDimension`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `partyId` | id | Y |  |
| `uomDimensionTypeId` | id | Y |  |
| `dimensionDate` | date-time | Y |  |
| `value` | number-decimal |  |  |
| `uomId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Party](Party.md) via `partyId`
- one `moqui.basic.UomDimensionType` via `uomDimensionTypeId`
- one `moqui.basic.Uom` via `uomId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.party.PartyDimension
