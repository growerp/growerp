---
type: Moqui Entity
title: MarketSegmentDimension
description: "Define the segment in terms of PartyDimension values"
resource: http://127.0.0.1:8080/rest/e1/mantle.marketing.segment.MarketSegmentDimension
tags: [mantle, marketing, segment]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# MarketSegmentDimension

Define the segment in terms of PartyDimension values

Full entity name: `mantle.marketing.segment.MarketSegmentDimension`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `marketSegmentId` | id | Y |  |
| `uomDimensionTypeId` | id | Y |  |
| `uomId` | id |  |  |
| `minValue` | number-decimal |  |  |
| `maxValue` | number-decimal |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [MarketSegment](MarketSegment.md) via `marketSegmentId`
- one `moqui.basic.UomDimensionType` via `uomDimensionTypeId`
- one `moqui.basic.Uom` via `uomId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.marketing.segment.MarketSegmentDimension
