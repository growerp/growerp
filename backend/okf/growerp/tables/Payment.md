---
type: Moqui Entity
title: Payment
description: "Payment"
resource: http://127.0.0.1:8080/rest/e1/mantle.account.payment.Payment
tags: [mantle, account, payment]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# Payment

Payment

Full entity name: `mantle.account.payment.Payment`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `paymentId` | id | Y |  |
| `paymentTypeEnumId` | id |  |  |
| `fromPartyId` | id |  |  |
| `toPartyId` | id |  |  |
| `paymentInstrumentEnumId` | id |  | The payment instrument used for the payment; for non-cash and other instruments represented by an account specify details of it with paymentMethodId |
| `paymentMethodId` | id |  | The from PaymentMethod (owned by fromPartyId) |
| `toPaymentMethodId` | id |  | The to PaymentMethod (owned by toPartyId), if applicable, the account the payment goes to |
| `paymentGatewayConfigId` | id |  | Use this PaymentGatewayConfig for auth/etc. For Payments by CC/etc that are not from an order and/or the order is not associated with a ProductStore. Also set automatically on auth for capture, etc. |
| `orderId` | id |  | Set if the Payment represents the payment settings for an Order. |
| `orderPartSeqId` | id |  | Set if the Payment represents the payment settings for an OrderPart. |
| `orderItemSeqId` | id |  | Set if the Payment represents the payment settings for an OrderItem. |
| `statusId` | id |  |  |
| `effectiveDate` | date-time |  | When the payment is issued (delivered) |
| `settlementDate` | date-time |  | When the payment is settled (confirmed) |
| `dueDate` | date-time |  | Due Date for this Payment, different concept than Invoice Due Date for planned split payments, etc |
| `paymentAuthCode` | text-short |  |  |
| `paymentRefNum` | text-short |  |  |
| `comments` | text-medium |  |  |
| `memo` | text-medium |  |  |
| `distGroupEnumId` | id |  |  |
| `amount` | currency-amount |  |  |
| `amountUomId` | id |  |  |
| `appliedTotal` | currency-amount |  |  |
| `unappliedTotal` | currency-amount |  |  |
| `forInvoiceId` | id |  |  |
| `refundForPaymentId` | id |  |  |
| `finAccountId` | id |  |  |
| `finAccountAuthId` | id |  |  |
| `finAccountTransId` | id |  |  |
| `overrideGlAccountId` | id |  | Overrides the GlAccount for the PaymentMethod entry, ie for the cash account the payment goes into. |
| `overrideOrgPartyId` | id |  | Used to specify the organization override rather than using the fromPartyId and/or toPartyId (depending on which is an internal org). |
| `partyRelationshipId` | id |  | For Payroll payments, points to Employment record |
| `timePeriodId` | id |  | For Payroll payments, points to Payroll TimePeriod |
| `originalCurrencyAmount` | currency-amount |  |  |
| `originalCurrencyUomId` | id |  |  |
| `presentFlag` | text-indicator |  |  |
| `swipedFlag` | text-indicator |  |  |
| `processAttempt` | number-integer |  |  |
| `needsNsfRetry` | text-indicator |  |  |
| `visitId` | id |  | Track the Visit so we know the session info, including client IP, for audit and fraud purposes. |
| `acctgTransResultEnumId` | id |  |  |
| `reconcileStatusId` | id |  |  |
| `paymentMethodFileId` | id |  | If included in a file for processing, file ID goes here |
| `pseudoId` | id |  |  |
| `itemTypeGlAccountId` | id |  | Is used for posting this payment without invoice |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.basic.Enumeration` via `paymentTypeEnumId`
- one `moqui.basic.Enumeration` via `paymentInstrumentEnumId`
- one [PaymentMethod](PaymentMethod.md) via `paymentMethodId`
- one [To PaymentMethod](PaymentMethod.md) via `toPaymentMethodId`
- one-nofk [CreditCard](CreditCard.md) via `paymentMethodId`
- one [PaymentGatewayConfig](PaymentGatewayConfig.md) via `paymentGatewayConfigId`
- one [OrderHeader](OrderHeader.md) via `orderId`
- one-nofk [OrderPart](OrderPart.md) via `orderId`, `orderPartSeqId`
- one-nofk [OrderItem](OrderItem.md) via `orderId`, `orderItemSeqId`
- one `moqui.basic.Enumeration` via `distGroupEnumId`
- one `moqui.basic.Uom` via `amountUomId`
- one [From Party](Party.md) via `fromPartyId`
- one [To Party](Party.md) via `toPartyId`
- one `moqui.basic.StatusItem` via `statusId`
- one [For Invoice](Invoice.md) via `forInvoiceId`
- one [RefundFor Payment](Payment.md) via `refundForPaymentId`
- one [FinancialAccount](FinancialAccount.md) via `finAccountId`
- one [FinancialAccountAuth](FinancialAccountAuth.md) via `finAccountAuthId`
- one [FinancialAccountTrans](FinancialAccountTrans.md) via `finAccountTransId`
- one [Override GlAccount](GlAccount.md) via `overrideGlAccountId`
- one [OverrideOrg Party](Party.md) via `overrideOrgPartyId`
- one [Employment](Employment.md) via `partyRelationshipId`
- one [TimePeriod](TimePeriod.md) via `timePeriodId`
- one `moqui.basic.Uom` via `originalCurrencyUomId`
- one `moqui.server.Visit` via `visitId`
- one `moqui.basic.Enumeration` via `acctgTransResultEnumId`
- one `moqui.basic.StatusItem` via `reconcileStatusId`
- one [PaymentMethodFile](PaymentMethodFile.md) via `paymentMethodFileId`
- many [PaymentApplication](PaymentApplication.md) via `paymentId`
- many [To PaymentApplication](PaymentApplication.md) via `paymentId`
- many [PaymentContent](PaymentContent.md) via `paymentId`
- one [ItemType GlAccount](GlAccount.md) via `itemTypeGlAccountId`
- many [BankAccountCheck](BankAccountCheck.md) via `paymentId`
- many [PaymentGatewayResponse](PaymentGatewayResponse.md) via `paymentId`
- many [PaymentMethodTrans](PaymentMethodTrans.md) via `paymentId`
- many [Deduction](Deduction.md) via `paymentId`
- many [PaymentBudgetAllocation](PaymentBudgetAllocation.md) via `paymentId`
- many [PaymentFraudEvidence](PaymentFraudEvidence.md) via `paymentId`
- many [AcctgTrans](AcctgTrans.md) via `paymentId`
- many [To AcctgTrans](AcctgTrans.md) via `paymentId`
- many [Refund ReturnItem](ReturnItem.md) via `paymentId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.account.payment.Payment
