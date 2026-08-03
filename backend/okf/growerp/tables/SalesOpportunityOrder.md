---
type: Moqui Entity
title: SalesOpportunityOrder
description: "Associate orders (including proposed/quote orders) with an opportunity"
resource: http://127.0.0.1:8080/rest/e1/mantle.sales.opportunity.SalesOpportunityOrder
tags: [mantle, sales, opportunity]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# SalesOpportunityOrder

Associate orders (including proposed/quote orders) with an opportunity

Full entity name: `mantle.sales.opportunity.SalesOpportunityOrder`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `salesOpportunityId` | id | Y |  |
| `orderId` | id | Y |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [SalesOpportunity](SalesOpportunity.md) via `salesOpportunityId`
- one [OrderHeader](OrderHeader.md) via `orderId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.sales.opportunity.SalesOpportunityOrder
