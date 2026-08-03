---
type: Moqui Entity
title: ProductStorePaymentGateway
description: "Product Store Payment Gateway"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.store.ProductStorePaymentGateway
tags: [mantle, product, store]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ProductStorePaymentGateway

Product Store Payment Gateway

Full entity name: `mantle.product.store.ProductStorePaymentGateway`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `productStoreId` | id | Y |  |
| `paymentInstrumentEnumId` | id | Y |  |
| `paymentGatewayConfigId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [ProductStore](ProductStore.md) via `productStoreId`
- one `moqui.basic.Enumeration` via `paymentInstrumentEnumId`
- one [PaymentGatewayConfig](PaymentGatewayConfig.md) via `paymentGatewayConfigId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.store.ProductStorePaymentGateway
