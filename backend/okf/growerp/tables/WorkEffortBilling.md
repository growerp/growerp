---
type: Moqui Entity
title: WorkEffortBilling
description: "Work Effort Billing"
resource: http://127.0.0.1:8080/rest/e1/mantle.work.effort.WorkEffortBilling
tags: [mantle, work, effort]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# WorkEffortBilling

Work Effort Billing

Full entity name: `mantle.work.effort.WorkEffortBilling`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `workEffortId` | id | Y |  |
| `invoiceId` | id | Y |  |
| `invoiceItemSeqId` | id | Y |  |
| `percentage` | number-decimal |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [WorkEffort](WorkEffort.md) via `workEffortId`
- one [InvoiceItem](InvoiceItem.md) via `invoiceId`, `invoiceItemSeqId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.work.effort.WorkEffortBilling
