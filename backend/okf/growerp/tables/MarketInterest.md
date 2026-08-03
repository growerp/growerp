---
type: Moqui Entity
title: MarketInterest
description: "Market Interest"
resource: http://127.0.0.1:8080/rest/e1/mantle.marketing.segment.MarketInterest
tags: [mantle, marketing, segment]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# MarketInterest

Market Interest

Full entity name: `mantle.marketing.segment.MarketInterest`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `productCategoryId` | id | Y |  |
| `marketSegmentId` | id | Y |  |
| `fromDate` | date-time | Y |  |
| `thruDate` | date-time |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [ProductCategory](ProductCategory.md) via `productCategoryId`
- one [MarketSegment](MarketSegment.md) via `marketSegmentId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.marketing.segment.MarketInterest
