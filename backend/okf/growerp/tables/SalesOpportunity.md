---
type: Moqui Entity
title: SalesOpportunity
description: "Sales Opportunity"
resource: http://127.0.0.1:8080/rest/e1/mantle.sales.opportunity.SalesOpportunity
tags: [mantle, sales, opportunity]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# SalesOpportunity

Sales Opportunity

Full entity name: `mantle.sales.opportunity.SalesOpportunity`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `salesOpportunityId` | id | Y |  |
| `typeEnumId` | id |  |  |
| `accountPartyId` | id |  |  |
| `opportunityName` | text-medium |  |  |
| `description` | text-very-long |  |  |
| `nextStep` | text-long |  |  |
| `estimatedAmount` | currency-amount |  |  |
| `estimatedProbability` | number-decimal |  |  |
| `estimatedCloseDate` | date-time |  |  |
| `currencyUomId` | id |  |  |
| `marketingCampaignId` | id |  |  |
| `dataSourceId` | id |  |  |
| `opportunityStageId` | id |  |  |
| `pseudoId` | id |  |  |
| `ownerPartyId` | id |  | The company owner, to separate companies. |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.basic.Enumeration` via `typeEnumId`
- one [Account Party](Party.md) via `accountPartyId`
- one `moqui.basic.Uom` via `currencyUomId`
- one [SalesOpportunityStage](SalesOpportunityStage.md) via `opportunityStageId`
- one [MarketingCampaign](MarketingCampaign.md) via `marketingCampaignId`
- one [Owner Party](Party.md) via `ownerPartyId`
- many [InvoiceItem](InvoiceItem.md) via `salesOpportunityId`
- many [OrderItem](OrderItem.md) via `salesOpportunityId`
- many [SalesOpportunityCompetitor](SalesOpportunityCompetitor.md) via `salesOpportunityId`
- many [SalesOpportunityOrder](SalesOpportunityOrder.md) via `salesOpportunityId`
- many [SalesOpportunityParty](SalesOpportunityParty.md) via `salesOpportunityId`
- many [SalesOpportunityTracking](SalesOpportunityTracking.md) via `salesOpportunityId`
- many [SalesOpportunityWorkEffort](SalesOpportunityWorkEffort.md) via `salesOpportunityId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.sales.opportunity.SalesOpportunity
