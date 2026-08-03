---
type: Moqui Entity
title: OrderPart
description: "Order Part"
resource: http://127.0.0.1:8080/rest/e1/mantle.order.OrderPart
tags: [mantle, order]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# OrderPart

Order Part

Full entity name: `mantle.order.OrderPart`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `orderId` | id | Y |  |
| `orderPartSeqId` | id | Y |  |
| `parentPartSeqId` | id |  |  |
| `partName` | text-medium |  |  |
| `statusId` | id |  |  |
| `vendorPartyId` | id |  | The vendor (seller) of the items in the order part. |
| `customerPartyId` | id |  | The customer (buyer) of the items in the order part. |
| `otherPartyOrderId` | text-short |  |  |
| `otherPartyOrderDate` | date-time |  |  |
| `facilityId` | id |  | The Facility to fulfill the order from (if null look up from ProductStore), or for purchase orders the Facility the order will be shipped to. |
| `carrierPartyId` | id |  |  |
| `shipmentMethodEnumId` | id |  |  |
| `tradeTermEnumId` | id |  |  |
| `settlementTermId` | id |  | Settlement (payment) term for auto order payments and set on Invoice(s) based on this OrderPart |
| `postalContactMechId` | id |  |  |
| `telecomContactMechId` | id |  |  |
| `trackingNumber` | text-short |  |  |
| `shippingInstructions` | text-long |  |  |
| `maySplit` | text-indicator |  |  |
| `signatureRequiredEnumId` | id |  |  |
| `giftMessage` | text-medium |  |  |
| `isGift` | text-indicator |  |  |
| `isNewCustomer` | text-indicator |  |  |
| `partTotal` | currency-amount |  |  |
| `priority` | number-integer |  | Numeric priority, 1 to 9 where 1 is highest priority and 9 is lowest priority (like a to do list), defaults to 5 |
| `shipAfterDate` | date-time |  |  |
| `shipBeforeDate` | date-time |  |  |
| `estimatedShipDate` | date-time |  |  |
| `estimatedDeliveryDate` | date-time |  |  |
| `estimatedPickUpDate` | date-time |  |  |
| `validFromDate` | date-time |  |  |
| `validThruDate` | date-time |  |  |
| `autoCancelDate` | date-time |  |  |
| `dontCancelSetDate` | date-time |  |  |
| `dontCancelSetUserId` | id |  |  |
| `disablePromotions` | text-indicator |  |  |
| `disableShippingCalc` | text-indicator |  |  |
| `disableTaxCalc` | text-indicator |  |  |
| `reservationAutoEnumId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [OrderHeader](OrderHeader.md) via `orderId`
- one [Parent OrderPart](OrderPart.md) via `orderId`, `parentPartSeqId`
- one `moqui.basic.StatusItem` via `statusId`
- one [Vendor Party](Party.md) via `vendorPartyId`
- many [Vendor PartyRole](PartyRole.md) via `vendorPartyId`
- one [Customer Party](Party.md) via `customerPartyId`
- many [Customer PartyRole](PartyRole.md) via `customerPartyId`
- many [Customer PartyClassificationAppl](PartyClassificationAppl.md) via `customerPartyId`
- one [Facility](Facility.md) via `facilityId`
- one [Carrier Party](Party.md) via `carrierPartyId`
- one `moqui.basic.Enumeration` via `shipmentMethodEnumId`
- one `moqui.basic.Enumeration` via `tradeTermEnumId`
- one [SettlementTerm](SettlementTerm.md) via `settlementTermId`
- one [Postal ContactMech](ContactMech.md) via `postalContactMechId`
- one [PostalAddress](PostalAddress.md) via `postalContactMechId`
- one [Telecom ContactMech](ContactMech.md) via `telecomContactMechId`
- one [TelecomNumber](TelecomNumber.md) via `telecomContactMechId`
- one `moqui.basic.Enumeration` via `signatureRequiredEnumId`
- one `moqui.basic.Enumeration` via `reservationAutoEnumId`
- many [OrderItem](OrderItem.md) via `orderId`, `orderPartSeqId`
- many [OrderPartParty](OrderPartParty.md) via `orderId`, `orderPartSeqId`
- many [OrderPartContactMech](OrderPartContactMech.md) via `orderId`, `orderPartSeqId`
- many [OrderPartTerm](OrderPartTerm.md) via `orderId`, `orderPartSeqId`
- many [Payment](Payment.md) via `orderId`, `orderPartSeqId`
- many `moqui.service.message.SystemMessage` via `orderId`, `orderPartSeqId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.order.OrderPart
