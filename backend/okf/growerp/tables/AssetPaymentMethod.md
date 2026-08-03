---
type: Moqui Entity
title: AssetPaymentMethod
description: "Asset Payment Method"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.asset.AssetPaymentMethod
tags: [mantle, product, asset]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# AssetPaymentMethod

Asset Payment Method

Full entity name: `mantle.product.asset.AssetPaymentMethod`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `assetId` | id | Y |  |
| `paymentMethodId` | id | Y |  |
| `typeEnumId` | id |  |  |
| `sequenceNum` | number-integer |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Asset](Asset.md) via `assetId`
- one [PaymentMethod](PaymentMethod.md) via `paymentMethodId`
- one `moqui.basic.Enumeration` via `typeEnumId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.asset.AssetPaymentMethod
