---
type: Moqui Entity
title: CampaignMetrics
description: "Campaign performance tracking and analytics"
resource: http://127.0.0.1:8080/rest/e1/growerp.marketing.CampaignMetrics
tags: [growerp, marketing]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# CampaignMetrics

Campaign performance tracking and analytics

Full entity name: `growerp.marketing.CampaignMetrics`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `metricId` | id | Y |  |
| `marketingCampaignId` | id |  |  |
| `messagesSent` | number-integer |  |  |
| `responsesReceived` | number-integer |  |  |
| `leadsGenerated` | number-integer |  |  |
| `lastUpdated` | date-time |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [MarketingCampaign](MarketingCampaign.md) via `marketingCampaignId`

# Citations

- http://127.0.0.1:8080/rest/e1/growerp.marketing.CampaignMetrics
