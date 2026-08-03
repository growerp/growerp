---
type: Moqui Entity
title: ProductPrice
description: "Product Price"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.ProductPrice
tags: [mantle, product]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ProductPrice

Product Price

Full entity name: `mantle.product.ProductPrice`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `productPriceId` | id | Y |  |
| `productId` | id |  |  |
| `productStoreId` | id |  | For pricing per store. Leave null to apply to all stores. |
| `vendorPartyId` | id |  | For sales from internal organization (ie company) set to internal organization's ID. For supplier prices set to supplier's ID. |
| `customerPartyId` | id |  | For general consumer prices leave null. For a price for a specific customer (or group of customers), set to that customer's ID. For supplier prices this is the internal organization's (ie company's) ID. |
| `priceTypeEnumId` | id |  |  |
| `pricePurposeEnumId` | id |  |  |
| `fromDate` | date-time |  |  |
| `thruDate` | date-time |  |  |
| `minQuantity` | number-decimal |  |  |
| `price` | currency-precise |  |  |
| `priceUomId` | id |  |  |
| `termUomId` | id |  | For recurring and usage prices to specify a time/freq measure, or a usage unit measure (bits, minutes, etc). |
| `taxInPrice` | text-indicator |  | If Y the price field has tax included for the given taxAuthorityId at the taxPercentage. |
| `taxAmount` | currency-precise |  |  |
| `taxPercentage` | number-decimal |  |  |
| `taxAuthorityId` | id |  |  |
| `agreementId` | id |  |  |
| `agreementItemSeqId` | id |  | Use along with agreementId to associate the price with an AgreementItem. |
| `otherPartyItemName` | text-medium |  |  |
| `otherPartyItemId` | text-short |  |  |
| `comments` | text-long |  |  |
| `quantityIncrement` | number-decimal |  |  |
| `quantityIncluded` | number-decimal |  |  |
| `quantityUomId` | id |  |  |
| `preferredOrderEnumId` | id |  |  |
| `supplierRatingTypeEnumId` | id |  |  |
| `standardLeadTimeDays` | number-decimal |  |  |
| `canDropShip` | text-indicator |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Product](Product.md) via `productId`
- one `moqui.basic.Enumeration` via `priceTypeEnumId`
- one `moqui.basic.Enumeration` via `pricePurposeEnumId`
- one `moqui.basic.Uom` via `priceUomId`
- one `moqui.basic.Uom` via `termUomId`
- one [ProductStore](ProductStore.md) via `productStoreId`
- one [TaxAuthority](TaxAuthority.md) via `taxAuthorityId`
- one `moqui.basic.Enumeration` via `preferredOrderEnumId`
- one `moqui.basic.Enumeration` via `supplierRatingTypeEnumId`
- one `moqui.basic.Uom` via `quantityUomId`
- many [OrderItem](OrderItem.md) via `productPriceId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.ProductPrice
