---
type: Moqui Entity
title: ContactMechPurpose
description: "Contact Mech Purpose"
resource: http://127.0.0.1:8080/rest/e1/mantle.party.contact.ContactMechPurpose
tags: [mantle, party, contact]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ContactMechPurpose

Contact Mech Purpose

Full entity name: `mantle.party.contact.ContactMechPurpose`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `contactMechPurposeId` | id | Y |  |
| `contactMechTypeEnumId` | id |  |  |
| `description` | text-medium |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.basic.Enumeration` via `contactMechTypeEnumId`
- many [InvoiceContactMech](InvoiceContactMech.md) via `contactMechPurposeId`
- many [FacilityContactMech](FacilityContactMech.md) via `contactMechPurposeId`
- many [OrderPartContactMech](OrderPartContactMech.md) via `contactMechPurposeId`
- many [ReturnContactMech](ReturnContactMech.md) via `contactMechPurposeId`
- many [PartyContactMech](PartyContactMech.md) via `contactMechPurposeId`
- many [ShipmentContactMech](ShipmentContactMech.md) via `contactMechPurposeId`
- many [WorkEffortContactMech](WorkEffortContactMech.md) via `contactMechPurposeId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.party.contact.ContactMechPurpose
