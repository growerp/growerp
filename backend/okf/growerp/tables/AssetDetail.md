---
type: Moqui Entity
title: AssetDetail
description: "Asset Detail"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.asset.AssetDetail
tags: [mantle, product, asset]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# AssetDetail

Asset Detail

Full entity name: `mantle.product.asset.AssetDetail`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `assetDetailId` | id | Y |  |
| `assetId` | id |  |  |
| `effectiveDate` | date-time |  |  |
| `quantityOnHandDiff` | number-decimal |  |  |
| `availableToPromiseDiff` | number-decimal |  |  |
| `unitCost` | number-decimal |  |  |
| `assetReservationId` | id |  |  |
| `otherAssetId` | id |  |  |
| `shipmentId` | id |  |  |
| `productId` | id |  |  |
| `orderId` | id |  |  |
| `orderItemSeqId` | id |  |  |
| `returnId` | id |  |  |
| `returnItemSeqId` | id |  |  |
| `workEffortId` | id |  |  |
| `assetMaintenanceId` | id |  |  |
| `assetIssuanceId` | id |  |  |
| `assetReceiptId` | id |  |  |
| `physicalInventoryId` | id |  |  |
| `physicalInventoryCountId` | id |  |  |
| `varianceReasonEnumId` | id |  |  |
| `description` | text-medium |  |  |
| `acctgTransResultEnumId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Asset](Asset.md) via `assetId`
- one-nofk [AssetReservation](AssetReservation.md) via `assetReservationId`
- one [Other Asset](Asset.md) via `otherAssetId`
- one [Shipment](Shipment.md) via `shipmentId`
- one [Product](Product.md) via `productId`
- one [OrderItem](OrderItem.md) via `orderId`, `orderItemSeqId`
- one [ReturnItem](ReturnItem.md) via `returnId`, `returnItemSeqId`
- one [WorkEffort](WorkEffort.md) via `workEffortId`
- one [AssetMaintenance](AssetMaintenance.md) via `assetMaintenanceId`
- one [AssetIssuance](AssetIssuance.md) via `assetIssuanceId`
- one [AssetReceipt](AssetReceipt.md) via `assetReceiptId`
- one [PhysicalInventory](PhysicalInventory.md) via `physicalInventoryId`
- one [PhysicalInventoryCount](PhysicalInventoryCount.md) via `physicalInventoryCountId`
- one `moqui.basic.Enumeration` via `varianceReasonEnumId`
- one `moqui.basic.Enumeration` via `acctgTransResultEnumId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.asset.AssetDetail
