---
type: Moqui Entity
title: GlReconciliationEntry
description: "Gl Reconciliation Entry"
resource: http://127.0.0.1:8080/rest/e1/mantle.ledger.reconciliation.GlReconciliationEntry
tags: [mantle, ledger, reconciliation]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# GlReconciliationEntry

Gl Reconciliation Entry

Full entity name: `mantle.ledger.reconciliation.GlReconciliationEntry`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `glReconciliationId` | id | Y |  |
| `acctgTransId` | id | Y |  |
| `acctgTransEntrySeqId` | id | Y |  |
| `reconciledAmount` | currency-amount |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [GlReconciliation](GlReconciliation.md) via `glReconciliationId`
- one-nofk [AcctgTrans](AcctgTrans.md) via `acctgTransId`
- one [AcctgTransEntry](AcctgTransEntry.md) via `acctgTransId`, `acctgTransEntrySeqId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.ledger.reconciliation.GlReconciliationEntry
