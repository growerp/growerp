# Agent Control Center — Demo Walkthrough

A guided demo of the GrowERP Agent Control Center (the ADK platform), using the
**GrowERP Operations Team** from the shared agent catalog — one coordinator that delegates to
domain specialists — so that every control-center capability shows up in one coherent business
story.

| Agent | What it shows |
|-------|---------------|
| **Operations Coordinator** (coordinator, router) | Multi-agent orchestration — routes each request to a specialist |
| **Sales Quote and Order Assistant** (scoped tools, approval-gated writes) | Tool scoping + human-in-the-loop **approvals** on writes |
| **Inventory Digest** (read-only) | Safe read-only MCP tool use + the action audit trail |
| **Sales / Purchasing / Finance / HR Digest** (scheduled) | Scheduled jobs |
| any agent + your own documents | **RAG** retrieval over the company's own policy docs |

Used live during the demo (generated, not seeded): the **approval** queue, the **action audit
log**, and **cross-session memory**.

## How it loads

The team's template rows (`ownerPartyId="_NA_"` in
`backend/data/GrowerpOperationsTeamData.xml`) are **cloned into a tenant** on demand from the
**agent catalog** (catalog icon, tooltip *Agent catalog*) on the **AI Agents** screen.

Call path: `AdkFunctionCatalogView` → `AdkConfigService.loadAgentTeam(adkAgentConfigIds: …)` →
`POST rest/s1/growerp/100/AdkAgentConfig/LoadAgentTeam` → `AdkServices100.load#AgentTeam`
(resolves the calling admin's tenant) → `AdkDemoServices.clone#AgentTeam` (the clone service).

## Prerequisites

- Backend running (`cd moqui && java -jar moqui.war no-run-es`).
- Seed loaded so the `_NA_` templates exist:
  `java -jar moqui.war load types=seed no-run-es`.
- An LLM key — a `gemini` (or other) `LlmConfig` for the tenant in **System Setup**, or the
  `GOOGLE_API_KEY` env var. For the RAG step the key must support embeddings (Gemini or OpenAI).

## Step 0 — Load the team into your tenant

1. Run the **agents** app (`flutter/packages/agents/`) — or any GrowERP app — logged in as a
   tenant admin.
2. Open **AI Agents**, tap the **Agent catalog** icon in the top bar, check every agent under
   the Operations, Sales, Purchasing, Inventory, Finance and HR categories, and tap
   **Add selected**. Idempotent: agents you already have show checked and greyed out.
3. The clone service creates the 9 agents and the coordinator's 8 team links for your tenant.

Verify (MCP / REST, replace `<tenant>` with your owner party id):
- `e1/moqui.adk.AdkAgentConfig?ownerPartyId=<tenant>&teamName=GrowERP Operations Team` → 9 agents.
- `e1/moqui.adk.AdkAgentTeamMember?ownerPartyId=<tenant>` → 8 links (coordinator → each specialist).

## The walkthrough (agents app)

Open the **agents** app. The left menu has: AI Chat, AI Agents, MCP Servers, Agent Jobs,
Approvals, Agent Actions, Knowledge.

### 1. AI Agents — see the team
Open **AI Agents**. You'll see the team grouped as *GrowERP Operations Team*. Open
**Operations Coordinator**: its role is *coordinator* and the specialists are its team members.
Orchestration routes by each member's **description**, so each specialist's description reads
like a "use this when…" hint.

### 2. AI Chat — orchestration
Open **AI Chat** and select **Operations Coordinator**. Try, one at a time:
- *"Which products are out of stock?"* → routes to **Inventory Digest** (read-only).
- *"How many sales orders are still open?"* → routes to **Sales Digest** (read-only).

### 3. Approvals — human-in-the-loop writes (the headline demo)
Still in chat: *"Create a sales quote for customer <name> for 2x <product>."* → the coordinator
routes to **Sales Quote and Order Assistant**. It is `writePolicy=approve`, so the create is
**not** executed — it is queued. The agent tells you it's awaiting approval.

Open **Approvals**: the pending write is listed. **Approve** it → the service runs and the quote
is created. (Reject instead to see it discarded.)

### 4. Agent Actions — the audit trail
Open **Agent Actions**. Every step is logged for your tenant only: the digest reads as
`allowed`, and the quote write going `pending` → `approved`, with token counts. Delegated calls
show the specialist `configId` and the coordinator as `parentConfigId`.

### 5. Agent Jobs — scheduled work
Open **Agent Jobs**. The digests are scheduled (`scheduleEnabled=Y`: Sales, Purchasing and
Inventory daily, Finance and HR weekly) and the Inventory Replenishment Assistant daily. To see a
run now, trigger `AdkSchedulerServices.run#ScheduledAgent` for one of them. The clone gives each
scheduled agent its own delivery room id (template rows cannot carry a tenant's room id).

### 6. Knowledge — the RAG corpus
Open **Knowledge** and add a short policy document, e.g. a return policy. Then ask the
coordinator in **AI Chat**: *"What is our return policy?"* — the agent answers from the
document via `searchKnowledge` and quotes it. The Knowledge screen shows the document and its
chunk count.

### 7. Memory — cross-session recall
After several turns the platform builds a rolling per-user **memory** summary that is injected
into the agent on the next session — mention a preference, start a new session, and the
assistant recalls it.

## What this demo does not add

No demo-only agents, screens, or services — the walkthrough uses the same catalog team, picker
(`AdkFunctionCatalogView`) and clone service (`AdkDemoServices.clone#AgentTeam`) a real company
uses.
