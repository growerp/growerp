---
type: Moqui Entity
title: SalesOpportunityWorkEffort
description: "Sales Opportunity Work Effort"
resource: http://127.0.0.1:8080/rest/e1/mantle.sales.opportunity.SalesOpportunityWorkEffort
tags: [mantle, sales, opportunity]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# SalesOpportunityWorkEffort

Sales Opportunity Work Effort

Full entity name: `mantle.sales.opportunity.SalesOpportunityWorkEffort`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `salesOpportunityId` | id | Y |  |
| `workEffortId` | id | Y |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [SalesOpportunity](SalesOpportunity.md) via `salesOpportunityId`
- one [WorkEffort](WorkEffort.md) via `workEffortId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.sales.opportunity.SalesOpportunityWorkEffort
