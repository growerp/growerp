---
type: Moqui Entity
title: OrderHeader
description: "Order Header"
resource: http://127.0.0.1:8080/rest/e1/mantle.order.OrderHeader
tags: [mantle, order]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# OrderHeader

Order Header

Full entity name: `mantle.order.OrderHeader`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `orderId` | id | Y |  |
| `orderName` | text-medium |  |  |
| `entryDate` | date-time |  |  |
| `placedDate` | date-time |  |  |
| `approvedDate` | date-time |  |  |
| `completedDate` | date-time |  |  |
| `statusId` | id |  |  |
| `processingStatusId` | id |  | Sub-status for use when statusId=OrderProcessing for custom pre-approve status flows |
| `orderRevision` | number-integer |  |  |
| `currencyUomId` | id |  |  |
| `billingAccountId` | id |  |  |
| `productStoreId` | id |  |  |
| `salesChannelEnumId` | id |  |  |
| `terminalId` | text-short |  | ID for the terminal, such as a POS system, where the order was recorded |
| `displayId` | text-short |  | ID to display to customers, can be different from orderId and/or externalId |
| `externalId` | text-short |  | ID for the order in the direct upstream system it came from if it came from an external system |
| `externalRevision` | text-short |  |  |
| `originId` | text-short |  | ID for the order in the original system it came from (system of record) if not the direct upstream system |
| `originUrl` | text-medium |  | URL to view the order on the original system it came from |
| `syncStatusId` | id |  |  |
| `systemMessageRemoteId` | id |  |  |
| `visitId` | id |  |  |
| `enteredByPartyId` | id |  |  |
| `parentOrderId` | id |  | The original/parent order this is based on, used for all order clones including recurring orders |
| `recurCronExpression` | text-medium |  | If populated is a recurring order, automatically cloned if in Approved status |
| `lastOrderedDate` | date-time |  | For recurring orders the date/time of the most recent clone/recurrence |
| `recurAutoInvoice` | text-indicator |  | If Y and cloned recurring order successfully auto-approved then also invoice/bill the order immediately |
| `remainingSubTotal` | currency-amount |  |  |
| `grandTotal` | currency-amount |  |  |
| `pseudoId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.basic.StatusItem` via `statusId`
- one `moqui.basic.StatusItem` via `processingStatusId`
- one `moqui.basic.Uom` via `currencyUomId`
- one [BillingAccount](BillingAccount.md) via `billingAccountId`
- one [ProductStore](ProductStore.md) via `productStoreId`
- one `moqui.basic.Enumeration` via `salesChannelEnumId`
- one `moqui.basic.StatusItem` via `syncStatusId`
- one `moqui.service.message.SystemMessageRemote` via `systemMessageRemoteId`
- one `moqui.server.Visit` via `visitId`
- one [EnteredBy Party](Party.md) via `enteredByPartyId`
- one [Parent OrderHeader](OrderHeader.md) via `parentOrderId`
- many [OrderPart](OrderPart.md) via `orderId`
- many [OrderItem](OrderItem.md) via `orderId`
- many [OrderContent](OrderContent.md) via `orderId`
- many [OrderNote](OrderNote.md) via `orderId`
- many [OrderCommunicationEvent](OrderCommunicationEvent.md) via `orderId`
- many [OrderEmailMessage](OrderEmailMessage.md) via `orderId`
- many [Payment](Payment.md) via `orderId`
- many [Child OrderHeader](OrderHeader.md) via `orderId`
- many `moqui.entity.EntityAuditLog` via `orderId`
- many [AssetRental](AssetRental.md) via `orderId`
- many [FinancialAccountTrans](FinancialAccountTrans.md) via `orderId`
- many [GiftCardFulfillment](GiftCardFulfillment.md) via `orderId`
- many [PaymentFraudEvidence](PaymentFraudEvidence.md) via `orderId`
- many [TrackingCodeOrder](TrackingCodeOrder.md) via `orderId`
- many [TrackingCodeOrderReturn](TrackingCodeOrderReturn.md) via `orderId`
- many [OrderDecision](OrderDecision.md) via `orderId`
- many [OrderDecisionReason](OrderDecisionReason.md) via `orderId`
- many [OrderPromoCode](OrderPromoCode.md) via `orderId`
- many [OrderServiceJobRun](OrderServiceJobRun.md) via `orderId`
- many [OrderSystemMessage](OrderSystemMessage.md) via `orderId`
- many [ReturnItem](ReturnItem.md) via `orderId`
- many [Replacement ReturnItem](ReturnItem.md) via `orderId`
- many [Acquire Asset](Asset.md) via `orderId`
- many [AssetReservation](AssetReservation.md) via `orderId`
- many [Purchase AssetMaintenance](AssetMaintenance.md) via `orderId`
- many [AssetMaintenanceOrderItem](AssetMaintenanceOrderItem.md) via `orderId`
- many [SalesOpportunityOrder](SalesOpportunityOrder.md) via `orderId`
- many [ShipmentItemSource](ShipmentItemSource.md) via `orderId`
- many `moqui.service.message.SystemMessage` via `orderId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.order.OrderHeader
