# Marketing Weekly Operational Guide

**Status:** Operational runbook — one work week (Monday–Friday) of running GrowERP's own marketing in the GrowERP Marketing app.
**Companions:** [GrowERP_Marketing_Sales_Plan.md](./GrowERP_Marketing_Sales_Plan.md) (the strategy — *what* and *why*), [Marketing_Agent_Team_User_Guide.md](./Marketing_Agent_Team_User_Guide.md) (agent mechanics), [GrowERP_User_Manual_Marketing_CRM.md](./GrowERP_User_Manual_Marketing_CRM.md) (screen reference).
**Principle:** GrowERP markets GrowERP *using GrowERP*. The agents and schedulers do the volume; you do the judgment. Budget: **1.5–2.5 hours per day**.

---

## 1. Standing setup (assumed done — verify once, not weekly)

| Requirement | Where |
|---|---|
| Marketing agent team enabled, each agent has a delivery chat room | **Agent Control → AI Agents** (🚀 rocket icon) |
| LLM API key configured | **System Setup** |
| Platforms enabled with daily limits (LinkedIn, X, Substack, …) | **Outreach → Platforms** |
| At least one active outreach campaign with recipients | **Outreach → Campaigns** |
| Personas current (Olivia, Henri/Fiona, Ben, Aaron — Sales Plan §3) | **Marketing → Personas** |
| Knowledge base current (feeds the SDR website-chat agent) | **Agent Control → Knowledge** |
| Assessment funnel live end-to-end (landing page → questions → results email) | **Marketing → Landing Pages / Assessments** |

If any of these is missing, fix it before starting the week — the daily routine below assumes the machine is running.

## 2. The automated backbone (what happens without you)

| When | What | Who/what runs it |
|---|---|---|
| Monday 08:00 | Week's Pain–News–Prize content generated: persona check → content plan → 3 master pieces → platform variants staggered Mon/Wed/Fri as READY posts | *Content and Social* agent |
| Daily 09:00 | Digest to chat: sends by channel, reply rate, weighted pipeline, stalled items | *Marketing Ops Digest* agent |
| Every 30 min, 9–18 | Ranked hot-leads summary + drafted follow-ups to chat | *Lead Triage* agent |
| Hourly, 9–17 | PENDING outreach message bodies personalized | *Outreach Personalizer* agent |
| Hourly, 9–17 | PENDING outreach messages sent within daily limits | Campaign automation job |
| Every 15 min | READY social posts published **if** their master content is approved, scheduled time passed, platform enabled, daily limit not reached | Publishing scheduler |
| Every 15 min | Due nurture-sequence emails sent | Nurture job |
| Continuous | Substack subscriber sync + engagement collection into Engagements | Substack jobs |

Your job all week is the four **human gates**: approve content, assist LinkedIn sends, convert engagements/replies to leads, and keep the pipeline moving.

## 3. Daily routine (every workday, ~30 min, at 09:00)

1. **Chat** — read the *Marketing Ops Digest* (arrives 09:00). Note anything stalled; it becomes today's extra task.
2. **Chat** — scan the latest *Lead Triage* summary. For each hot item, act now: reply, or create/advance the opportunity it points at.
3. **CRM → My To Do, tasks** — work today's due activities. Close what's done; nothing overdue leaves the screen without a new date or a reason.
4. **Outreach → Send Queue** — one assisted-sending pass: review each pending LinkedIn message, **AI Polish** if flat, **Copy & Open LinkedIn**, send, **Sent → Next** (or **Skip**). Stop at the daily limit or an empty queue.
5. **Marketing → Engagements** — new likes/comments/restacks since yesterday: **Convert to lead** for anyone warm, then follow up with the assessment link (the "scorecard bridge", Sales Plan §5.1).

## 4. Day by day

### Monday — Content approval & pipeline kickoff (~2.5 h)

The *Content and Social* agent ran at 08:00 and posted its output to chat. This is the week's single most important gate: **nothing publishes until you approve.**

1. Daily routine (§3).
2. **Marketing → Content** — open each of the 3 new master pieces (Pain / News / Prize). Edit for voice and accuracy — the human "icing" — then tap **Approve**. Approval unlocks auto-publishing of *all* platform variants of that piece at their scheduled Mon/Wed/Fri slots.
3. Check the piece's *Platform variants* section: Monday's variants should flip to published within 15 minutes. If one stays READY, see §7.
4. **Marketing → Content Plans** — confirm this week's plan (theme, persona) matches the quarter's focus vertical; adjust next week's theme note if needed.
5. **CRM → Pipeline** — weekly pipeline review (Sales Plan §6): drag opportunities to their true stage, set/refresh `nextStep` on every card, make sure every open opportunity has a due activity. No opportunity older than 14 days without activity.
6. **Main dashboard** — weekly KPI check against Sales Plan §8: trial signups, assessment completions, messages sent / reply rate, weighted pipeline. Write the 3-line week plan in the team chat room.

### Tuesday — Outreach engine (~2 h)

1. Daily routine (§3).
2. **Outreach → Campaigns** — per active campaign: metrics (sent / responses), status, daily limit still appropriate. Pause anything with a reply rate collapsing; start the next campaign if one is queued.
3. Top up recipients: **Import LinkedIn leads** (CSV) into the campaign for the quarter's flagship vertical.
4. **Outreach → Messages** — spot-check ~5 PENDING messages the *Personalizer* filled: right name, title, company, no URL in LinkedIn messages, ends on a question. Fix the campaign template if a pattern is off — not the individual messages.
5. Heavier **Send Queue** session: aim for ~10 personalized DMs tied to Monday's post (Sales Plan §5.1).
6. Replies from yesterday: **Outreach → Messages** → **Convert to lead** on every genuine response; warm ones get an opportunity.

### Wednesday — Publish check & engagement mining (~1.5 h)

1. Daily routine (§3).
2. **Marketing → Content** — confirm Wednesday's platform variants published. Medium variants land as *drafts* on Medium — publish the draft manually there.
3. **Marketing → Engagements** — the mid-week mining pass: everyone who engaged with Monday's post gets a short follow-up DM ending in the assessment link; convert warm ones to leads.
4. **Marketing → Email Sequences** — check active/completed enrollment counts per sequence. Flat active counts mean capture is broken (assessment or chat) — investigate, don't wait for Friday.
5. **X posting** — if X is manual this week, use **Copy & Open X** on the Wednesday piece.

### Thursday — Capture funnel & knowledge (~1.5 h)

1. Daily routine (§3).
2. **Marketing → Assessments → Assessment Leads** — review new respondents: expand answers, check scores against thresholds. Warm/hot → create an Opportunity (estAmount, estProbability, nextStep) and a follow-up activity.
3. **Marketing → Landing Pages** — sanity-check the live page(s): CTA still points at the right assessment, credibility statistics current (stars, tenants, releases). Generate/update the quarter's vertical landing page if the calendar (Sales Plan §9) says so.
4. **Website chat** — review this week's SDR conversations; every "I don't know" answer is a missing knowledge entry.
5. **Agent Control → Knowledge** — add what was missing: new release notes, pricing changes, new case study. This is what the SDR quotes to visitors tomorrow.

### Friday — Wrap, audit & reset (~2 h)

1. Daily routine (§3).
2. **Marketing → Content** — confirm Friday's variants published; the week's 3 PNP pieces are now fully out.
3. **Metrics wrap** — **Outreach → Campaigns** metrics + **Main dashboard** tiles: posts published, DMs sent, responses, engagements converted, assessment completions, new opportunities, weighted pipeline delta. Post a 5-bullet week summary in the team chat (this is also the input for the Monday KPI check).
4. **Agent Control → Agent Jobs** — every agent ran on schedule? Clear stale locks; re-enable anything paused by accident.
5. **Agent Control → Agent Actions** — skim the audit trail for blocked or failed calls; fix allowlists or configuration, not symptoms.
6. **Reset for next week:** persona tweaks from what resonated (**Marketing → Personas**), next campaign/recipient list staged (**Outreach → Campaigns**), platform daily limits adjusted if a channel is saturating (**Outreach → Platforms**).

## 5. Weekly time budget

| Day | Focus | Budget |
|---|---|---|
| Monday | Content approval, pipeline review, week plan | ~2.5 h |
| Tuesday | Campaigns, recipients, DM volume | ~2 h |
| Wednesday | Publish check, engagement mining, nurture health | ~1.5 h |
| Thursday | Assessment leads, landing pages, knowledge base | ~1.5 h |
| Friday | Metrics wrap, agent audit, next-week reset | ~2 h |

Daily routine (§3) is included in each day's budget. Everything else — personalizing, sending, publishing, nurturing, triaging, digesting — the system does.

## 6. Weekly output when the loop runs clean

- 3 approved PNP master pieces → published across all enabled platforms Mon/Wed/Fri
- ~30–50 personalized LinkedIn DMs sent (10/post plus queue drain), within daily limits
- Every engagement and reply converted or explicitly skipped
- Zero opportunities without a `nextStep` and due activity
- Knowledge base one week fresher; agents audited and unblocked

## 7. When things don't happen

Full table: [Marketing_Agent_Team_User_Guide.md §7](./Marketing_Agent_Team_User_Guide.md). The four you'll actually hit:

| Symptom | Fix |
|---|---|
| Post stays READY, never publishes | Master content not approved, platform disabled, `scheduledDate` in the future, or daily limit reached (UTC) — in that order of likelihood |
| No Monday content in chat | *Content and Social* schedule disabled, or delivery Chat Room ID empty — **Agent Control → AI Agents** → pencil |
| Send Queue empty but campaign active | No PENDING messages: recipients exhausted (import more) or campaign paused |
| Medium article not public | By design: Medium gets a draft — publish it manually on Medium |
