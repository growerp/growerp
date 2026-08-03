---
type: Moqui Entity
title: SettlementTerm
description: "Settlement Term"
resource: http://127.0.0.1:8080/rest/e1/mantle.account.invoice.SettlementTerm
tags: [mantle, account, invoice]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# SettlementTerm

Settlement Term

Full entity name: `mantle.account.invoice.SettlementTerm`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `settlementTermId` | id | Y |  |
| `termTypeEnumId` | id |  |  |
| `description` | text-medium |  |  |
| `termValue` | number-decimal |  |  |
| `termValueUomId` | id |  |  |
| `orderPmtServiceRegisterId` | id |  | Use ServiceRegister.serviceTypeEnumId = 'SettleTermOrderPmt'; service will receive in-parameters: orderId, orderPartSeqId, and settlementTermId |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.basic.Enumeration` via `termTypeEnumId`
- one `moqui.basic.Uom` via `termValueUomId`
- one `moqui.service.ServiceRegister` via `orderPmtServiceRegisterId`
- many [Invoice](Invoice.md) via `settlementTermId`
- many [InvoiceTerm](InvoiceTerm.md) via `settlementTermId`
- many [PartyAcctgPreference](PartyAcctgPreference.md) via `settlementTermId`
- many [AcctgTransEntry](AcctgTransEntry.md) via `settlementTermId`
- many [OrderPart](OrderPart.md) via `settlementTermId`
- many [OrderPartTerm](OrderPartTerm.md) via `settlementTermId`
- many [AgreementTerm](AgreementTerm.md) via `settlementTermId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.account.invoice.SettlementTerm
