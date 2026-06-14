# AI-Native Implementation — Phase 4: Multi-agent orchestration

## Context

Phases 1–3 are shipped and merged to master: per-agent trust/scoping + write-approval gate
(Phase 1), conversational prefill/submit (Phase 2), and per-tenant RAG + rolling memory
(Phase 3). The last AI-native dimension is **multi-agent orchestration**: let a company compose
named **specialist** agents (e.g. Sales, Finance, Support, CI Monitor) under a **coordinator**
that routes/delegates work, plus deterministic **workflow** pipelines (onboard customer, close
period). Roadmap line: *"Named specialist agents composed via an ADK orchestrator agent;
per-company agent teams. Builds directly on the existing dynamic multi-agent config."*

**Goal:** a tenant's chat (or a scheduled job) talks to one coordinator; the coordinator
delegates to the right specialist; every specialist's tool calls remain governed by **its own**
scope/writePolicy/tenant-pin and are audited per agent. No privilege escalation through
delegation; no cross-tenant teams.

## Grounding decisions (from the codebase)

- **The trust linchpin already exists.** Each `AdkAgentConfig` is built into its own `LlmAgent`
  in `AdkManager.initConfig`, each with its **own** `McpToolset` carrying `adk_config_id` +
  `adk_owner_party_id` (`buildMcpToolset(configId, owner)`). The MCP gate
  (`AdkGovernanceServices.govern#AgentAction`) resolves scope/owner from those headers by MCP
  sessionId (see [[project_adk_agent_identity]]). Therefore, **wrapping a specialist's LlmAgent
  as a delegate preserves its governance automatically** — a read-only specialist stays
  read-only even when a coordinator calls it. This is why orchestration is safe to add now.
- **ADK 1.3.0 primitives are present** (verified in `google-adk-1.3.0.jar`):
  - `com.google.adk.tools.AgentTool.create(agent)` — wrap an agent as a callable tool;
    control returns to the caller with the result (`skipSummarization` available).
  - `LlmAgent.Builder.subAgents(...)` with `disallowTransferToParent/Peers` — transfer-style
    delegation (hand off the conversation).
  - `SequentialAgent` / `ParallelAgent` / `LoopAgent` (+ Builders) — deterministic workflows.
- **Default delegation = AgentTool**, not transfer. AgentTool keeps the coordinator in control,
  produces a clean per-specialist audit trail, and avoids the coordinator losing the thread.
  Transfer mode is a later option for "route this whole conversation to Support".
- **Reuse** the per-tenant interactive routing (`ensureInteractiveForTenant`,
  `tenantRegistry`), `runOneOff` + `AdkSchedulerServices` for workflow execution, and the
  owner-scoping helper `growerp.100.GeneralServices100.get#RelatedCompanyAndOwner` for all REST.

## Changes

### 1. Data model — `moqui-adk/entity/AdkEntities.xml`
- **`AdkAgentConfig`** new fields:
  - `agentRole` (`text-short`): `specialist` (default) | `coordinator` | `workflow`.
  - `orchestrationType` (`text-short`, coordinator/workflow only): `router` (LLM picks, via
    AgentTool — default) | `sequential` | `parallel` | `loop`.
- **`AdkAgentTeamMember`** (new, relational, ordered, tenant-keyed):
  `adkAgentTeamMemberId` PK, `ownerPartyId`, `coordinatorConfigId`, `memberConfigId`,
  `sequenceNum` (`number-integer`, for sequential/loop ordering), `delegationMode`
  (`tool` | `transfer`, default `tool`), `enabled`. Constraint: a member's owner must equal the
  coordinator's owner (no cross-tenant teams).
- **`AdkActionLog`** add `parentConfigId` (`id`) — the coordinator that drove this specialist's
  action, so the audit shows the delegation chain. (`loopAgentMaxIterations` optional on config.)

### 2. Orchestration build — `moqui-adk/.../AdkManager.groovy`
- Specialists build exactly as today (own McpToolset/scope) — unchanged.
- In `initConfig`, when `agentRole != specialist`, after building the agent, load its
  `AdkAgentTeamMember` rows (owner-scoped), resolve each `memberConfigId` to its already-built
  `LlmAgent` from `agentRegistry` (build on demand if absent), then:
  - `router` → coordinator `LlmAgent.builder().tools(members.collect { AgentTool.create(it) } + ownMcpToolset?)`.
    Coordinator instruction enumerates each member by name/description ("use Sales for
    quotes/orders, Support for policies…") — generated from member `description`s.
  - `sequential`/`parallel`/`loop` → `SequentialAgent|ParallelAgent|LoopAgent.builder().name(..)
    .subAgents(members).build()` (workflow agents take BaseAgents directly).
- Routing: a tenant's interactive chat should reach its coordinator when one exists —
  `ensureInteractiveForTenant`/`resolveConfigId` prefer an enabled `coordinator` for the owner
  over the generic `INTERACTIVE_<owner>` agent.
- **Delegation audit:** when a member is invoked, write an `AdkActionLog`
  (`toolName=<memberAgentName>`, `verbClass='delegate'`, `decision='delegated'`,
  `parentConfigId=<coordinator>`, `configId=<member>`) — best-effort, mirrors the gate log.
  Member tool calls then log normally under the member's own `configId` (governance unchanged).

### 3. Governance across delegation — `moqui-adk/service/AdkGovernanceServices.xml`
- **No new gate logic needed**: each member's MCP calls already carry its own `adk_config_id`,
  so `govern#AgentAction` enforces that member's `toolMode`/`writePolicy`/allowlist and pins its
  owner. Add only: accept/stamp `parentConfigId` on the log row for trace, and (defensive)
  reject team membership whose `memberConfig.ownerPartyId != coordinator.ownerPartyId`.

### 4. REST + Flutter — `AdkServices100.xml`, `growerp.rest.xml`, `growerp_adk`
- REST (owner-scoped via `get#RelatedCompanyAndOwner`): `get/create/update/delete#AdkAgentTeam`
  for `AdkAgentTeamMember`; coordinator flags ride on the existing AgentConfig CRUD.
- Flutter (`growerp_adk`): in the agent config dialog add **role** + **orchestration type**, and
  a **member picker** (multi-select existing tenant agents, with ordering for sequential/loop).
  In `AdkChatView`, surface a **delegation trace** — ADK events carry the responding agent's
  `author`; show "→ Sales", "→ Support" chips so the user sees who answered. Models in
  `growerp_models` (`adk_agent_team_model.dart`), retrofit endpoints in `rest_client`.

## Phasing
- **4a (router teams):** entities + coordinator(router via AgentTool) + per-member governance
  preserved + delegation audit + config UI (role + members). The headline capability.
- **4b (workflows):** `Sequential/Parallel/Loop` coordinators, runnable as scheduled jobs
  (reuse `runOneOff`/`AdkSchedulerServices`); chat delegation-trace UI.
- **4c (later/optional):** sub-agent **transfer** mode; shared cross-agent session memory;
  external **A2A** (agent-to-agent across tenants/systems) — explicitly out of scope here.

## Critical files
- `moqui/runtime/component/moqui-adk/entity/AdkEntities.xml` — `AdkAgentTeamMember`,
  `AdkAgentConfig.agentRole/orchestrationType`, `AdkActionLog.parentConfigId`.
- `moqui/runtime/component/moqui-adk/src/main/groovy/org/moqui/adk/AdkManager.groovy` —
  coordinator/workflow construction (AgentTool/subAgents), member resolution, routing,
  delegation audit. Reuse `buildMcpToolset`, `agentRegistry`, `tenantRegistry`,
  `ensureInteractiveForTenant`.
- `moqui/runtime/component/moqui-adk/service/AdkServices100.xml` — team-member CRUD REST.
- `moqui/runtime/component/moqui-adk/service/AdkGovernanceServices.xml` — `parentConfigId` on
  log + cross-tenant membership guard.
- `backend/service/growerp.rest.xml` — `/adk` team-member resource.
- `flutter/packages/growerp_adk/lib/src/` — config dialog (role/type/members), chat delegation
  trace; `flutter/packages/growerp_models` — team model + `rest_client`.

## Verification (end-to-end)
1. **Routing:** create specialists "Sales" (`toolMode=scoped`, order/product `get*`) and
   "Support" (knowledge access); create a `coordinator` (router) with both as members; route
   the tenant chat to it. Ask a sales question → coordinator delegates to Sales (AgentTool);
   ask a policy question → delegates to Support → `searchKnowledge` under **Support's**
   `configId`. `AdkActionLog` shows a `delegated` row (parentConfigId=coordinator) then the
   member's own tool rows.
2. **No privilege escalation:** set Sales `toolMode=readOnly`; have the coordinator ask Sales to
   create an order → **blocked** by the gate under Sales's own config (delegation can't widen
   scope).
3. **Tenant isolation:** company B's coordinator cannot add company A's agent as a member
   (owner mismatch rejected); B's chat never reaches A's specialists.
4. **Workflow (4b):** a `SequentialAgent` "onboard customer" runs members in `sequenceNum`
   order; runnable from the scheduler; each step audited.
5. **Regression:** single-agent chat, scheduled CI Monitor, RAG, memory, and the governance
   gate all still work; `melos analyze` clean; `gradlew :runtime:component:moqui-adk:build`.

## ADK version note
- **Java ADK** (`com.google.adk:google-adk`, used by `moqui-adk`) — project pins **1.3.0**;
  latest on Maven Central is **1.4.0**. There is **no Java 2.0**. All Phase-4 primitives
  (`AgentTool`, `SequentialAgent`/`ParallelAgent`/`LoopAgent`, `subAgents` transfer) exist in
  1.3.0 (verified in the bundled jar) and 1.4.0 — so this plan is buildable as-is. Optional
  low-risk bump 1.3.0 → 1.4.0 in `moqui-adk/build.gradle` (`compileOnly`/`adkDevAssets`); first
  confirm the version the **Moqui framework** ships at runtime matches, since ADK is declared
  `runtimeOnly` there and `compileOnly` here.
- **ADK 2.0 is Python-only** (`adk.dev/2.0`): graph workflows + collaborative agents — a richer
  orchestration model than the Java workflow agents. Adopting it would require running agents in
  a **separate Python service** (route via the existing non-Google `llmProvider` side-registry /
  an A2A bridge), not a drop-in upgrade. Out of scope for Phase 4; revisit in 4c/future if the
  Java `Sequential/Parallel/Loop` agents prove too limiting.

## Notes / decisions
- **AgentTool vs transfer:** default AgentTool (control returns, clean audit). Offer transfer
  per-member (`delegationMode=transfer`) only in 4c once the trace UI exists.
- **Coordinator key/model:** reuse the tenant key resolution already in
  `ensureInteractiveForTenant` / `resolveTenantKey`; a coordinator is just another
  `AdkAgentConfig`.
- **Cost/loops:** keep `RunConfig.maxLlmCalls` bounded; `loop` orchestration needs a max-iteration
  cap to avoid runaway spend.
- **Identity gotcha:** every member must keep its **own** `McpToolset` (built per configId) —
  do NOT share the coordinator's toolset, or governance/owner-pinning would collapse to the
  coordinator. See [[project_adk_agent_identity]] and [[reference_moqui_entityauto_servicedef]].
