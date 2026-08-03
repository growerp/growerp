---
type: Moqui Entity
title: TaxGatewayConfig
description: "Tax Gateway Config"
resource: http://127.0.0.1:8080/rest/e1/mantle.other.tax.TaxGatewayConfig
tags: [mantle, other, tax]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# TaxGatewayConfig

Tax Gateway Config

Full entity name: `mantle.other.tax.TaxGatewayConfig`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `taxGatewayConfigId` | id | Y |  |
| `taxGatewayTypeEnumId` | id |  | Each payment gateway integration should define a TaxGatewayType Enumeration record plus an entity with a shared PK (ie PK is taxGatewayTypeEnumId). |
| `description` | text-medium |  |  |
| `calculateServiceName` | text-medium |  | Service implementing mantle.other.TaxServices.calculate#SalesTax interface. |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.basic.Enumeration` via `taxGatewayTypeEnumId`
- many [ProductStore](ProductStore.md) via `taxGatewayConfigId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.other.tax.TaxGatewayConfig
