# GrowERP Marketing & Sales Process Flow

End-to-end flow from lead generation (outreach/marketing) through CRM, order,
fulfillment, invoicing and payment. Implemented across `growerp_outreach`,
`growerp_sales`, `growerp_order_accounting` (Flutter) and the Moqui `growerp`
backend.

## High-level flow

```mermaid
flowchart TD
    subgraph MKT["MARKETING / OUTREACH (growerp_outreach)"]
        A1[Lead import / discovery<br/>LinkedIn CSV, Apollo, scrapers] --> A2[Campaign create & configure<br/>platforms, templates, limits]
        A2 --> A3[Recipients -> PENDING messages]
        A3 --> A4[AI personalize message<br/>Gemini per platform]
        A4 --> A5[Send<br/>assisted LinkedIn queue / adapters]
        A5 --> A6{Response?}
        A6 -- no --> A7[FAILED / no reply]
        A6 -- yes --> A8[RESPONDED]
        A8 --> A9[Convert prospect to lead<br/>create#User role=lead<br/>OutreachMessage=CONVERTED]
    end

    A9 --> B1

    subgraph CRM["CRM (growerp_sales)"]
        B1[Opportunity created<br/>stage=Prospecting] --> B2[Qualification]
        B2 --> B3[Demo / Meeting]
        B3 --> B4[Proposal]
        B4 --> B5{Convert to order?}
        B5 -- lost --> B6[Closed Lost]
        B5 -- won --> B7[stage=Quote<br/>OpportunityConvertToOrder]
    end

    B7 --> C1

    subgraph SALES["ORDER / ACCOUNTING (growerp_order_accounting, FinDoc)"]
        C1[Sales Order<br/>FinDoc docType=order sales=true<br/>FinDocPrep] --> C2[FinDocCreated -> FinDocApproved]
        C2 --> C3{Physical goods?}
        C3 -- yes --> C4[Shipment<br/>ShipInput->Packed->Shipped->Delivered]
        C3 -- no --> C5
        C4 --> C5[Invoice<br/>docType=invoice<br/>InProcess->Finalized->Sent]
        C5 --> C6[Payment<br/>docType=payment<br/>Proposed->Authorized->Confirmed]
        C6 --> C7[Order FinDocCompleted]
    end

    C7 --> D1[Closed Won]
    B7 -.opportunity stage.-> D1
```

## Stage detail

### Marketing / Outreach
| Stage | Screen / Service | BLoC / event | REST -> backend service | Entity / status |
|---|---|---|---|---|
| Lead import | `growerp_outreach/.../screens/linkedin_lead_import_dialog.dart` | manual upload | `POST ImportExport/companyUsers` -> `import#CompanyUsers` | `User(role=lead)` + `Company` |
| Campaign create | `.../screens/campaign_detail_screen.dart` | `OutreachCampaignBloc` / `OutreachCampaignCreate` | `POST OutreachCampaign` -> `create#OutreachCampaign` | `MarketingCampaign` PLANNED |
| Recipients | campaign_detail_screen / orchestrator | programmatic | `POST OutreachRecipients` -> `import#OutreachRecipients` | `OutreachMessage` PENDING |
| Personalize | backend | — | `POST generate#PlatformMessage` (GeminiAiUtil) | `OutreachMessage.messageContent` |
| Send | `.../screens/linkedin_send_queue_screen.dart` + adapters | `OutreachMessageBloc` | `PATCH OutreachMessage` -> `update#OutreachMessageStatus` | PENDING -> SENT |
| Respond | send queue | `OutreachMessageBloc` | `PATCH OutreachMessage` | SENT -> RESPONDED |
| Convert | `.../services/campaign_automation_service.dart` | — | `POST User` + `PATCH OutreachMessage` | `User(role=lead)`, msg CONVERTED + `convertedPartyId` |

### CRM (Opportunity)
- File: `growerp_sales/lib/src/opportunities/` (`opportunity_bloc.dart`, `opportunity_dialog.dart`).
- Backend: `backend/service/growerp/100/CrmServices100.xml`, entity `mantle.sales.opportunity.SalesOpportunity`.
- Stages: Prospecting -> Qualification -> Demo/Meeting -> Proposal -> Quote -> Closed Won / Closed Lost.
- `OpportunityConvertToOrder` creates a sales-order FinDoc from `estAmount`, `leadUser`, `leadUser.company`; sets stage=Quote.

### Order / Accounting (unified FinDoc)
- File: `growerp_order_accounting/lib/src/findoc/` (`fin_doc_bloc.dart`, `findoc_dialog.dart`).
- Backend: `backend/service/growerp/100/FinDocServices100.xml`.
- One `FinDoc` model covers order / shipment / invoice / payment via `docType` + `sales` flag.
- Unified status: FinDocPrep -> FinDocCreated -> FinDocApproved -> FinDocCompleted (or FinDocCancelled).
  - order: Prep/Created/Approved/Completed
  - shipment: ShipInput -> Scheduled -> Packed -> Shipped -> Delivered
  - invoice: InProcess -> Finalized -> Sent -> PmtRecvd
  - payment: Proposed -> Promised -> Authorized -> Delivered -> Confirmed (gateway via `GatewayPayment`)

## Handoff
Outreach `convertProspectToLead` -> `User(role=lead)` is the boundary; caller then
opens an `Opportunity(stage=Prospecting)` against that `partyId`, after which the CRM
and FinDoc pipeline drives the deal to Closed Won + payment.

## Key files
- Outreach entities/services: `backend/entity/OutreachEntities.xml`, `backend/service/growerp/100/OutreachServices100.xml`
- CRM: `backend/service/growerp/100/CrmServices100.xml`
- FinDoc: `backend/service/growerp/100/FinDocServices100.xml`
- REST contracts: `flutter/packages/growerp_models/lib/src/rest_client.dart`
