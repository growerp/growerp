---
type: Moqui Entity
title: PaymentFraudEvidence
description: "Evidence of payment fraud with references to the Payment and possibly OrderHeader that represents the fraud. Other entities like ContactMech and PaymentMethod have a reference to this entity when they are gray- or black-listed based on this evidence."
resource: http://127.0.0.1:8080/rest/e1/mantle.account.payment.PaymentFraudEvidence
tags: [mantle, account, payment]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# PaymentFraudEvidence

Evidence of payment fraud with references to the Payment and possibly OrderHeader that represents the fraud. Other entities like ContactMech and PaymentMethod have a reference to this entity when they are gray- or black-listed based on this evidence.

Full entity name: `mantle.account.payment.PaymentFraudEvidence`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `paymentFraudEvidenceId` | id | Y |  |
| `fraudTypeEnumId` | id |  |  |
| `comments` | text-medium |  |  |
| `contentLocation` | text-medium |  |  |
| `paymentId` | id |  |  |
| `orderId` | id |  |  |
| `partyId` | id |  |  |
| `visitId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.basic.Enumeration` via `fraudTypeEnumId`
- one [Payment](Payment.md) via `paymentId`
- one [OrderHeader](OrderHeader.md) via `orderId`
- one [Party](Party.md) via `partyId`
- one `moqui.server.Visit` via `visitId`
- many [PaymentMethod](PaymentMethod.md) via `paymentFraudEvidenceId`
- many [ContactMech](ContactMech.md) via `paymentFraudEvidenceId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.account.payment.PaymentFraudEvidence
