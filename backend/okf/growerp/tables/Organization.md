---
type: Moqui Entity
title: Organization
description: "Organization"
resource: http://127.0.0.1:8080/rest/e1/mantle.party.Organization
tags: [mantle, party]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# Organization

Organization

Full entity name: `mantle.party.Organization`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `partyId` | id | Y |  |
| `organizationName` | text-medium |  |  |
| `officeSiteName` | text-medium |  |  |
| `annualRevenue` | currency-amount |  |  |
| `numEmployees` | number-integer |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Party](Party.md) via `partyId`
- many [Owner Facility](Facility.md) via `partyId`
- many [From Invoice](Invoice.md) via `partyId`
- many [To Invoice](Invoice.md) via `partyId`
- many [OrderItemParty](OrderItemParty.md) via `partyId`
- many [OrderPartParty](OrderPartParty.md) via `partyId`
- many [RequestParty](RequestParty.md) via `partyId`
- many [From Shipment](Shipment.md) via `partyId`
- many [To Shipment](Shipment.md) via `partyId`
- many [WorkEffortParty](WorkEffortParty.md) via `partyId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.party.Organization
