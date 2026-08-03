---
type: Moqui Entity
title: PartyBadgeScan
description: "Party Badge Scan"
resource: http://127.0.0.1:8080/rest/e1/mantle.party.PartyBadgeScan
tags: [mantle, party]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# PartyBadgeScan

Party Badge Scan

Full entity name: `mantle.party.PartyBadgeScan`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `partyBadgeId` | id | Y |  |
| `scanDate` | date-time | Y |  |
| `scanValue` | text-short |  |  |
| `scanPurposeEnumId` | id |  |  |
| `scanResultEnumId` | id |  |  |
| `facilityId` | id |  |  |
| `timeEntryId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [PartyBadge](PartyBadge.md) via `partyBadgeId`
- one `moqui.basic.Enumeration` via `scanPurposeEnumId`
- one `moqui.basic.Enumeration` via `scanResultEnumId`
- one [Facility](Facility.md) via `facilityId`
- one [TimeEntry](TimeEntry.md) via `timeEntryId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.party.PartyBadgeScan
