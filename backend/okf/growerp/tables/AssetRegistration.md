---
type: Moqui Entity
title: AssetRegistration
description: "Asset Registration"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.maintenance.AssetRegistration
tags: [mantle, product, maintenance]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# AssetRegistration

Asset Registration

Full entity name: `mantle.product.maintenance.AssetRegistration`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `assetId` | id | Y |  |
| `assetRegSeqId` | id | Y |  |
| `fromDate` | date-time |  |  |
| `thruDate` | date-time |  |  |
| `registrationDate` | date-time |  |  |
| `govAgencyPartyId` | id |  |  |
| `registrationNumber` | text-medium |  |  |
| `licenseNumber` | text-medium |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Asset](Asset.md) via `assetId`
- one [GovAgency Party](Party.md) via `govAgencyPartyId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.maintenance.AssetRegistration
