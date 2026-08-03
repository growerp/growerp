---
type: Moqui Entity
title: PartyBadge
description: "Party Badge"
resource: http://127.0.0.1:8080/rest/e1/mantle.party.PartyBadge
tags: [mantle, party]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# PartyBadge

Party Badge

Full entity name: `mantle.party.PartyBadge`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `partyBadgeId` | id | Y |  |
| `partyId` | id |  |  |
| `organizationPartyId` | id |  |  |
| `fromDate` | date-time |  |  |
| `thruDate` | date-time |  |  |
| `serialNumber` | text-short |  |  |
| `storedValue` | text-medium |  | For RFID this is the unique tracking identifier (the TID can be tracked in the serialNumber field) |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Party](Party.md) via `partyId`
- one [Organization Party](Party.md) via `organizationPartyId`
- many [PartyBadgeScan](PartyBadgeScan.md) via `partyBadgeId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.party.PartyBadge
