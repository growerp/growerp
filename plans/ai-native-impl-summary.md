# GrowERP AI-Native — Implementation Summary

How GrowERP becomes the platform for an "AI-native company": agents do real work, the ERP is
driven conversationally, agents are governed/trusted, and they reason over company knowledge.
This is the phase index; see the linked docs for detail.

- Positioning + gap analysis: `plans/growerp-ai-native-company-roadmap.md`
- Phase 1 detail: `plans/ai-native-next.md`
- Phase 2 detail: `plans/ai-native-impl-phase2.md`

## Backbone already in place
LLM agents run **inside** Moqui (`moqui-adk`, Google ADK) — multi-tenant per company, dynamic
create, cron-scheduled, persistent sessions. Every Moqui service + screen is exposed as MCP
tools (`moqui-mcp`). Chat drives the Flutter UI via `growerp-action` directives; `screenCatalog`
auto-derived from `WidgetRegistry`. No separate AI stack to keep in sync.

---

## Phase 1 — Agent Trust Foundation ✅ shipped
Let agents do real work *safely*. The chokepoint: every agent mutation flows through
`moqui_execute_service` in `mcp#ToolsCall`.
- Per-agent scoping on `AdkAgentConfig`: `toolMode` (readOnly|scoped|full), `serviceAllowlist`,
  `writePolicy` (block|approve|allow), `approvalChatRoomId`, `agentPartyId`.
- New `AdkActionLog` (audit) + `AdkApproval` (human-in-the-loop), both `ownerPartyId`-keyed.
- Gate classifies the service verb (read vs write), **pins the call to the agent's own tenant**,
  scopes/approves/blocks, and audit-logs. Approvals delivered to the per-owner chat room.
- New building block **`growerp_adk`** (extracted from core) + tenant-facing Actions & Approvals
  UI; new standalone **`agents` app** (dynamic menu) and `growerp_adk/example`.
- Multi-tenancy is the governing constraint: data, execution, and UI all owner-scoped.
- Commits: moqui-adk `0694443`, moqui-mcp `88c7981`, runtime `d9e0d3b`, root `c17a2b64`+ (merged
  to master, pushed). Integration test green on emulator.
- Deferred: token-usage capture into `AdkActionLog`; cross-tenant isolation integration test.

## Phase 2 — Conversational Depth (prefill + submit) ✅ core shipped
Make chat *do*, not just open. (Auto-derived `screenCatalog` was already done.)
- New `entityFromArgs<T>()` in `growerp_core` builds a typed entity from a directive's `params`.
- `UserDialog`/`ShowCompanyDialog`/`ProductDialog`/`CategoryDialog` builders **prefill on create**
  and advertise prefillable fields in `WidgetMetadata.parameters`.
- `UserDialog` fixed to populate fields in create mode; agent `CONTEXT_PREAMBLE` teaches prefill
  with `_aiPrefill:true`. Writes stay user-confirmed (human reviews & taps Save).
- Commits: root `55b34e90`, moqui-adk `5091d5a` (branch `feat/adk-phase2-prefill-submit`, unpushed).
- Loose ends: "AI-filled — review & Save" banner; Decimal coercion edge; emulator verify.

## Phase 3 — Knowledge / RAG ⏳ next (highest new value)
Let agents reason over company knowledge, not just live queries.
- A knowledge-ingest pipeline (docs/attachments/policies/past chats → embeddings → ES/pgvector;
  ES already in the stack) exposed as a `searchKnowledge` MCP tool.
- Per-company memory: summarize sessions into a durable profile (`AdkMemory` or
  `AdkSession.stateJson`) so agents carry context across conversations.
- Verify: ingest a policy doc; ask a question only answerable from it; confirm `searchKnowledge`
  was called (session event log) and the answer cites it.

## Phase 4 — Multi-Agent Orchestration ⏳ later
- Named specialist agents (sales / finance / support) composed via an ADK orchestrator agent;
  per-company agent teams. Builds directly on the existing dynamic multi-agent config.

---

## Recommended order
1. Close Phase 2 loose ends (emulator verify + push; optional banner).
2. Phase 1 hardening (token capture, cross-tenant test) — small, high-trust.
3. Phase 3 (knowledge/RAG) — the last major gap in the four AI-native dimensions.
4. Phase 4 (multi-agent orchestration).
