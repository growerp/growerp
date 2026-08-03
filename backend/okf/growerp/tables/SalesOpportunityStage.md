---
type: Moqui Entity
title: SalesOpportunityStage
description: "Sales Opportunity Stage"
resource: http://127.0.0.1:8080/rest/e1/mantle.sales.opportunity.SalesOpportunityStage
tags: [mantle, sales, opportunity]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# SalesOpportunityStage

Sales Opportunity Stage

Full entity name: `mantle.sales.opportunity.SalesOpportunityStage`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `opportunityStageId` | id | Y |  |
| `description` | text-medium |  |  |
| `defaultProbability` | number-decimal |  |  |
| `sequenceNum` | number-integer |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- many [SalesOpportunity](SalesOpportunity.md) via `opportunityStageId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.sales.opportunity.SalesOpportunityStage
