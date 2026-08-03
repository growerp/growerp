---
type: Moqui Entity
title: TrackingCode
description: "Tracking Code"
resource: http://127.0.0.1:8080/rest/e1/mantle.marketing.tracking.TrackingCode
tags: [mantle, marketing, tracking]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# TrackingCode

Tracking Code

Full entity name: `mantle.marketing.tracking.TrackingCode`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `trackingCodeId` | id | Y |  |
| `trackingCodeTypeEnumId` | id |  |  |
| `marketingCampaignId` | id |  |  |
| `redirectUrl` | text-long |  |  |
| `comments` | text-medium |  |  |
| `description` | text-medium |  |  |
| `trackableLifetime` | number-integer |  |  |
| `billableLifetime` | number-integer |  |  |
| `fromDate` | date-time |  |  |
| `thruDate` | date-time |  |  |
| `groupId` | id |  |  |
| `subgroupId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [MarketingCampaign](MarketingCampaign.md) via `marketingCampaignId`
- one `moqui.basic.Enumeration` via `trackingCodeTypeEnumId`
- many [TrackingCodeOrder](TrackingCodeOrder.md) via `trackingCodeId`
- many [TrackingCodeOrderReturn](TrackingCodeOrderReturn.md) via `trackingCodeId`
- many [TrackingCodeVisit](TrackingCodeVisit.md) via `trackingCodeId`
- many [SalesOpportunityTracking](SalesOpportunityTracking.md) via `trackingCodeId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.marketing.tracking.TrackingCode
