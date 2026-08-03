---
type: Moqui Entity
title: Shipment
description: "Shipment"
resource: http://127.0.0.1:8080/rest/e1/mantle.shipment.Shipment
tags: [mantle, shipment]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# Shipment

Shipment

Full entity name: `mantle.shipment.Shipment`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `shipmentId` | id | Y |  |
| `shipmentTypeEnumId` | id |  |  |
| `statusId` | id |  |  |
| `fromPartyId` | id |  |  |
| `toPartyId` | id |  |  |
| `binLocationNumber` | number-integer |  | For picking multiple shipments in a single shipment load (shipWorkEffortId, with purpose Shipment Load/Ship, WepShipmentShip); this is the structure for a picklist instead of having a separate Picklist entity. This may be overridden within a Shipment with the field of the same name on ShipmentItemSource. |
| `productStoreId` | id |  |  |
| `priority` | number-integer |  | Numeric priority, 1 to 9 where 1 is highest priority and 9 is lowest priority (like a to do list), defaults to 5 |
| `entryDate` | date-time |  |  |
| `shipAfterDate` | date-time |  |  |
| `shipBeforeDate` | date-time |  |  |
| `estimatedReadyDate` | date-time |  |  |
| `estimatedShipDate` | date-time |  |  |
| `estimatedArrivalDate` | date-time |  |  |
| `latestCancelDate` | date-time |  |  |
| `packedDate` | date-time |  |  |
| `pickContainerId` | id |  | Container assigned for picking, to move Asset(s) to Container on pick and issue from Container on pack |
| `shipWorkEffortId` | id |  |  |
| `receiveWorkEffortId` | id |  |  |
| `assemblyWorkEffortId` | id |  |  |
| `estimatedShipCost` | currency-amount |  |  |
| `costUomId` | id |  |  |
| `addtlShippingCharge` | currency-amount |  |  |
| `addtlShippingChargeDesc` | text-medium |  |  |
| `signatureRequiredEnumId` | id |  |  |
| `handlingInstructions` | text-long |  |  |
| `otherPartyOrderId` | text-short |  |  |
| `systemMessageRemoteId` | id |  |  |
| `externalId` | text-short |  | ID for the shipment in the direct upstream system it came from if it came from an external system |
| `originId` | text-short |  | ID for the shipment in the original system it came from if not the direct upstream system |
| `pseudoId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.basic.Enumeration` via `shipmentTypeEnumId`
- one `moqui.basic.StatusItem` via `statusId`
- one [From Party](Party.md) via `fromPartyId`
- one-nofk [From Organization](Organization.md) via `fromPartyId`
- one-nofk [From Person](Person.md) via `fromPartyId`
- one [To Party](Party.md) via `toPartyId`
- one-nofk [To Organization](Organization.md) via `toPartyId`
- one-nofk [To Person](Person.md) via `toPartyId`
- one [ProductStore](ProductStore.md) via `productStoreId`
- one [Pick Container](Container.md) via `pickContainerId`
- one [Ship WorkEffort](WorkEffort.md) via `shipWorkEffortId`
- one [Receive WorkEffort](WorkEffort.md) via `receiveWorkEffortId`
- one [Assembly WorkEffort](WorkEffort.md) via `assemblyWorkEffortId`
- one `moqui.basic.Uom` via `costUomId`
- one `moqui.basic.Enumeration` via `signatureRequiredEnumId`
- one `moqui.service.message.SystemMessageRemote` via `systemMessageRemoteId`
- many [ShipmentContent](ShipmentContent.md) via `shipmentId`
- many [ShipmentItem](ShipmentItem.md) via `shipmentId`
- many [ShipmentItemSource](ShipmentItemSource.md) via `shipmentId`
- many [ShipmentPackage](ShipmentPackage.md) via `shipmentId`
- many [ShipmentRouteSegment](ShipmentRouteSegment.md) via `shipmentId`
- many [ShipmentPackageRouteSeg](ShipmentPackageRouteSeg.md) via `shipmentId`
- many [AcctgTrans](AcctgTrans.md) via `shipmentId`
- many [OrderItemBilling](OrderItemBilling.md) via `shipmentId`
- many [Acquire Asset](Asset.md) via `shipmentId`
- many [AssetDetail](AssetDetail.md) via `shipmentId`
- many [AssetIssuance](AssetIssuance.md) via `shipmentId`
- many [AssetReceipt](AssetReceipt.md) via `shipmentId`
- many [ShipmentContactMech](ShipmentContactMech.md) via `shipmentId`
- many [ShipmentEmailMessage](ShipmentEmailMessage.md) via `shipmentId`
- many [ShipmentPackageContent](ShipmentPackageContent.md) via `shipmentId`
- many [ShipmentParty](ShipmentParty.md) via `shipmentId`
- many [ShipmentSystemMessage](ShipmentSystemMessage.md) via `shipmentId`
- many `moqui.service.message.SystemMessage` via `shipmentId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.shipment.Shipment
