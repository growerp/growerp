---
type: Moqui Entity
title: GlReconciliation
description: "Gl Reconciliation"
resource: http://127.0.0.1:8080/rest/e1/mantle.ledger.reconciliation.GlReconciliation
tags: [mantle, ledger, reconciliation]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# GlReconciliation

Gl Reconciliation

Full entity name: `mantle.ledger.reconciliation.GlReconciliation`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `glReconciliationId` | id | Y |  |
| `glReconciliationName` | text-medium |  |  |
| `description` | text-medium |  |  |
| `glAccountId` | id |  |  |
| `statusId` | id |  |  |
| `organizationPartyId` | id |  |  |
| `reconciledBalance` | currency-amount |  |  |
| `openingBalance` | currency-amount |  |  |
| `reconciledDate` | date-time |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [GlAccount](GlAccount.md) via `glAccountId`
- one [Organization Party](Party.md) via `organizationPartyId`
- one `moqui.basic.StatusItem` via `statusId`
- many [FinancialAccountTrans](FinancialAccountTrans.md) via `glReconciliationId`
- many [GlReconciliationEntry](GlReconciliationEntry.md) via `glReconciliationId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.ledger.reconciliation.GlReconciliation
