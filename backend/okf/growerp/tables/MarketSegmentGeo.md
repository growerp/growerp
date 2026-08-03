---
type: Moqui Entity
title: MarketSegmentGeo
description: "Define the segment by geographic area"
resource: http://127.0.0.1:8080/rest/e1/mantle.marketing.segment.MarketSegmentGeo
tags: [mantle, marketing, segment]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# MarketSegmentGeo

Define the segment by geographic area

Full entity name: `mantle.marketing.segment.MarketSegmentGeo`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `marketSegmentId` | id | Y |  |
| `geoId` | id | Y |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [MarketSegment](MarketSegment.md) via `marketSegmentId`
- one `moqui.basic.Geo` via `geoId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.marketing.segment.MarketSegmentGeo
