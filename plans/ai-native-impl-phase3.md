# AI-Native Implementation — Phase 3: Knowledge / RAG + per-company memory

## Context
Phases 1 (agent trust foundation) and 2 (conversational prefill/submit) are shipped. Agents can
act safely and drive the UI, but they only reason over **live ERP queries** — they have no access
to company documents/policies and no memory across conversations. Phase 3 closes the last of the
four AI-native dimensions: let agents **reason over org knowledge** and **remember**.

Two capabilities:
1. **RAG** — a `searchKnowledge` MCP tool over a per-tenant knowledge store (docs, policies,
   product copy, past-chat summaries).
2. **Per-company memory** — a rolling summary of a user/company's past sessions, injected into the
   agent's context so it carries continuity.

### Grounding decisions (from the codebase)
- **No Elasticsearch dependency.** `no-run-es` is used everywhere and there is no `ElasticFacade`
  usage in growerp/mcp/adk — ES is normally not running. So the vector store is an **in-DB entity
  + cosine similarity in a service** (brute-force over a tenant's chunks is fine at the scale of
  company docs; can be swapped for ES/pgvector later behind the same service interface).
- **Embeddings via Gemini** `text-embedding-004` (`embedContent` REST), using the tenant's
  resolved API key — the same key-resolution `AdkServices.update#AgentConfig` already does
  (per-agent `apiKey` → `growerp.general.LlmConfig`). Keeps one provider.
- **MCP tool wiring** mirrors the existing pattern: a descriptor in the `tools/list` block
  (`McpServices.xml` ~line 3300) + a branch in `mcp#ToolsCall`, delegating to a moqui-adk service
  guarded by `ec.service.isServiceDefined(...)` (exactly how the Phase 1 governance hook is wired).
- **Tenant isolation** reuses Phase 1: the agent's `ownerPartyId` is resolved from its
  `AdkAgentConfig` (configId carried on the MCP call); all knowledge/memory rows carry
  `ownerPartyId` and every query filters on it.
- **Memory injection** reuses the `CONTEXT_PREAMBLE` templating in `AdkManager` (`{userId}`,
  `{tenantId}`, `{screenCatalog}` …) — add a `{memory}` placeholder.

## Changes

### 1. Data model — `moqui-adk/entity/AdkEntities.xml`
- **`AdkKnowledgeDoc`** (`ownerPartyId`, `adkKnowledgeDocId` PK, `sourceType` [upload|product|
  policy|chat|note], `sourceId`, `title`, `mimeType`, `createdByUserId`, `createdDate`,
  `enabled`). One row per ingested document/note.
- **`AdkKnowledgeChunk`** (`adkKnowledgeChunkId` PK, `ownerPartyId`, `adkKnowledgeDocId`, `seq`,
  `text` text-very-long, `embeddingJson` text-very-long [JSON float array], `tokens`). Indexed on
  `ownerPartyId`.
- **`AdkMemory`** (`adkMemoryId` PK, `ownerPartyId`, `userId`, `summaryText` text-very-long,
  `factsJson`, `lastUpdated`). One rolling summary per (owner,user) — and optionally an
  owner-level summary (`userId` null).

### 2. Knowledge + embedding services — `moqui-adk/service/AdkKnowledgeServices.xml` (new)
- `embed#Text` — Groovy helper: POST to Gemini `:embedContent` (model `text-embedding-004`) with
  the tenant key; returns `List<Double>`. (One place; reused by ingest + search.)
- `ingest#AdkKnowledge` (in: ownerPartyId, sourceType, sourceId, title, text) — chunk the text
  (~800 tokens, ~100 overlap), embed each chunk, upsert `AdkKnowledgeDoc` + `AdkKnowledgeChunk`.
- `search#AdkKnowledge` (in: ownerPartyId, query, limit=5) — embed the query, load the owner's
  chunks, rank by cosine similarity, return top-K `{text, title, sourceType, score}`. Cosine in
  Groovy (Java math API → allowed).
- `delete#AdkKnowledgeDoc`, `reindex#AdkKnowledge` (housekeeping).

### 3. `searchKnowledge` MCP tool — `moqui-mcp/service/McpServices.xml`
- Add a descriptor to the `tools/list` array (name `searchKnowledge`, inputSchema `{query, limit}`).
- Add a `if (name == 'searchKnowledge')` branch in `mcp#ToolsCall` that resolves the agent's
  `ownerPartyId` (same `adk_config_id` header / `AdkGovernanceServices`-style lookup used by the
  gate) and calls `moqui.adk.AdkKnowledgeServices.search#AdkKnowledge` **only if defined**
  (`isServiceDefined` guard). Returns the chunks as MCP text content. Also log it to
  `AdkActionLog` (read verb) via the existing governance hook so usage is auditable.

### 4. Per-company memory — `moqui-adk/.../AdkManager.groovy` + `AdkKnowledgeServices.xml`
- `summarize#AdkSession` (in: adkSessionId | ownerPartyId+userId) — read recent `AdkSessionEvent`
  rows, ask the model for a concise running summary + key facts, upsert `AdkMemory`. Trigger:
  on session close / every N turns, or a scheduled job reusing `AdkSchedulerServices`.
- In `AdkManager` session bootstrap (where `{userId}`/`{tenantId}` are filled), load the
  `(owner,user)` `AdkMemory.summaryText` and substitute a new `{memory}` placeholder in
  `CONTEXT_PREAMBLE` (empty string when none).

### 5. REST + Flutter UI (tenant-facing) — `growerp_adk`
- REST in `AdkServices100.xml` + `growerp.rest.xml`: `AdkKnowledge` (GET list, POST ingest text,
  DELETE) — all owner-scoped via `get#RelatedCompanyAndOwner` (same pattern as `/adk/actions`).
- `growerp_models`: `AdkKnowledgeDoc` model + RestClient methods.
- `growerp_adk`: a **Knowledge** view (list docs, add note/upload, delete) next to the Agents /
  Approvals / Actions views; register its widget + add a menu item (admin + agents apps).
  Document upload can reuse Moqui `DbResource` for the file, then `ingest#AdkKnowledge` on its text.

## Phasing
- **3a (core RAG):** entities + `embed#Text` + `ingest`/`search` services + `searchKnowledge` MCP
  tool. Ingest seedable via REST. This alone proves "agent answers from a company doc."
- **3b (sources + UI):** Flutter Knowledge view (note/upload + list), plus auto-ingest of product
  descriptions / policies.
- **3c (memory):** `AdkMemory` + `summarize#AdkSession` + `{memory}` preamble injection.

## Critical files
- `moqui/runtime/component/moqui-adk/entity/AdkEntities.xml` — 3 new entities.
- `moqui/runtime/component/moqui-adk/service/AdkKnowledgeServices.xml` — new (embed/ingest/search/summarize).
- `moqui/runtime/component/moqui-mcp/service/McpServices.xml` — `searchKnowledge` descriptor + dispatch (optional-hook to moqui-adk).
- `moqui/runtime/component/moqui-adk/src/main/groovy/org/moqui/adk/AdkManager.groovy` — `{memory}` placeholder + key resolution reuse.
- `moqui/runtime/component/moqui-adk/service/AdkServices100.xml` + `backend/service/growerp.rest.xml` — owner-scoped `/adk/knowledge` REST.
- `flutter/packages/growerp_models` (AdkKnowledge model + RestClient) and `flutter/packages/growerp_adk` (Knowledge view + service + menu).

Reuse: Phase 1 configId→owner resolution and the `isServiceDefined` MCP→adk hook; `AdkActionLog`
for auditing tool use; `CONTEXT_PREAMBLE` templating; `LlmConfig`/per-agent key resolution from
`AdkServices.update#AgentConfig`; `get#RelatedCompanyAndOwner` owner scoping; `AdkSchedulerServices`
for periodic summarization; Moqui `DbResource` for uploaded files.

## Verification
1. **RAG:** POST a short policy ("Returns accepted within 14 days") via `/adk/knowledge`; in chat
   ask "what's our return policy?" → agent calls `searchKnowledge` (visible in `AdkActionLog`) and
   answers citing the chunk. A question with no matching doc → agent says it doesn't know (no
   hallucinated citation).
2. **Tenant isolation:** company B cannot retrieve company A's chunks (search filtered by owner).
3. **Memory:** multi-turn chat stating a preference; start a **new** session; agent recalls it from
   `AdkMemory` (and `{memory}` appears in the rendered preamble / session log).
4. **Regression:** existing MCP tools and the governance gate unaffected; `melos analyze` clean;
   backend builds (`gradlew :runtime:component:moqui-adk:build`).

## Notes / decisions
- **In-DB cosine vs ES:** start in-DB (no infra dependency). If a tenant's knowledge grows large,
  swap the `search#AdkKnowledge` internals for ES `dense_vector` behind the same service — no
  caller/tool change.
- **Embedding cost/caching:** embeddings computed once at ingest; only the query is embedded per
  search. Store the embedding model id on the chunk so a model change can trigger reindex.
- **Memory privacy:** memory is per (owner,user); never mix tenants. Summaries exclude secrets
  (api keys, tokens).
