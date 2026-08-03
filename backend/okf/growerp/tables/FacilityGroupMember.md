---
type: Moqui Entity
title: FacilityGroupMember
description: "Facility Group Member"
resource: http://127.0.0.1:8080/rest/e1/mantle.facility.FacilityGroupMember
tags: [mantle, facility]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# FacilityGroupMember

Facility Group Member

Full entity name: `mantle.facility.FacilityGroupMember`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `facilityId` | id | Y |  |
| `facilityGroupId` | id | Y |  |
| `fromDate` | date-time | Y |  |
| `thruDate` | date-time |  |  |
| `sequenceNum` | number-integer |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Facility](Facility.md) via `facilityId`
- one [FacilityGroup](FacilityGroup.md) via `facilityGroupId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.facility.FacilityGroupMember
