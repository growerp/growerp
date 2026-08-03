---
type: Moqui Entity
title: SalesOpportunityTracking
description: "Sales Opportunity Tracking"
resource: http://127.0.0.1:8080/rest/e1/mantle.sales.opportunity.SalesOpportunityTracking
tags: [mantle, sales, opportunity]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# SalesOpportunityTracking

Sales Opportunity Tracking

Full entity name: `mantle.sales.opportunity.SalesOpportunityTracking`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `salesOpportunityId` | id | Y |  |
| `trackingCodeId` | id | Y |  |
| `receivedDate` | date-time |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [SalesOpportunity](SalesOpportunity.md) via `salesOpportunityId`
- one [TrackingCode](TrackingCode.md) via `trackingCodeId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.sales.opportunity.SalesOpportunityTracking
