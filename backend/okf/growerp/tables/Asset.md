---
type: Moqui Entity
title: Asset
description: "Asset"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.asset.Asset
tags: [mantle, product, asset]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# Asset

Asset

Full entity name: `mantle.product.asset.Asset`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `assetId` | id | Y |  |
| `parentAssetId` | id |  |  |
| `assetTypeEnumId` | id |  |  |
| `classEnumId` | id |  |  |
| `statusId` | id |  |  |
| `ownerPartyId` | id |  |  |
| `assetPoolId` | id |  |  |
| `productId` | id |  | The Asset is an Instance of this Product (for inventory, maintenance schedules/etc, content about what sort of thing the Asset is, etc) |
| `hasQuantity` | text-indicator |  | If Y asset has a quantity and QOH/ATP may be greater than one. If N (default) asset is a single item and may have a serial number, etc. |
| `quantityOnHandTotal` | number-decimal |  |  |
| `availableToPromiseTotal` | number-decimal |  |  |
| `originalQuantity` | number-decimal |  |  |
| `originalQuantityUomId` | id |  | QOHT and ATPT are in units of the Product (amountUomId). This field specifies the original UOM (along with originalQuantity) when it differs from Product.amountUomId. |
| `assetName` | text-medium |  |  |
| `comments` | text-long |  |  |
| `serialNumber` | text-medium |  |  |
| `softIdentifier` | text-medium |  |  |
| `activationNumber` | text-medium |  |  |
| `activationValidThru` | date-time |  |  |
| `receivedDate` | date-time |  |  |
| `acquiredDate` | date-time |  |  |
| `manufacturedDate` | date-time |  |  |
| `expectedEndOfLife` | date |  |  |
| `actualEndOfLife` | date |  |  |
| `capacity` | number-decimal |  |  |
| `capacityUomId` | id |  |  |
| `facilityId` | id |  | Current Facility, where stored. |
| `locationSeqId` | id |  |  |
| `containerId` | id |  | Container stored in, if specified the current facilityId and locationSeqId should come from the container and not from this record or with standard EECA rule in place facilityId and locationSeqId will be set and maintained from the Container values. |
| `shipmentBoxTypeId` | id |  |  |
| `lotId` | id |  |  |
| `geoPointId` | id |  |  |
| `originId` | id |  | Origin ID, the ID used wherever this came from. |
| `originFacilityId` | id |  | Origin Facility, where manufactured or came from. |
| `acquireOrderId` | id |  |  |
| `acquireOrderItemSeqId` | id |  |  |
| `acquireWorkEffortId` | id |  | For assets created from production runs, etc. |
| `acquireShipmentId` | id |  |  |
| `acquireCost` | currency-amount |  |  |
| `acquireCostUomId` | id |  |  |
| `salvageValue` | currency-amount |  |  |
| `depreciation` | currency-amount |  | History in AssetDepreciation |
| `depreciationTypeEnumId` | id |  |  |
| `yearBeginDepreciation` | currency-amount |  | History in AssetDepreciation |
| `taxDepreciation` | currency-amount |  |  |
| `taxDepreciationTypeEnumId` | id |  |  |
| `assetPseudoId` | id |  |  |
| `hkStatusId` | text-short |  | Housekeeping status for hotel rooms: Clean / Dirty |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Parent Asset](Asset.md) via `parentAssetId`
- one `moqui.basic.Enumeration` via `assetTypeEnumId`
- one `moqui.basic.Enumeration` via `classEnumId`
- one `moqui.basic.StatusItem` via `statusId`
- one [Owner Party](Party.md) via `ownerPartyId`
- one [AssetPool](AssetPool.md) via `assetPoolId`
- one [Product](Product.md) via `productId`
- one `moqui.basic.Uom` via `originalQuantityUomId`
- one [Origin Facility](Facility.md) via `originFacilityId`
- one [Facility](Facility.md) via `facilityId`
- one-nofk [FacilityLocation](FacilityLocation.md) via `facilityId`, `locationSeqId`
- one [Container](Container.md) via `containerId`
- one [ShipmentBoxType](ShipmentBoxType.md) via `shipmentBoxTypeId`
- one [Lot](Lot.md) via `lotId`
- one `moqui.basic.GeoPoint` via `geoPointId`
- one-nofk [Acquire OrderHeader](OrderHeader.md) via `acquireOrderId`
- one [Acquire OrderItem](OrderItem.md) via `acquireOrderId`, `acquireOrderItemSeqId`
- one [Acquire WorkEffort](WorkEffort.md) via `acquireWorkEffortId`
- one [Acquire Shipment](Shipment.md) via `acquireShipmentId`
- one `moqui.basic.Uom` via `acquireCostUomId`
- one `moqui.basic.Enumeration` via `depreciationTypeEnumId`
- one `moqui.basic.Enumeration` via `taxDepreciationTypeEnumId`
- many [AssetDetail](AssetDetail.md) via `assetId`
- many [AssetDepreciation](AssetDepreciation.md) via `assetId`
- many [AssetGlAppl](AssetGlAppl.md) via `assetId`
- many [AssetIdentification](AssetIdentification.md) via `assetId`
- many [AssetPartyAssignment](AssetPartyAssignment.md) via `assetId`
- many [AssetIssuance](AssetIssuance.md) via `assetId`
- many [AssetReservation](AssetReservation.md) via `assetId`
- many [AssetReceipt](AssetReceipt.md) via `assetId`
- many [AssetRental](AssetRental.md) via `assetId`
- many [InvoiceItem](InvoiceItem.md) via `assetId`
- many [InvoiceItemDetail](InvoiceItemDetail.md) via `assetId`
- many [AssetTypeGlAccount](AssetTypeGlAccount.md) via `assetId`
- many [AcctgTrans](AcctgTrans.md) via `assetId`
- many [AcctgTransEntry](AcctgTransEntry.md) via `assetId`
- many [From OrderItem](OrderItem.md) via `assetId`
- many [BudgetItemDetail](BudgetItemDetail.md) via `assetId`
- many [Other AssetDetail](AssetDetail.md) via `assetId`
- many [AssetPaymentMethod](AssetPaymentMethod.md) via `assetId`
- many [AssetStandardCost](AssetStandardCost.md) via `assetId`
- many [AssetMaintenance](AssetMaintenance.md) via `assetId`
- many [AssetMeter](AssetMeter.md) via `assetId`
- many [AssetRegistration](AssetRegistration.md) via `assetId`
- many [Requirement](Requirement.md) via `assetId`
- many [Delivery](Delivery.md) via `assetId`
- many [WorkEffortAssetAssign](WorkEffortAssetAssign.md) via `assetId`
- many [ProductionEstimateAsset](ProductionEstimateAsset.md) via `assetId`
- many [Measurement](Measurement.md) via `assetId`
- many `moqui.basic.print.NetworkPrinter` via `assetId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.asset.Asset
