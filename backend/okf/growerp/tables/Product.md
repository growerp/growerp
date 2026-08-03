---
type: Moqui Entity
title: Product
description: "Product"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.Product
tags: [mantle, product]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# Product

Product

Full entity name: `mantle.product.Product`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `productId` | id | Y |  |
| `pseudoId` | text-short |  |  |
| `productTypeEnumId` | id |  |  |
| `productClassEnumId` | id |  |  |
| `assetTypeEnumId` | id |  |  |
| `assetClassEnumId` | id |  |  |
| `statusId` | id |  |  |
| `ownerPartyId` | id |  | Brand or other organization that owns the product design, IP, etc. There may be multiple suppliers, manufacturers, etc for a product but only one that 'owns' it. |
| `productName` | text-medium |  |  |
| `description` | text-long |  |  |
| `comments` | text-long |  |  |
| `salesIntroductionDate` | date-time |  |  |
| `salesDiscontinuationDate` | date-time |  |  |
| `salesDiscWhenNotAvail` | text-indicator |  |  |
| `supportDiscontinuationDate` | date-time |  |  |
| `requireInventory` | text-indicator |  |  |
| `chargeShipping` | text-indicator |  | Set to N to not charge shipping (ie defaults to Y) |
| `signatureRequiredEnumId` | id |  |  |
| `shippingInsuranceReqd` | text-indicator |  |  |
| `inShippingBox` | text-indicator |  |  |
| `defaultShipmentBoxTypeId` | id |  |  |
| `taxable` | text-indicator |  | Set to N to not charge sales tax (ie defaults to Y) |
| `taxCode` | text-short |  | A code representing the tax category of the product, passed to the tax calculation gateway. |
| `returnable` | text-indicator |  |  |
| `amountUomId` | id |  |  |
| `amountFixed` | number-decimal |  | For products with fixed amounts such as gift certificate amounts, rope lengths, etc. |
| `amountRequire` | text-indicator |  | Require an amount in addition to quantity on orders/etc. |
| `originGeoId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.basic.Enumeration` via `productTypeEnumId`
- one `moqui.basic.Enumeration` via `productClassEnumId`
- one `moqui.basic.Enumeration` via `assetTypeEnumId`
- one `moqui.basic.Enumeration` via `assetClassEnumId`
- one `moqui.basic.StatusItem` via `statusId`
- one [Owner Party](Party.md) via `ownerPartyId`
- one `moqui.basic.Geo` via `originGeoId`
- one `moqui.basic.Enumeration` via `signatureRequiredEnumId`
- one [Default ShipmentBoxType](ShipmentBoxType.md) via `defaultShipmentBoxTypeId`
- one `moqui.basic.Uom` via `amountUomId`
- many [ProductAssoc](ProductAssoc.md) via `productId`
- many [To ProductAssoc](ProductAssoc.md) via `productId`
- many [ProductContent](ProductContent.md) via `productId`
- many [ProductDimension](ProductDimension.md) via `productId`
- many [ProductGeo](ProductGeo.md) via `productId`
- many [ProductGlAppl](ProductGlAppl.md) via `productId`
- many [ProductIdentification](ProductIdentification.md) via `productId`
- many [ProductOtherIdentification](ProductOtherIdentification.md) via `productId`
- many [ProductParty](ProductParty.md) via `productId`
- many [ProductPrice](ProductPrice.md) via `productId`
- many [ProductCategoryMember](ProductCategoryMember.md) via `productId`
- many [ProductFeatureAppl](ProductFeatureAppl.md) via `productId`
- many [ProductMaintenance](ProductMaintenance.md) via `productId`
- many [ProductMeter](ProductMeter.md) via `productId`
- many [ProductSubscriptionResource](ProductSubscriptionResource.md) via `productId`
- many [Asset](Asset.md) via `productId`
- many [Course Course](Course.md) via `productId`
- many [ProductRouting](ProductRouting.md) via `productId`
- many [AssetRental](AssetRental.md) via `productId`
- many [RentalPrice](RentalPrice.md) via `productId`
- many [InvoiceItem](InvoiceItem.md) via `productId`
- many [ProductFacility](ProductFacility.md) via `productId`
- many [ProductFacilityLocation](ProductFacilityLocation.md) via `productId`
- many [ProductGlAccount](ProductGlAccount.md) via `productId`
- many [AcctgTransEntry](AcctgTransEntry.md) via `productId`
- many [OrderItem](OrderItem.md) via `productId`
- many [ReturnItem](ReturnItem.md) via `productId`
- many [Replacement ReturnItem](ReturnItem.md) via `productId`
- many [BudgetItem](BudgetItem.md) via `productId`
- many [BudgetItemDetail](BudgetItemDetail.md) via `productId`
- many [AgreementItem](AgreementItem.md) via `productId`
- many [CommunicationEventProduct](CommunicationEventProduct.md) via `productId`
- one-nofk [ProductCalculatedInfo](ProductCalculatedInfo.md) via `productId`
- many [ProductDbForm](ProductDbForm.md) via `productId`
- many [Parent ProductOtherIdentification](ProductOtherIdentification.md) via `productId`
- many [ProductParameterOption](ProductParameterOption.md) via `productId`
- many [ProductParameterProduct](ProductParameterProduct.md) via `productId`
- many [ProductParameterSet](ProductParameterSet.md) via `productId`
- many [ProductReview](ProductReview.md) via `productId`
- many [ProductUomDimension](ProductUomDimension.md) via `productId`
- many [ProductWorkEffort](ProductWorkEffort.md) via `productId`
- many [AssetDetail](AssetDetail.md) via `productId`
- many [PhysicalInventoryCount](PhysicalInventoryCount.md) via `productId`
- many [Feature ProductFeatureAppl](ProductFeatureAppl.md) via `productId`
- many [AssetIssuance](AssetIssuance.md) via `productId`
- many [AssetReservation](AssetReservation.md) via `productId`
- many [AssetReceipt](AssetReceipt.md) via `productId`
- many [ProductStoreProduct](ProductStoreProduct.md) via `productId`
- many [ProductStorePromoProduct](ProductStorePromoProduct.md) via `productId`
- many [Subscription](Subscription.md) via `productId`
- many [RequestItem](RequestItem.md) via `productId`
- many [Requirement](Requirement.md) via `productId`
- many [SalesForecastDetail](SalesForecastDetail.md) via `productId`
- many [PartyNeed](PartyNeed.md) via `productId`
- many [ShipmentContent](ShipmentContent.md) via `productId`
- many [ShipmentItem](ShipmentItem.md) via `productId`
- many [ShipmentItemSource](ShipmentItemSource.md) via `productId`
- many [ShipmentPackageContent](ShipmentPackageContent.md) via `productId`
- many [Asset WorkEffortAssetNeeded](WorkEffortAssetNeeded.md) via `productId`
- many [WorkEffortProduct](WorkEffortProduct.md) via `productId`
- many [ProductionEstimate](ProductionEstimate.md) via `productId`
- many [Measurement](Measurement.md) via `productId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.Product
