---
type: Moqui Entity
title: FacilityBoxType
description: "Facility Box Type"
resource: http://127.0.0.1:8080/rest/e1/mantle.facility.FacilityBoxType
tags: [mantle, facility]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# FacilityBoxType

Facility Box Type

Full entity name: `mantle.facility.FacilityBoxType`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `facilityId` | id | Y |  |
| `shipmentBoxTypeId` | id | Y |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Facility](Facility.md) via `facilityId`
- one [ShipmentBoxType](ShipmentBoxType.md) via `shipmentBoxTypeId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.facility.FacilityBoxType
