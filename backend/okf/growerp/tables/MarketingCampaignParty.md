---
type: Moqui Entity
title: MarketingCampaignParty
description: "Marketing Campaign Party"
resource: http://127.0.0.1:8080/rest/e1/mantle.marketing.campaign.MarketingCampaignParty
tags: [mantle, marketing, campaign]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# MarketingCampaignParty

Marketing Campaign Party

Full entity name: `mantle.marketing.campaign.MarketingCampaignParty`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `marketingCampaignId` | id | Y |  |
| `partyId` | id | Y |  |
| `roleTypeId` | id | Y |  |
| `fromDate` | date-time | Y |  |
| `thruDate` | date-time |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [MarketingCampaign](MarketingCampaign.md) via `marketingCampaignId`
- one [Party](Party.md) via `partyId`
- one [RoleType](RoleType.md) via `roleTypeId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.marketing.campaign.MarketingCampaignParty
