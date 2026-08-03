---
type: Moqui Entity
title: ProductionEstimate
description: "Production Estimate"
resource: http://127.0.0.1:8080/rest/e1/mantle.work.estimate.ProductionEstimate
tags: [mantle, work, estimate]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ProductionEstimate

Production Estimate

Full entity name: `mantle.work.estimate.ProductionEstimate`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `productionEstimateId` | id | Y |  |
| `estimateName` | text-medium |  |  |
| `productId` | id |  |  |
| `facilityId` | id |  |  |
| `destinationFacilityId` | id |  |  |
| `quantity` | number-decimal |  |  |
| `quantityUomId` | id |  |  |
| `readyDate` | date |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Product](Product.md) via `productId`
- one [Facility](Facility.md) via `facilityId`
- one [Destination Facility](Facility.md) via `destinationFacilityId`
- one `moqui.basic.Uom` via `quantityUomId`
- many [ProductionEstimateAsset](ProductionEstimateAsset.md) via `productionEstimateId`
- many [ProductionEstimateWorkEff](ProductionEstimateWorkEff.md) via `productionEstimateId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.work.estimate.ProductionEstimate
