---
type: Moqui Entity
title: OrderItem
description: "Order Item"
resource: http://127.0.0.1:8080/rest/e1/mantle.order.OrderItem
tags: [mantle, order]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# OrderItem

Order Item

Full entity name: `mantle.order.OrderItem`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `orderId` | id | Y |  |
| `orderItemSeqId` | id | Y |  |
| `orderPartSeqId` | id |  |  |
| `parentItemSeqId` | id |  |  |
| `itemTypeEnumId` | id |  |  |
| `productId` | id |  |  |
| `productFeatureId` | id |  |  |
| `otherPartyProductId` | text-short |  |  |
| `productParameterSetId` | id |  | For a set of Product Parameters to personalize a Product and/or record details specific to a purchase of the Product. If used represents a distinct Product instance (OrderItem, etc records should not be combined unless matches). |
| `itemDescription` | text-medium |  |  |
| `comments` | text-medium |  |  |
| `quantity` | number-decimal |  |  |
| `quantityUomId` | id |  |  |
| `quantityCancelled` | number-decimal |  |  |
| `selectedAmount` | number-decimal |  |  |
| `priority` | number-integer |  | NOTE: this may be deprecated in favor of OrderPart.priority |
| `requiredByDate` | date-time |  |  |
| `unitAmount` | currency-precise |  | The purchase or sales price. For barter/exchange orders this represents the market value of the item at the time of the exchange in terms of the OrderHeader.currencyUomId. |
| `unitListPrice` | currency-precise |  |  |
| `isModifiedPrice` | text-indicator |  |  |
| `standardCost` | currency-precise |  | For purchase orders the cost for accounting purposes if different from unitAmount. Used to set Asset.acquireCost on receipt. |
| `externalItemSeqId` | id |  |  |
| `fromAssetId` | id |  | Order for a particular Asset, not just any associated with the Product. |
| `productPriceId` | id |  |  |
| `productCategoryId` | id |  |  |
| `isPromo` | text-indicator |  |  |
| `promoQuantity` | number-decimal |  | For promo items. The quantity of the parent order item 'consumed' by the promotion, excluding from use in other promotions if promotion set to limit by this. |
| `promoTimesUsed` | number-decimal |  | For promo items. The number of times the promo was used for use limits. |
| `storePromotionId` | id |  |  |
| `promoCodeId` | id |  |  |
| `promoCodeText` | text-medium |  | Promo code(s) entered by customer used for the item, may be from external system |
| `subscriptionId` | id |  |  |
| `finAccountId` | id |  | Populate along with finAccountTransId for gift card/certificate/etc purchase and replenishment |
| `finAccountTransId` | id |  |  |
| `overrideGlAccountId` | id |  | Used to specify the override or actual glAccountId used for the item. |
| `salesOpportunityId` | id |  |  |
| `sourceReferenceId` | text-short |  |  |
| `sourcePercentage` | number-decimal |  | The percentage used for tax, promo, etc items |
| `amountAlreadyIncluded` | currency-precise |  | The amount here is already represented in the item price, such as VAT taxes. |
| `exemptAmount` | currency-amount |  | An amount that would normally apply, but not to this order; for tax exemption represents the what the tax would have been. |
| `customerReferenceId` | text-short |  | For tax entries this is partyTaxId |
| `taxAuthorityId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [OrderHeader](OrderHeader.md) via `orderId`
- one `moqui.basic.Enumeration` via `itemTypeEnumId`
- one [OrderPart](OrderPart.md) via `orderId`, `orderPartSeqId`
- one-nofk [Parent OrderItem](OrderItem.md) via `orderId`, `parentItemSeqId`
- many [Child OrderItem](OrderItem.md) via `orderId`, `orderItemSeqId`
- one [Product](Product.md) via `productId`
- one [ProductFeature](ProductFeature.md) via `productFeatureId`
- one [ProductParameterSet](ProductParameterSet.md) via `productParameterSetId`
- one `moqui.basic.Uom` via `quantityUomId`
- one [From Asset](Asset.md) via `fromAssetId`
- one [ProductPrice](ProductPrice.md) via `productPriceId`
- one [ProductCategory](ProductCategory.md) via `productCategoryId`
- one [ProductStorePromotion](ProductStorePromotion.md) via `storePromotionId`
- one [ProductStorePromoCode](ProductStorePromoCode.md) via `promoCodeId`
- one [Subscription](Subscription.md) via `subscriptionId`
- one [FinancialAccount](FinancialAccount.md) via `finAccountId`
- one [FinancialAccountTrans](FinancialAccountTrans.md) via `finAccountTransId`
- one [Override GlAccount](GlAccount.md) via `overrideGlAccountId`
- one [SalesOpportunity](SalesOpportunity.md) via `salesOpportunityId`
- one [TaxAuthority](TaxAuthority.md) via `taxAuthorityId`
- many [AssetReservation](AssetReservation.md) via `orderId`, `orderItemSeqId`
- many [AssetIssuance](AssetIssuance.md) via `orderId`, `orderItemSeqId`
- many [AssetReceipt](AssetReceipt.md) via `orderId`, `orderItemSeqId`
- many [ShipmentItemSource](ShipmentItemSource.md) via `orderId`, `orderItemSeqId`
- many [OrderItemBilling](OrderItemBilling.md) via `orderId`, `orderItemSeqId`
- many [AssetRental](AssetRental.md) via `orderId`, `orderItemSeqId`
- many [GiftCardFulfillment](GiftCardFulfillment.md) via `orderId`, `orderItemSeqId`
- many [Payment](Payment.md) via `orderId`, `orderItemSeqId`
- many [OrderContent](OrderContent.md) via `orderId`, `orderItemSeqId`
- many [OrderItemFormResponse](OrderItemFormResponse.md) via `orderId`, `orderItemSeqId`
- many [OrderItemParty](OrderItemParty.md) via `orderId`, `orderItemSeqId`
- many [OrderItemWorkEffort](OrderItemWorkEffort.md) via `orderId`, `orderItemSeqId`
- many [ReturnItem](ReturnItem.md) via `orderId`, `orderItemSeqId`
- many [Acquire Asset](Asset.md) via `orderId`, `orderItemSeqId`
- many [AssetDetail](AssetDetail.md) via `orderId`, `orderItemSeqId`
- many [AssetMaintenanceOrderItem](AssetMaintenanceOrderItem.md) via `orderId`, `orderItemSeqId`
- many [RequestItemOrder](RequestItemOrder.md) via `orderId`, `orderItemSeqId`
- many [RequirementOrderItem](RequirementOrderItem.md) via `orderId`, `orderItemSeqId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.order.OrderItem
