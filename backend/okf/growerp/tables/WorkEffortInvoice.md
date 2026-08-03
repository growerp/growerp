---
type: Moqui Entity
title: WorkEffortInvoice
description: "Work Effort Invoice"
resource: http://127.0.0.1:8080/rest/e1/mantle.work.effort.WorkEffortInvoice
tags: [mantle, work, effort]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# WorkEffortInvoice

Work Effort Invoice

Full entity name: `mantle.work.effort.WorkEffortInvoice`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `invoiceId` | id | Y |  |
| `workEffortId` | id | Y |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Invoice](Invoice.md) via `invoiceId`
- one [WorkEffort](WorkEffort.md) via `workEffortId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.work.effort.WorkEffortInvoice
