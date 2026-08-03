---
type: Moqui Entity
title: ProductionEstimateWorkEff
description: "Production Estimate Work Eff"
resource: http://127.0.0.1:8080/rest/e1/mantle.work.estimate.ProductionEstimateWorkEff
tags: [mantle, work, estimate]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ProductionEstimateWorkEff

Production Estimate Work Eff

Full entity name: `mantle.work.estimate.ProductionEstimateWorkEff`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `productionEstimateId` | id | Y |  |
| `workEffortId` | id | Y |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [ProductionEstimate](ProductionEstimate.md) via `productionEstimateId`
- one [WorkEffort](WorkEffort.md) via `workEffortId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.work.estimate.ProductionEstimateWorkEff
