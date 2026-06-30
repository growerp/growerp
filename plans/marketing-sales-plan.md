# GrowERP Self-Marketing Sprint — 4 Weeks to 1 New Customer

## Context

Goal: land **1 paying customer** for GrowERP within 4 weeks, by running GrowERP's *own*
marketing/sales modules against itself ("dogfooding"). We have ~4000 LinkedIn profile URLs
(CSV: name, title, company, url), browsermcp ready for ~25 LinkedIn DMs/day, and a configured
Moqui EmailServer for real cold email. Apollo.io is a last-resort enricher only.

GrowERP already ships a near-complete outreach stack — we mostly **configure and run** it, with a
few small build gaps to close. Key existing pieces found:

- **Campaigns**: `OutreachServices100.xml` — `create/update/list/get/delete#OutreachCampaign`,
  `start/pause#CampaignAutomation`, `get#CampaignProgress`, `CampaignMetrics`.
- **Recipients/messages**: `growerp.marketing.OutreachMessage` (has `recipientProfileUrl`,
  `recipientEmail`, `status` PENDING/SENT/RESPONDED/FAILED), `create#OutreachMessage`.
- **AI message gen**: `generate#PlatformMessage` (Gemini, per-platform: LINKEDIN/EMAIL/...).
- **Sending**: `send#OutreachEmail` (Moqui email + unsubscribe), `MCPAutomationServices100.send#OutreachMessageViaBrowser`
  → `LinkedInAutomationServices100.send#LinkedInMessage` (browsermcp localhost:3000).
- **Inbound funnel**: Assessment landing pages (`LandingPageServices100.xml`,
  `pop-rest-store/.../assessmentLandingPage.ftl`) auto-create scored `SalesOpportunity`
  (cold/warm/hot); anonymous **WebsiteChat** widget with AI agent answering.
- **CRM**: `CrmServices100.xml` Opportunity pipeline; Flutter `growerp_sales` opportunities UI.
- **Content**: `MarketingServices100.xml` — MarketingPersona + ContentPlan (PNP) + draft/publish#SocialPost.
- **Control center (ADK)**: `/adk` screens (agents, jobs, actions, approvals, knowledge); scheduled
  cron agents (`AdkAgentConfig.scheduleExpression`), scoped tool allowlists, write-approval governance,
  RAG knowledge base, coordinator/specialist teams.

Realistic funnel math: ~500 LinkedIn DMs (25/day × ~20 working days) + ~2000 emails →
~150 replies → ~15-25 trials → **1-2 customers**. Tight but achievable with strong personalization,
the assessment landing magnet, and an AI SDR catching inbound fast.

---

## Strategy — one funnel, GrowERP-operated

```
4000 CSV ──import──▶ OutreachMessage(PENDING)  ──segment/score──▶ ICP fit
   │                                                                │
   ├─ top ~700  ──AI personalize──▶ LinkedIn DM (browsermcp ≤25/day)
   └─ rest      ──AI personalize──▶ Cold email (send#OutreachEmail ≤~100/day)
                         │
                         ▼  link → Assessment Landing Page
                 auto-scored SalesOpportunity (cold/warm/hot)
                         │
        ┌────────────────┼─────────────────┐
   WebsiteChat AI SDR   email replies   LinkedIn replies
        └──────── triage agent → human handoff → demo/trial → CLOSE
```

ICP: SMB owners / ops managers running on spreadsheets. Lead magnet: the existing assessment
("5 Signs You've Outgrown Spreadsheets") → scored opportunity + 7-step nurture (already drafted in
`docs/marketing_plan.md`).

---

## Control-Center (ADK) agents to stand up

Configure these in `/adk` (Flutter `growerp_adk`) on Hans's GrowERP owner tenant. Use scoped tool
allowlists + `approve` write policy where they touch sends.

1. **Outreach Personalizer** (scheduled, hourly during work hours) — pulls today's PENDING
   `OutreachMessage` batch, calls `generate#PlatformMessage` per recipient (name/title/company),
   writes back `messageContent`. Scope: `*get#OutreachMessages,*update#OutreachMessageStatus,*generate#PlatformMessage`.
2. **GrowERP SDR (website chat)** — `websiteChat='Y'`, RAG-grounded on GrowERP value prop / pricing /
   FAQ / trial steps (ingest via `/adk/knowledge`). Answers visitors, pushes the free trial, and
   `requestHumanHandoff` on buying signals. Model: gemini-2.5-flash.
3. **Lead Triage** (scheduled, every 30 min) — scans `OutreachMessage` RESPONDED + new WebsiteChats +
   new assessment `SalesOpportunity`; ranks by score, drafts a follow-up, notifies Hans in a chat room.
4. **Content/Social** (scheduled, weekly) — generate ContentPlan (PNP) → `draft#SocialPost` →
   `publish#SocialPost` to keep the sending LinkedIn profile warm and credible while DMs go out.
5. **Ops Digest** (cron `0 0 9 * * ?`, reuse `ADK_DEMO_DIGEST` pattern) — daily 9am summary:
   DMs/emails sent, replies, new opportunities, trials, against the 1-customer goal → chat + email.

Sending itself stays a **service scheduler** job (not an LLM agent) for reliability/cost:
`start#CampaignAutomation` flips status; a scheduled job drains PENDING within `dailyLimitPerPlatform`
(25 LinkedIn / ~100 email) calling `send#OutreachMessageViaBrowser` / `send#OutreachEmail`.

---

## Week-by-week

### Week 1 — Load, build the two gaps, pilot
- **Build gap A — bulk recipient importer** (only real code needed): add
  `import#OutreachRecipients` in `OutreachServices100.xml` (or extend `ImportExportServices100`),
  CSV → `OutreachMessage(status=PENDING, recipientName/Handle/ProfileUrl/Email)` tied to the campaign.
  Currently `create#OutreachMessage` is one-at-a-time — this is the blocker for 4000 rows.
- **Build gap B — verify/implement the send scheduler loop**: confirm a job drains PENDING messages
  respecting `dailyLimitPerPlatform` and calls `send#OutreachMessageViaBrowser` (LinkedIn) /
  `send#OutreachEmail`. `MCPAutomationServices100.process#CampaignAutomation` is an `interface` only —
  wire/confirm its implementation.
- Create campaign: `create#OutreachCampaign` (platforms=[LINKEDIN,EMAIL], dailyLimitPerPlatform=25,
  link the assessment `landingPageId`, `expectedRevenue`, ICP `targetAudience`).
- Import the 4000 CSV → PENDING messages. Segment/score by title fit (rule-based or a one-shot AI
  classify). Tag top ~700 LINKEDIN, rest EMAIL.
- Stand up ADK agents 1, 2, 5 (Personalizer, SDR, Digest). Ingest GrowERP knowledge for the SDR.
- **Pilot: 5 LinkedIn + 5 email** — verify browsermcp DMs land (screenshot), email delivers,
  landing-page click → SalesOpportunity created. Fix before scaling.

### Week 2 — Ramp sending
- `start#CampaignAutomation`. Daily: 25 LinkedIn DMs + ~100 emails, AI-personalized.
- Add ADK agents 3, 4 (Triage, Content/Social). Publish 2-3 social posts.
- Monitor via `get#CampaignProgress` + Ops Digest. Watch LinkedIn for throttling; back off if flagged.
- For URL-only contacts lacking email → **Apollo (last resort)**: enrich email, register Apollo as an
  `AdkMcpServer` or batch-export → import as EMAIL recipients.

### Week 3 — Optimize + work the pipeline
- A/B the message template (subject line, opener) via `generate#PlatformMessage` variants; compare
  response rates in `CampaignMetrics`.
- Triage agent surfaces warm/hot opportunities daily → Hans books demos. Move stages in `growerp_sales`
  Opportunity UI (Qualified → Proposal).
- Re-send next-best segment; second-touch the non-responders (nurture email 2-3 from the 7-step sequence).

### Week 4 — Close
- Push trials to paid: targeted "see it on your data" demos for warm/hot opportunities.
- Send the day-14 "breakup" email to stalled cold leads (sequence step 7) to surface fence-sitters.
- Final digest + retro: response/conversion rates, cost per reply, what to keep.

---

## Apollo.io — last resort only
Use **only** to fill missing emails for URL-only / unenriched contacts. Path: register as an external
MCP server (`moqui.adk.AdkMcpServer` + per-agent `AdkAgentMcpServer`) so an agent can call it, or do a
batch export and import via the gap-A importer. Do not make it the primary channel.

---

## System improvements to propose (ranked)
1. **Bulk OutreachMessage importer** (`import#OutreachRecipients`) — required for 4000 URLs; today only
   single `create#OutreachMessage` exists. *(Built in Week 1.)*
2. **Complete the campaign send scheduler** — implement `process#CampaignAutomation` to drain PENDING
   within daily limits across LinkedIn + email. *(Verified/built Week 1.)*
3. **Email in `send#OutreachMessageViaBrowser`** — currently returns "Email platform not yet
   implemented"; route EMAIL to existing `send#OutreachEmail` so one automation path covers all platforms.
4. **Auto-create SalesOpportunity from RESPONDED OutreachMessage** — close the CRM loop; today replies
   only bump `CampaignMetrics`, not the pipeline.
5. **Configurable base/unsubscribe URL** — `send#OutreachEmail` hardcodes `https://growerp.com/landing/...`
   and unsubscribe (TODO at `OutreachServices100.xml:1016`); make it a system property.
6. **Inbound reply detection** — LinkedIn/email replies are manually marked `RESPONDED`; add polling/webhook
   to auto-flag so the Triage agent reacts in real time.
7. **Ship a reusable "Sales SDR" ADK agent template** + a GrowERP-tuned website-chat config, so any tenant
   can run this funnel out of the box (productizes this very sprint).

---

## Verification
- **Data**: `moqui_rest_call` (read-only MCP) to confirm `OutreachCampaign`, ~4000 `OutreachMessage`
  rows, and `CampaignMetrics` incrementing. Endpoints: `/OutreachCampaigns`, `/OutreachCampaign/progress`,
  `e1/growerp.marketing.OutreachMessage`.
- **Pilot gate**: 5+5 send — browsermcp screenshot proves LinkedIn DM posted; test inbox proves email
  delivered; clicking the landing link creates a scored `SalesOpportunity` (check `/Opportunity`).
- **Daily**: Ops Digest + `get#CampaignProgress` (sent / pending / failed / responseRate).
- **Success criteria**: ≥1 signed customer (trial→paid) in 4 weeks. Leading indicators tracked weekly —
  reply rate ≥10%, ≥15 trials started, ≥3 warm/hot opportunities in pipeline by end of Week 3.
- Run `melos analyze` + relevant integration tests after the Week-1 backend additions; verify XML-mini-language
  style (Groovy only where the Java email/HTTP API is needed).
```

---

## Implemented (Week-1 build — done, verified on live backend)

Backend gaps closed and registered (hot-loaded; all `xmllint`-clean):

- **Bulk recipient importer** — `import#OutreachRecipients` (CSV → PENDING `OutreachMessage`),
  `OutreachServices100.xml`; REST `POST /OutreachRecipients`.
- **Send scheduler loop** — `process#CampaignAutomation` (drains PENDING per platform ≤ `dailyLimitPerPlatform`/day,
  sends + bumps metrics) and `run#AllCampaignAutomation` (per-owner dispatcher), `MCPAutomationServices100.xml`.
  Both accept an explicit `ownerPartyId` so the headless ServiceJob works without a logged-in user.
  `run#AllCampaignAutomation` is `authenticate="anonymous"` and logs in as the owner's main-company
  administrator (`GROWERP_M_ADMIN`, looked up via `OwnerPersonDetailAndCompany`) before any work,
  so nested authenticated services run with proper authz. REST `POST /OutreachCampaign/process`.
- **Email send path** — EMAIL branch of `send#OutreachMessageViaBrowser` now sends via Moqui email
  (was "not yet implemented"); operates on the existing message (no duplicate record).
- **Personalizer write service** — `update#OutreachMessageContent` (sets body of a PENDING message only),
  REST `PATCH /OutreachMessageContent`.

Control-center setup (load after GROWERP exists):
`backend/data/GrowerpMarketingAgentsData.xml` — 5 ADK agents for `ownerPartyId=GROWERP`
(Outreach Personalizer, GrowERP SDR / website chat, Lead Triage, Content & Social, Marketing Ops Digest)
+ `ServiceJob GrowerpCampaignAutomation` (hourly 9-17) passing `ownerPartyId=GROWERP`.
Load: `java -jar moqui.war load types=install file=runtime/component/growerp/data/GrowerpMarketingAgentsData.xml`.
Set each scheduled agent's `scheduleChatRoomId` in `/adk` to receive output; agents need an LLM key.

Still operational/runtime (needs Hans): create the campaign + import the real CSV, ingest GrowERP
knowledge for the SDR, run the 5+5 pilot before `start#CampaignAutomation`.

## Week 2 — message template (approved: pain-led / assessment CTA / LinkedIn link-on-reply)

Live state: landing page `ERP_LANDING_PAGE` (pseudoId `erp-landing-page`, assessment
`ERP_READINESS_ASSESSMENT`, Published) → `assessmentUrl = https://growerp.com/landing/erp-landing-page`.
Campaign already exists: `marketingCampaignId=100000` "4 week sprint" (platforms `[LINKEDIN]`, no template).

Apply to campaign 100000 via `update#OutreachCampaign` (UI or REST `PATCH /OutreachCampaign`):
- `platforms`: `["LINKEDIN","EMAIL"]`, `dailyLimitPerPlatform`: `25`, `landingPageId`: `ERP_LANDING_PAGE`
- `emailSubject`: `{company}: outgrowing spreadsheets?`
- `messageTemplate` (link-free seed):
  `{firstName}, quick question about {company}. Most {title}s I speak with start on spreadsheets and a few
  separate tools — fine until it isn't: numbers that don't reconcile, no live view of stock or cash, hours
  re-keying. We made a 2-minute check — "5 Signs You've Outgrown Spreadsheets" — that tells you whether
  {company} is at that tipping point. Worth me sending it over?`
- `platformSettings`: `{"LINKEDIN":{"actionType":"send_dms","dailyLimit":25},"EMAIL":{"actionType":"send_email","dailyLimit":100}}`

Done in code this week:
- `process#CampaignAutomation` now tolerates non-JSON `platforms` (`[LINKEDIN]` as well as `["LINKEDIN"]`
  and CSV) — campaign 100000's value would otherwise have thrown in JsonSlurper.
- Personalizer instruction now carries the channel rules: LinkedIn = question, no URL (link-on-reply);
  EMAIL = include `https://growerp.com/landing/erp-landing-page` + "Hans, GrowERP" sign-off.
  (Re-load `GrowerpMarketingAgentsData.xml` to apply the new instruction.)

Full template detail (subjects A/B, example DM1/email/DM2 outputs, A/B + compliance) in the plan-mode
file `~/.claude/plans/write-a-marketing-and-cheerful-hejlsberg.md` § "Week 2 — Message Template Proposal".
