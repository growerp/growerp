---
type: Moqui Entity
title: ProductStoreShippingGateway
description: "Product Store Shipping Gateway"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.store.ProductStoreShippingGateway
tags: [mantle, product, store]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ProductStoreShippingGateway

Product Store Shipping Gateway

Full entity name: `mantle.product.store.ProductStoreShippingGateway`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `productStoreId` | id | Y |  |
| `carrierPartyId` | id | Y |  |
| `shippingGatewayConfigId` | id |  |  |
| `billingType` | text-short |  | For third party and other carrier account billing; for Shippo valid values are SENDER, RECIPIENT, THIRD_PARTY |
| `billingAccount` | text-short |  | Third party or other carrier account number |
| `billingZip` | text-short |  |  |
| `billingCountry` | text-short |  | For Shippo this is the 2 letter ISO country code |
| `insurancePercent` | number-decimal |  | For insurance estimate records the percent of insured amount that is the cost of the insurance |
| `defaultTradeTermEnumId` | id |  |  |
| `customsContentsEnumId` | id |  |  |
| `customsNonDeliveryEnumId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [ProductStore](ProductStore.md) via `productStoreId`
- one [Carrier Party](Party.md) via `carrierPartyId`
- one [ShippingGatewayConfig](ShippingGatewayConfig.md) via `shippingGatewayConfigId`
- one `moqui.basic.Enumeration` via `defaultTradeTermEnumId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.store.ProductStoreShippingGateway
