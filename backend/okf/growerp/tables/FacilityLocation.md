---
type: Moqui Entity
title: FacilityLocation
description: "Facility Location"
resource: http://127.0.0.1:8080/rest/e1/mantle.facility.FacilityLocation
tags: [mantle, facility]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# FacilityLocation

Facility Location

Full entity name: `mantle.facility.FacilityLocation`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `facilityId` | id | Y |  |
| `locationSeqId` | id | Y |  |
| `locationTypeEnumId` | id |  |  |
| `description` | text-medium |  |  |
| `areaId` | id |  |  |
| `aisleId` | id |  |  |
| `sectionId` | id |  |  |
| `levelId` | id |  |  |
| `positionId` | id |  |  |
| `geoPointId` | id |  |  |
| `capacity` | number-decimal |  |  |
| `capacityUomId` | id |  |  |
| `sequenceNum` | number-integer |  | For pick, etc sort by this then by area, aisle, section, level, position |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Facility](Facility.md) via `facilityId`
- one `moqui.basic.Enumeration` via `locationTypeEnumId`
- one `moqui.basic.GeoPoint` via `geoPointId`
- one `moqui.basic.Uom` via `capacityUomId`
- many [ProductFacilityLocation](ProductFacilityLocation.md) via `facilityId`, `locationSeqId`
- many [Asset](Asset.md) via `facilityId`, `locationSeqId`
- many [Container](Container.md) via `facilityId`, `locationSeqId`
- many [PhysicalInventoryCount](PhysicalInventoryCount.md) via `facilityId`, `locationSeqId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.facility.FacilityLocation
