# Implementation Plan — Phase 1: Agent Trust Foundation

## Context

GrowERP already runs LLM agents inside Moqui (`moqui-adk`) with the full ERP exposed as MCP
tools (`moqui-mcp`). The blocker to letting agents do **real operational work** is trust:
today an agent is either read-only or can call **any** Moqui service with no scoping, no
approval, and no agent-specific audit. This phase closes that gap so later phases
(conversational depth, knowledge, multi-agent) can build on a safe base.

The single chokepoint is the `moqui_execute_service` branch of `mcp#ToolsCall`
(`moqui-mcp/service/McpServices.xml`) — every agent mutation flows through it. We add three
things around it: **per-agent tool/service scoping**, a **read/write + approval gate**, and an
**action audit log** attributed to the agent's own party.

Key insight that keeps this small: Moqui service **verbs** already classify intent. Verbs
`get/find/search/view/list/check/calculate` are reads; `create/update/delete/store/add/
remove/send/...` are writes (mirrors Moqui's own authz-action derivation). So write detection
needs no hand-maintained per-service list — derive it from `ec.service.getServiceDefinition(name).verb`.

---

## Changes

### 1. Data model — `moqui-adk/entity/AdkEntities.xml`
Add scoping fields to **`AdkAgentConfig`**:
- `toolMode` (`text-short`): `readOnly` | `scoped` | `full` (default `readOnly`).
- `serviceAllowlist` (`text-long`): CSV/JSON of service-name globs the agent may execute
  (used when `toolMode=scoped`, e.g. `mantle.order.*,growerp.*#get*`).
- `writePolicy` (`text-short`): `block` | `approve` | `allow` (default `approve`) — what
  happens when the agent calls a write-verb service.
- `approvalChatRoomId` (`id`): room where approval requests are posted (reuse the scheduler's
  chat-delivery path).

Add two new entities:
- **`AdkActionLog`** (transactional): `adkActionLogId` PK, `configId`, `adkSessionId`,
  `agentPartyId`, `toolName`, `serviceName`, `argsJson` (`text-very-long`), `verbClass`
  (read/write), `decision` (allowed/blocked/pending/approved/rejected), `resultSummary`,
  `tokensIn`/`tokensOut`/`tokensTotal` (`number-integer`), `actionTime` (`date-time`). Indexes
  on `configId` and `adkSessionId`.
- **`AdkApproval`** (transactional): `adkApprovalId` PK, `adkActionLogId`, `configId`,
  `serviceName`, `argsJson`, `status` (`pending`/`approved`/`rejected`), `requestedByUserId`,
  `decidedByUserId`, `decisionTime`, `expireTime`.

### 2. Scoping + gate at the chokepoint — `moqui-mcp/service/McpServices.xml`
In the `moqui_execute_service` branch of **`mcp#ToolsCall`** (currently runs any defined
service unconditionally):
1. Resolve the calling agent config. The agent identity must reach MCP — today the SSE
   connection authenticates with one identity (`AdkManager.groovy:150-156`). Pass `configId`
   through as an MCP `arguments`/header value set per-runner in `AdkManager`, and read it here.
2. Classify the service: `verbClass = isWriteVerb(def.verb) ? 'write' : 'read'`.
3. Enforce `toolMode`:
   - `readOnly` → reject any `write`; allow reads.
   - `scoped` → reject services not matching `serviceAllowlist` (and still apply `writePolicy`
     to writes).
   - `full` → no scope restriction (still subject to `writePolicy`).
4. Enforce `writePolicy` for writes: `allow` → run; `block` → reject with message; `approve`
   → create `AdkApproval` (status pending) + `AdkActionLog` (decision pending), post an
   approval card to `approvalChatRoomId`, and **return without executing** — telling the agent
   the action is queued for human approval.
5. Always write an `AdkActionLog` row (allowed/blocked/pending) with `argsJson` and timing.

Implement `isWriteVerb` as a small shared helper (new service `mcp#ClassifyServiceVerb` or a
static in `McpToolAdapter`) so it is testable and reusable.

### 3. Approval execution path — `moqui-adk/service/AdkServices.xml` (+ REST in `AdkServices100.xml`)
- **`approve#AdkApproval` / `reject#AdkApproval`**: on approve, run the stored
  `serviceName(argsJson)`, update `AdkActionLog.decision=approved` + `resultSummary`, set
  `AdkApproval.status`. On reject, mark rejected, no execution. Expire stale pending rows.
- REST verbs in `AdkServices100.xml` (`/adk/approvals`, `/adk/actions`) so the Flutter
  `AdkAgentListView` area and the dashboard can list/decide. Approve/reject also reachable from
  the chat card.

### 4. Agent identity & token capture — `moqui-adk/.../AdkManager.groovy`
- Run each agent under a dedicated **agent PartyId** (config field, default a per-company
  `AGENT_<ownerPartyId>` party) so `AdkActionLog.agentPartyId` and Moqui's native entity-audit
  attribute mutations to the agent, not `SystemSupport` (avoids the UserAccount gotcha noted in
  `[[project_chat_useraccount_gotchas]]`).
- Pass `configId` (and agentPartyId) into the MCP call context per runner (extend the SSE
  header/arg map built around `AdkManager.groovy:148-160`).
- Capture token usage from the ADK `Runner` response events and persist on `AdkActionLog`
  (one summary row per turn, or per tool call).

### 5. Tool-list scoping in agent construction — `AdkManager.groovy:173-187`
The hardcoded `allTools` list (Email/Github/MCP) is identical for every agent. Gate the
**FunctionTool** additions by `toolMode`/allowlist too (e.g. only attach `GithubTool` write
methods for agents allowed them). The MCP toolset stays attached but is now governed
server-side by step 2, so a scoped agent physically cannot execute out-of-scope services even
if it tries.

### 6. Dashboard / surfacing — `moqui-adk/screen/Adk/*`
Add an **Actions & Approvals** view under `/vapps/adk/`: recent `AdkActionLog` (filter by
agent), pending `AdkApproval` with approve/reject buttons, and per-agent token totals. Reuses
existing dashboard screen structure.

---

## Critical files

- `moqui/runtime/component/moqui-adk/entity/AdkEntities.xml` — new fields + `AdkActionLog`, `AdkApproval`.
- `moqui/runtime/component/moqui-mcp/service/McpServices.xml` — scoping + gate in `mcp#ToolsCall`.
- `moqui/runtime/component/moqui-adk/service/AdkServices.xml` — approve/reject + execute services.
- `moqui/runtime/component/moqui-adk/service/AdkServices100.xml` — REST `/adk/approvals`, `/adk/actions`.
- `moqui/runtime/component/moqui-adk/src/main/groovy/org/moqui/adk/AdkManager.groovy` — agent
  party identity, configId propagation to MCP, token capture, tool scoping (~lines 148-160, 173-187, 223-229).
- `moqui/runtime/component/moqui-adk/service/AdkSchedulerServices.xml` — reuse its `ChatRoom`
  post helper for approval cards (pattern at lines 122-131).
- `moqui/runtime/component/moqui-adk/screen/Adk/` — Actions & Approvals dashboard view.

Reuse: Moqui service-verb convention for write detection (no new classification table); the
scheduler's chat-room delivery for approval cards; existing `AdkAgentConfig` REST CRUD pattern
in `AdkServices100.xml` for the new endpoints.

---

## Verification (end-to-end)

1. **Read-only enforced:** create an agent with `toolMode=readOnly`. Via `/adk` DevUI, ask it
   to create a product → it should refuse/queue, and `moqui_execute_service` on a `create#`
   service returns blocked. A `get#`/`find#` query still works. Check `AdkActionLog` rows.
2. **Approval gate:** set `toolMode=full, writePolicy=approve, approvalChatRoomId=<room>`. Ask
   the agent to create a customer → no party created yet; an approval card appears in the chat
   room and a `pending` `AdkApproval` row exists. Approve via REST `/adk/approvals` → verify the
   party now exists (`moqui_execute_service` find, or entity find) and `AdkActionLog.decision=approved`.
3. **Reject:** repeat, reject → no entity created, status `rejected`.
4. **Scoping:** `toolMode=scoped`, allowlist `growerp.*#get*` → a `mantle.order.*` call is
   rejected; an allowed read passes.
5. **Attribution & tokens:** confirm an approved mutation's audit/`AdkActionLog.agentPartyId`
   is the agent party (not SystemSupport) and `tokensTotal` is populated.
6. **Regressions:** `cd flutter && ./build_run_all_tests.sh` stays green; existing unscoped
   default agent still answers (default `readOnly` may change behaviour — confirm default
   `growerp-agent` is set to `full`/`approve` to preserve current demo behaviour, or document
   the change). Backend tests under `moqui-mcp/src/test` pass.

---

## Notes / decisions to confirm before build

- **Default for existing agents:** new `toolMode` defaults to `readOnly`. The current
  `growerp-agent` and CI Monitor rely on writes — seed/migrate them to `full` (CI Monitor) and
  `approve` (interactive) so nothing silently breaks.
- **configId→MCP propagation** is the one non-trivial plumbing step (MCP currently has a single
  shared auth identity). If per-call config can't be threaded cleanly, fallback: enforce scope
  in `AdkManager` *before* the MCP call by intercepting tool invocations — less robust, so the
  server-side gate is preferred.
- Phases 2-4 (prefill+submit directives, RAG/`searchKnowledge`, multi-agent orchestration)
  remain in the positioning doc at `plans/growerp-ai-native-company-roadmap.md`.
