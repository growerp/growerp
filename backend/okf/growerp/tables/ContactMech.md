---
type: Moqui Entity
title: ContactMech
description: "Contact Mech"
resource: http://127.0.0.1:8080/rest/e1/mantle.party.contact.ContactMech
tags: [mantle, party, contact]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ContactMech

Contact Mech

Full entity name: `mantle.party.contact.ContactMech`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `contactMechId` | id | Y |  |
| `contactMechTypeEnumId` | id |  |  |
| `dataSourceId` | id |  |  |
| `infoString` | text-medium |  |  |
| `gatewayCimId` | text-short |  |  |
| `trustLevelEnumId` | id |  |  |
| `validateMessage` | text-medium |  |  |
| `paymentFraudEvidenceId` | id |  | Refer to evidence here if trustLevelEnumId is gray listed or black listed |
| `replacesContactMechId` | id |  | For update by copy-on-write this is the ID of the ContactMech it replaces |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.basic.Enumeration` via `contactMechTypeEnumId`
- one `moqui.basic.DataSource` via `dataSourceId`
- one `moqui.basic.Enumeration` via `trustLevelEnumId`
- one [PaymentFraudEvidence](PaymentFraudEvidence.md) via `paymentFraudEvidenceId`
- one-nofk [Replaces ContactMech](ContactMech.md) via `replacesContactMechId`
- one-nofk [TelecomNumber](TelecomNumber.md) via `contactMechId`
- one-nofk [PostalAddress](PostalAddress.md) via `contactMechId`
- many [PartyContactMech](PartyContactMech.md) via `contactMechId`
- many [Postal BillingAccount](BillingAccount.md) via `contactMechId`
- many [InvoiceContactMech](InvoiceContactMech.md) via `contactMechId`
- many [Postal PaymentMethod](PaymentMethod.md) via `contactMechId`
- many [Telecom PaymentMethod](PaymentMethod.md) via `contactMechId`
- many [Email PaymentMethod](PaymentMethod.md) via `contactMechId`
- many [FacilityContactMech](FacilityContactMech.md) via `contactMechId`
- many [ContactListCommStatus](ContactListCommStatus.md) via `contactMechId`
- many [Preferred ContactListParty](ContactListParty.md) via `contactMechId`
- many [Postal OrderPart](OrderPart.md) via `contactMechId`
- many [Telecom OrderPart](OrderPart.md) via `contactMechId`
- many [OrderPartContactMech](OrderPartContactMech.md) via `contactMechId`
- many [ReturnContactMech](ReturnContactMech.md) via `contactMechId`
- many [Postal ReturnHeader](ReturnHeader.md) via `contactMechId`
- many [Telecom ReturnHeader](ReturnHeader.md) via `contactMechId`
- many [From CommunicationEvent](CommunicationEvent.md) via `contactMechId`
- many [To CommunicationEvent](CommunicationEvent.md) via `contactMechId`
- many [CommunicationEventParty](CommunicationEventParty.md) via `contactMechId`
- one-nofk [Telecom PostalAddress](PostalAddress.md) via `contactMechId`
- one-nofk [Email PostalAddress](PostalAddress.md) via `contactMechId`
- many [Return ProductStore](ProductStore.md) via `contactMechId`
- many [DeliverTo Subscription](Subscription.md) via `contactMechId`
- many [Email Request](Request.md) via `contactMechId`
- many [ShipmentContactMech](ShipmentContactMech.md) via `contactMechId`
- many [Origin ShipmentRouteSegment](ShipmentRouteSegment.md) via `contactMechId`
- many [Return ShipmentRouteSegment](ShipmentRouteSegment.md) via `contactMechId`
- many [Destination ShipmentRouteSegment](ShipmentRouteSegment.md) via `contactMechId`
- many [WorkEffortContactMech](WorkEffortContactMech.md) via `contactMechId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.party.contact.ContactMech
