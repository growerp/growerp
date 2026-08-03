---
type: Moqui Entity
title: AssetMaintenanceContent
description: "Asset Maintenance Content"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.maintenance.AssetMaintenanceContent
tags: [mantle, product, maintenance]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# AssetMaintenanceContent

Asset Maintenance Content

Full entity name: `mantle.product.maintenance.AssetMaintenanceContent`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `assetMaintenanceId` | id | Y |  |
| `contentDate` | date-time | Y |  |
| `contentTypeEnumId` | id |  |  |
| `contentLocation` | text-medium |  |  |
| `description` | text-long |  |  |
| `userId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [AssetMaintenance](AssetMaintenance.md) via `assetMaintenanceId`
- one `moqui.basic.Enumeration` via `contentTypeEnumId`
- one `moqui.security.UserAccount` via `userId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.maintenance.AssetMaintenanceContent
