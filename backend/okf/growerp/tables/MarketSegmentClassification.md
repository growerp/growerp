---
type: Moqui Entity
title: MarketSegmentClassification
description: "Define the segment by PartyClassification"
resource: http://127.0.0.1:8080/rest/e1/mantle.marketing.segment.MarketSegmentClassification
tags: [mantle, marketing, segment]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# MarketSegmentClassification

Define the segment by PartyClassification

Full entity name: `mantle.marketing.segment.MarketSegmentClassification`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `marketSegmentId` | id | Y |  |
| `partyClassificationId` | id | Y |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [MarketSegment](MarketSegment.md) via `marketSegmentId`
- one [PartyClassification](PartyClassification.md) via `partyClassificationId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.marketing.segment.MarketSegmentClassification
