---
type: Moqui Entity
title: ReturnHeader
description: "Return Header"
resource: http://127.0.0.1:8080/rest/e1/mantle.order.return.ReturnHeader
tags: [mantle, order, return]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ReturnHeader

Return Header

Full entity name: `mantle.order.return.ReturnHeader`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `returnId` | id | Y |  |
| `statusId` | id |  |  |
| `customerPartyId` | id |  |  |
| `vendorPartyId` | id |  |  |
| `paymentMethodId` | id |  | Customer PaymentMethod to refund to, override original |
| `useSingleRefundPayment` | text-indicator |  | If Y create a single refund Payment, otherwise look for Credit Card order payments and refund first against those |
| `finAccountId` | id |  |  |
| `entryDate` | date-time |  |  |
| `postalContactMechId` | id |  | If customer is internal org is shipment destination, otherwise is origin |
| `telecomContactMechId` | id |  | If customer is internal org is shipment destination, otherwise is origin |
| `facilityId` | id |  | If customer is internal org is shipment origin, otherwise is destination |
| `shipmentMethodEnumId` | id |  | Only needed for generating a return label, can also be specified on return shipment |
| `carrierPartyId` | id |  | Only needed for generating a return label, can also be specified on return shipment |
| `currencyUomId` | id |  |  |
| `supplierRmaId` | text-short |  |  |
| `visitId` | id |  |  |
| `systemMessageRemoteId` | id |  |  |
| `displayId` | text-short |  | ID to display to customers, can be different from returnId and/or externalId |
| `externalId` | text-short |  | ID for the return in the direct upstream system it came from if it came from an external system |
| `originId` | text-short |  | ID for the return in the original system it came from if not the direct upstream system |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.basic.StatusItem` via `statusId`
- one [Customer Party](Party.md) via `customerPartyId`
- one [Vendor Party](Party.md) via `vendorPartyId`
- one [FinancialAccount](FinancialAccount.md) via `finAccountId`
- one [PaymentMethod](PaymentMethod.md) via `paymentMethodId`
- one [Postal ContactMech](ContactMech.md) via `postalContactMechId`
- one [PostalAddress](PostalAddress.md) via `postalContactMechId`
- one [Telecom ContactMech](ContactMech.md) via `telecomContactMechId`
- one [Facility](Facility.md) via `facilityId`
- one `moqui.basic.Enumeration` via `shipmentMethodEnumId`
- one [Carrier Party](Party.md) via `carrierPartyId`
- one `moqui.basic.Uom` via `currencyUomId`
- one `moqui.server.Visit` via `visitId`
- one `moqui.service.message.SystemMessageRemote` via `systemMessageRemoteId`
- many [ReturnItem](ReturnItem.md) via `returnId`
- many [TrackingCodeOrderReturn](TrackingCodeOrderReturn.md) via `returnId`
- many [ReturnContactMech](ReturnContactMech.md) via `returnId`
- many [ReturnSystemMessage](ReturnSystemMessage.md) via `returnId`
- many [ShipmentItemSource](ShipmentItemSource.md) via `returnId`
- many `moqui.service.message.SystemMessage` via `returnId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.order.return.ReturnHeader
