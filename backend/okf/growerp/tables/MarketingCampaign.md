---
type: Moqui Entity
title: MarketingCampaign
description: "Marketing Campaign"
resource: http://127.0.0.1:8080/rest/e1/mantle.marketing.campaign.MarketingCampaign
tags: [mantle, marketing, campaign]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# MarketingCampaign

Marketing Campaign

Full entity name: `mantle.marketing.campaign.MarketingCampaign`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `marketingCampaignId` | id | Y |  |
| `parentCampaignId` | id |  |  |
| `statusId` | id |  |  |
| `campaignName` | text-medium |  |  |
| `campaignSummary` | text-long |  |  |
| `budgetedCost` | currency-amount |  |  |
| `actualCost` | currency-amount |  |  |
| `estimatedCost` | currency-amount |  |  |
| `costUomId` | id |  |  |
| `fromDate` | date-time |  |  |
| `thruDate` | date-time |  |  |
| `isActive` | text-indicator |  |  |
| `convertedLeads` | id |  |  |
| `expectedResponsePercent` | number-float |  |  |
| `expectedRevenue` | currency-amount |  |  |
| `numSent` | number-integer |  |  |
| `startDate` | date-time |  |  |
| `pseudoId` | id |  |  |
| `ownerPartyId` | id |  | The company owner, to separate companies. |
| `platforms` | text-medium |  | JSON array of platforms: ["EMAIL", "LINKEDIN", "TWITTER", "MEDIUM", "SUBSTACK", "FACEBOOK"] |
| `targetAudience` | text-long |  |  |
| `landingPageId` | id |  |  |
| `messageTemplate` | text-very-long |  |  |
| `emailSubject` | text-medium |  | Email subject line (for EMAIL platform) |
| `dailyLimitPerPlatform` | number-integer |  |  |
| `platformSettings` | text-very-long |  | JSON object storing per-platform settings: actionType, searchKeywords, messageTemplate |
| `createdByUserLogin` | id |  |  |
| `lastModifiedByUserLogin` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Parent MarketingCampaign](MarketingCampaign.md) via `parentCampaignId`
- one `moqui.basic.StatusItem` via `statusId`
- one `moqui.basic.Uom` via `costUomId`
- one [Owner Party](Party.md) via `ownerPartyId`
- one [LandingPage](LandingPage.md) via `landingPageId`
- many [CampaignMetrics](CampaignMetrics.md) via `marketingCampaignId`
- many [EmailSequence](EmailSequence.md) via `marketingCampaignId`
- many [OutreachMessage](OutreachMessage.md) via `marketingCampaignId`
- many [MarketingCampaignNote](MarketingCampaignNote.md) via `marketingCampaignId`
- many [MarketingCampaignParty](MarketingCampaignParty.md) via `marketingCampaignId`
- many [ContactList](ContactList.md) via `marketingCampaignId`
- many [TrackingCode](TrackingCode.md) via `marketingCampaignId`
- many [SalesOpportunity](SalesOpportunity.md) via `marketingCampaignId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.marketing.campaign.MarketingCampaign
