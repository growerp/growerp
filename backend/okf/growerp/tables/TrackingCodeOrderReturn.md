---
type: Moqui Entity
title: TrackingCodeOrderReturn
description: "Tracking Code Order Return"
resource: http://127.0.0.1:8080/rest/e1/mantle.marketing.tracking.TrackingCodeOrderReturn
tags: [mantle, marketing, tracking]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# TrackingCodeOrderReturn

Tracking Code Order Return

Full entity name: `mantle.marketing.tracking.TrackingCodeOrderReturn`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `trackingCodeTypeEnumId` | id | Y |  |
| `returnId` | id | Y |  |
| `orderId` | id | Y |  |
| `orderItemSeqId` | id |  |  |
| `trackingCodeId` | id |  |  |
| `isBillable` | text-indicator |  |  |
| `siteId` | text-medium |  |  |
| `hasExported` | text-indicator |  |  |
| `affiliateReferredTimeStamp` | date-time |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.basic.Enumeration` via `trackingCodeTypeEnumId`
- one [ReturnHeader](ReturnHeader.md) via `returnId`
- one [OrderHeader](OrderHeader.md) via `orderId`
- one [TrackingCode](TrackingCode.md) via `trackingCodeId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.marketing.tracking.TrackingCodeOrderReturn
