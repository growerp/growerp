---
type: Moqui Entity
title: TrackingCodeOrder
description: "Tracking Code Order"
resource: http://127.0.0.1:8080/rest/e1/mantle.marketing.tracking.TrackingCodeOrder
tags: [mantle, marketing, tracking]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# TrackingCodeOrder

Tracking Code Order

Full entity name: `mantle.marketing.tracking.TrackingCodeOrder`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `orderId` | id | Y |  |
| `trackingCodeTypeEnumId` | id | Y |  |
| `trackingCodeId` | id |  |  |
| `isBillable` | text-indicator |  |  |
| `siteId` | text-medium |  |  |
| `hasExported` | text-indicator |  |  |
| `affiliateReferredTimeStamp` | date-time |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [OrderHeader](OrderHeader.md) via `orderId`
- one [TrackingCode](TrackingCode.md) via `trackingCodeId`
- one `moqui.basic.Enumeration` via `trackingCodeTypeEnumId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.marketing.tracking.TrackingCodeOrder
