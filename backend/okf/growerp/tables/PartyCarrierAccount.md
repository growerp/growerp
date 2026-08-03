---
type: Moqui Entity
title: PartyCarrierAccount
description: "Party Carrier Account"
resource: http://127.0.0.1:8080/rest/e1/mantle.shipment.carrier.PartyCarrierAccount
tags: [mantle, shipment, carrier]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# PartyCarrierAccount

Party Carrier Account

Full entity name: `mantle.shipment.carrier.PartyCarrierAccount`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `partyId` | id | Y |  |
| `carrierPartyId` | id | Y |  |
| `fromDate` | date-time | Y |  |
| `thruDate` | date-time |  |  |
| `accountNumber` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Party](Party.md) via `partyId`
- one [Carrier Party](Party.md) via `carrierPartyId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.shipment.carrier.PartyCarrierAccount
