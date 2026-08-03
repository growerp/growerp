---
type: Moqui Entity
title: FacilityParty
description: "Facility Party"
resource: http://127.0.0.1:8080/rest/e1/mantle.facility.FacilityParty
tags: [mantle, facility]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# FacilityParty

Facility Party

Full entity name: `mantle.facility.FacilityParty`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `facilityId` | id | Y |  |
| `partyId` | id | Y |  |
| `roleTypeId` | id | Y |  |
| `fromDate` | date-time | Y |  |
| `thruDate` | date-time |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Facility](Facility.md) via `facilityId`
- one [Party](Party.md) via `partyId`
- one [RoleType](RoleType.md) via `roleTypeId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.facility.FacilityParty
