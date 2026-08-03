---
type: Moqui Entity
title: MeasurementType
description: "Measurement Type"
resource: http://127.0.0.1:8080/rest/e1/mantle.work.measurement.MeasurementType
tags: [mantle, work, measurement]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# MeasurementType

Measurement Type

Full entity name: `mantle.work.measurement.MeasurementType`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `measurementTypeId` | id | Y |  |
| `description` | text-medium |  |  |
| `hasValue` | text-indicator |  |  |
| `uomTypeEnumId` | id |  |  |
| `enumTypeId` | id |  |  |
| `productMeterTypeId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.basic.Enumeration` via `uomTypeEnumId`
- one `moqui.basic.EnumerationType` via `enumTypeId`
- one [ProductMeterType](ProductMeterType.md) via `productMeterTypeId`
- many [Measurement](Measurement.md) via `measurementTypeId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.work.measurement.MeasurementType
