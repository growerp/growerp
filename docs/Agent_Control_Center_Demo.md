# Agent Control Center — Demo Walkthrough

A guided demo of the GrowERP Agent Control Center (the ADK platform). It loads a
**"GrowERP Operations Assistant"** team — one coordinator that delegates to three specialists —
chosen so that every control-center capability shows up in one coherent business story.

| Agent | What it shows |
|-------|---------------|
| **Operations Assistant** (coordinator, router) | Multi-agent orchestration — routes each request to a specialist |
| **Sales Specialist** (scoped tools, approval-gated writes) | Tool scoping + human-in-the-loop **approvals** on writes |
| **Inventory Specialist** (read-only) | Safe read-only MCP tool use + the action audit trail |
| **Support Specialist** (read-only + knowledge) | **RAG** retrieval over the company's own policy docs |
| **Ops Digest** (scheduled) | Scheduled jobs |

Used live during the demo (generated, not seeded): the **approval** queue, the **action audit
log**, and **cross-session memory**.

## How it loads

The demo rides the same path as ordinary demo data: template rows
(`ownerPartyId="_NA_"` in `moqui/runtime/component/moqui-adk/data/AgentDemoData.xml`) are
**cloned into a tenant** when the admin ticks a checkbox at tenant setup. It has its own
selectable indicator — **Load Agent Demo** — next to the existing **Load Demo Data**.

Flag path: `tenant_setup_dialog` (`agentDemoData`) → `AuthLogin` → `auth_bloc` → `Login` REST →
`GeneralServices100.login#User` → `TenantServices100.complete#TenantSetup` →
`PartyServices100.setup#SpecificApp` → `AdkDemoServices.load#AgentDemo` (the clone service).

## Prerequisites

- Backend running (`cd moqui && java -jar moqui.war no-run-es`).
- Seed loaded so the `_NA_` templates exist:
  `java -jar moqui.war load types=seed no-run-es`.
- For the RAG part only: a Gemini key — `GOOGLE_API_KEY` env var, or a `gemini` `LlmConfig`
  for the tenant. Without it the agents still load; only the Support knowledge docs are skipped.

## Step 0 — Load the demo into a new tenant

1. Run the **agents** app (`flutter/packages/agents/`) — or any GrowERP app — and start
   registration for a brand-new company (not the GROWERP system tenant; the flag is forced off
   for GROWERP).
2. On the tenant setup dialog, tick **Load Agent Demo** (key `agentDemoData`) and complete
   setup. (Setup uses a 15-minute client timeout because knowledge ingest + embedding can be
   slow.)
3. The clone service creates the 5 agents and 3 team links for your tenant, and — if a key is
   present — ingests the demo policy docs.

Verify (MCP / REST, replace `<tenant>` with your owner party id):
- `e1/moqui.adk.AdkAgentConfig?ownerPartyId=<tenant>` → 5 agents.
- `e1/moqui.adk.AdkAgentTeamMember?ownerPartyId=<tenant>` → 3 links (coordinator → each specialist).
- `e1/moqui.adk.AdkKnowledgeDoc?ownerPartyId=<tenant>` → 3 policy docs (only if a key was set).

## The walkthrough (agents app)

Open the **agents** app. The left menu has: AI Chat, AI Agents, MCP Servers, Agent Jobs,
Approvals, Agent Actions, Knowledge.

### 1. AI Agents — see the team
Open **AI Agents**. You'll see the five agents. Open **Operations Assistant**: note its role is
*coordinator* and that the three specialists are its team members. Orchestration routes by each
member's **description**, so each specialist's description reads like a "use this when…" hint.

### 2. AI Chat — orchestration + RAG
Open **AI Chat** and select **Operations Assistant**. Try, one at a time:
- *"What's the stock level of <one of your products>?"* → routes to **Inventory** (read-only).
- *"What is your return policy?"* → routes to **Support**, which answers from the ingested
  policy doc via `searchKnowledge` (RAG). (Requires the key step above.)

### 3. Approvals — human-in-the-loop writes (the headline demo)
Still in chat: *"Create a sales quote for customer <name> for 2x <product>."* → the coordinator
routes to **Sales**. Sales is `writePolicy=approve`, so the create is **not** executed — it is
queued. The agent tells you it's awaiting approval.

Open **Approvals**: the pending write is listed. **Approve** it → the service runs and the quote
is created. (Reject instead to see it discarded.)

### 4. Agent Actions — the audit trail
Open **Agent Actions**. Every step is logged for your tenant only: the Inventory/Support reads
as `allowed`, and the Sales write going `pending` → `approved`, with token counts. Delegated
calls show the specialist `configId` and the coordinator as `parentConfigId`.

### 5. Agent Jobs — scheduled work
Open **Agent Jobs**. The **Ops Digest** agent is scheduled (`scheduleEnabled=Y`). To see a run
now, trigger `AdkSchedulerServices.run#ScheduledAgent` for it. To have the digest delivered to a
chat room, set the agent's `scheduleChatRoomId` to one of the tenant's chat rooms (the clone
leaves it unset because room ids are tenant-specific).

### 6. Knowledge — the RAG corpus
Open **Knowledge** to see the ingested policy docs and their chunk counts — the source the
Support specialist quoted in step 2.

### 7. Memory — cross-session recall
After several turns the platform builds a rolling per-user **memory** summary that is injected
into the agent on the next session — mention a preference, start a new session, and the
assistant recalls it.

## What this demo does not add

No new ADK entities, screens, or capabilities — the platform already exposes all of the above.
The demo is one dialog checkbox + flag threading, one clone service
(`AdkDemoServices.load#AgentDemo`), one template-seed file (`AgentDemoData.xml`), and this doc.
