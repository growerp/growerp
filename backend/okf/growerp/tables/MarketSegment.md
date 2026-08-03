---
type: Moqui Entity
title: MarketSegment
description: "Market Segment"
resource: http://127.0.0.1:8080/rest/e1/mantle.marketing.segment.MarketSegment
tags: [mantle, marketing, segment]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# MarketSegment

Market Segment

Full entity name: `mantle.marketing.segment.MarketSegment`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `marketSegmentId` | id | Y |  |
| `marketSegmentTypeEnumId` | id |  |  |
| `typeSequenceNum` | number-integer |  | Intra-type Sequence Number for sets of segments that are not fully mutually exclusive. When determining a MarketSegment by type, evaluate in order of this number to determine the first match. |
| `parentMarketSegmentId` | id |  | NOTE: this description is for the intended application of parentMarketSegmentId, actual behavior depends on code and could vary A MarketSegment tree is a dependency tree with bi-directional dependencies so that any node in the tree can be evaluated for membership by a Party while being able to configure segment factors at any level of the tree and have them apply to all levels of a branch of the tree. To implement this the general rule is that a Party is a member of a MarketSegment if all factors of that MarketSegment match, and the factors of the parent MarketSegment match (if there is one), and the factors of at least one child segment all match (if there is at least one child segment). For example if segment A has two child segments A-1 and A-2, then a Party is in A if all factors of A match AND they are a member of either sub-segment A-1 or sub-segment A-2. A Party is in A-2 if all factors of A-2 match, and all factors of A match. |
| `description` | text-medium |  |  |
| `productStoreId` | id |  |  |
| `ownerPartyId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.basic.Enumeration` via `marketSegmentTypeEnumId`
- one [ProductStore](ProductStore.md) via `productStoreId`
- one [Parent MarketSegment](MarketSegment.md) via `parentMarketSegmentId`
- one [Owner Party](Party.md) via `ownerPartyId`
- many [MarketInterest](MarketInterest.md) via `marketSegmentId`
- many [MarketSegmentClassification](MarketSegmentClassification.md) via `marketSegmentId`
- many [MarketSegmentDimension](MarketSegmentDimension.md) via `marketSegmentId`
- many [MarketSegmentGeo](MarketSegmentGeo.md) via `marketSegmentId`
- many [MarketSegmentParty](MarketSegmentParty.md) via `marketSegmentId`
- many [ProductDbForm](ProductDbForm.md) via `marketSegmentId`
- many [ProductOtherIdentification](ProductOtherIdentification.md) via `marketSegmentId`
- many [ProductParameterOption](ProductParameterOption.md) via `marketSegmentId`
- many [ProductParameterValue](ProductParameterValue.md) via `marketSegmentId`
- many [ProductUomDimension](ProductUomDimension.md) via `marketSegmentId`
- many [ProductCategoryIdent](ProductCategoryIdent.md) via `marketSegmentId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.marketing.segment.MarketSegment
