---
type: Moqui Entity
title: Party
description: "Party"
resource: http://127.0.0.1:8080/rest/e1/mantle.party.Party
tags: [mantle, party]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# Party

Party

Full entity name: `mantle.party.Party`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `partyId` | id | Y |  |
| `pseudoId` | text-short |  |  |
| `partyTypeEnumId` | id |  |  |
| `disabled` | text-indicator |  |  |
| `customerStatusId` | id |  |  |
| `ownerPartyId` | id |  | If applicable, such as for customer records, the other Party that 'owns' the data for this Party. |
| `externalId` | id |  |  |
| `dataSourceId` | id |  |  |
| `gatewayCimId` | text-short |  |  |
| `comments` | text-long |  |  |
| `shippingInstructions` | text-long |  |  |
| `hasDuplicates` | text-indicator |  |  |
| `lastDupCheckDate` | date-time |  |  |
| `mergedToPartyId` | id |  |  |
| `vatPerc` | number-decimal |  |  |
| `salesPerc` | number-decimal |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.basic.Enumeration` via `partyTypeEnumId`
- one `moqui.basic.StatusItem` via `customerStatusId`
- one [Owner Party](Party.md) via `ownerPartyId`
- one `moqui.basic.DataSource` via `dataSourceId`
- one-nofk [Organization](Organization.md) via `partyId`
- one-nofk [Person](Person.md) via `partyId`
- many [PartyBadge](PartyBadge.md) via `partyId`
- many [PartyClassificationAppl](PartyClassificationAppl.md) via `partyId`
- many [PartyContent](PartyContent.md) via `partyId`
- many [PartyIdentification](PartyIdentification.md) via `partyId`
- many [PartyNote](PartyNote.md) via `partyId`
- many [PartyRole](PartyRole.md) via `partyId`
- many [PartySetting](PartySetting.md) via `partyId`
- many [From PartyRelationship](PartyRelationship.md) via `partyId`
- many [To PartyRelationship](PartyRelationship.md) via `partyId`
- many [PartyContactMech](PartyContactMech.md) via `partyId`
- many [FinancialAccount](FinancialAccount.md) via `partyId`
- many [PaymentMethod](PaymentMethod.md) via `partyId`
- many `moqui.security.UserAccount` via `partyId`
- many `Stripe.PaymentGatewayStripe` via `partyId`
- many [PartyApplication](PartyApplication.md) via `partyId`
- many [Owner Assessment](Assessment.md) via `partyId`
- many [Company Assessment](Assessment.md) via `partyId`
- many [Course](Course.md) via `partyId`
- many [CourseMedia](CourseMedia.md) via `partyId`
- many [Owner ChatRoom](ChatRoom.md) via `partyId`
- many [Owner Statistics](Statistics.md) via `partyId`
- many [Owner TenantSetup](TenantSetup.md) via `partyId`
- many [Owner LandingPage](LandingPage.md) via `partyId`
- many [Company LandingPage](LandingPage.md) via `partyId`
- many [Owner LinerPanel](LinerPanel.md) via `partyId`
- many [Owner LinerType](LinerType.md) via `partyId`
- many [Owner Routing](Routing.md) via `partyId`
- many [ContentPlan](ContentPlan.md) via `partyId`
- many [EmailSequence](EmailSequence.md) via `partyId`
- many [EmailSequenceEnrollment](EmailSequenceEnrollment.md) via `partyId`
- many [MarketingPersona](MarketingPersona.md) via `partyId`
- many [MasterContent](MasterContent.md) via `partyId`
- many [PlatformConfiguration](PlatformConfiguration.md) via `partyId`
- many [SocialPost](SocialPost.md) via `partyId`
- many [MenuConfiguration](MenuConfiguration.md) via `partyId`
- many [WebsiteForm](WebsiteForm.md) via `partyId`
- many [WebsiteFormSubmission](WebsiteFormSubmission.md) via `partyId`
- many [BillTo BillingAccount](BillingAccount.md) via `partyId`
- many [BillingAccountParty](BillingAccountParty.md) via `partyId`
- many [Organization FinancialAccount](FinancialAccount.md) via `partyId`
- many [Owner FinancialAccount](FinancialAccount.md) via `partyId`
- many [FinancialAccountParty](FinancialAccountParty.md) via `partyId`
- many [From FinancialAccountTrans](FinancialAccountTrans.md) via `partyId`
- many [To FinancialAccountTrans](FinancialAccountTrans.md) via `partyId`
- many [From Invoice](Invoice.md) via `partyId`
- many [To Invoice](Invoice.md) via `partyId`
- many [OverrideOrg Invoice](Invoice.md) via `partyId`
- many [From InvoiceItemAssoc](InvoiceItemAssoc.md) via `partyId`
- many [To InvoiceItemAssoc](InvoiceItemAssoc.md) via `partyId`
- many [InvoiceItemDetail](InvoiceItemDetail.md) via `partyId`
- many [InvoiceParty](InvoiceParty.md) via `partyId`
- many [Bank BankAccount](BankAccount.md) via `partyId`
- many [GiftCardFulfillment](GiftCardFulfillment.md) via `partyId`
- many [Owner PaymentMethod](PaymentMethod.md) via `partyId`
- many [From Payment](Payment.md) via `partyId`
- many [To Payment](Payment.md) via `partyId`
- many [OverrideOrg Payment](Payment.md) via `partyId`
- many [PaymentFraudEvidence](PaymentFraudEvidence.md) via `partyId`
- many [Owner Facility](Facility.md) via `partyId`
- many [Contact FacilityCertification](FacilityCertification.md) via `partyId`
- many [Auditor FacilityCertification](FacilityCertification.md) via `partyId`
- many [AuditorOrg FacilityCertification](FacilityCertification.md) via `partyId`
- many [FacilityGroupParty](FacilityGroupParty.md) via `partyId`
- many [FacilityParty](FacilityParty.md) via `partyId`
- many [PartySkill](PartySkill.md) via `partyId`
- one-nofk [Employee](Employee.md) via `partyId`
- many [Applying EmploymentApplication](EmploymentApplication.md) via `partyId`
- many [ReferredBy EmploymentApplication](EmploymentApplication.md) via `partyId`
- many [Approver EmploymentApplication](EmploymentApplication.md) via `partyId`
- many [Approver EmploymentLeave](EmploymentLeave.md) via `partyId`
- many [Garnish EmploymentPayDetail](EmploymentPayDetail.md) via `partyId`
- many [Organization PayrollAdjustment](PayrollAdjustment.md) via `partyId`
- many [Payee PayrollAdjustment](PayrollAdjustment.md) via `partyId`
- many [Organization WorkTypeGlOverride](WorkTypeGlOverride.md) via `partyId`
- many [Organization EmplPosition](EmplPosition.md) via `partyId`
- many [EmplPositionClassParty](EmplPositionClassParty.md) via `partyId`
- many [EmplPositionParty](EmplPositionParty.md) via `partyId`
- many [RateAmount](RateAmount.md) via `partyId`
- many [Organization GlAccountOrgTimePeriod](GlAccountOrgTimePeriod.md) via `partyId`
- many [Organization GlAccountOrganization](GlAccountOrganization.md) via `partyId`
- many [GlAccountParty](GlAccountParty.md) via `partyId`
- many [AssetTypeGlAccount](AssetTypeGlAccount.md) via `partyId`
- many [Organization CreditCardTypeGlAccount](CreditCardTypeGlAccount.md) via `partyId`
- many [Organization FinancialAccountReasonGlAccount](FinancialAccountReasonGlAccount.md) via `partyId`
- many [Organization FinancialAccountTypeGlAccount](FinancialAccountTypeGlAccount.md) via `partyId`
- many [Organization GlAccountTypeDefault](GlAccountTypeDefault.md) via `partyId`
- many [Organization GlAccountTypePartyDefault](GlAccountTypePartyDefault.md) via `partyId`
- many [GlAccountTypePartyDefault](GlAccountTypePartyDefault.md) via `partyId`
- many [Organization InvoiceTypeTransType](InvoiceTypeTransType.md) via `partyId`
- many [Organization ItemTypeGlAccount](ItemTypeGlAccount.md) via `partyId`
- many [Organization PartyAcctgPreference](PartyAcctgPreference.md) via `partyId`
- many [Organization PaymentInstrumentGlAccount](PaymentInstrumentGlAccount.md) via `partyId`
- many [Organization PaymentTypeGlAccount](PaymentTypeGlAccount.md) via `partyId`
- many [Organization ProductCategoryGlAccount](ProductCategoryGlAccount.md) via `partyId`
- many [Organization ProductGlAccount](ProductGlAccount.md) via `partyId`
- many [Organization TaxAuthorityGlAccount](TaxAuthorityGlAccount.md) via `partyId`
- many [Organization VarianceReasonGlAccount](VarianceReasonGlAccount.md) via `partyId`
- many [Organization GlReconciliation](GlReconciliation.md) via `partyId`
- many [Organization AcctgTrans](AcctgTrans.md) via `partyId`
- many [Other AcctgTrans](AcctgTrans.md) via `partyId`
- many [Organization GlJournal](GlJournal.md) via `partyId`
- many [Owner MarketingCampaign](MarketingCampaign.md) via `partyId`
- many [MarketingCampaignParty](MarketingCampaignParty.md) via `partyId`
- many [Owner ContactList](ContactList.md) via `partyId`
- many [ContactListCommStatus](ContactListCommStatus.md) via `partyId`
- many [ContactListParty](ContactListParty.md) via `partyId`
- many [Owner MarketSegment](MarketSegment.md) via `partyId`
- many [MarketSegmentParty](MarketSegmentParty.md) via `partyId`
- many [OrderContent](OrderContent.md) via `partyId`
- many [DecisionBy OrderDecision](OrderDecision.md) via `partyId`
- many [OrderEmailMessage](OrderEmailMessage.md) via `partyId`
- many [EnteredBy OrderHeader](OrderHeader.md) via `partyId`
- many [OrderItemFormResponse](OrderItemFormResponse.md) via `partyId`
- many [OrderItemParty](OrderItemParty.md) via `partyId`
- many [Vendor OrderPart](OrderPart.md) via `partyId`
- many [Customer OrderPart](OrderPart.md) via `partyId`
- many [Carrier OrderPart](OrderPart.md) via `partyId`
- many [OrderPartParty](OrderPartParty.md) via `partyId`
- many [Customer ReturnHeader](ReturnHeader.md) via `partyId`
- many [Vendor ReturnHeader](ReturnHeader.md) via `partyId`
- many [Carrier ReturnHeader](ReturnHeader.md) via `partyId`
- many [BudgetParty](BudgetParty.md) via `partyId`
- many [BudgetReview](BudgetReview.md) via `partyId`
- many [TaxAuth TaxAuthority](TaxAuthority.md) via `partyId`
- many [TaxAuthorityParty](TaxAuthorityParty.md) via `partyId`
- many [Organization PartyBadge](PartyBadge.md) via `partyId`
- many [PartyDimension](PartyDimension.md) via `partyId`
- many [PartyGeoPoint](PartyGeoPoint.md) via `partyId`
- many [IssuedBy PartyIdentification](PartyIdentification.md) via `partyId`
- many [PartySystemMessage](PartySystemMessage.md) via `partyId`
- many [Organization Agreement](Agreement.md) via `partyId`
- many [Other Agreement](Agreement.md) via `partyId`
- many [AgreementItemParty](AgreementItemParty.md) via `partyId`
- many [AgreementParty](AgreementParty.md) via `partyId`
- many [From CommunicationEvent](CommunicationEvent.md) via `partyId`
- many [To CommunicationEvent](CommunicationEvent.md) via `partyId`
- many [CommunicationEventParty](CommunicationEventParty.md) via `partyId`
- many [Owner Product](Product.md) via `partyId`
- many [Customer ProductParameterSet](ProductParameterSet.md) via `partyId`
- many [ProductParty](ProductParty.md) via `partyId`
- many [Owner Asset](Asset.md) via `partyId`
- many [AssetPartyAssignment](AssetPartyAssignment.md) via `partyId`
- many [AssetPoolParty](AssetPoolParty.md) via `partyId`
- many [Mfg Lot](Lot.md) via `partyId`
- many [PhysicalInventory](PhysicalInventory.md) via `partyId`
- many [Owner ProductCategory](ProductCategory.md) via `partyId`
- many [ProductCategoryParty](ProductCategoryParty.md) via `partyId`
- many [Owner ProductFeature](ProductFeature.md) via `partyId`
- many [AssetIssuanceParty](AssetIssuanceParty.md) via `partyId`
- many [GovAgency AssetRegistration](AssetRegistration.md) via `partyId`
- many [Organization ProductStore](ProductStore.md) via `partyId`
- many [ProductStoreGroupParty](ProductStoreGroupParty.md) via `partyId`
- many [ProductStoreParty](ProductStoreParty.md) via `partyId`
- many [ProductStorePromoCodeParty](ProductStorePromoCodeParty.md) via `partyId`
- many [Carrier ProductStoreShipOption](ProductStoreShipOption.md) via `partyId`
- many [Carrier ProductStoreShippingGateway](ProductStoreShippingGateway.md) via `partyId`
- many [Subscriber Subscription](Subscription.md) via `partyId`
- many [Owner Subscription](Subscription.md) via `partyId`
- many [FiledBy Request](Request.md) via `partyId`
- many [Owner Request](Request.md) via `partyId`
- many [Responsible RequestCategory](RequestCategory.md) via `partyId`
- many [RequestEmailMessage](RequestEmailMessage.md) via `partyId`
- many [Supplier RequestItem](RequestItem.md) via `partyId`
- many [RequestParty](RequestParty.md) via `partyId`
- many [RequirementParty](RequirementParty.md) via `partyId`
- many [Organization SalesForecast](SalesForecast.md) via `partyId`
- many [Internal SalesForecast](SalesForecast.md) via `partyId`
- many [PartyNeed](PartyNeed.md) via `partyId`
- many [Account SalesOpportunity](SalesOpportunity.md) via `partyId`
- many [Owner SalesOpportunity](SalesOpportunity.md) via `partyId`
- many [SalesOpportunityParty](SalesOpportunityParty.md) via `partyId`
- many [From Shipment](Shipment.md) via `partyId`
- many [To Shipment](Shipment.md) via `partyId`
- many [ShipmentParty](ShipmentParty.md) via `partyId`
- many [Carrier ShipmentRouteSegment](ShipmentRouteSegment.md) via `partyId`
- many [Carrier CarrierShipmentBoxType](CarrierShipmentBoxType.md) via `partyId`
- many [Carrier CarrierShipmentMethod](CarrierShipmentMethod.md) via `partyId`
- many [PartyCarrierAccount](PartyCarrierAccount.md) via `partyId`
- many [Carrier PartyCarrierAccount](PartyCarrierAccount.md) via `partyId`
- many [Carrier ShippingGatewayCarrier](ShippingGatewayCarrier.md) via `partyId`
- many [Carrier ShippingGatewayMethod](ShippingGatewayMethod.md) via `partyId`
- many [Owner WorkEffort](WorkEffort.md) via `partyId`
- many [Owner WorkEffortCategory](WorkEffortCategory.md) via `partyId`
- many [WorkEffortParty](WorkEffortParty.md) via `partyId`
- many [TimeEntry](TimeEntry.md) via `partyId`
- many [Team TimeEntry](TimeEntry.md) via `partyId`
- many [Client TimeEntry](TimeEntry.md) via `partyId`
- many [Timesheet](Timesheet.md) via `partyId`
- many [Client Timesheet](Timesheet.md) via `partyId`
- many [TimesheetParty](TimesheetParty.md) via `partyId`
- many `moqui.service.message.SystemMessage` via `partyId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.party.Party
