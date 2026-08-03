---
type: Moqui Entity
title: RoleType
description: "Role Type"
resource: http://127.0.0.1:8080/rest/e1/mantle.party.RoleType
tags: [mantle, party]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# RoleType

Role Type

Full entity name: `mantle.party.RoleType`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `roleTypeId` | id | Y |  |
| `parentTypeId` | id |  |  |
| `description` | text-medium |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Parent RoleType](RoleType.md) via `parentTypeId`
- many [BillingAccountParty](BillingAccountParty.md) via `roleTypeId`
- many [FinancialAccountParty](FinancialAccountParty.md) via `roleTypeId`
- many [InvoiceParty](InvoiceParty.md) via `roleTypeId`
- many [FacilityGroupParty](FacilityGroupParty.md) via `roleTypeId`
- many [FacilityParty](FacilityParty.md) via `roleTypeId`
- many [EmplPositionParty](EmplPositionParty.md) via `roleTypeId`
- many [GlAccountParty](GlAccountParty.md) via `roleTypeId`
- many [GlAccountTypePartyDefault](GlAccountTypePartyDefault.md) via `roleTypeId`
- many [MarketingCampaignParty](MarketingCampaignParty.md) via `roleTypeId`
- many [MarketSegmentParty](MarketSegmentParty.md) via `roleTypeId`
- many [OrderContent](OrderContent.md) via `roleTypeId`
- many [OrderEmailMessage](OrderEmailMessage.md) via `roleTypeId`
- many [OrderItemFormResponse](OrderItemFormResponse.md) via `roleTypeId`
- many [OrderItemParty](OrderItemParty.md) via `roleTypeId`
- many [OrderPartParty](OrderPartParty.md) via `roleTypeId`
- many [BudgetParty](BudgetParty.md) via `roleTypeId`
- many [From PartyRelationship](PartyRelationship.md) via `roleTypeId`
- many [To PartyRelationship](PartyRelationship.md) via `roleTypeId`
- many [PartyRole](PartyRole.md) via `roleTypeId`
- many [PartySettingTypeRole](PartySettingTypeRole.md) via `roleTypeId`
- many [RoleGroupMember](RoleGroupMember.md) via `roleTypeId`
- many [Organization Agreement](Agreement.md) via `roleTypeId`
- many [Other Agreement](Agreement.md) via `roleTypeId`
- many [AgreementItemParty](AgreementItemParty.md) via `roleTypeId`
- many [AgreementParty](AgreementParty.md) via `roleTypeId`
- many [From CommunicationEvent](CommunicationEvent.md) via `roleTypeId`
- many [To CommunicationEvent](CommunicationEvent.md) via `roleTypeId`
- many [CommunicationEventParty](CommunicationEventParty.md) via `roleTypeId`
- many [ProductDbForm](ProductDbForm.md) via `roleTypeId`
- many [ProductParty](ProductParty.md) via `roleTypeId`
- many [AssetPartyAssignment](AssetPartyAssignment.md) via `roleTypeId`
- many [AssetPoolParty](AssetPoolParty.md) via `roleTypeId`
- many [ProductCategoryParty](ProductCategoryParty.md) via `roleTypeId`
- many [AssetIssuanceParty](AssetIssuanceParty.md) via `roleTypeId`
- many [ProductStoreGroupParty](ProductStoreGroupParty.md) via `roleTypeId`
- many [ProductStoreParty](ProductStoreParty.md) via `roleTypeId`
- many [Use ProductSubscriptionResource](ProductSubscriptionResource.md) via `roleTypeId`
- many [RequestParty](RequestParty.md) via `roleTypeId`
- many [RequirementParty](RequirementParty.md) via `roleTypeId`
- many [PartyNeed](PartyNeed.md) via `roleTypeId`
- many [SalesOpportunityParty](SalesOpportunityParty.md) via `roleTypeId`
- many [ShipmentParty](ShipmentParty.md) via `roleTypeId`
- many [WorkEffortParty](WorkEffortParty.md) via `roleTypeId`
- many [TimesheetParty](TimesheetParty.md) via `roleTypeId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.party.RoleType
