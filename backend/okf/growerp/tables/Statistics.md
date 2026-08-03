---
type: Moqui Entity
title: Statistics
description: "Statistics"
resource: http://127.0.0.1:8080/rest/e1/growerp.general.Statistics
tags: [growerp, general]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# Statistics

Statistics

Full entity name: `growerp.general.Statistics`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `ownerPartyId` | id | Y |  |
| `admins` | number-integer |  |  |
| `employees` | number-integer |  |  |
| `suppliers` | number-integer |  |  |
| `leads` | number-integer |  |  |
| `customers` | number-integer |  |  |
| `openSlsOrders` | number-integer |  |  |
| `openPurOrders` | number-integer |  |  |
| `opportunities` | number-integer |  |  |
| `myOpportunities` | number-integer |  |  |
| `categories` | number-integer |  |  |
| `products` | number-integer |  |  |
| `assets` | number-integer |  |  |
| `salesInvoicesNotPaidCount` | number-integer |  |  |
| `salesInvoicesNotPaidAmount` | number-float |  |  |
| `purchInvoicesNotPaidCount` | number-integer |  |  |
| `purchInvoicesNotPaidAmount` | number-float |  |  |
| `allTasks` | number-integer |  |  |
| `notInvoicedHours` | number-integer |  |  |
| `outgoingShipments` | number-integer |  |  |
| `incomingShipments` | number-integer |  |  |
| `whLocations` | number-integer |  |  |
| `requests` | number-integer |  |  |
| `notReadChatRooms` | text-medium |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Owner Party](Party.md) via `ownerPartyId`

# Citations

- http://127.0.0.1:8080/rest/e1/growerp.general.Statistics
