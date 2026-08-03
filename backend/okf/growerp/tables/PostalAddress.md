---
type: Moqui Entity
title: PostalAddress
description: "Postal Address"
resource: http://127.0.0.1:8080/rest/e1/mantle.party.contact.PostalAddress
tags: [mantle, party, contact]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# PostalAddress

Postal Address

Full entity name: `mantle.party.contact.PostalAddress`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `contactMechId` | id | Y |  |
| `toName` | text-medium |  |  |
| `attnName` | text-medium |  |  |
| `address1` | text-medium |  |  |
| `address2` | text-medium |  |  |
| `unitNumber` | text-medium |  |  |
| `directions` | text-long |  |  |
| `city` | text-medium |  |  |
| `cityGeoId` | id |  |  |
| `schoolDistrictGeoId` | id |  |  |
| `countyGeoId` | id |  |  |
| `stateProvinceGeoId` | id |  |  |
| `countryGeoId` | id |  |  |
| `postalCode` | text-short |  |  |
| `postalCodeExt` | text-short |  |  |
| `postalCodeGeoId` | id |  |  |
| `geoPointId` | id |  |  |
| `commercial` | text-indicator |  |  |
| `accessCode` | text-short |  |  |
| `telecomContactMechId` | id |  |  |
| `emailContactMechId` | id |  |  |
| `shipGatewayAddressId` | text-medium |  |  |
| `stateProvince` | text-medium |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [ContactMech](ContactMech.md) via `contactMechId`
- one `moqui.basic.Geo` via `cityGeoId`
- one `moqui.basic.Geo` via `schoolDistrictGeoId`
- one `moqui.basic.Geo` via `countyGeoId`
- one `moqui.basic.Geo` via `stateProvinceGeoId`
- one `moqui.basic.Geo` via `countryGeoId`
- one `moqui.basic.Geo` via `postalCodeGeoId`
- one `moqui.basic.GeoPoint` via `geoPointId`
- one-nofk [Telecom ContactMech](ContactMech.md) via `telecomContactMechId`
- one [Telecom TelecomNumber](TelecomNumber.md) via `telecomContactMechId`
- one [Email ContactMech](ContactMech.md) via `emailContactMechId`
- many [BillingAccount](BillingAccount.md) via `contactMechId`
- many [InvoiceContactMech](InvoiceContactMech.md) via `contactMechId`
- many [PaymentMethod](PaymentMethod.md) via `contactMechId`
- many [FacilityContactMech](FacilityContactMech.md) via `contactMechId`
- many [TaxHome Employee](Employee.md) via `contactMechId`
- many [TaxWork Employment](Employment.md) via `contactMechId`
- many [OrderPart](OrderPart.md) via `contactMechId`
- many [OrderPartContactMech](OrderPartContactMech.md) via `contactMechId`
- many [ReturnHeader](ReturnHeader.md) via `contactMechId`
- many [PartyContactMech](PartyContactMech.md) via `contactMechId`
- many [Return ProductStore](ProductStore.md) via `contactMechId`
- many [Origin ShipmentRouteSegment](ShipmentRouteSegment.md) via `contactMechId`
- many [Return ShipmentRouteSegment](ShipmentRouteSegment.md) via `contactMechId`
- many [Destination ShipmentRouteSegment](ShipmentRouteSegment.md) via `contactMechId`
- many [WorkEffortContactMech](WorkEffortContactMech.md) via `contactMechId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.party.contact.PostalAddress
