---
type: Moqui Entity
title: TimeEntry
description: "Time Entry"
resource: http://127.0.0.1:8080/rest/e1/mantle.work.time.TimeEntry
tags: [mantle, work, time]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# TimeEntry

Time Entry

Full entity name: `mantle.work.time.TimeEntry`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `timeEntryId` | id | Y |  |
| `parentEntryId` | id |  |  |
| `timesheetId` | id |  |  |
| `partyId` | id |  | The party performing work (worker, may be the vendor or work for the vendor) |
| `teamPartyId` | id |  |  |
| `vendorPartyId` | id |  | The vendor (employer, etc) who pays the worker. With workEffortId (task or project) the party in the Vendor role, with facilityId the party in the Manager role |
| `clientPartyId` | id |  | The client who pays the vendor for bill through. May get through timesheetId, workEffortId (with Customer or CustomerBillTo role), or facilityId (Facility.ownerPartyId) |
| `rateTypeEnumId` | id |  |  |
| `rateModifierEnumId` | id |  |  |
| `workTypeEnumId` | id |  |  |
| `emplPositionClassId` | id |  |  |
| `hasModifiedRates` | text-indicator |  | Set to Y when *Rate fields are manually set and not from RateAmount lookups |
| `rateAmountId` | id |  | Client/customer hourly RateAmount reference |
| `clientHourRate` | number-decimal |  |  |
| `vendorRateAmountId` | id |  | Vendor/worker hourly RateAmount reference |
| `vendorHourRate` | number-decimal |  |  |
| `fromDate` | date-time |  |  |
| `thruDate` | date-time |  |  |
| `hours` | number-decimal |  |  |
| `breakHours` | number-decimal |  | Non-paid break hours e.g. Lunch |
| `pieceCount` | number-decimal |  |  |
| `pieceRateTypeEnumId` | id |  |  |
| `pieceRateAmountId` | id |  | Client/customer piece RateAmount reference |
| `clientPieceRate` | number-decimal |  |  |
| `vendorPieceRateAmountId` | id |  | Vendor/worker piece RateAmount reference |
| `vendorPieceRate` | number-decimal |  |  |
| `comments` | text-long |  |  |
| `facilityId` | id |  | Where the work was done; if null and workEffortId is set get from WorkEffort.facilityId |
| `workEffortId` | id |  |  |
| `invoiceId` | id |  |  |
| `invoiceItemSeqId` | id |  |  |
| `vendorInvoiceId` | id |  |  |
| `vendorInvoiceItemSeqId` | id |  |  |
| `approvalStatusId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Timesheet](Timesheet.md) via `timesheetId`
- one [Parent TimeEntry](TimeEntry.md) via `parentEntryId`
- one [Party](Party.md) via `partyId`
- one-nofk [Person](Person.md) via `partyId`
- one [Team Party](Party.md) via `teamPartyId`
- one [Client Party](Party.md) via `clientPartyId`
- one `moqui.basic.Enumeration` via `rateTypeEnumId`
- one `moqui.basic.Enumeration` via `rateModifierEnumId`
- one `moqui.basic.Enumeration` via `workTypeEnumId`
- one [EmplPositionClass](EmplPositionClass.md) via `emplPositionClassId`
- one [RateAmount](RateAmount.md) via `rateAmountId`
- one [Vendor RateAmount](RateAmount.md) via `vendorRateAmountId`
- one `moqui.basic.Enumeration` via `pieceRateTypeEnumId`
- one [Piece RateAmount](RateAmount.md) via `pieceRateAmountId`
- one [VendorPiece RateAmount](RateAmount.md) via `vendorPieceRateAmountId`
- one [Facility](Facility.md) via `facilityId`
- one [WorkEffort](WorkEffort.md) via `workEffortId`
- one [InvoiceItem](InvoiceItem.md) via `invoiceId`, `invoiceItemSeqId`
- one [Vendor InvoiceItem](InvoiceItem.md) via `vendorInvoiceId`, `vendorInvoiceItemSeqId`
- many [PartyBadgeScan](PartyBadgeScan.md) via `timeEntryId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.work.time.TimeEntry
