---
type: Moqui Entity
title: FacilityLocationType
description: "Facility Location Type"
resource: http://127.0.0.1:8080/rest/e1/mantle.facility.FacilityLocationType
tags: [mantle, facility]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# FacilityLocationType

Facility Location Type

Full entity name: `mantle.facility.FacilityLocationType`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `facilityId` | id | Y |  |
| `locationTypeEnumId` | id | Y |  |
| `autoStatusId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Facility](Facility.md) via `facilityId`
- one `moqui.basic.Enumeration` via `locationTypeEnumId`
- one `moqui.basic.StatusItem` via `autoStatusId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.facility.FacilityLocationType
