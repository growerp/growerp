---
type: Moqui Entity
title: Facility
description: "Facility"
resource: http://127.0.0.1:8080/rest/e1/mantle.facility.Facility
tags: [mantle, facility]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# Facility

Facility

Full entity name: `mantle.facility.Facility`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `facilityId` | id | Y |  |
| `pseudoId` | text-short |  |  |
| `facilityTypeEnumId` | id |  |  |
| `parentFacilityId` | id |  |  |
| `statusId` | id |  |  |
| `ownerPartyId` | id |  |  |
| `facilityName` | text-medium |  |  |
| `facilitySize` | number-decimal |  |  |
| `facilitySizeUomId` | id |  |  |
| `openedDate` | date-time |  |  |
| `closedDate` | date-time |  |  |
| `description` | text-medium |  |  |
| `geoId` | id |  | A geographic boundary describing the area of the facility (not a geographic boundary like a state that the facility is in). |
| `geoPointId` | id |  |  |
| `countyGeoId` | id |  |  |
| `stateGeoId` | id |  |  |
| `assetAllowOtherOwner` | text-indicator |  |  |
| `assetAllowIssueOverQoh` | text-indicator |  |  |
| `assetInventoryLocRequire` | text-indicator |  |  |
| `defaultDaysToShip` | number-integer |  |  |
| `externalId` | text-short |  | ID for the Facility in the direct upstream system it came from if it came from an external system |
| `originId` | text-short |  | ID for the Facility in the original system it came from (system of record) if not the direct upstream system |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.basic.Enumeration` via `facilityTypeEnumId`
- one [Parent Facility](Facility.md) via `parentFacilityId`
- one `moqui.basic.StatusItem` via `statusId`
- one [Owner Party](Party.md) via `ownerPartyId`
- one-nofk [Owner Organization](Organization.md) via `ownerPartyId`
- one-nofk [Owner Person](Person.md) via `ownerPartyId`
- one `moqui.basic.Uom` via `facilitySizeUomId`
- one `moqui.basic.Geo` via `geoId`
- one `moqui.basic.GeoPoint` via `geoPointId`
- one `moqui.basic.Geo` via `countyGeoId`
- one `moqui.basic.Geo` via `stateGeoId`
- many [FacilityCertification](FacilityCertification.md) via `facilityId`
- many [FacilityContactMech](FacilityContactMech.md) via `facilityId`
- many [FacilityContent](FacilityContent.md) via `facilityId`
- many [FacilityGlAppl](FacilityGlAppl.md) via `facilityId`
- many [FacilityGroupMember](FacilityGroupMember.md) via `facilityId`
- many [FacilityLocation](FacilityLocation.md) via `facilityId`
- many [FacilityLocationType](FacilityLocationType.md) via `facilityId`
- many [FacilityNote](FacilityNote.md) via `facilityId`
- many [FacilityParty](FacilityParty.md) via `facilityId`
- many [FacilityPrinter](FacilityPrinter.md) via `facilityId`
- many [InvoiceItemDetail](InvoiceItemDetail.md) via `facilityId`
- many [FacilityBoxType](FacilityBoxType.md) via `facilityId`
- many [ProductFacility](ProductFacility.md) via `facilityId`
- many [OrderPart](OrderPart.md) via `facilityId`
- many [ReturnHeader](ReturnHeader.md) via `facilityId`
- many [BudgetItemDetail](BudgetItemDetail.md) via `facilityId`
- many [PartyBadgeScan](PartyBadgeScan.md) via `facilityId`
- many [Origin Asset](Asset.md) via `facilityId`
- many [Asset](Asset.md) via `facilityId`
- many [Container](Container.md) via `facilityId`
- many [PhysicalInventory](PhysicalInventory.md) via `facilityId`
- many [PhysicalInventoryCount](PhysicalInventoryCount.md) via `facilityId`
- many [AssetIssuance](AssetIssuance.md) via `facilityId`
- many [Inventory ProductStore](ProductStore.md) via `facilityId`
- many [ProductStoreFacility](ProductStoreFacility.md) via `facilityId`
- many [Request](Request.md) via `facilityId`
- many [Requirement](Requirement.md) via `facilityId`
- many [Origin ShipmentRouteSegment](ShipmentRouteSegment.md) via `facilityId`
- many [Destination ShipmentRouteSegment](ShipmentRouteSegment.md) via `facilityId`
- many [Origin Delivery](Delivery.md) via `facilityId`
- many [Dest Delivery](Delivery.md) via `facilityId`
- many [WorkEffort](WorkEffort.md) via `facilityId`
- many [WorkEffortFacility](WorkEffortFacility.md) via `facilityId`
- many [ProductionEstimate](ProductionEstimate.md) via `facilityId`
- many [Destination ProductionEstimate](ProductionEstimate.md) via `facilityId`
- many [Measurement](Measurement.md) via `facilityId`
- many [TimeEntry](TimeEntry.md) via `facilityId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.facility.Facility
