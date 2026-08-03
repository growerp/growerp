---
type: Moqui Entity
title: WorkEffort
description: "Work Effort"
resource: http://127.0.0.1:8080/rest/e1/mantle.work.effort.WorkEffort
tags: [mantle, work, effort]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# WorkEffort

Work Effort

Full entity name: `mantle.work.effort.WorkEffort`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `workEffortId` | id | Y |  |
| `universalId` | text-medium |  |  |
| `sourceReferenceId` | text-short |  |  |
| `parentWorkEffortId` | id |  | For task/etc breakdown |
| `rootWorkEffortId` | id |  | The root of the tree this is part of (if applicable), like a project |
| `workEffortTypeEnumId` | id |  |  |
| `purposeEnumId` | id |  |  |
| `visibilityEnumId` | id |  |  |
| `resolutionEnumId` | id |  |  |
| `workTypeEnumId` | id |  |  |
| `ownerPartyId` | id |  | The party that "owns" the work effort, for production runs producing inventory this will be used as the Asset.ownerPartyId |
| `productStoreId` | id |  |  |
| `statusId` | id |  |  |
| `statusFlowId` | id |  |  |
| `priority` | number-integer |  |  |
| `sendNotificationEmail` | text-indicator |  |  |
| `percentComplete` | number-integer |  |  |
| `revisionNumber` | number-integer |  |  |
| `workEffortName` | text-medium |  |  |
| `description` | text-long |  |  |
| `location` | text-medium |  |  |
| `facilityId` | id |  | Where the WorkEffort takes place |
| `infoUrl` | text-medium |  |  |
| `shipmentMethodEnumId` | id |  | Mostly for Shipment Load/Ship (WepShipmentShip) purpose, using WorkEffort as a more task and planning oriented approach to a picklist. |
| `estimatedStartDate` | date-time |  |  |
| `estimatedCompletionDate` | date-time |  |  |
| `actualStartDate` | date-time |  |  |
| `actualCompletionDate` | date-time |  |  |
| `recurStartCron` | text-medium |  |  |
| `recurLimit` | number-integer |  |  |
| `recurEndDate` | date-time |  |  |
| `allDayStart` | date |  |  |
| `allDayEnd` | date |  | Can be null for single day events |
| `estimatedWorkTime` | number-decimal |  | Total estimated work time across all parties |
| `estimatedSetupTime` | number-decimal |  | Total estimated setup time across all parties |
| `remainingWorkTime` | number-decimal |  | Total remaining work time across all parties |
| `actualWorkTime` | number-decimal |  | Total actual work time across all parties |
| `actualSetupTime` | number-decimal |  | Total actual setup time across all parties |
| `totalTimeAllowed` | number-decimal |  | Total work time allowed (budgeted) across all parties |
| `estimatedWorkDuration` | number-decimal |  | Estimated work duration in calendar time (see estimatedWorkTime for total worked time across parties) |
| `actualWorkDuration` | number-decimal |  | Actual work duration in calendar time (see actualWorkTime for total worked time across parties) |
| `actualBreakDuration` | number-decimal |  | Actual break duration in calendar time |
| `timeUomId` | id |  | Time unit for all time and duration fields; defaults to hours (TF_hr) |
| `actualCost` | currency-amount |  |  |
| `actualClientCost` | currency-amount |  |  |
| `totalClientCostAllowed` | currency-amount |  |  |
| `costUomId` | id |  |  |
| `workEffortPseudoId` | id |  |  |
| `flowElementId` | id |  |  |
| `routing` | text-medium |  |  |
| `routingId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Parent WorkEffort](WorkEffort.md) via `parentWorkEffortId`
- one [Root WorkEffort](WorkEffort.md) via `rootWorkEffortId`
- one `moqui.basic.Enumeration` via `workEffortTypeEnumId`
- one `moqui.basic.Enumeration` via `purposeEnumId`
- one `moqui.basic.Enumeration` via `visibilityEnumId`
- one `moqui.basic.Enumeration` via `resolutionEnumId`
- one `moqui.basic.Enumeration` via `workTypeEnumId`
- one [Owner Party](Party.md) via `ownerPartyId`
- one [ProductStore](ProductStore.md) via `productStoreId`
- one `moqui.basic.StatusItem` via `statusId`
- one [Facility](Facility.md) via `facilityId`
- one `moqui.basic.Uom` via `timeUomId`
- one `moqui.basic.Uom` via `costUomId`
- many [WorkEffortAssetAssign](WorkEffortAssetAssign.md) via `workEffortId`
- many [WorkEffortAssetNeeded](WorkEffortAssetNeeded.md) via `workEffortId`
- many [WorkEffortAssoc](WorkEffortAssoc.md) via `workEffortId`
- many [WorkEffortAssoc](WorkEffortAssoc.md) via `workEffortId`
- many [WorkEffortBilling](WorkEffortBilling.md) via `workEffortId`
- many [WorkEffortCategoryAppl](WorkEffortCategoryAppl.md) via `workEffortId`
- many [WorkEffortCommEvent](WorkEffortCommEvent.md) via `workEffortId`
- many [WorkEffortContactMech](WorkEffortContactMech.md) via `workEffortId`
- many [WorkEffortContent](WorkEffortContent.md) via `workEffortId`
- many [WorkEffortFacility](WorkEffortFacility.md) via `workEffortId`
- many [WorkEffortNote](WorkEffortNote.md) via `workEffortId`
- many [WorkEffortParty](WorkEffortParty.md) via `workEffortId`
- many [WorkEffortProduct](WorkEffortProduct.md) via `workEffortId`
- many [CalendarEventSync](CalendarEventSync.md) via `workEffortId`
- many [LinerPanel](LinerPanel.md) via `workEffortId`
- many [InvoiceItemDetail](InvoiceItemDetail.md) via `workEffortId`
- many [RateAmount](RateAmount.md) via `workEffortId`
- many [AcctgTrans](AcctgTrans.md) via `workEffortId`
- many [OrderItemWorkEffort](OrderItemWorkEffort.md) via `workEffortId`
- many [AgreementItemWorkEffort](AgreementItemWorkEffort.md) via `workEffortId`
- many [Routing ProductAssoc](ProductAssoc.md) via `workEffortId`
- many [ProductWorkEffort](ProductWorkEffort.md) via `workEffortId`
- many [Acquire Asset](Asset.md) via `workEffortId`
- many [AssetDetail](AssetDetail.md) via `workEffortId`
- many [AssetIssuance](AssetIssuance.md) via `workEffortId`
- many [Task AssetMaintenance](AssetMaintenance.md) via `workEffortId`
- many [Template ProductMaintenance](ProductMaintenance.md) via `workEffortId`
- many [AssetReceipt](AssetReceipt.md) via `workEffortId`
- many [Root Request](Request.md) via `workEffortId`
- many [RequestWorkEffort](RequestWorkEffort.md) via `workEffortId`
- many [WorkRequirementFulfillment](WorkRequirementFulfillment.md) via `workEffortId`
- many [SalesOpportunityWorkEffort](SalesOpportunityWorkEffort.md) via `workEffortId`
- many [Ship Shipment](Shipment.md) via `workEffortId`
- many [Receive Shipment](Shipment.md) via `workEffortId`
- many [Assembly Shipment](Shipment.md) via `workEffortId`
- many [WikiPageWorkEffort](WikiPageWorkEffort.md) via `workEffortId`
- many [To WorkEffortAssoc](WorkEffortAssoc.md) via `workEffortId`
- many [WorkEffortDeliverableProd](WorkEffortDeliverableProd.md) via `workEffortId`
- many [WorkEffortEmplPosition](WorkEffortEmplPosition.md) via `workEffortId`
- many [WorkEffortInvoice](WorkEffortInvoice.md) via `workEffortId`
- many [WorkEffortSkillStandard](WorkEffortSkillStandard.md) via `workEffortId`
- many [ProductionEstimateWorkEff](ProductionEstimateWorkEff.md) via `workEffortId`
- many [Measurement](Measurement.md) via `workEffortId`
- many [TimeEntry](TimeEntry.md) via `workEffortId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.work.effort.WorkEffort
