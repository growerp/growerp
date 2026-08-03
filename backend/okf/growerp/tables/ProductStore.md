---
type: Moqui Entity
title: ProductStore
description: "Product Store"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.store.ProductStore
tags: [mantle, product, store]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ProductStore

Product Store

Full entity name: `mantle.product.store.ProductStore`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `productStoreId` | id | Y |  |
| `storeName` | text-medium |  |  |
| `organizationPartyId` | id |  | The Organization Party that Orders, Invoices, GL transactions, etc will be associated with. |
| `inventoryFacilityId` | id |  |  |
| `reservationOrderEnumId` | id |  |  |
| `reservationAutoEnumId` | id |  |  |
| `requireInventory` | text-indicator |  |  |
| `defaultDisablePromotions` | text-indicator |  |  |
| `defaultDisableShippingCalc` | text-indicator |  |  |
| `defaultDisableTaxCalc` | text-indicator |  |  |
| `returnPostalContactMechId` | id |  | Return postal address for shipping labels |
| `markupOrderShipLabels` | text-indicator |  |  |
| `markupShipmentShipLabels` | text-indicator |  |  |
| `shipmentAnyCarrierMethod` | text-indicator |  | If Y don't restrict Shipment Shipping Options by ProductStoreShipOption records during fulfillment, show all Shipment Methods for Carriers associated with shipping gateway |
| `insurancePackageThreshold` | currency-amount |  | If total cost of items in a package is above this amount buy insurance on that package |
| `autoApproveDelay` | number-integer |  | Minimum time in minutes to wait before trying to auto-approve; defaults to 0 which means auto-approve immediately (via SECA rule), otherwise delayed auto-approve handled with service job |
| `storeDomain` | text-short |  | Store domain for use in emails |
| `profileUrlPath` | text-medium |  | Path to profile page for use in emails |
| `wikiSpaceId` | id |  | For a WikiSpace mounted as content, superceded by ProductStoreWikiSpace with spaceTypeEnumId=PstFull |
| `contentDataDocumentId` | id |  | Warning: this field to be deprecated in favor of a ProductStoreDataDocument entity with a typeEnumId of PsdtContent. The dataDocumentId to use for search of content pages in wikiSpaceId |
| `blogDataDocumentId` | id |  | Warning: this field to be deprecated in favor a ProductStoreDataDocument entity with a typeEnumId of PsdtBlog. The dataDocumentId to use for search of blog entries |
| `productDataDocumentId` | id |  | Warning: this field to be deprecated in favor of a ProductStoreDataDocument entity with a typeEnumId of PsdtProduct. The dataDocumentId to use for product search |
| `defaultLocale` | text-short |  |  |
| `defaultCurrencyUomId` | id |  |  |
| `defaultSalesChannelEnumId` | id |  |  |
| `requireCustomerRole` | text-indicator |  |  |
| `taxGatewayConfigId` | id |  |  |
| `systemMessageRemoteId` | id |  | Reference to the SystemMessageRemote record for the remote system this store is for such as a separate, integrated ecommerce app. Note that SystemMessageRemote is extended with a productStoreId so that other SystemMessageRemotes know which store they are for (if applicable). |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Organization Party](Party.md) via `organizationPartyId`
- one [Inventory Facility](Facility.md) via `inventoryFacilityId`
- one `moqui.basic.Enumeration` via `reservationOrderEnumId`
- one `moqui.basic.Enumeration` via `reservationAutoEnumId`
- one-nofk [Return ContactMech](ContactMech.md) via `returnPostalContactMechId`
- one [Return PostalAddress](PostalAddress.md) via `returnPostalContactMechId`
- one `moqui.resource.wiki.WikiSpace` via `wikiSpaceId`
- many [ProductStoreDataDocument](ProductStoreDataDocument.md) via `productStoreId`
- one `moqui.entity.document.DataDocument` via `contentDataDocumentId`
- one `moqui.entity.document.DataDocument` via `blogDataDocumentId`
- one `moqui.entity.document.DataDocument` via `productDataDocumentId`
- one `moqui.basic.Uom` via `defaultCurrencyUomId`
- one `moqui.basic.Enumeration` via `defaultSalesChannelEnumId`
- one [TaxGatewayConfig](TaxGatewayConfig.md) via `taxGatewayConfigId`
- one `moqui.service.message.SystemMessageRemote` via `systemMessageRemoteId`
- many [ProductStoreCategory](ProductStoreCategory.md) via `productStoreId`
- many [ProductStoreEmail](ProductStoreEmail.md) via `productStoreId`
- many [ProductStoreFacility](ProductStoreFacility.md) via `productStoreId`
- many [ProductStoreParty](ProductStoreParty.md) via `productStoreId`
- many [ProductStorePaymentGateway](ProductStorePaymentGateway.md) via `productStoreId`
- many [ProductStoreSetting](ProductStoreSetting.md) via `productStoreId`
- many [ProductStoreShippingGateway](ProductStoreShippingGateway.md) via `productStoreId`
- many [ProductStoreShipOption](ProductStoreShipOption.md) via `productStoreId`
- many [ProductStoreGroupMember](ProductStoreGroupMember.md) via `productStoreId`
- many [ProductStoreContent](ProductStoreContent.md) via `productStoreId`
- many [WebsiteForm](WebsiteForm.md) via `productStoreId`
- many [Invoice](Invoice.md) via `productStoreId`
- many [MarketSegment](MarketSegment.md) via `productStoreId`
- many [OrderHeader](OrderHeader.md) via `productStoreId`
- many [ProductContent](ProductContent.md) via `productStoreId`
- many [ProductOtherIdentification](ProductOtherIdentification.md) via `productStoreId`
- many [ProductParameterOption](ProductParameterOption.md) via `productStoreId`
- many [ProductPrice](ProductPrice.md) via `productStoreId`
- many [ProductReview](ProductReview.md) via `productStoreId`
- many [AssetPoolStore](AssetPoolStore.md) via `productStoreId`
- many [ProductCategoryContent](ProductCategoryContent.md) via `productStoreId`
- many [ProductCategoryIdent](ProductCategoryIdent.md) via `productStoreId`
- many [ProductStoreApprove](ProductStoreApprove.md) via `productStoreId`
- many [ProductStoreProduct](ProductStoreProduct.md) via `productStoreId`
- many [ProductStorePromotion](ProductStorePromotion.md) via `productStoreId`
- many [ProductStoreWikiContent](ProductStoreWikiContent.md) via `productStoreId`
- many [ProductStoreWikiSpace](ProductStoreWikiSpace.md) via `productStoreId`
- many [Request](Request.md) via `productStoreId`
- many [Shipment](Shipment.md) via `productStoreId`
- many [WorkEffort](WorkEffort.md) via `productStoreId`
- many `moqui.mcp.agent.ProductStoreAiConfig` via `productStoreId`
- many `moqui.service.message.SystemMessage` via `productStoreId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.store.ProductStore
