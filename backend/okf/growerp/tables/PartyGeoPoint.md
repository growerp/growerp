---
type: Moqui Entity
title: PartyGeoPoint
description: "Party Geo Point"
resource: http://127.0.0.1:8080/rest/e1/mantle.party.PartyGeoPoint
tags: [mantle, party]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# PartyGeoPoint

Party Geo Point

Full entity name: `mantle.party.PartyGeoPoint`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `partyId` | id | Y |  |
| `geoPointId` | id | Y |  |
| `fromDate` | date-time | Y |  |
| `thruDate` | date-time |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Party](Party.md) via `partyId`
- one `moqui.basic.GeoPoint` via `geoPointId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.party.PartyGeoPoint
