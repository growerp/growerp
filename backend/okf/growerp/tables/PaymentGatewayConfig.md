---
type: Moqui Entity
title: PaymentGatewayConfig
description: "Payment Gateway Config"
resource: http://127.0.0.1:8080/rest/e1/mantle.account.method.PaymentGatewayConfig
tags: [mantle, account, method]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# PaymentGatewayConfig

Payment Gateway Config

Full entity name: `mantle.account.method.PaymentGatewayConfig`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `paymentGatewayConfigId` | id | Y |  |
| `paymentGatewayTypeEnumId` | id |  | Each payment gateway integration should define a PaymentGatewayType Enumeration record plus an entity with a shared PK (ie PK is paymentGatewayConfigId). |
| `description` | text-medium |  |  |
| `authorizeServiceName` | text-medium |  | Service implementing the mantle.account.PaymentServices.authorize#Payment interface |
| `captureServiceName` | text-medium |  | Service implementing the mantle.account.PaymentServices.capture#Payment interface |
| `releaseServiceName` | text-medium |  | Service implementing the mantle.account.PaymentServices.release#Payment interface |
| `refundServiceName` | text-medium |  | Service implementing the mantle.account.PaymentServices.refund#Payment interface |
| `detailsServiceName` | text-medium |  | Service implementing the mantle.account.PaymentServices.get#PaymentGatewayDetails interface |
| `systemMessageRemoteId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.basic.Enumeration` via `paymentGatewayTypeEnumId`
- one `moqui.service.message.SystemMessageRemote` via `systemMessageRemoteId`
- many `Stripe.PaymentGatewayStripe` via `paymentGatewayConfigId`
- many [PaymentMethod](PaymentMethod.md) via `paymentGatewayConfigId`
- many [Payment](Payment.md) via `paymentGatewayConfigId`
- many [ProductStorePaymentGateway](ProductStorePaymentGateway.md) via `paymentGatewayConfigId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.account.method.PaymentGatewayConfig
