# Plan: OKF (Open Knowledge Format) for the GrowERP ADK knowledge base

## Context

Google's Open Knowledge Format (OKF v0.1, GoogleCloudPlatform/knowledge-catalog/okf)
formalizes "knowledge" into a **portable bundle of markdown files with YAML frontmatter**,
so the same files are human-readable and AI/agent-parseable. Conformance is deliberately thin:

- Each concept = one `.md` file with YAML frontmatter; **`type` is the only required field**
  (recommended: `title`, `description`, `resource`, `tags`, `timestamp`).
- File path = concept identity; directory tree groups concepts (`datasets/`, `tables/`, ...).
- Relationships = **normal markdown links** between files (`[customers](/tables/customers.md)`),
  forming a graph richer than the folder tree.
- Reserved files: `index.md` (navigation), `log.md` (change history).
- Bundle is "just files" — shippable as a git dir or tarball, no runtime/SDK.

**Goal:** make GrowERP a full participant in the OKF ecosystem and slot OKF into the ADK stack
as the **curated-knowledge layer that complements RAG — it does not replace it.** OKF and RAG
solve different problems and work together:

| Layer | Role |
| ----- | ---- |
| **OKF** | Curated, structured, version-controlled domain knowledge — "what the agent knows". |
| **RAG** | Retrieves the most relevant chunks at query time, for data too large/dynamic to preload. |
| **MCP** | Connects the agent to tools and live systems. |
| **LLM** | Reasons over all of the above. |

Pipeline: *raw docs → AI/human curation → OKF bundle → feeds **both** agent context **and** the
RAG index.* Instead of indexing messy documents directly, RAG indexes high-quality OKF. For
GrowERP, **OKF holds stable domain knowledge** (entity definitions, business processes,
accounting rules, manufacturing workflows, API docs, module relationships) loaded into context;
**RAG keeps its role** for large/changing/user-specific/permissioned data (manuals, customer
documents, transaction history, logs). This covers all five OKF call-to-action items (read spec,
producer, consumer, try reference impl, contribute upstream). Producer source = GrowERP's
**entity/data model**.

GrowERP's ADK already has most of the pieces (Google ADK Java):
- Sessions/State → `MoquiSessionService` + `AdkSession`/`AdkSessionEvent` ✓
- Memory/compaction → `AdkMemory` + `maybeSummarize` rolling summary (`{memory}`) ✓
- RAG → `embed#Text`/`ingest#AdkKnowledge`/`search#AdkKnowledge` over `AdkKnowledgeChunk` ✓ **kept**
- **Missing (to add):** OKF-navigation tooling for direct context loading, file-based **skills**
  (`load_skill_resource` analog), an OKF→RAG ingest path, ADK **Artifacts** for large binaries.

Phases:
- **Phase 0 — Read the real spec (#1):** validate assumptions against canonical `SPEC.md`.
- **Phase 1 — Producer (#2):** backend exporter → OKF bundle hosted as a Moqui `WikiSpace`;
  frontmatter `type` uses title-case human strings (`Moqui Entity`, `Reference`, `Playbook`);
  bundle-root `index.md` declares `okf_version: "0.1"`; `index.md` is the agent's entry graph.
- **Phase 2 — Human viewer/editor (#3a):** `growerp_wiki` Flutter building block.
- **Phase 3 — Consumer, OKF + RAG together (#3b):** add OKF context-navigation tooling + skills
  AND feed OKF into the existing RAG index; both paths coexist, reusing Session/Memory services.
- **Phase 4 — Run the reference implementation (#4):** Google's visualizer + enrichment agent
  against the GrowERP bundle, as an acceptance gate.
- **Phase 5 — Upstream contribution (#5):** file issues / PRs / propose extensions.

GrowERP today has the raw material but no OKF: `backend/entity/*.xml` only *extend* mantle/moqui
base entities, docs are plain markdown (no frontmatter), and there is no bundle structure or
exporter. The clean approach is to introspect the **runtime** entity definitions (which already
merge base + GrowERP extensions) via Moqui's `EntityFacade` and emit markdown.

**Hosting via the Moqui wiki.** Moqui's wiki (`moqui.resource.wiki.WikiSpace` /
`WikiPage`, framework-level) is itself a tree of CommonMark `.md` files: a `WikiSpace` has a
`rootPageLocation`, and pages are `<rootPageLocation>/<pagePath>.md` rendered by flexmark with
GFM tables. That is exactly the OKF substrate. So the produced bundle is registered as a
`WikiSpace` and becomes immediately **AI-consumable** — `McpServices.xml:62` reads wiki pages
via `pageRef.getText()`, `moqui_get_help(uri="wiki:...")` exposes them, and growerp REST already
serves `get#PublishedWikiPageText` (backend/service/growerp.rest.xml:1307).
So no new serving layer is needed for machines. Note: this runtime has **no Moqui wiki render
screen** (no SimpleScreens/HiveMind wiki component), so there is no human browse UI yet — that
is exactly what Phase 2 provides.

## Phase 0 — Read the real spec (#1) — DONE

Read canonical `okf/SPEC.md` (v0.1 draft) + sample bundles (GA4, crypto_bitcoin, stackoverflow)
from `GoogleCloudPlatform/knowledge-catalog`. Findings:

**Confirmed:** `type` is the only required field; concept = one `.md` (frontmatter + body);
reserved `index.md`/`log.md`; absolute bundle-relative links (`/tables/x.md`) recommended;
`# Schema` is a conventional body heading; conformance is just 3 rules (parseable frontmatter,
non-empty `type`, valid index/log structure) and consumers MUST tolerate broken links + unknown
types + missing fields — matching our permissive `okf_follow`.

**Deltas folded into the plan below:**
1. `type` values are **title-case human strings** (`BigQuery Table`, `Metric`, `Playbook`,
   `Reference`). Use `Moqui Entity`, `Reference`, `Playbook` — not lowercase tokens.
2. `index.md` files carry **no frontmatter**, except the **bundle-root** `index.md` MAY declare
   `okf_version: "0.1"` (the only place frontmatter is allowed in an index).
3. `index.md` format is fixed: `# Section` headings + `* [Title](relative-link) - description`
   bullets, **relative** links, description copied from the target concept's frontmatter.
4. `references/` subdirectory holds metrics/external material as first-class `type: Reference`
   concepts (relevant to the deferred metrics phase).
5. `# Citations` is the conventional source-list heading; our `# Relationships` is a
   producer-defined heading (allowed) — relationships expressed as prose + markdown links.
6. Each sample bundle ships a `viz.html` (the static visualizer) at its root, plus Python tooling
   under `okf/src` + repo `toolbox/` — used directly in Phase 4.

## Approach

Add one backend Moqui service that walks runtime entity definitions and writes an OKF bundle.
Introspection + file IO require the Java API, so a Groovy script is justified here (per the
XML-mini-language rule, Groovy is allowed for Java API calls).

### Bundle layout produced
```
<rootPageLocation>/growerp/     # output dir = WikiSpace GROWERP_OKF root (configurable)
├── index.md                    # bundle root nav (links to datasets/)
├── log.md                      # generation timestamp + counts
├── datasets/
│   ├── index.md
│   └── growerp.md              # the "GrowERP data model" dataset, links to every table
└── tables/
    ├── index.md                # links to every entity .md
    ├── Party.md
    ├── OrderHeader.md
    └── ... one file per entity
```

### Per-entity file (e.g. `tables/OrderHeader.md`)
```markdown
---
type: Moqui Entity
title: OrderHeader
description: <entity @description, else prettyName>
resource: ${baseUrl}/rest/e1/mantle.order.OrderHeader
tags: [mantle, order]
timestamp: 2026-06-22T...Z
---

# Schema
| Column | Type | PK | Description |
|--------|------|----|-------------|
| `orderId` | id | ✓ | ... |

# Relationships
- one [Party](/tables/Party.md) via `partyId`
- many [OrderItem](/tables/OrderItem.md)
```

## Phase 1 — Backend exporter + wiki hosting

### 1. New service — `backend/service/growerp/100/OkfServices100.xml`
Define `export#OkfBundle` with params:
- `wikiSpaceId` (default `GROWERP_OKF`) — target wiki space; service resolves its
  `rootPageLocation` (creating the `WikiSpace` row if missing) and writes the bundle under it.
- `outputPath` (default = `<rootPageLocation>/growerp`) — overridable for plain-dir export.
- `packagePrefixes` (default `mantle.,growerp.`) — **scopes the export** away from the
  thousands of framework entities; entity universe is huge so this filter is essential.
- `includeViewEntities` (default `false`)
- `baseUrl` (default from `SystemSettings`/`localhost:8080`) — for the `resource` link
  (use the wiki `publicPageUrl` form so `resource:` points at the served wiki page).

Returns `outputPath`, `wikiSpaceId`, `entityCount`. Admin-auth only.

After writing files, **register the WikiSpace**: ensure a `moqui.resource.wiki.WikiSpace`
row exists with `wikiSpaceId=GROWERP_OKF`, `rootPageLocation` = the bundle parent, and a
`publicPageUrl`. The bundle's `index.md` becomes the space root page; the folder tree maps to
the wiki page hierarchy automatically (no per-page `WikiPage` rows needed — pages resolve from
the filesystem under `rootPageLocation`).

### 2. New Groovy script — `backend/src/main/groovy/.../OkfExport.groovy`
(called via `<script>` from the service). Core loop, using the confirmed APIs:

- `efi = ec.entity` (EntityFacadeImpl); iterate `efi.getAllEntityNames()`.
- Filter by `packagePrefixes`; skip view entities unless requested
  (`ed.isViewEntity()` / `ed.getEntityNode()`).
- For each `ed = efi.getEntityDefinition(name)`:
  - Frontmatter: `type: Moqui Entity`; `title = ed.getEntityName()`;
    `description` from `ed.getEntityNode().attribute("description")` or `getPrettyName(...)`;
    `resource = baseUrl + "/rest/e1/" + ed.getFullEntityName()`;
    `tags` = package segments; `timestamp` = `ec.user.nowTimestamp` ISO.
  - `# Schema`: `for (fn in ed.getAllFieldNames())` → `fi = ed.getFieldInfo(fn)` →
    columns `fi.name`, `fi.type`, `fi.isPk` (FieldInfo fields confirmed).
  - `# Relationships`: `ed.getRelationshipsInfo(false)` → each `RelationshipInfo` has
    `type` (one/many), `relatedEntityName`, `title`, `keyMap` → emit markdown link
    `[<RelatedShortName>](/tables/<RelatedShortName>.md)` (graph edges).
- Write files via `java.nio` / `File`. Generate the three `index.md`, `datasets/growerp.md`,
  and `log.md` after the loop.

**Reuse / reference (do not duplicate):**
- `moqui/framework/.../util/RestSchemaUtil.groovy` — reference for field-type handling and
  `getRelationshipsInfo` usage (lines 91–255); we emit raw Moqui types, no remapping needed.
- `EntityDefinition.groovy` — `getAllFieldNames` (527), `getFieldInfo` (621),
  `getRelationshipsInfo` (700), `getPrettyName` (882), `getFullEntityName` (503).
- `FieldInfo.java` (`type`, `columnName`, `isPk`); `EntityJavaUtil.RelationshipInfo`
  (`type`, `relatedEntityName`, `title`, `keyMap`).

### 3. Renderer fix — `moqui/framework/.../renderer/MarkdownTemplateRenderer.groovy`
flexmark currently loads only `TablesExtension` + `TocExtension`, so OKF's `---` YAML
frontmatter renders as raw text / a thematic break in the wiki UI. Add flexmark's
`YamlFrontMatterExtension` to the extension list so frontmatter is parsed/stripped cleanly
(GitHub already hides it). **This is an upstream change to `moqui/framework`** → must be made
on the growerp fork and pulled back via `sync-submodules.sh` (see CLAUDE.md). Cosmetic only —
the OKF files are valid with or without it.

### 4. WikiSpace registration (seed/data)
Add a `moqui.resource.wiki.WikiSpace` seed row for `GROWERP_OKF` (or create it idempotently in
the service per step 1). This makes the bundle browsable at its `publicPageUrl` and reachable
via the existing MCP wiki tools — the native "data sharing" surface.

### 5. (Optional) REST trigger — `backend/service/growerp.rest.xml`
Add an `Okf` resource (admin auth) with `GET` → calls `export#OkfBundle` for on-demand
regeneration. Optional; the service + wiki space already satisfy "produce and serve a bundle".

### Phase 1 verification

1. Run the exporter: via MCP `moqui_execute_service` (`growerp.100.OkfServices100.export#OkfBundle`)
   or the REST endpoint, against a running backend (`java -jar moqui.war no-run-es`).
2. Inspect the bundle dir (under the WikiSpace `rootPageLocation`):
   - `tables/Party.md` exists, has valid YAML frontmatter with **`type:`** present,
     a `# Schema` table, and `# Relationships` markdown links pointing at real sibling files.
   - `index.md` / `datasets/growerp.md` link to existing table files (no dead links).
3. Wiki serving (machine): call `growerp.website.WebSiteRestServices.get#PublishedWikiPageText`
   for `GROWERP_OKF` / `tables/Party` — returns rendered text, frontmatter hidden (renderer fix),
   schema as a GFM table.
4. AI consumption: `moqui_get_help(uri="wiki:GROWERP_OKF/tables/Party")` (or `moqui_rest_call`)
   returns the page text — confirms agents reach the bundle.
5. Conformance smoke test: render a file on GitHub (frontmatter hides); optionally run Google's
   OKF **static HTML visualizer** (knowledge-catalog/okf reference impl) over the bundle dir.
6. Re-run with `packagePrefixes=growerp.` to confirm scoping narrows output.

## Phase 2 — `growerp_wiki` Flutter building block (human browse/edit)

New building block under `flutter/packages/growerp_wiki/` following the standard domain pattern
(`blocs/`, `views/`, `widgets/`, `example/integration_test/`) — see
`docs/Building_Blocks_Development_Guide.md` and an existing block like `growerp_catalog` as the
template. Purpose: browse the OKF/wiki page tree and manually author/enrich pages from any
GrowERP app.

### Backend REST (extend, don't duplicate)
A read path already exists (`get#PublishedWikiPageText`); add the missing pieces in
`backend/service/growerp/100/` + `growerp.rest.xml`, wrapping framework `WikiServices.xml`:
- `get#WikiSpaces` / `get#WikiPageTree` (list spaces + page hierarchy — wraps
  `get#WikiPageChildren`).
- `update#WikiPage` (upsert page text → writes the `.md` under `rootPageLocation`,
  calls `set#PublishedVersion`).
Admin/owner-auth; reuse existing wiki services rather than reimplementing storage.

### Flutter
- `WikiBloc` (Fetch tree / Fetch page / Update page) + freezed `WikiPage`/`WikiSpace` models in
  `growerp_models` (with `@DateTimeConverter()` per the DateTime rule).
- `WikiList` (ListFilterBar search + StyledDataTable of pages + add FAB) and `WikiDialog`
  (Dialog+popUp detail/edit with a markdown editor + preview) — matching the canonical
  list/detail design rules. All interactive widgets keyed.
- Render markdown with an existing Flutter markdown widget; show frontmatter as structured
  metadata fields (type/title/tags) above the body.
- Compose the block into at least the `admin` app menu.

### Generated-vs-authored safety
The exporter regenerates entity pages and would clobber hand edits. Keep generated pages
(`tables/`, `datasets/`) and authored pages in **separate path prefixes** within the space, and
have the exporter only overwrite under its own generated prefixes; record changes in `log.md`.

### Verify
Integration test (`example/integration_test/`, `CommonTest` add/update/check pattern): list the
`GROWERP_OKF` space, open `tables/Party`, edit an authored note page, save, re-fetch and confirm
persistence; run `melos build` (freezed/retrofit) + `melos analyze`; run headless via
`./build_run_all_tests.sh wiki`.

## Phase 3 — Consumer: OKF curation feeding both context and RAG (#3b)

OKF and RAG **coexist**. OKF is the curated layer for stable domain knowledge loaded into agent
context; RAG keeps its role for large/dynamic/permissioned data. Add the two OKF paths; keep the
existing RAG stack untouched.

**Path A — direct context navigation (new).** OKF-navigation MCP tools in `moqui-mcp`, alongside
the existing wiki read path that already serves `pageRef.getText()`:
- `okf_index` — return the bundle's `index.md` (the entry graph) for the agent to orient.
- `okf_load_concept(path)` — return one concept's frontmatter + body (the `load_skill_resource`
  / file-based **skill pattern**: pull exactly the reference needed, progressive disclosure via
  `index.md`, no whole-corpus dump). Use for stable domain knowledge: entity defs, business
  processes, accounting rules, manufacturing workflows, API docs, module relationships.
- `okf_follow(path)` — resolve a concept's markdown links to navigable neighbours; tolerate
  broken links (spec requires it).
These read the same files the wiki hosts (`<rootPageLocation>`), so no second store.

**Path B — OKF into the existing RAG index (new ingest, RAG kept).** Add `ingest#OkfBundle` to
`AdkKnowledgeServices.xml` that walks a bundle, parses YAML frontmatter (type/title/tags/resource)
into `AdkKnowledgeDoc` metadata, then chunks + embeds the body via the **existing**
`embed#Text`/`ingest#AdkKnowledge` pipeline. This realizes "index high-quality OKF, not messy
docs": curated OKF becomes the preferred RAG source. `search#AdkKnowledge` and `searchKnowledge`
**stay** as the retrieval path for large/changing/user-specific/permissioned data. Add a small
`sourceType='okf'` + optional `metadataJson` field on `AdkKnowledgeDoc` to round-trip frontmatter.

**Routing.** Agent instruction: *load stable domain knowledge directly via `okf_index` →
`okf_load_concept`/`okf_follow`; fall back to `searchKnowledge` (RAG) for bulk/operational data
(manuals, customer docs, transaction history, logs).*

**Reuse (no new infra):** `MoquiSessionService` (state), `AdkMemory` + `maybeSummarize`
(memory / compaction).

**ADK Artifacts (in scope):** wire an ADK `ArtifactService` (Moqui-resource-backed) so large
binaries (PDFs/images) referenced by a concept stay out of the conversation context; the agent
loads them only when needed.

**External consume:** both paths work on any OKF bundle (e.g. Google sample bundles dropped under
a `WikiSpace`) — the real, format-level consumer.

### Phase 3 verification
- Path A: ask a stable-knowledge question ("what joins to `OrderHeader`?"); confirm the agent
  answers via `okf_index`→`okf_load_concept`/`okf_follow` (check `AdkActionLog`), citing concept
  paths; broken-link target degrades gracefully.
- Path B: run `ingest#OkfBundle` on the GrowERP bundle; confirm `AdkKnowledgeDoc`/`Chunk` rows
  created with `sourceType='okf'` and `search#AdkKnowledge` returns OKF-sourced chunks.
- Routing: a bulk/operational question still resolves via RAG `searchKnowledge` (unchanged).
- Large-binary check: a concept referencing a PDF loads via `ArtifactService` without dumping the
  file into context.

## Phase 4 — Run the reference implementation (#4)

Acceptance gate, not optional:
- Run the OKF repo's **static HTML visualizer** against the generated GrowERP bundle; confirm the
  concept graph loads and entity-relationship links resolve.
- Run the repo's **enrichment agent** against a slice of GrowERP data (the entities have a live
  `resource:` REST endpoint) and diff its output structure against our exporter's — adopt any
  conventions we missed.
- Cross-validate by loading a Google **sample bundle** under a `WikiSpace` and navigating it with
  the Phase 3 `okf_*` tools.

## Phase 5 — Upstream contribution (#5)

Turn the gaps found in Phases 0/4 into ecosystem contributions:
- File issues for spec ambiguities or producer/consumer interop problems discovered.
- PR fixes/examples (e.g. a Moqui/ERP producer example) if valuable to the repo.
- Propose backward-compatible extensions if the entity-model use case needs fields the spec
  lacks (e.g. PK/relationship-cardinality conventions).

## Out of scope (future passes)
REST-API concepts, curated metrics/business concepts, retrofitting frontmatter onto `docs/`.
