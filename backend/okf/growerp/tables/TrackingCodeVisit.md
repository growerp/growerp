---
type: Moqui Entity
title: TrackingCodeVisit
description: "Tracking Code Visit"
resource: http://127.0.0.1:8080/rest/e1/mantle.marketing.tracking.TrackingCodeVisit
tags: [mantle, marketing, tracking]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# TrackingCodeVisit

Tracking Code Visit

Full entity name: `mantle.marketing.tracking.TrackingCodeVisit`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `trackingCodeId` | id | Y |  |
| `visitId` | id | Y |  |
| `fromDate` | date-time | Y |  |
| `sourceEnumId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [TrackingCode](TrackingCode.md) via `trackingCodeId`
- one `moqui.server.Visit` via `visitId`
- one `moqui.basic.Enumeration` via `sourceEnumId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.marketing.tracking.TrackingCodeVisit
