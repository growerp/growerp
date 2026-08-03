---
type: Moqui Entity
title: MarketSegmentParty
description: "Market Segment Party"
resource: http://127.0.0.1:8080/rest/e1/mantle.marketing.segment.MarketSegmentParty
tags: [mantle, marketing, segment]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# MarketSegmentParty

Market Segment Party

Full entity name: `mantle.marketing.segment.MarketSegmentParty`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `marketSegmentId` | id | Y |  |
| `partyId` | id | Y |  |
| `roleTypeId` | id | Y |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [MarketSegment](MarketSegment.md) via `marketSegmentId`
- one [Party](Party.md) via `partyId`
- one [RoleType](RoleType.md) via `roleTypeId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.marketing.segment.MarketSegmentParty
