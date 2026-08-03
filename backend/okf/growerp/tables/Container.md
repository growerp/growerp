---
type: Moqui Entity
title: Container
description: "Container"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.asset.Container
tags: [mantle, product, asset]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# Container

Container

Full entity name: `mantle.product.asset.Container`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `containerId` | id | Y |  |
| `serialNumber` | id |  | Serial number or license plate for the container. |
| `containerTypeEnumId` | id |  |  |
| `createdDate` | date-time |  |  |
| `description` | text-medium |  |  |
| `externalId` | id |  | An identifier for the container in an external system (source, origin, etc). |
| `facilityId` | id |  |  |
| `locationSeqId` | id |  |  |
| `geoPointId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.basic.Enumeration` via `containerTypeEnumId`
- one [Facility](Facility.md) via `facilityId`
- one-nofk [FacilityLocation](FacilityLocation.md) via `facilityId`, `locationSeqId`
- many [Asset](Asset.md) via `containerId`
- many [Pick Shipment](Shipment.md) via `containerId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.asset.Container
