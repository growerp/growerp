# Marketing Agent Team User Guide

The **marketing agent team** is a ready-made set of five AI agents that run GrowERP's
marketing loop for you: personalising outreach, answering website visitors, triaging replies,
producing weekly content, and mailing you a daily digest.

You install the team with one click: the **rocket icon** (🚀 *Enable marketing agent team*)
on the **Agent Control → AI Agents** screen.

See also: [Agent Control Center User Guide](Agent_Control_Center_User_Guide.md) for the
general agent screens (Jobs, Approvals, Actions, Knowledge).

---

## 1. Before you press the rocket

| Requirement | Where |
|---|---|
| An LLM API key (Gemini by default) | **System Setup → AI / LLM settings** |
| A chat room to receive agent output | **Chat** — create a room, e.g. "Marketing" |
| Outreach campaign with recipients | **Marketing → Outreach** (needed by Personalizer, Lead Triage) |
| Knowledge base entries about your company | **Agent Control → Knowledge** (needed by the SDR agent) |

Without an LLM key the agents are created but every run fails. Without knowledge documents
the SDR agent will honestly answer "I don't know" instead of making things up.

## 2. Enabling the team

1. Open **Agent Control → AI Agents**.
2. Tap the **rocket icon** in the search bar (tooltip *Enable marketing agent team*).
3. Confirm the dialog.

What happens:

* The five agents are copied into **your company** from the GrowERP templates.
* All schedules start **disabled**, except **Marketing Ops Digest** (daily 9:00).
* It is **safe to run again** — an existing agent with the same name is updated, not duplicated.
* You cannot run it on the GROWERP company itself (it already owns the templates).

You land back on the agent list with five new agents.

## 3. The five agents

### Outreach Personalizer
Fills in the body of every **PENDING** outreach message using the campaign template plus the
recipient's name, title and company. It never sends and never touches a SENT message.
LinkedIn messages get no URL and end on a question; e-mails include your assessment link.

* Default schedule: hourly, 09:00–17:00 (`0 0 9-17 * * ?`) — **starts disabled**
* Tool access: scoped to the outreach services; writes allowed

### GrowERP SDR
The **public website chat** agent. It answers visitor questions from your Knowledge base
(RAG), pushes the free trial, and hands hot leads to a human. Read-only — it cannot change
data. Not scheduled: it reacts to website chat visitors.

### Lead Triage
Every 30 minutes in work hours it lists replied outreach messages plus new opportunities,
ranks them hottest-first, drafts short follow-ups, and posts a ranked summary to your team
chat room. It never sends anything to prospects.

* Default schedule: `0 0,30 9-18 * * ?` — **starts disabled**

### Content and Social
Weekly "Pain–News–Prize" content. It ensures a persona exists, generates the content plan,
authors each piece **once** as platform-neutral master content, then adapts it to every
enabled platform (LinkedIn, X, Facebook, Medium, Substack, e-mail) as READY social posts,
staggering them across Monday/Wednesday/Friday instead of bursting them all at once.

* Default schedule: Mondays 08:00 (`0 0 8 ? * MON`) — **starts disabled**
* Write policy: **allow** — generating and adapting content runs immediately, no approval
  card per step. The gate is elsewhere: you approve each **master content piece** once
  (**Marketing → Master Content**), and only then does the scheduler auto-publish every
  platform variant of that piece, at its scheduled time, within each platform's daily limit.
  The agent never publishes anything itself.

### Marketing Ops Digest
A 5–7 bullet daily digest: messages sent by channel, reply rate, pipeline by stage with
weighted value, new and advancing opportunities, and anything stalled. Read-only.

* Default schedule: daily 09:00 (`0 0 9 * * ?`) — **the only one enabled after install**

## 4. Finish the setup (per agent)

The clone deliberately does **not** copy chat-room settings, so each agent needs one edit:

1. Tap the **pencil** next to an agent.
2. **Scheduled runs → Chat Room ID for delivery** — set the room where results should land.
   Without it a scheduled run only writes to the log.
3. For *Content and Social*, also set **Approval Chat Room ID** so approval cards reach you.
4. Turn on **Enable scheduled runs** when you are ready for that agent to work.
5. Adjust the **cron expression** to your timezone / working hours.

Recommended order: enable the **Digest** first (it only reads), then **Lead Triage**, then
**Outreach Personalizer**, and last **Content and Social**.

## 5. Running the team day to day

* **Agent Control → Agent Jobs** — see the last run, its status and schedule. Pause/resume an
  agent here without deleting its schedule; clear a stale lock if a run crashed mid-way.
* **Marketing → Master Content** — after the Monday run, *Content and Social* posts a chat
  message listing the pieces it authored. Open each one and tap **Approve**; every platform
  variant adapted from it then auto-publishes at its own scheduled time (Mon/Wed/Fri), as long
  as that platform is enabled and under its daily limit. Tap **Revoke** to stop future
  auto-publishes for a piece (already-published variants are unaffected). You can also approve
  inline from **Marketing → Content Plans** → a plan's Content section.
* **Agent Control → Approvals** — governs the agent's *other* writes (persona/plan/master
  content creation) only if you ever set this agent's write policy back to `approve`; with the
  default `allow` policy nothing from this agent appears here.
* **Agent Control → Agent Actions** — the audit trail: every service the agents called, whether
  it was allowed, blocked, pending or rejected, and the result.
* **Agent Control → Knowledge** — add notes, upload documents, or import your product catalog.
  This is what the SDR agent quotes to website visitors; keep it current.

## 6. Safety model

* Every agent is scoped to **your company** — it cannot see or touch another company's data.
* Tool access is **scoped** (an explicit service allowlist) or **read-only** for the SDR and
  the Digest. No agent has full access.
* *Content and Social* may generate and adapt content freely (`writePolicy=allow`), but it
  cannot publish or approve — `publish#SocialPost` and `approve#MasterContent` are not in its
  allowlist. Publishing only happens through the scheduler, and only for pieces you approved.
* The scheduler additionally enforces each platform's **daily limit**
  (**Marketing → Platform Configuration**) — at most that many posts publish per platform per
  day, counted in UTC.
* No agent sends messages to prospects on its own; the outreach send scheduler (a separate job)
  drains PENDING outreach messages within your daily limits.

## 7. Troubleshooting

| Symptom | Cause / fix |
|---|---|
| "Enable failed: The GROWERP owner already has the marketing team" | You are logged in on the GROWERP company; the templates are already there. |
| Agent runs but nothing appears in chat | **Chat Room ID for delivery** is empty on that agent. |
| Every run errors | Missing or invalid LLM API key — see **System Setup**. |
| Job never runs | **Enable scheduled runs** is off, or the job is paused in **Agent Jobs**. |
| Job stuck "running" | Stale lock — use **Clear Lock** in **Agent Jobs**. |
| SDR answers "I don't know" | Knowledge base empty — add documents under **Knowledge**. |
| A social post stays READY and never publishes | Its master content isn't approved yet (approve it in **Master Content**), the platform is disabled in **Platform Configuration**, its `scheduledDate` is still in the future, or the platform's daily limit is already reached today. |
| You already installed the team before this update | The old copy still gates every step through **Approvals** (`writePolicy=approve`). Press the rocket again on **Agent Control → AI Agents** — it updates your existing agents in place with the new approval model, no duplicates. |
| Article published to Medium isn't public | The Medium publisher intentionally creates a **draft** on Medium — publish it manually there once you're happy with it. |
