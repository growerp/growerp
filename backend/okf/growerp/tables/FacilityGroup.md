---
type: Moqui Entity
title: FacilityGroup
description: "Facility Group"
resource: http://127.0.0.1:8080/rest/e1/mantle.facility.FacilityGroup
tags: [mantle, facility]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# FacilityGroup

Facility Group

Full entity name: `mantle.facility.FacilityGroup`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `facilityGroupId` | id | Y |  |
| `parentGroupId` | id |  |  |
| `facilityGroupTypeEnumId` | id |  |  |
| `description` | text-medium |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Parent FacilityGroup](FacilityGroup.md) via `parentGroupId`
- one `moqui.basic.Enumeration` via `facilityGroupTypeEnumId`
- many [FacilityGroupMember](FacilityGroupMember.md) via `facilityGroupId`
- many [FacilityGroupParty](FacilityGroupParty.md) via `facilityGroupId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.facility.FacilityGroup
