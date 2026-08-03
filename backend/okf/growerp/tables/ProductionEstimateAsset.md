---
type: Moqui Entity
title: ProductionEstimateAsset
description: "Production Estimate Asset"
resource: http://127.0.0.1:8080/rest/e1/mantle.work.estimate.ProductionEstimateAsset
tags: [mantle, work, estimate]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ProductionEstimateAsset

Production Estimate Asset

Full entity name: `mantle.work.estimate.ProductionEstimateAsset`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `productionEstimateId` | id | Y |  |
| `assetId` | id | Y |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [ProductionEstimate](ProductionEstimate.md) via `productionEstimateId`
- one [Asset](Asset.md) via `assetId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.work.estimate.ProductionEstimateAsset
