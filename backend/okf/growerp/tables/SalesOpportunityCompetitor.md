---
type: Moqui Entity
title: SalesOpportunityCompetitor
description: "Sales Opportunity Competitor"
resource: http://127.0.0.1:8080/rest/e1/mantle.sales.opportunity.SalesOpportunityCompetitor
tags: [mantle, sales, opportunity]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# SalesOpportunityCompetitor

Sales Opportunity Competitor

Full entity name: `mantle.sales.opportunity.SalesOpportunityCompetitor`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `salesOpportunityId` | id | Y |  |
| `competitorPartyId` | id | Y |  |
| `positionEnumId` | id |  |  |
| `strengths` | text-long |  |  |
| `weaknesses` | text-long |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [SalesOpportunity](SalesOpportunity.md) via `salesOpportunityId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.sales.opportunity.SalesOpportunityCompetitor
