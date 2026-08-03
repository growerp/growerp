---
type: Moqui Entity
title: SalesOpportunityParty
description: "Sales Opportunity Party"
resource: http://127.0.0.1:8080/rest/e1/mantle.sales.opportunity.SalesOpportunityParty
tags: [mantle, sales, opportunity]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# SalesOpportunityParty

Sales Opportunity Party

Full entity name: `mantle.sales.opportunity.SalesOpportunityParty`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `salesOpportunityId` | id | Y |  |
| `partyId` | id | Y |  |
| `roleTypeId` | id | Y |  |
| `fromDate` | date-time | Y |  |
| `thruDate` | date-time |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [SalesOpportunity](SalesOpportunity.md) via `salesOpportunityId`
- one [Party](Party.md) via `partyId`
- one [RoleType](RoleType.md) via `roleTypeId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.sales.opportunity.SalesOpportunityParty
