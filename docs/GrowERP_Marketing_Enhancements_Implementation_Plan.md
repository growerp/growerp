# GrowERP Marketing Enhancements — Implementation Plan

**Scope:** engineering plan for the 9 system enhancements listed in [GrowERP_Marketing_Sales_Plan.md](./GrowERP_Marketing_Sales_Plan.md) §10, in the suggested build order **7 → 2 → 3 → 1 → 4 → 8 → 9 → 5 → 6**.
**Date:** July 2026

All entity/service/file references below were verified against the codebase.

---

## Shared conventions (apply to every item)

- **Backend**: Moqui service XML mini-language wherever possible; Groovy only for Java API calls. Services in `backend/service/growerp/100/*Services100.xml`, entities in `backend/entity/*.xml`, REST exposure in `backend/service/growerp.rest.xml`. Anonymous endpoints: service `authenticate="false"`/`"anonymous-all"` + `<resource require-authentication="anonymous-all">`.
- **Multi-tenant**: every new entity carries `ownerPartyId`; anonymous flows resolve owner via `ProductStore.organizationPartyId → Party.ownerPartyId` (pattern: `submit#WebsiteChat`, `ChatServices100.xml`).
- **Lead creation**: `PartyServices100.create#User` with `role: 'Lead'`, `userGroupId: 'GROWERP_M_LEAD'`, **no loginName** (no login/password email); reuse existing party by email ContactMech first.
- **Email**: `org.moqui.impl.EmailServices.send#EmailTemplate async="true"`; template = `moqui.basic.email.EmailTemplate` seed row + body screen in `backend/screen/email/`; always guard with `emailServer && emailServer.mailPassword != 'SMTP_PASSWORD'`.
- **Scheduled batch**: clone `SocialPostPublishingServices100.publish#ScheduledSocialPosts` — `authenticate="false" allow-remote="false"`, iterate all tenants, resolve per-record `ownerPartyId`, `ignore-error="true"` per item; ServiceJob seed row in `GrowerpAaSetupData.xml`.
- **Frontend**: freezed models in `growerp_models` (string defaults `''`, never real values — non-empty defaults leak into PATCH); retrofit client method; `melos build` after model changes; `melos l10n` for strings. Lists follow the UserList pattern (ListFilterBar + StyledDataTable + FAB + row-tap detail); detail dialogs use `Dialog` + `popUp` from growerp_core. Every interactive widget gets a `Key`; keys must be findable in both mobile (412px) and desktop (1280px) CI layouts; route-scope keys to avoid collisions.
- **Tests**: integration tests in `<package>/example/integration_test/` using `CommonTest`; test class exposes `add`/`update`/`delete`/`check` statics.

**Phases:** A: #7+#2 (now) · B: #3 · C: #1 · D: #4 · E: #8+#9 · F: #5+#6.
**Dependencies:** #9 consumes #2's summary service; #8 allowlists reference services from #1/#2/#9; #3's form submissions enroll into #1's sequences once available.

---

## #7 Opportunity nextStep → Activity auto-link (S) — Phase A ✅ shipped

**Goal:** setting/changing `nextStep` on an opportunity automatically creates a linked to-do Activity, so follow-ups land in the assignee's task list.

**Backend** (`backend/service/growerp/100/`):
1. `ActivityServices100.xml create#Activity`: accept optional `activity.opportunityId`; after the WorkEffort is created, if present, `create#mantle.sales.opportunity.SalesOpportunityWorkEffort` (same call `create#Event` already makes, ~line 75). The read side already exists: view `growerp.workEffort.WorkEffortOpportunityAndParty`.
2. `CrmServices100.xml create#Opportunity`: after creation, if `opportunity.nextStep` non-empty → call `create#Activity` with `activityType: 'todo'`, `activityName: nextStep`, `opportunityId`, assignee = `opportunity.employeeUser?.partyId` else current user.
3. `CrmServices100.xml update#Opportunity`: in the existing field-diff, when `nextStep` is present and differs from the stored value → same call.

**Frontend:** none required (tasks appear via existing activity lists / `todoActivities` stat).

**Tests:** existing opportunity integration tests stay green; REST-level check that `SalesOpportunityWorkEffort` + a `WetTask` WorkEffort exist after create/update with `nextStep`.

---

## #2 Pipeline board + funnel report (M) — Phase A ✅ shipped

**Goal:** kanban view of opportunities by stage with drag-to-move, plus a per-stage funnel summary (count, total, weighted value).

**Facts:** stage stored on `mantle.sales.opportunity.SalesOpportunity.opportunityStageId`; master `SalesOpportunityStage` seeded in `GrowerpAaSeedData.xml`: Prospecting(1) … Quote(5), Deleted (soft delete). Frontend list `growerp_models/lib/src/models/opportunity_stages_model.dart` additionally has `Closed Won`/`Closed Lost` — **not in backend seed** (data written with those stageIds violates nothing today because the FK target is missing only for new values; reconcile in seed).

**Backend:**
1. `GrowerpAaSeedData.xml`: add `SalesOpportunityStage` rows `Closed Won` (seq 6), `Closed Lost` (seq 7); move `Deleted` to seq 99.
2. `CrmServices100.xml` new `get#OpportunitySummary`: iterate stages by `sequenceNum` (exclude `Deleted`), aggregate `growerp.crm.OpportunityAndParties` (filter `ownerPartyId`): count, Σ `estAmount`, Σ `estAmount × estProbability / 100`. Out: `stageSummary` list.
3. `growerp.rest.xml`: sub-resource `Opportunity/summary` (GET).

**Frontend:**
4. `growerp_models`: freezed `OpportunitySummaryItem` (stageId, sequenceNum, count, totalAmount, weightedAmount); retrofit `getOpportunitySummary()`; `melos build`.
5. `growerp_sales`: bloc event `OpportunitySummaryFetch` + `summary` on state; new `views/opportunity_pipeline.dart` (stage columns, `LongPressDraggable` cards, `DragTarget` drop → `OpportunityUpdate(copyWith(stageId))`; column header = count + total) and `widgets/sales_funnel_chart.dart` (fl_chart BarChart; structure per `revenue_expense_chart_mini.dart` in growerp_order_accounting).
6. `admin` app: menu route for the pipeline view; existing opportunity list untouched.

**Tests:** new pipeline integration test in `growerp_sales/example/integration_test`: seed 2 opportunities in different stages, open pipeline, assert cards in correct columns; change stage via dialog, assert card moved. No drag simulation on CI (flaky at 412px).

---

## #3 Website SEO metadata + lead-capture form builder (M) — Phase B ✅ shipped

**Goal:** per-page `<title>`/meta description/OG tags on the generated website; embeddable lead-capture forms that create Lead users.

**Facts:** website pages are Moqui WikiPages backed by DbResource files `${rootPageLocation}/content/${pagePath}.md.ftl` (or `.html.ftl`); `WebsiteServices100.xml` derives page title by regex (`title: … -->` comment or first `#` heading) — nothing else stored. The `<head>` is rendered once per store in `pop-rest-store/template/store/{modern,legacy}/root.html.ftl` (meta description hardcoded; store 100000 special-cased). `pop-rest-store/screen/store/content.xml` resolves the page (and title) *before* rendering the header — the insertion point.

**SEO:**
1. Extend the existing comment front-matter convention with `description:` and `ogImage:` lines; parse in `WebsiteServices100.xml` get/upload WebsiteContent alongside title.
2. `content.xml`: put `pageTitle`, `pageDescription`, `pageOgImage`, canonical URL into template scope; `root.html.ftl` (both modern and legacy): render per-page `<title>`, `<meta name="description">`, OG/twitter tags, `<link rel="canonical">`, falling back to store defaults.
3. Store-wide defaults as new `ProductStoreSetting` types (e.g. `PsstMetaDescription`), replacing the hardcoded strings.
4. `growerp_website`: SEO fields (title/description/og image) on the content edit dialog; `Content` model gains `description`/`ogImage` (`''` defaults).

**Form builder:**
5. New entities `growerp.website.WebsiteForm` (formId, ownerPartyId, productStoreId, name, title, submitLabel, successMessage, emailSequenceId*) and `WebsiteFormField` (formId, fieldId, seq, label, fieldType text/email/phone/textarea, required). *sequence link activates with #1.
6. Anonymous `submit#WebsiteForm` in `WebsiteServices100.xml`: owner resolution + lead creation copied from `submit#WebsiteChat`; store submission values (new `WebsiteFormSubmission` entity) and notify owner (NOTIFICATION email template).
7. REST: `anonymous-all` resource `WebsiteForm` (GET definition for rendering, POST submit) in `growerp.rest.xml`.
8. FTL renderer in pop-rest-store content templates: `<div data-growerp-form="formId">` markers in page content render the form (pattern: chatWidget.html.ftl shared include).
9. `growerp_website` UI: form list + dialog (fields editor), per list/dialog design rules.

**Tests:** website integration test extends content edit with SEO fields; REST test of anonymous submit creating lead.

---

## #1 Native email nurture-sequence engine (L) — Phase C ✅ shipped

> Shipped notes: processor sends via `send#EmailTemplate` directly (not `send#OutreachEmail`,
> which needs an authenticated user + campaign); browser endpoints live at `/nurture/*`
> (pop-rest-store screen) and the previously dead outreach unsubscribe links now point there
> with the tenant's store hostname. Enrollment hooks v1 = website forms
> (`WebsiteForm.emailSequenceId`); chat/assessment/register hooks deferred until a per-owner
> default-sequence setting exists.

**Goal:** multi-step drip campaigns run natively (enroll on capture, timed sends, unsubscribe, open/click metrics) — replaces BirdSend/MailerLight (`registerAdd#UserToGroup` external push, `BirdSendServices100.xml`/`MailerLightServices100.xml`).

**Backend:**
1. Entities (`MarketingEntities.xml` or new `NurtureEntities.xml`, package `growerp.marketing`):
   - `EmailSequence`: sequenceId, ownerPartyId, marketingCampaignId?, name, status ACTIVE/PAUSED.
   - `EmailSequenceStep`: sequenceId, stepSeq, delayDays, subject, bodyHtml (template vars `{name}`, `{company}` as in outreach).
   - `EmailSequenceEnrollment`: enrollmentId, sequenceId, ownerPartyId, partyId, emailAddress, currentStep, status ACTIVE/COMPLETED/UNSUBSCRIBED/CONVERTED, nextSendDate, opens, clicks.
2. Services (`NurtureServices100.xml`): CRUD + `enroll#EmailSequence` (dedupe by email+sequence) + `unsubscribe#Enrollment` (anonymous, token = enrollmentId+hash).
3. Processor `process#DueSequenceEmails`: clone the `publish#ScheduledSocialPosts` batch pattern; select ACTIVE enrollments with `nextSendDate <= now`; send via the `send#OutreachEmail` machinery (`OutreachServices100.xml` ~1272 — reuse its unsubscribe-link insertion and CampaignMetrics update; fix its hardcoded `https://growerp.com` base URL via ProductStoreSetting/Interface config while here); advance `currentStep`, set next `nextSendDate`, COMPLETED at end. ServiceJob seed (cron 15 min) in `GrowerpAaSetupData.xml`.
4. Tracking: anonymous endpoints `track/open/{enrollmentId}/{stepSeq}` (1×1 pixel) and `track/click/{enrollmentId}/{stepSeq}?url=` (redirect), incrementing enrollment counters.
5. Enrollment hooks: `submit#WebsiteChat` lead path, `submit#Assessment` completion, #3 form submit, `register#User` trial signup (welcome/onboarding sequence). Auto-mark CONVERTED on trial registration with matching email.
6. Migration: call sites of BirdSend/MailerLight switch to `enroll#EmailSequence`; keep those services for tenants that still want external ESPs.

**Frontend (`growerp_marketing`):** sequence list + dialog (steps editor with delay/subject/body), enrollment counts + open/click columns.

**Tests:** service-level: enroll → force `nextSendDate` past → run processor → assert step advanced and OutreachMessage recorded (works without SMTP because email guard no-ops; assert enrollment state, not delivery).

---

## #4 Self-serve pricing page + plan-tier checkout (M–L) — Phase D ✅ shipped (partial)

> Shipped: anonymous `get#SubscriptionPlans` + `/rest/s1/growerp/100/SubscriptionPlans`;
> pricing pages embed plan cards with `<div data-growerp-plans></div>` (plansWidget.html.ftl);
> `renew#TenantSubscription` card params now optional (reuses the stored payment method);
> daily `renew#DueTenantSubscriptions` auto-renews subscriptions expiring within ±3 days and
> sends the new PAYMENT_FAILED dunning email on charge failure.
> Deferred: a pre-expiry in-app "Subscription" settings screen — `PaymentSubscriptionDialog`
> is coupled to the login/AuthBloc flow; reusing it outside the expiry paywall needs an
> auth-flow refactor. The expiry paywall itself already handles plan choice + payment.

**Goal:** visitor sees pricing, picks a plan, pays; trial converts without manual intervention; renewals charge automatically with dunning.

**Facts:** `TenantServices100.create#Tenant` seeds a 14-day trial Subscription (product `GROWERP_SMALL_PLAN`, `externalSubscriptionId = ownerPartyId`, stored in GROWERP tenant). `check#TenantSubscription` yields `daysRemaining`/`subscriptionStatus`; `renew#TenantSubscription` (plan + card) creates PaymentMethod and extends one month — invoked from `login#User`. Stripe is charge-based (`mantle-stripe` `authorizeAndCapture#Payment`; gateway gated by system property `paymentGatewayConfigId=STRIPE`). Paywall UI exists: `growerp_core .../views/payment_subscription_dialog.dart`. Public anonymous checkout exists: `AccountingServices100.checkOut#OnePage`.

**Work:**
1. Seed plan products `GROWERP_MEDIUM_PLAN`, `GROWERP_LARGE_PLAN` (+ `ProductPrice` purchase prices) next to `GROWERP_SMALL_PLAN`; a `get#SubscriptionPlans` service returning tiers+prices for UI and pricing page.
2. Public pricing page: website content page listing tiers (data via anonymous `get#SubscriptionPlans`), CTA → trial signup (existing) — actual payment happens in-app where the tenant is known.
3. In-app upgrade: surface `PaymentSubscriptionDialog` from a Subscription/Plan settings screen (not only the expiry paywall); show current plan + daysRemaining from `check#TenantSubscription`.
4. Auto-renewal: monthly ServiceJob `renew#DueTenantSubscriptions` — for subscriptions expiring in ≤3 days with a stored PaymentMethod, charge via Stripe `authorizeAndCapture#Payment` and extend; on failure send dunning email (new `PAYMENT_FAILED` template), retry ×3 over grace week, then mark expired (existing login paywall takes over).
5. Keep charge-based Stripe; defer Stripe Billing/webhooks (bigger migration, not needed for v1).

**Tests:** service tests for plan listing + renewal date math; integration: upgrade dialog reachable outside expiry; dummy-card path on `.org` staging.

---

## #8 ADK marketing-agent toolset (M) — Phase E ✅ shipped

> Shipped: `AdkServices100.enable#MarketingAgentTeam` clones the 5 GROWERP marketing
> agents into any tenant (idempotent upsert by owner+agentName; schedules cloned disabled
> except the Ops Digest), REST `AdkAgentConfig/EnableMarketingTeam`, rocket button in the
> agents list; OPS_DIGEST allowlist/prompt now include `get#OpportunitySummary` +
> `get#MarketingDashboard`, LEAD_TRIAGE can `enroll#EmailSequence` + `create#Activity`.

**Goal:** every tenant can enable the marketing agent team; agents can use the new services from #1/#2/#9.

**Facts:** agent tools = FunctionTools assembled in `AdkManager.assembleFunctionTools(allowWrites)` (EmailTool/GithubTool pattern) + per-agent McpToolset governed by `AdkAgentConfig.toolMode`/`serviceAllowlist` glob patterns. Five marketing agents already seeded for owner GROWERP in `backend/data/GrowerpMarketingAgentsData.xml`: OUTREACH_PERSONALIZER, SDR (website chat), LEAD_TRIAGE, CONTENT_SOCIAL (approve-gated), OPS_DIGEST. Scheduler: `AdkSchedulerServices.sync#AgentJob`/`run#ScheduledAgent`.

**Work — config-first, minimal code:**
1. `enable#MarketingAgentTeam` service: clones the 5 seeded agent configs for a given `ownerPartyId` (agent instructions parameterized by tenant), runs `sync#AgentJob` per schedule-enabled config. Expose in agents app ("Enable marketing team" action).
2. Extend `serviceAllowlist`s: OPS_DIGEST gets `*get#OpportunitySummary` (#2) and `*get#MarketingDashboard` (#9); LEAD_TRIAGE gets `*enroll#EmailSequence` (#1) and `*create#Activity`; CONTENT_SOCIAL unchanged (approval flow already correct).
3. Weekly KPI digest: OPS_DIGEST `schedulePrompt` updated to compile funnel + campaign + pipeline numbers from the new services and post to the owner's chat room (and email via EmailTool where write-enabled).
4. New FunctionTool only if a needed capability can't be expressed as an allowlisted Moqui service (follow EmailTool template: static methods + `@Schema` params incl. `ownerPartyId`, own thread + `internalLoginUser('SystemSupport')`). Remember: AgentTool requires non-null `description`; description edits need coordinator rebuild.

**Tests:** enable-team service test (configs cloned, jobs synced); agent smoke via ADK DevUI.

---

## #9 Marketing/sales dashboard (M) — Phase E ✅ shipped

> Shipped: `get#MarketingDashboard` (funnel via get#OpportunitySummary, campaign rollup,
> lead count, assessment completions, nurture enrollment counts) + REST GET
> `MarketingDashboard`; admin dashboard `/marketing` tile auto-upgrades to a graphic tile
> rendering `MarketingDashboardChartMini` (funnel bars + counters, reuses SalesFunnelChart).

**Goal:** one dashboard pane: funnel by stage, campaign metrics, new leads, assessment completions, trial signups.

**Facts:** admin dashboard = `admin/lib/views/admin_dashboard_content.dart` — tiles from MenuConfigBloc; `chartBuilder(route)` maps routes to chart widgets (RevenueExpenseChartMini today); stats ride on `authenticate.stats` (`stats_model.dart` already carries `opportunities`, `leads`); backend aggregate pattern = `GeneralServices100.get#Stats` + persisted `growerp.general.Statistics` per owner.

**Work:**
1. Backend `get#MarketingDashboard` (`MarketingServices100.xml`): opportunities by stage (call `get#OpportunitySummary` from #2), CampaignMetrics rollup (view `MarketingCampaignAndMetrics`), leads created last 7/30 days, assessment completions, active nurture enrollments (#1 when present). REST GET `MarketingDashboard`.
2. Frontend: `MarketingDashboardChartMini` (funnel BarChart) in `growerp_marketing`; register route in admin `chartBuilder`; menu item with `tileType: graphic`. Optional Stats-model additions for cheap counters (follow `get#Stats` store pattern).

**Tests:** dashboard renders with seeded data; summary numbers match list counts.

---

## #5 Appointment booking (M) — Phase F ✅ shipped

> Shipped: `AppointmentSlot` entity + management CRUD, anonymous `Booking` REST
> (GET available slots by store, POST book), public `/booking` page on the generated
> website (slot picker + form), booked slots become WetEvent WorkEfforts with the lead
> attached, APPOINTMENT_CONFIRM emails to both sides; warm/hot assessment results emails
> include a "Book a free consultation" button; Booking Slots admin screen + menu row.

**Goal:** warm/hot leads book a demo slot; booking creates a calendar event linked to the lead and opportunity.

**Facts:** nothing exists. Reusable: `create#Event` (`ActivityServices100.xml` ~75) creates WetEvent WorkEffort + `SalesOpportunityWorkEffort` + `WorkEffortParty` attendees — the appointment record itself. `submit#Assessment` end-of-service has respondent identity + `leadStatus` (hook). `LandingPage` entity already has `ctaActionType`/`ctaButtonLink`. No Flutter calendar widget dependency exists (hotel uses a custom gantt).

**Work:**
1. Entity `growerp.marketing.AppointmentSlot` (slotId, ownerPartyId, startDateTime, endDateTime, status AVAILABLE/BOOKED, workEffortId?) — deliberately simpler than the hotel asset-rental machinery.
2. Services: `get#AvailableSlots` (anonymous, by owner + date range), `book#Appointment` (anonymous): reuse-or-create lead (chat pattern), mark slot BOOKED, `create#Event` with lead as attendee (+ opportunity link if one exists), send `APPOINTMENT_CONFIRM` email template to both sides.
3. Hooks: `ASSESSMENT_RESULTS` email gains a booking link when `leadStatus` warm/hot; `LandingPage.ctaActionType='booking'`.
4. Public booking page: FTL screen in pop-rest-store (slot picker, name/email form).
5. Admin UI (`growerp_marketing`): slot management list + dialog (recurring weekly slots generator optional v2).

**Tests:** anonymous book flow via REST (slot → booked, WorkEffort exists, lead created); double-booking rejected.

---

## #6 Social engagement monitor (M) — Phase F

**Goal:** record likes/comments/shares/DM-replies per SocialPost as signals; convert signals to leads and follow-up tasks.

**Facts:** `MarketingEntities.xml` SocialPost holds publish state only. Platform creds live in `PlatformConfiguration` (`OutreachEntities.xml`). Per-platform HttpClient call pattern: `SocialPostPublishingServices100.xml`.

**Work:**
1. Entity `growerp.marketing.SocialEngagement`: engagementId, ownerPartyId, postId, platform, engagementType LIKE/COMMENT/SHARE/DM_REPLY, userName, userProfileUrl, note, status NEW/CONTACTED/CONVERTED, createdDate.
2. Services: `record#SocialEngagement` (manual entry v1), `convert#EngagementToLead` (create Lead user + follow-up `create#Activity` todo, set CONTACTED). Roll counts into `CampaignMetrics`.
3. v2: platform pollers per the HttpClient publisher pattern where read APIs exist (LinkedIn/X API access limitations make manual-first pragmatic).
4. UI (`growerp_marketing`): engagement list per SocialPost (from post detail), "convert to lead" action.

**Tests:** record → convert creates lead + activity; CampaignMetrics increments.

---

## Effort & sequence recap

| Phase | Items | Effort |
|---|---|---|
| A (now) | #7 (S) + #2 (M) | ~1–2 wk |
| B | #3 SEO + forms | ~2 wk |
| C | #1 nurture engine | ~3–4 wk |
| D | #4 plan checkout + dunning | ~2–3 wk |
| E | #8 agents + #9 dashboard | ~2–3 wk |
| F | #5 booking + #6 engagement | ~3 wk |
