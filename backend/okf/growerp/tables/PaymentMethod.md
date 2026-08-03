---
type: Moqui Entity
title: PaymentMethod
description: "Payment Method"
resource: http://127.0.0.1:8080/rest/e1/mantle.account.method.PaymentMethod
tags: [mantle, account, method]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# PaymentMethod

Payment Method

Full entity name: `mantle.account.method.PaymentMethod`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `paymentMethodId` | id | Y |  |
| `paymentMethodTypeEnumId` | id |  |  |
| `purposeEnumId` | id |  |  |
| `ownerPartyId` | id |  |  |
| `description` | text-medium |  |  |
| `fromDate` | date-time |  |  |
| `thruDate` | date-time |  |  |
| `thruDateSetAuto` | text-indicator |  | If Y then expire (set thruDate) once allowed (no active Payment) |
| `openedDate` | date-time |  |  |
| `titleOnAccount` | text-medium |  | Not commonly used; payment gateways generally only separate first and last names |
| `firstNameOnAccount` | text-medium |  |  |
| `middleNameOnAccount` | text-medium |  | Not commonly used; payment gateways generally only separate first and last names; for credit cards middle initial generally included with first name |
| `lastNameOnAccount` | text-medium |  |  |
| `suffixOnAccount` | text-medium |  | Not commonly used; payment gateways generally only separate first and last names |
| `companyNameOnAccount` | text-medium |  |  |
| `ledgerBalance` | currency-amount |  |  |
| `availableBalance` | currency-amount |  |  |
| `balanceDate` | date-time |  |  |
| `loanPaymentAmount` | currency-amount |  |  |
| `loanPaymentPeriodUomId` | id |  | Uom with uomTypeEnumId=UT_TIME_FREQ_MEASURE |
| `currencyUomId` | id |  |  |
| `postalContactMechId` | id |  |  |
| `telecomContactMechId` | id |  |  |
| `emailContactMechId` | id |  |  |
| `gatewayCimId` | text-short |  |  |
| `paymentGatewayConfigId` | id |  |  |
| `imageUrl` | text-medium |  | Usually specific to a type or sub-type of PaymentMethod, for display to users |
| `trustLevelEnumId` | id |  |  |
| `paymentFraudEvidenceId` | id |  | Refer to evidence here if trust level is gray listed or black listed |
| `glAccountId` | id |  | A GL Account associated with this PaymentMethod for reconciliation, etc |
| `finAccountId` | id |  | Refers to FinancialAccount when paymentMethodTypeEnumId=PmtFinancialAccount |
| `originalPaymentMethodId` | id |  | Because PaymentMethod records are treated as immutable (except for certain fields) they are cloned and expired on update and this field will have the paymentMethodId of the original record. |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.basic.Enumeration` via `paymentMethodTypeEnumId`
- one `moqui.basic.Enumeration` via `purposeEnumId`
- one [Owner Party](Party.md) via `ownerPartyId`
- one `moqui.basic.Uom` via `currencyUomId`
- one [Postal ContactMech](ContactMech.md) via `postalContactMechId`
- one [PostalAddress](PostalAddress.md) via `postalContactMechId`
- one [Telecom ContactMech](ContactMech.md) via `telecomContactMechId`
- one [TelecomNumber](TelecomNumber.md) via `telecomContactMechId`
- one [Email ContactMech](ContactMech.md) via `emailContactMechId`
- one [PaymentGatewayConfig](PaymentGatewayConfig.md) via `paymentGatewayConfigId`
- one `moqui.basic.Enumeration` via `trustLevelEnumId`
- one [PaymentFraudEvidence](PaymentFraudEvidence.md) via `paymentFraudEvidenceId`
- one [GlAccount](GlAccount.md) via `glAccountId`
- one [FinancialAccount](FinancialAccount.md) via `finAccountId`
- one-nofk [BankAccount](BankAccount.md) via `paymentMethodId`
- one-nofk [BitcoinWallet](BitcoinWallet.md) via `paymentMethodId`
- one-nofk [CreditCard](CreditCard.md) via `paymentMethodId`
- one-nofk [GiftCard](GiftCard.md) via `paymentMethodId`
- one-nofk [PayPalAccount](PayPalAccount.md) via `paymentMethodId`
- many [Replenish FinancialAccount](FinancialAccount.md) via `paymentMethodId`
- many [BankAccountCheck](BankAccountCheck.md) via `paymentMethodId`
- many [PaymentGatewayResponse](PaymentGatewayResponse.md) via `paymentMethodId`
- many [PaymentMethodContent](PaymentMethodContent.md) via `paymentMethodId`
- many [PaymentMethodFile](PaymentMethodFile.md) via `paymentMethodId`
- many [PaymentMethodFileType](PaymentMethodFileType.md) via `paymentMethodId`
- many [PaymentMethodTrans](PaymentMethodTrans.md) via `paymentMethodId`
- many [Payment](Payment.md) via `paymentMethodId`
- many [To Payment](Payment.md) via `paymentMethodId`
- many [Refund PartyAcctgPreference](PartyAcctgPreference.md) via `paymentMethodId`
- many [ReturnHeader](ReturnHeader.md) via `paymentMethodId`
- many [Party](Party.md) via `ownerPartyId`
- many [AssetPaymentMethod](AssetPaymentMethod.md) via `paymentMethodId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.account.method.PaymentMethod
