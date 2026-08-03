---
type: Moqui Entity
title: TelecomNumber
description: "Telecom Number"
resource: http://127.0.0.1:8080/rest/e1/mantle.party.contact.TelecomNumber
tags: [mantle, party, contact]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# TelecomNumber

Telecom Number

Full entity name: `mantle.party.contact.TelecomNumber`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `contactMechId` | id | Y |  |
| `countryCode` | text-short |  |  |
| `areaCode` | text-short |  |  |
| `contactNumber` | text-short |  |  |
| `askForName` | text-medium |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [ContactMech](ContactMech.md) via `contactMechId`
- many [InvoiceContactMech](InvoiceContactMech.md) via `contactMechId`
- many [PaymentMethod](PaymentMethod.md) via `contactMechId`
- many [FacilityContactMech](FacilityContactMech.md) via `contactMechId`
- many [OrderPart](OrderPart.md) via `contactMechId`
- many [OrderPartContactMech](OrderPartContactMech.md) via `contactMechId`
- many [PartyContactMech](PartyContactMech.md) via `contactMechId`
- one-nofk [Telecom PostalAddress](PostalAddress.md) via `contactMechId`
- many [Origin ShipmentRouteSegment](ShipmentRouteSegment.md) via `contactMechId`
- many [Destination ShipmentRouteSegment](ShipmentRouteSegment.md) via `contactMechId`
- many [WorkEffortContactMech](WorkEffortContactMech.md) via `contactMechId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.party.contact.TelecomNumber
