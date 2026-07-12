# GrowERP Marketing & Sales Plan

**Status:** Master go-to-market plan — consolidates and extends [marketing_plan.md](./marketing_plan.md), [MarketingProposal.md](./MarketingProposal.md) and [SocialMediaLeadSystem.md](./SocialMediaLeadSystem.md)
**Principle:** GrowERP markets and sells GrowERP *using GrowERP*. Every activity in this plan runs on a GrowERP module. Where a step cannot yet run on GrowERP, it is listed in [Section 10: System Enhancements](#10-system-enhancements-required).
**Date:** July 2026

---

## 1. Executive Summary

GrowERP is an open-source (CC0), AI-native, multi-platform ERP for small and medium businesses, distributed as a hosted multi-tenant SaaS with a free 2-week trial (no credit card) and as free self-hosted software.

**Objective (12 months):**
- Grow trial signups to a predictable weekly flow and convert trials to paying hosted tenants.
- Build a developer/contributor community that compounds product velocity and generates services revenue.
- Establish "AI-agent-first ERP" as GrowERP's recognizable category position.

**Strategy in one paragraph:** Lead with the already-built assessment/scorecard funnel and AI content engine to generate inbound SMB leads; run niche-led campaigns for one flagship vertical per quarter; grow the open-source community as a parallel acquisition and credibility channel; and position the ADK Agent Control Center as the headline differentiator against both legacy ERPs and closed SaaS. All execution is dogfooded through `growerp_marketing`, `growerp_outreach`, `growerp_sales`, `growerp_activity`, `growerp_website` and moqui-adk agents — making the company itself the best case study.

**Headline KPIs:** weekly trial signups · trial→paid conversion % · MRR from hosted tenants · GitHub stars/contributors · assessment completions · pipeline value (weighted).

---

## 2. Positioning & Messaging

### Core value proposition

> **Stop managing spreadsheets. Start growing your business — with an open-source ERP that installs in minutes, runs everywhere, and works for you with AI agents.**

### Positioning against alternatives

| Alternative | Their weakness | GrowERP counter-message |
|---|---|---|
| Spreadsheets / patchwork tools | Errors, no real-time visibility, doesn't scale | "One system, one truth. Orders, stock, invoices, accounting — connected." |
| Legacy ERP (SAP B1, NetSuite, Dynamics) | Multi-year, over-budget implementations; per-seat license fees | "Live in a day, not a year. Zero license fees — CC0 public domain." |
| Odoo / ERPNext (open-source ERP) | Odoo's open core is limited, enterprise features paid; web-first UIs | "Truly free (CC0, even patent-granted). Native apps on Web, Android, iOS, Windows, macOS, Linux from one codebase." |
| Closed vertical SaaS (hotel PMS, clinic software, LMS) | Point solutions; data silos; no accounting integration | "A vertical app *plus* full ERP underneath — reservations and the general ledger in the same system." |

### Message house per segment

| Segment | Primary message | Proof points |
|---|---|---|
| SMB horizontal | "The all-in-one ERP for ambitious SMBs" | Free trial in 2 minutes; demo data; 6 platforms; Stripe payments; auto-generated business website |
| Verticals | "Built for your industry, backed by a full ERP" | hotel, freelance, elearner, health, support apps; shared accounting core |
| Developers / open-source | "The extensible ERP platform: Flutter building blocks + Moqui backend, CC0" | 41+ docs, building-block architecture, 50% faster app development, no CLA friction |
| AI-agent-first buyers | "The ERP that works for you: governed AI agents inside your business system" | Agent Control Center, scheduled agents, approval/governance workflow, invoice scan, AI landing pages |

**Tagline candidates:** "Grow your business, not your admin." / "The AI-native open-source ERP."

---

## 3. Target Segments & Personas

Each persona below is created and maintained as a **MarketingPersona** in `growerp_marketing` (Marketing → Personas), so the AI content engine (Content Plans, Social Posts) generates against real, versioned avatars.

### 3.1 SMB horizontal — "Overwhelmed Olivia"
Owner/GM of a 5–50 person product or service business. Runs the company on spreadsheets + accounting package + email. Pain: double entry, no stock visibility, month-end chaos. Buys when shown time saved and a credible migration path. **App:** admin.

### 3.2 Vertical operators — one flagship per quarter
- **Hotel Henri** — independent hotel/guesthouse manager (5–80 rooms). Pain: OTA-only visibility, paper housekeeping, separate books. **App:** hotel.
- **Freelance Fiona** — consultant/agency of 1–10. Pain: time tracking, project invoicing. **App:** freelance.
- **Educator Elena** — course creator/training company. Pain: enrollment + content + billing in three tools. **App:** elearner + courses.
- (health, support follow the same playbook later.)

### 3.3 Developer / integrator — "Builder Ben"
Flutter or Java/Groovy developer, freelancer or small software house, wants to ship business apps fast without writing an ERP backend. Motivations: CC0 license (resell without restriction), building blocks, documented patterns. Converts to: contributor, integrator/partner, hosted-tenant referrer.

### 3.4 AI-forward operator — "Automation Aaron"
Tech-savvy founder/ops lead who evaluates software by "what can the AI do for me." Wants agents that draft content, chase invoices, summarize the business — with governance. **App:** agents (Agent Control Center) + admin.

---

## 4. Funnel Architecture — the Dogfood Map

Every funnel stage runs on a GrowERP capability. Gaps are marked **[Gap #n]** and defined in Section 10.

| Stage | Activity | GrowERP feature that executes it |
|---|---|---|
| **Awareness** | Pain-News-Prize social posts (Mon/Wed/Fri) per persona | `growerp_marketing`: MarketingPersona → ContentPlan → SocialPost (AI draft + human "icing") |
| | Multi-platform posting & cold DMs (LinkedIn primary, X, Substack) | `growerp_outreach`: campaigns, platform adapters, daily rate limits |
| | Blog/SEO articles on generated website | `growerp_website` Content pages **[Gap #3: SEO metadata, blog engine]** |
| | GitHub presence (README, discussions, releases) | moqui-adk GithubTool for release notes/issue triage agent |
| **Capture** | ERP Readiness Assessment (scorecard bridge) | Assessment landing page (FTL) + Flutter assessment app → lead + AI-scored PDF report emailed |
| | Website chat widget | `submit#WebsiteChat` auto-creates Lead (User without login) |
| | Lead-magnet download forms | **[Gap #3: form builder]** — today only chat + assessment capture |
| | Free trial signup | `register#User` / `create#Tenant` self-service flow, demo data option |
| **Nurture** | 7-step email sequence (existing copy in [marketing_plan.md](./marketing_plan.md)) | Today: BirdSend/MailerLight via `registerAdd#UserToGroup` **[Gap #1: native drip engine]** |
| **Qualify** | Score leads cold/warm/hot | Assessment `ScoringThreshold`; lead role on User |
| | Create opportunity for warm+ leads | `growerp_sales` Opportunity (estAmount, estProbability, stage, nextStep) |
| **Close** | Demo/consult booking | **[Gap #5: appointment booking]** — interim: calendly-style link in email |
| | Follow-up cadence | `growerp_activity` tasks linked to lead party **[Gap #7: auto-create from Opportunity.nextStep]** |
| | Pipeline review & forecast | **[Gap #2: pipeline board + weighted forecast report]** |
| **Convert** | Trial → paid subscription | `TenantServices100` check/renew subscription + `mantle-stripe` **[Gap #4: self-serve plan checkout]** |
| **Retain & expand** | Weekly newsletter (tips, releases, spotlights) | ESP today **[Gap #1]**; support app for tickets; courses for onboarding education |
| **Advocate** | Case studies, testimonials, contributor spotlights | SocialPost engine; GitHub discussions |
| **Automate all of it** | Scheduled agents: weekly KPI digest, stale-lead chaser, content-drafting agent | moqui-adk scheduled agents + EmailTool **[Gap #8: marketing agent tools]** |

---

## 5. Channel Plans

### 5.1 LinkedIn (primary outbound + content)
- 3 posts/week per PNP formula from ContentPlan; human-edited before publish.
- 10 personalized cold DMs per post via `growerp_outreach` LinkedIn adapter (respect `dailyLimitPerPlatform`).
- Follow-up DM to every commenter → assessment link ("scorecard bridge").
- Target lists: SMB owners by industry for the quarter's flagship vertical.

### 5.2 X / Substack
- Repurpose LinkedIn winners via SocialPost (platform variants). Substack long-form monthly: build-in-public + AI-agent stories (feeds Aaron persona).

### 5.3 SEO / website (growerp.com + generated site)
- Publish the guides already promised in outreach copy ("5 Signs You've Outgrown Spreadsheets", "Ultimate ERP Selection Guide") as Content pages; each ends with assessment CTA.
- Vertical landing pages per quarter (AI landing-page generation — `LandingPageServices100.xml`).
- **[Gap #3]** blocks serious SEO (no meta description/og tags) — priority fix.

### 5.4 GitHub / community (Builder Ben)
- Monthly release with human-readable notes (agent-drafted via GithubTool).
- 10–15 curated `good-first-issue`s; respond to every discussion within 48h (support app queue).
- "Build an app in a day" tutorial + video as the developer lead magnet.
- Partner/integrator page: listed in exchange for a case study.

### 5.5 App stores (6 platforms)
- Stores are discovery surfaces: refresh screenshots/keywords quarterly (fastlane metadata already in repo); reviews prompt in-app after 2 weeks of active use.

### 5.6 AI-agent showcase
- Bi-weekly demo video/gif: an agent doing real work in GrowERP (draft campaign, scan invoice, weekly digest). This is the differentiation content; everything else earns trust, this earns attention.

---

## 6. Sales Process

**Model: product-led trial with human assist.** Inbound trials sell themselves; sales time is spent only on warm/hot assessment leads and multi-user prospects.

### Pipeline stages (standardize `stageId` values — today free text, see [Gap #2])

| Stage | Entry criterion | Exit action |
|---|---|---|
| Prospecting | Lead captured (assessment/chat/trial) | Nurture sequence running |
| Qualified | Warm/hot score OR trial with 3+ active days | Opportunity created, estAmount set |
| Demo | Demo/consult booked | Demo done, needs confirmed |
| Proposal | Plan + price proposed | Decision date agreed |
| Won / Lost | Subscription active / explicit no | Won → onboarding; Lost → reason logged, recycle in 6 months |

- **Weighted forecast** = Σ estAmount × estProbability per stage — needs [Gap #2] report.
- **Cadence:** every Opportunity has a `nextStep` and an Activity due date; no opportunity older than 14 days without activity ([Gap #7] automates this).
- **Outbound:** `growerp_outreach` campaigns per vertical; responses become leads → same pipeline.
- **Weekly ritual:** Monday pipeline review from dashboard ([Gap #9]); agent-generated KPI digest emailed Sunday night ([Gap #8]).

---

## 7. Pricing & Packaging (recommendation)

| Tier | Offer | Revenue role |
|---|---|---|
| **Self-host** | Free forever, CC0. Docs + community support. | Adoption, community, credibility. Funnel into hosting/support. |
| **Hosted Starter** | Single company, one app, standard support. | Convert trials; low-friction entry price. |
| **Hosted Business** | All apps, multi-user, AI agents included with token quota, priority support. | Core MRR. AI quota (LLM usage tracking already exists) is the natural upgrade meter. |
| **Vertical editions** | Hotel/Health/eLearning packaging of Business tier with vertical onboarding. | Higher willingness-to-pay in niches. |
| **Services & partners** | Implementation, custom building blocks, integrator program. | Services revenue + ecosystem. |

Publish a real pricing page and wire trial→paid checkout ([Gap #4]); today conversion is manual, which caps growth.

---

## 8. KPIs & Reporting

| Funnel stage | KPI | Measured by (today) | Needs |
|---|---|---|---|
| Awareness | Posts published, impressions, DM responses | `CampaignMetrics` (messagesSent, responsesReceived) | [Gap #6] engagement monitor for likes/comments |
| Capture | Assessment starts/completions, chat leads, trial signups | Assessment data + lead Users + `register#AppUsed` | [Gap #9] one dashboard |
| Nurture | Email open/click, sequence completion | BirdSend external | [Gap #1] native metrics |
| Qualify | Warm/hot lead count, opportunities created | ScoringThreshold + Opportunity list | — |
| Close | Stage conversion %, win rate, weighted pipeline | manual today | [Gap #2] |
| Convert | Trial→paid %, MRR, churn | Subscription records + Stripe | [Gap #4] plan-level reporting |
| Community | Stars, contributors, discussions answered | GitHub | agent-collected via GithubTool |

**Review cadence:** weekly funnel review (Monday), monthly channel retro, quarterly segment/vertical rotation decision.

---

## 9. 90-Day Execution Calendar

**Weeks 1–2 — Foundation**
- Create 4 MarketingPersonas in `growerp_marketing`; generate first ContentPlans.
- Verify assessment funnel end-to-end on production (.com); fix copy; confirm results email/PDF.
- Standardize pipeline stage values in team convention (pending [Gap #2]).
- Write pricing page copy (Section 7); publish as website Content page.
- Ship quick wins: [Gap #7] nextStep→Activity, start [Gap #2] pipeline report.

**Weeks 3–6 — Engine on (SMB horizontal)**
- PNP posting live: 3 LinkedIn posts/week + 10 DMs/post via outreach campaigns.
- Publish both lead-magnet guides on website with assessment CTA.
- 7-step nurture sequence live (BirdSend interim; [Gap #1] in development).
- Weekly pipeline review starts; agent KPI digest prototype ([Gap #8]).

**Weeks 7–10 — Vertical wedge #1: Hotel**
- AI-generate hotel landing page + hotel-specific assessment variant.
- Outreach campaign: independent hotels/guesthouses (LinkedIn + email), hotel-Henri messaging.
- One hotel case study or founder-story demo video.
- Developer channel: publish "Build an app in a day" tutorial; curate good-first-issues; first agent-drafted release notes.

**Weeks 11–13 — Convert & compound**
- Launch self-serve plan checkout if [Gap #4] ready; else concierge conversion of every expiring trial.
- AI-agent showcase videos ×2 (Agent Control Center doing marketing work — meta-story: "GrowERP markets itself").
- Quarter retro: funnel numbers vs KPI table; pick vertical #2; reprioritize gaps by observed bottleneck.

---

## 10. System Enhancements Required

Prioritized by funnel impact. Effort: S < 1 wk · M = 1–3 wk · L > 3 wk.
Engineering detail per item: [GrowERP_Marketing_Enhancements_Implementation_Plan.md](./GrowERP_Marketing_Enhancements_Implementation_Plan.md).

| # | Enhancement | Why the plan needs it | Effort | Priority |
|---|---|---|---|---|
| 1 | **Native email nurture-sequence engine** — multi-step drip on `MarketingCampaign` (delay per step, templates, unsubscribe, open/click tracking), replacing BirdSend dependency | Nurture is the conversion core; today outsourced, unmeasured in-system, and off-brand for "ERP does it all" | L | P1 |
| 2 | **Pipeline board + funnel report** — named stage enum for Opportunity (today free-text `stageId` in `opportunity_model.dart`), kanban view, stage-conversion & win-rate, weighted forecast | Sales process (§6) and KPIs (§8) unmeasurable without it | M | P1 |
| 3 | **Website SEO metadata + lead-capture form builder** — meta title/description/og tags per Content page; simple form → lead User (like chat widget path) | SEO channel (§5.3) and lead magnets need capture beyond chat/assessment | M | P1 |
| 4 | **Self-serve pricing page + plan-tier Stripe checkout** — plan tiers on tenant subscription, upgrade/downgrade, dunning | Trial→paid is manual; caps conversion (§7) | M–L | P1 |
| 5 | **Appointment booking** — `AppointmentSlot`/`Appointment` per [SocialMediaLeadSystem.md](./SocialMediaLeadSystem.md) Phase 4 design | Warm lead → demo call step (§6) | M | P2 |
| 6 | **Engagement monitor** — `SocialEngagement` entity + recordEngagement service (Phase 2 of same doc) | Signal detection feeds warm-DM follow-up (§5.1) | M | P2 |
| 7 | **Opportunity `nextStep` → Activity auto-link** — creating/updating nextStep creates a due Activity | Follow-up discipline; cheap win | S | P1 (quick win) |
| 8 | **ADK marketing-agent toolset** — agent tools to create campaigns, draft/schedule posts, update opportunities, compile weekly KPI digest; seed a scheduled "Marketing Ops" agent | Automation multiplier; is itself the flagship demo for AI-first positioning (§5.6) | M | P2 |
| 9 | **Marketing/sales dashboard** — funnel counts, CampaignMetrics, trial signups, pipeline value in admin dashboard | Single pane for weekly review ritual (§6, §8) | M | P2 |

**Suggested build order:** 7 → 2 → 3 → 1 → 4 → 8 → 9 → 5 → 6.

---

## 11. Relationship to Existing Documents

- [marketing_plan.md](./marketing_plan.md) — its outreach scripts and 7-email sequence copy are adopted verbatim into §4 Nurture / §5.1; this document supersedes it as the plan of record.
- [MarketingProposal.md](./MarketingProposal.md) / [SocialMediaLeadSystem.md](./SocialMediaLeadSystem.md) — the social system is the Awareness/Capture engine of §4; its Phase 2 and Phase 4 gaps appear here as enhancements #6 and #5.
- [marketing_implementation_guide.md](./marketing_implementation_guide.md) — current BirdSend wiring; retired when enhancement #1 ships.
- [GrowERP_Features.md](./GrowERP_Features.md), [Management_Summary_Open_Source_Extensibility.md](./Management_Summary_Open_Source_Extensibility.md) — source material for §2 proof points.
