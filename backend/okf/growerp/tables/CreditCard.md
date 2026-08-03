---
type: Moqui Entity
title: CreditCard
description: "Credit Card"
resource: http://127.0.0.1:8080/rest/e1/mantle.account.method.CreditCard
tags: [mantle, account, method]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# CreditCard

Credit Card

Full entity name: `mantle.account.method.CreditCard`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `paymentMethodId` | id | Y |  |
| `creditCardTypeEnumId` | id |  |  |
| `cardNumber` | text-medium |  |  |
| `cardNumberLookupHash` | text-medium |  | A one-way hash (SHA, etc) of the cardNumber used for looking up a credit card by its number in a secure way. |
| `validFromDate` | text-short |  | Not common but used in some parts of the world |
| `expireDate` | text-short |  | String representing the date in the format: MM/yyyy |
| `issueNumber` | text-short |  | Single digit number on some Switch and Maestro cards |
| `cardSecurityCode` | text-medium |  | CVV/etc number for card. By PCI rules can only be recorded until authorization is complete, after that must be deleted. Set the mantle.account.PaymentServices.authorize#SinglePayment service for where this is done. |
| `consecutiveFailedAuths` | number-integer |  |  |
| `lastFailedAuthDate` | date-time |  |  |
| `consecutiveFailedNsf` | number-integer |  |  |
| `lastFailedNsfDate` | date-time |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [PaymentMethod](PaymentMethod.md) via `paymentMethodId`
- one `moqui.basic.Enumeration` via `creditCardTypeEnumId`
- many [Payment](Payment.md) via `paymentMethodId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.account.method.CreditCard
