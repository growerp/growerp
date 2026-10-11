# How the Marketing Agent Team Works with CRM, Marketing and Outreach

GrowERP has three modules that together take someone from stranger to customer:

- **Marketing**: attract attention with content, and capture and warm up leads.
- **Outreach**: contact prospects directly by e-mail, LinkedIn and other platforms.
- **CRM**: work the leads into opportunities and won deals.

The **marketing agent team** is a set of AI agents that does the repetitive work inside
these three modules, while you keep the decisions. This document explains what each agent
does, where in the app its work shows up, and which steps stay with you.

> **Audience:** business users of the GrowERP admin app. It describes the flow; for the
> step-by-step setup of the agents see the
> [Marketing Agent Team User Guide](Marketing_Agent_Team_User_Guide.md), and for the
> screens themselves the [Marketing, Outreach & CRM manual](GrowERP_User_Manual_Marketing_CRM.md).

---

## 1. The big picture

```
              MARKETING                       OUTREACH                    CRM
              ─────────                       ────────                    ───
 Content and Social agent                Outreach Personalizer      Lead Triage agent
   Persona → Content Plan                  fills PENDING messages     ranks replies +
   → Master Content ──adapt──→ posts        │                         opportunities,
         │  (you approve once)              ▼                         drafts follow-ups
         ▼                               Campaign send job                │
   Scheduler publishes posts              sends within limits             ▼
         │                                  │                       To Do / Email Sequence
   readers click "read more"                ▼                             │
         ▼                                Replies (RESPONDED) ──────→ Opportunity → Pipeline → Won
   Reads, Engagements ──convert──────────────────────────────────→ Lead
                                                                         ▲
 Website chat (SDR agent), web forms, assessments ──────────────────────┘

                         Marketing Ops Digest: daily summary of all of the above
```

Every capture channel creates the same kind of **lead** (CRM → Leads). So however someone
found you, they end up in one list and one pipeline.

---

## 2. Who does what

| Agent | Works in | Reads | Creates or changes | Your part |
|---|---|---|---|---|
| **Content and Social** (weekly, Mon 08:00) | Marketing | personas, content plans, existing content | persona (if missing), this week's Pain-News-Prize plan, 3 master content pieces, their per-platform posts (READY) | **Approve** each master content piece once |
| **Outreach Personalizer** (hourly, 09–17) | Outreach | PENDING messages, the campaign template, recipient name/title/company | the body text of PENDING messages | Create the campaign and its recipients |
| **Sales Development Rep** (website chat, always on) | Website → CRM | your Knowledge base | nothing (read-only); hands hot visitors to a human | Answer handed-off chats; keep Knowledge current |
| **Lead Triage** (every 30 min, 09–18) | Outreach + CRM | replied outreach messages, new opportunities, campaign reply rates | ranked summary + draft follow-ups in team chat, To Do activities, e-mail sequence enrolments | Make the call or send the follow-up |
| **Marketing Ops Digest** (daily 09:00) | all three | sends, replies, pipeline, opportunities, marketing dashboard | one chat message | Read it, act on what is stalled |
| **Partner Scout** (on demand) | Outreach + CRM | the web, existing companies | partner companies as leads, a research note, a PENDING outreach draft per partner | Fill in its `[[...]]` parts; review drafts |

Two **background jobs** do the actual sending. Neither is an agent:

- **Social post scheduler**: publishes READY posts of *approved* master content at
  their scheduled time, within each platform's daily limit.
- **Campaign send job**: sends PENDING outreach messages hourly, inside each campaign's
  send window and daily limit.

No agent publishes a post or sends a message to a prospect by itself.

---

## 3. The flow, stage by stage

### 3.1 Attract: content (Marketing)

1. **Content and Social** checks there is a **persona** (Marketing → Personas). The persona
   describes your target customer, and every piece of content is written for it.
2. It generates this week's **content plan** (Marketing → Content Plans), with three slots:
   *Pain*, *News* and *Prize*.
3. For each slot it writes one **master content** piece (Marketing → Content). The piece is
   platform-neutral text with a title, body, call to action and optional **Target URL**,
   plus an AI-made **related image**, made in the background right after the run.
4. It **adapts** each piece to every enabled platform (LinkedIn, X, Facebook, Medium,
   Substack, Substack note, e-mail). This creates one READY post per platform, spread over
   Monday, Wednesday and Friday.
5. It posts in team chat which pieces are waiting for you. You open **Marketing → Content**,
   check a piece and its platform variants, and tap **Approve**. From then on the scheduler
   publishes every variant at its own time. **Revoke** stops future publishing.

**Your own ideas first (the Ideas strip at the top of Marketing → Content).** Paste an
article, rough notes or a one-line idea, give the URL of an article, or both; both are used.
Drag the ideas into the order you want (long-press, then drag), or collapse the strip.
- **Write article** turns an idea into a ~500 word article in your house style and removes
  the idea. The article shows up under **Marketing → Content**, in teaser mode, with its Target URL set to a page on your
  website.
- When you **approve** it, the article goes onto your website, and the **Articles** page
  (one menu item) lists every article. Its platform posts are teasers that link to it.
- The weekly **Content and Social** agent uses the ideas in that order first and only invents
  subjects for the slots that are left.

**Related image (optional, per piece).** Every AI-written piece gets one automatically; in
the piece's dialog you can also pick your own (**Add** / **Update**), remove it, or press
**Generate image with AI**. Tap the image to see it full size. The image is the hero at the
top of the article page and is attached to the LinkedIn, X and Facebook posts. Medium and
Substack drafts show it through its link on your website. Substack notes and e-mail go
without it.

**Download / upload (ZIP).** The files button on **Marketing → Content** downloads every
piece with its image as one ZIP, or uploads such a ZIP. A piece whose ID exists is updated;
others are added as drafts, never approved, so nothing publishes until you approve it.

**Teaser mode (optional, per piece).** Switch on *Teaser only (link to full article)* in a
master content piece and set its Target URL to the full article on your GrowERP website.
Every platform then gets a short teaser with a "Read the full article" link, not the full
text. An ARTICLE piece that has no website page yet gets one when it is adapted: its
Target URL becomes the new page, and the previous Target URL (say a landing page) is kept
as the call-to-action link at the bottom of the article, so readers still get there. Use it when you want to know who actually *reads* your content. Read on for why.

### 3.2 Measure what is read (Marketing → Content)

Open-rate pixels in e-mail newsletters no longer tell you much:

- Apple Mail loads every image automatically, so everyone looks like a reader.
- Outlook blocks images, so real readers stay invisible.
- Security scanners click links on their own.

GrowERP measures on **your own website** instead:

- Every adapted post links to the Target URL with a tag for its platform and content piece.
  This happens with or without teaser mode.
- A visit from such a link counts as **landed**.
- It counts as **read** only when the visitor keeps the page visible for 15 seconds and
  scrolls at least halfway. Scanners, link previews and mail privacy proxies don't do that.
- **Marketing → Content** shows, per content piece:
  - landings, reads and the read percentage
  - a per-platform breakdown when you tap a row, so you can compare channels directly
- The marketing dashboard tile shows the reads of the last 30 days.

### 3.3 Capture: leads (Marketing → CRM)

People who react end up in **CRM → Leads**:

- **Engagements** (Marketing → Engagements): a comment, like or DM reply on a post is recorded
  here and **converted to a lead** with a follow-up To Do.
- **Website chat**: the **Sales Development Rep** answers visitors from your Knowledge base.
  It suggests the next step (trial, demo, signup) and calls a human in when someone is
  ready to buy.
- **Web forms and assessments**: submissions create leads directly. A form can enrol the lead
  in an **e-mail sequence** that nurtures them automatically.

### 3.4 Contact: outreach (Outreach)

1. You create a **campaign** (Outreach → Campaigns) with its platforms, a message template,
   daily limits and a send window. The **Platforms** screen holds each platform's account
   settings.
2. Recipients become **PENDING messages** (Outreach → Messages). **Partner Scout** can also
   create them for partners it found.
3. **Outreach Personalizer** fills in each PENDING message body from the template and the
   recipient's details:
   - LinkedIn messages get no link and end on a question.
   - E-mails include your link.
4. The **campaign send job** sends them inside the send window and daily limit. LinkedIn
   messages that must be sent by hand appear in **Outreach → Send Queue**.
5. When a prospect answers, the message becomes **RESPONDED**, and an **opportunity** is
   created for it in CRM.

### 3.5 Follow up: CRM

- **Lead Triage** looks at new replies and new opportunities every half hour. It ranks them
  hottest-first and posts a summary with draft follow-ups in your team chat. It can also:
  - log a follow-up as a **To Do** (CRM → My To Do, tasks)
  - enrol a lead in an **e-mail sequence**
- You do the human part: call the lead, send the follow-up, and move the deal through
  **CRM → Opportunities** and **CRM → Pipeline** until it is won.

### 3.6 Keep an eye on it: the daily digest

**Marketing Ops Digest** posts 5–7 bullets every morning to your chat room:

- messages sent per channel and the reply rate
- the pipeline by stage with its weighted value
- new and advancing opportunities
- anything that is stalled

---

## 4. What stays with you

| Decision | Where |
|---|---|
| Which content goes out | **Approve** per master content piece (Marketing → Content) |
| How much goes out per day | Daily limits per platform (Outreach → Platforms) and per campaign |
| When outreach is sent | Campaign send window (Outreach → Campaigns) |
| Which agents run, and when | Agent Control → AI Agents (schedule on/off) and Agent Jobs (pause) |
| Talking to a ready buyer | Website chat handoff, Lead Triage drafts, CRM To Do |

Every agent sees only your own company's data, can use only the services on its list,
and logs every call in **Agent Control → Agent Actions**.

---

## 5. Getting started in five steps

1. **Settings:** an LLM key (System Setup → AI), your platforms (Outreach → Platforms), and a
   team chat room (Chat).
2. **Agents:** add the marketing team from the agent catalog (Agent Control → AI Agents →
   catalog icon) and set the chat room on each agent.
3. **Content:**
   - Create one persona (or let *Content and Social* do it).
   - Add an idea in the Ideas strip (a few lines of notes or an article URL) and tap
     **Write article**: you get a ~500 word article in teaser mode. Or write an ARTICLE
     master content piece yourself, set a Target URL (e.g. your landing page) and switch on
     teaser mode: adapting it gives it a page on your website.
   - Approve it: the article goes on your website and its teasers are scheduled.
4. **Outreach:** create one outreach campaign with a few recipients and let the Personalizer
   fill the messages.
5. **Monitor:** switch on the schedules one at a time, in this order: Digest, Lead Triage,
   Personalizer, Content and Social. After a week, check the **Reads** column under Content and the
   **Pipeline**.

The *Guide* items under Marketing and Outreach walk you through the same steps in the app.
The [Marketing Agent Team User Guide](Marketing_Agent_Team_User_Guide.md) covers every
agent setting and the troubleshooting table.

---

## 6. Where it lives (for implementers)

| Area | Flutter package | Backend services |
|---|---|---|
| Personas, plans, ideas, master content, posts, e-mail sequences, engagements, content reads | `growerp_marketing` | `MarketingServices100`, `MasterContentServices100`, `SocialPostPublishingServices100`, `NurtureServices100` |
| Campaigns, platforms, messages, automation, send queue | `growerp_outreach` | `OutreachServices100`, `MCPAutomationServices100` |
| Opportunities, pipeline | `growerp_sales` | `CrmServices100` |
| To Do / activities | `growerp_activity` | `ActivityServices100` |
| Leads, customers | `growerp_user_company` | `PartyServices100` |
| Agents, jobs, approvals, actions, knowledge | `growerp_adk` | `moqui-adk` component |
| Website read tracker | `pop-rest-store/template/contentReadWidget.html.ftl` | `record#ContentRead`, `get#ContentReadStats` |

The agent definitions, including instructions, service allowlists and schedules, are
seeded in `backend/data/GrowerpMarketingCatalogData.xml` (catalog templates) and
`GrowerpPartnerScoutAgentData.xml`.

## Related documents

- [Marketing Agent Team User Guide](Marketing_Agent_Team_User_Guide.md): agent setup, schedules, troubleshooting
- [GrowERP User Manual: Marketing, Outreach & CRM](GrowERP_User_Manual_Marketing_CRM.md): every screen
- [Marketing Weekly Operational Guide](Marketing_Weekly_Operational_Guide.md): a weekly routine
- [Agent Control Center User Guide](Agent_Control_Center_User_Guide.md): the agent screens
- [AI Agent Teams Overview](AI_Agent_Teams_Overview.md): all agent teams
