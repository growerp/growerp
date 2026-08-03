---
type: Moqui Entity
title: Measurement
description: "Measurement"
resource: http://127.0.0.1:8080/rest/e1/mantle.work.measurement.Measurement
tags: [mantle, work, measurement]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# Measurement

Measurement

Full entity name: `mantle.work.measurement.Measurement`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `measurementId` | id | Y |  |
| `measurementTypeId` | id |  |  |
| `measurementDate` | date-time |  |  |
| `measurementValue` | number-decimal |  |  |
| `measurementUomId` | id |  |  |
| `measurementEnumId` | id |  |  |
| `workEffortId` | id |  |  |
| `assetId` | id |  |  |
| `facilityId` | id |  |  |
| `productId` | id |  |  |
| `reasonEnumId` | id |  |  |
| `productMeterId` | id |  |  |
| `assetMaintenanceId` | id |  |  |
| `userId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [MeasurementType](MeasurementType.md) via `measurementTypeId`
- one `moqui.basic.Uom` via `measurementUomId`
- one `moqui.basic.Enumeration` via `measurementEnumId`
- one [WorkEffort](WorkEffort.md) via `workEffortId`
- one [Asset](Asset.md) via `assetId`
- one [Facility](Facility.md) via `facilityId`
- one [Product](Product.md) via `productId`
- one `moqui.basic.Enumeration` via `reasonEnumId`
- one [AssetMaintenance](AssetMaintenance.md) via `assetMaintenanceId`
- one [ProductMeter](ProductMeter.md) via `productMeterId`
- one `moqui.security.UserAccount` via `userId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.work.measurement.Measurement
