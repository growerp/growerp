---
type: Moqui Entity
title: MarketingCampaignNote
description: "Marketing Campaign Note"
resource: http://127.0.0.1:8080/rest/e1/mantle.marketing.campaign.MarketingCampaignNote
tags: [mantle, marketing, campaign]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# MarketingCampaignNote

Marketing Campaign Note

Full entity name: `mantle.marketing.campaign.MarketingCampaignNote`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `marketingCampaignId` | id | Y |  |
| `noteDate` | date-time | Y |  |
| `noteText` | text-very-long |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [MarketingCampaign](MarketingCampaign.md) via `marketingCampaignId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.marketing.campaign.MarketingCampaignNote
