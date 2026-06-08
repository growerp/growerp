# GrowERP as the AI-Native Company Platform — Positioning + Gap Roadmap

## Context

Question: how can GrowERP be the tool that facilitates an "AI-native company" — a
company where AI agents do real operational work, the ERP is driven conversationally,
agents are governed/trusted, and they reason over company knowledge.

This is a **strategy/positioning doc**, not a code change. It maps the requirements of an
AI-native company onto what GrowERP **already has**, names the **gaps**, and proposes a
**phased roadmap**. Gaps reference the components/files where the work would land.

The core thesis: GrowERP is unusually well-positioned because the AI layer lives **inside**
the same process and data model as the ERP — no integration glue, no separate AI stack to
keep in sync. The data model, every service, and every screen are already machine-callable.

---

## What GrowERP already has (the AI-native backbone)

| Capability | Where | Status |
|---|---|---|
| LLM agents embedded in the ERP process | `moqui-adk` (Google ADK Java SDK, no Python/extra ports) | ✅ |
| Multi-tenant agents — one+ per company | `AdkAgentConfig.ownerPartyId` | ✅ |
| Dynamic agent create/edit/delete at runtime | REST `/adk/configs` + Flutter `AdkAgentListView` | ✅ |
| Persistent sessions (survive restart) | `AdkSession` / `AdkSessionEvent` entities | ✅ |
| Scheduled (cron) agents posting to chat | `AdkSchedulerServices.xml` → `growerp.general.ChatRoom` | ✅ |
| Every Moqui service+screen as MCP tools | `moqui-mcp` (`mcp#ToolsCall`, `execute#ScreenAsMcpTool`) wired via `McpToolset` in `AdkManager.groovy:160` | ✅ |
| Custom function tools | `EmailTool`, `GithubTool` registered in `AdkManager.groovy:175-185` | ✅ |
| Chat → drive the actual UI (open screens) | `adk_chat_view.dart` + `ai_navigation_service.dart` via `growerp-action` JSON directives; `screenCatalog` in session state | ✅ |
| Working autonomous agent example | CI Monitor agent (`GithubTool.groovy` + `CI_MONITOR_AGENT` config) | ✅ |

So GrowERP can already: spin up a per-company agent, give it the full ERP API as tools,
let it run on a schedule or in chat, persist its memory, and have it open the right screen
for a human. That is most of the skeleton of an AI-native company.

---

## The four dimensions: what's missing, and the fix

### 1. Agents do real work (autonomous operational execution)
**Have:** agents can *call* any Moqui service (create order, post invoice, send email) and
run on cron. CI Monitor proves end-to-end autonomous action (reads CI, opens PR).
**Gap:**
- No **approval/confirmation gate** before a mutating service runs — agents either can do
  everything or read-only, nothing between.
- No **tool registry / scoping** per agent — every agent gets the same global toolset
  (`AdkManager.groovy:175-185`). Can't say "support agent: read tickets + reply only."
- No **idempotency / dry-run** convention for agent-invoked mutations.
**Fix lands in:** `AdkManager` tool wiring (per-config tool allowlist on `AdkAgentConfig`),
a new `mcp` mutation-classification (mark services read vs write), an approval queue entity
+ chat-card UI reusing the existing chat-room delivery path.

### 2. Conversational ERP (everything reachable by natural language)
**Have:** chat opens operational Flutter screens via directives; ADK DevUI chat; MCP screen
browse/narrate.
**Gap:**
- Directives currently **navigate-only** (per memory `project_adk_screen_directives`) —
  chat can open a screen but not pre-fill / submit a form for the user to confirm.
- `screenCatalog` is curated, not auto-derived — new screens aren't discoverable until added.
- No voice / no embedded chat on every screen (chat is a destination, not ambient).
**Fix lands in:** extend `growerp-action` JSON schema + `ai_navigation_service.dart` to carry
prefilled args and a "review & submit" action; auto-populate `screenCatalog` from the Moqui
screen tree already exposed by `moqui-mcp`.

### 3. Governance & trust (so agents can be trusted with operations)
**Have:** every turn persisted (`AdkSessionEvent`), Moqui's native per-service authz, audit
log on entity changes.
**Gap:**
- No **agent-action audit view** ("what did agent X do across all sessions, with which
  tool args, on whose behalf").
- No **cost/token tracking** per agent/company.
- No **guardrails** (rate limits, spend caps, blocked services) or **eval harness** to catch
  regressions in agent behaviour.
- Agents run as a system identity → actions not attributed to the agent's own party for
  authz/audit (see chat UserAccount gotchas, `project_chat_useraccount_gotchas`).
**Fix lands in:** an `AdkActionLog` entity + Moqui dashboard screen under `/vapps/adk/`;
token usage capture in `AdkManager` runner; run each agent under a dedicated PartyId so
existing Moqui audit attributes actions correctly; optional eval set (ADK eval skill).

### 4. Knowledge & memory (reason over company data, not just live queries)
**Have:** agents query live ERP data through MCP on demand; session state is durable.
**Gap:**
- No **RAG / vector store** over company documents, policies, past chats, product copy.
- No **cross-session long-term memory** beyond raw event log (no summarized profile per
  company/user/customer).
- ES is in the stack (`no-run-es` flag everywhere) but not used as a knowledge index for
  agents.
**Fix lands in:** a knowledge-ingest service (docs/attachments → embeddings → ES or pgvector)
exposed as an MCP `searchKnowledge` tool; a memory-summarization step writing back to
`AdkSession.stateJson` or a new `AdkMemory` entity.

---

## Recommended phased roadmap

**Phase 0 — Inventory & narrative (no code).** Publish this positioning so the AI-native
story is explicit in `docs/` (e.g. `docs/GrowERP_AI_Native.md`), linking the existing
`GrowERP_AI_Instructions.md` and the `moqui-adk` README.

**Phase 1 — Trust foundation (highest leverage).** Per-agent tool scoping + read/write
service classification + approval gate + `AdkActionLog`. Without this, "agents do real work"
is unsafe, so this unblocks every other dimension. Reuses existing chat-room delivery for
approvals.

**Phase 2 — Conversational depth.** Prefill+submit directives and auto-derived
`screenCatalog`. Turns "open the screen" into "do the thing, here's what I'll do, confirm."

**Phase 3 — Knowledge layer.** RAG `searchKnowledge` MCP tool + per-company memory summaries.

**Phase 4 — Multi-agent orchestration.** Named specialist agents (sales, finance, support)
composed via an ADK orchestrator agent; per-company agent teams. Builds directly on the
existing dynamic multi-agent config.

---

## Critical files / components (where work would land)

- `moqui/runtime/component/moqui-adk/src/main/groovy/org/moqui/adk/AdkManager.groovy` — tool
  registration, runner, where scoping + token tracking attach (lines ~160, 175–185).
- `moqui/runtime/component/moqui-adk/entity/AdkEntities.xml` — add `AdkActionLog`,
  `AdkMemory`, per-config tool allowlist fields.
- `moqui/runtime/component/moqui-adk/service/AdkSchedulerServices.xml` — reuse chat-room
  delivery for approval requests.
- `moqui/runtime/component/moqui-mcp/service/McpServices.xml` — read/write service
  classification; `searchKnowledge` tool.
- `flutter/packages/growerp_core/lib/src/services/ai_navigation_service.dart` &
  `src/adk/adk_chat_view.dart` — extend directive schema (prefill/submit/approve cards).
- `docs/GrowERP_AI_Native.md` (new) — the published positioning.

## Verification (per phase, once built)

- **Phase 1:** configure an agent with a write tool behind approval; ask it (via `/adk` DevUI
  or chat) to create an order; confirm an approval card appears in the chat room, action only
  fires on approve, and a row lands in `AdkActionLog` attributed to the agent party.
- **Phase 2:** in chat, "create a customer named X" → screen opens prefilled → submit →
  verify via `moqui_execute_service` / entity find that the party exists.
- **Phase 3:** ingest a sample policy doc; ask the agent a question only answerable from it;
  confirm the `searchKnowledge` tool was called (session event log) and the answer cites it.
- **Cross-cutting:** existing integration tests (`./build_run_all_tests.sh`) stay green;
  add ADK eval set using the `google-agents-cli-eval` skill.
