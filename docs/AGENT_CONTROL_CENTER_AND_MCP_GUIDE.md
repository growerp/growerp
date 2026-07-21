# Agent Control Center and Moqui MCP: Comprehensive Guide

The **Agent Control Center (ADK)** and **Moqui MCP** are GrowERP's AI layer. Together they let a
company configure, govern and run autonomous AI agents that do real work inside the ERP — with a
full audit trail and human-in-the-loop approval on every write.

This guide is the complete reference: what every screen does, what every field means, what agents
are actually allowed to do, and how to verify it.

Related docs:
- [Agent Control Center User Guide](./Agent_Control_Center_User_Guide.md) — short UI-only guide
- [Agent Demo Walkthrough](./Agent_Control_Center_Demo.md) — guided demo of the built-in team
- [Moqui MCP User Guide](./Moqui_MCP_User_Guide.md) — connecting external MCP clients
- [Marketing Agent Team User Guide](./Marketing_Agent_Team_User_Guide.md) — the marketing team preset

---

## 1. Executive Summary

- **Agent Control Center (ADK)** — the UI and orchestration engine. Create agents, assign roles
  (coordinator vs. specialist), scope their permissions, gate their writes behind approval,
  schedule autonomous runs, feed them company documents for RAG, and inspect everything they did.
- **Moqui MCP** — the integration layer. It exposes Moqui **services**, a read-only REST proxy and
  the knowledge/wiki tools to the LLM over the Model Context Protocol (MCP).

Everything is **tenant-isolated**: every ADK record carries `ownerPartyId`, and the governance gate
pins it on every call. One company can never see or touch another's data through an agent.

> **Note (changed):** earlier versions of this platform also exposed Moqui *screens* to agents in a
> "MARIA" format. Those screen tools were removed (commit `fddd726b`, *drop screen tools,
> service-only toolset*). GrowERP uses a Flutter frontend; agents work **only** against services,
> which gives stable semantic contracts, lower token cost and direct artifact-authorization
> enforcement.

---

## 2. Where to find it

The dedicated **agents** app (`flutter/packages/agents/`) is the full control center. The **admin**
app embeds the same screens under an *Agent Control* menu group.

Menu of the agents app ([router_builder.dart:32-146](../flutter/packages/agents/lib/router_builder.dart#L32-L146)):

| Menu | Route | Screen |
|---|---|---|
| Main | `/` | Dashboard tiles + chat FAB |
| AI Agents | `/adk-agents` | Agent configuration list |
| Tools & integrations | `/adk-mcp-servers` | External MCP server registry |
| Agent Jobs | `/adk-jobs` | Scheduled run status, pause/resume, locks |
| Approvals | `/adk-approvals` | Write-approval queue |
| Agent Actions | `/adk-actions` | Audit trail (see §6) |
| Knowledge | `/adk-knowledge` | RAG document corpus |
| Wiki | `/wiki` | Browse/edit wiki spaces — the docs agents read (§9) and the OKF bundle (§11) |
| Organization | `/organization` | Company, employees, website |
| System Setup | `/setup` | AI / LLM settings (API key, model, token limit) |

**There is no "AI Chat" menu item.** Chat moved to the **floating action button on the dashboard**
(key `adkChatFab`) — commit `d2818e9c`. Tap it, pick an agent, talk to it.

The support app additionally has **System Usage** (`AdkSystemUsageView`) — cross-tenant LLM token
usage, listing only tenants that run on the *system* key (no own `apiKey` and no tenant `LlmConfig`).

### Dashboard cards

Each route has a compact chart on its dashboard tile — bars plus a counter row:

| Card | Bars | Counters |
|---|---|---|
| Agents | approval funnel by stage | agents, enabled, scheduled, servers |
| Jobs | Active / Paused / Locked | jobs, locked |
| Approvals | Pending / Approved / Rejected | total, pending |
| Actions | Allowed / Blocked / Pending | actions, tokens |
| Tools & integrations | Enabled / Disabled | servers, enabled |
| Knowledge | docs grouped by source type | docs, chunks |
| Wiki | pages per wiki space | spaces, pages |

The ADK cards live in
[adk_dashboard_minis.dart](../flutter/packages/growerp_adk/lib/src/adk_dashboard_minis.dart) and the
wiki card in
[wiki_dashboard_chart_mini.dart](../flutter/packages/growerp_wiki/lib/src/wiki_dashboard_chart_mini.dart).
Both build on the shared scaffold `DashboardMini` / `DashboardBar` / `DashboardCounter` /
`DashboardMiniLoader` in
[growerp_core/templates/dashboard_mini.dart](../flutter/packages/growerp_core/lib/src/templates/dashboard_mini.dart)
— use it for new tiles rather than depending on `growerp_adk`.

---

## 3. Configuring an agent

**AI Agents → +** (or tap a row to edit). Fields, grouped as in the dialog:

### 3.1 Basic
- **Agent Name** — required, unique per company.
- **Model** — e.g. `gemini-2.5-flash`, `gemini-2.5-flash-lite` (the platform default).
- **LLM Provider** — `gemini` (default), `openai`, `anthropic`.
- **Instruction (system prompt)** — the agent's operating manual. Be exhaustive.
- **Description** — *matters more than it looks*: for a coordinator's team members, routing is
  decided by the member's **description**, not its instruction. Write each specialist's description
  as a "use this agent when…" hint.
- **API Key** — blank = use the company key from System Setup, else the server default. Set one here
  only when this agent needs its own billing/rate limit.
- **Website chat** — let this agent answer public website chat automatically.

### 3.2 Permissions & governance
- **Tool Access (`toolMode`)**
  - `readOnly` — read services only. Write tools are not even handed to the LLM.
  - `scoped` — only services matching **Allowed services** (comma/space-separated globs, `*`
    wildcard, e.g. `*get#FinDoc,*create#FinDoc,*get#Product`).
  - `full` — unrestricted (within the user's own artifact authorizations).
- **Write Policy (`writePolicy`)**
  - `block` — writes refused.
  - `approve` — writes queued for a human (see §7).
  - `allow` — writes run autonomously.
- **Approval Chat Room ID** — where approval cards get posted.

New agents are created with the safe defaults `readOnly` + `approve`.

> **Gotcha:** these fields are plain strings with no enumeration constraint. A typo in `toolMode` or
> `writePolicy` falls through to the *legacy-permissive* branch (`?: 'full'`, `?: 'allow'`) — the
> agent becomes unrestricted rather than erroring. Always set them from the dialog dropdowns.

### 3.3 Team / orchestration
- **Role (`agentRole`)** — `specialist` (does the work) or `coordinator` (delegates).
- **Orchestration Type** — `router` (LLM picks the best member), `sequential`, `parallel`, `loop`.
- **Max Loop Iterations** — safety cap for `loop`.
- **Team Members** — add specialists to a coordinator. **Save the coordinator first**; team links
  need an existing config id. Delegation mode is `tool` (member exposed as a tool) or `transfer`.

### 3.4 Scheduled runs
- **Enable scheduled runs**, **Cron Expression** (Quartz 6-field, e.g. `0 0 9 * * ?` = 09:00 daily),
  **Prompt for each run**, **Chat Room ID for delivery**.

Saving syncs a real Moqui `ServiceJob` named `adk_scheduled_<configId>` — see §8.

### 3.5 System Setup — company-wide AI settings
Per-agent fields above override these; **System Setup** (`/setup`) holds the defaults for the whole
company:

- **API keys per provider** — *Add Provider* creates an `LlmConfig` row (Provider + API Key). This is
  the "company key" an agent falls back to when its own **API Key** is blank.
- **Default AI Model** — used by agents that do not name their own model. *System default* leaves it
  to the server.
- **System LLM Monthly Token Limit** — only applies to companies with **no** key of their own. The
  governance gate sums the month's `tokensTotal` and blocks further calls past the limit, telling the
  user to add their own key (§6.3). Leave blank for no limit.

> The `githubToken` / `githubRepository` settings that the GitHub tools (§4.3) depend on exist on
> `SystemSettings` and are read into system properties when a session is created — but the System
> Setup dialog was slimmed to AI/LLM only (commit `a743edb7`), so they are **not editable there**.
> Set them through the REST API or seed data.

---

## 4. What agents can actually do — the MCP toolset

### 4.1 Service tools (primary)
- **`moqui_search_services`** — find services by keyword.
- **`moqui_get_service_details`** — a service's in/out parameters.
- **`moqui_execute_service`** — run a service. Hard rules, independent of the agent's config:
  only `growerp.*` services are callable, and direct entity-auto CRUD
  (`create#Party` etc.) is rejected outright.

### 4.2 Data & documentation tools
- **`moqui_rest_call`** — read-only (GET) REST access for data inspection.
- **`moqui_get_help`** — the wiki (see §9).
- **`searchKnowledge`** — RAG search over the company's own ingested documents.
- **`okf_index` / `okf_load_concept` / `okf_follow`** — navigate the curated OKF domain-knowledge
  bundle: data model, entities, relationships (see §11).
- **`moqui_prompts_list` / `moqui_prompts_get`** — MCP prompt templates.

### 4.3 Built-in function tools
Beyond MCP, agents get in-process tools. Write-capable ones are **withheld entirely** when the agent
is `readOnly` (`AdkManager.assembleFunctionTools(allowWrites)`):

| Tool group | Read (always) | Write (only if not read-only) |
|---|---|---|
| Email | `readEmails` | `sendEmail` |
| GitHub | `getLatestTestRun`, `getTestExceptions`, `getMainSha`, `getFileContent` | `createBranch`, `updateFileContent`, `createPullRequest`, `addComment` |
| Substack | `listSubstackPosts`, `getSubstackPostComments`, `getSubstackEngagements`, `getSubscriberSyncStats` | `postSubstackNote`, `publishSubstackArticle`, `addSubstackSubscriber` |
| Misc | `getCurrentTime`, `requestHumanHandoff`, artifact loading | — |

GitHub tools need `githubToken` / `githubRepository` in System Setup.

### 4.4 External MCP servers ("Tools & integrations")
Register a server (**name**, **URL**, **transport** `sse`/`http`, **auth headers**, **enabled**),
then attach it to a saved agent. Header values are stored encrypted and never shown again —
re-enter to change. Servers are company-scoped, and attachment is refused across tenants. Changes
take effect on the agent's next run; no restart. External tools are still subject to the agent's
Tool Access and Write Policy.

---

## 5. Talking to agents

### 5.1 Chat — and letting the agent drive the app
Open chat with the **FAB on the dashboard** (key `adkChatFab`), pick an agent, and type. Sessions
stream over the ADK endpoints (`POST /adk/apps/{app}/users/{uid}/sessions` to open,
`POST /adk/run_sse` to stream).

What makes this more than a chatbot: **an agent can drive the Flutter UI.** The app passes its
`screenCatalog` (the widget registry) into session state, so the agent knows which screens exist, and
it can answer with a fenced directive block:

````
```growerp-action
{"action": "navigate", "widget": "FinDocListSalesOrder", "label": "Open sales orders",
 "params": {"openNew": true}}
```
````

The block is **stripped from the displayed reply** and rendered as a tappable chip — nothing happens
until the user taps it. A block holds either one JSON object or an array of them.

| Field | Meaning |
|---|---|
| `action` | `navigate` (default), `dialog`, or `menutailor` |
| `route` | Target route. Optional for `navigate` if `widget` is given — the client resolves it from the menu |
| `widget` | Registry widget name; **required** for `dialog` |
| `label` / `title` | Chip text (falls back to widget, then route, then "Open") |
| `params` | Forwarded as the route query string (`navigate`) or widget args (`dialog`) |
| `tab` | Jump to a tab index, appended as `?tab=N` |

`menutailor` is the onboarding case: the agent proposes menu items to `show` / `minimize` / `hide`,
and the chip lets the user confirm before anything is applied.

Malformed directives return null and are silently ignored, so a bad suggestion degrades to plain
text rather than breaking the reply.

### 5.2 Website chat — agents answering the public
An agent with **Website chat** enabled (§3.1) can answer visitors on your public site.

Wiring is per chat room: `ChatRoom.chatAgentConfigId` names the agent and `agentActive` (`Y`/`N`)
switches it on. When a visitor posts a message, `ChatServices100` fires
`AdkChatServices.reply#WebsiteChatAgent` **asynchronously** — it returns immediately if the room has
no agent or `agentActive != 'Y'`, so a room never blocks on the LLM.

Because scheduled/one-off runs are stateless, the service feeds the agent the **last 12 messages** of
the room as a transcript, labelled `Customer` / `Assistant`, rather than relying on session memory.

**Handing over to a human:** `escalate#WebsiteChat` (or the agent's own `requestHumanHandoff` tool)
sets `agentActive = 'N'` and posts *"Connecting you to a support agent — someone from our team will
reply here shortly."* The agent stops replying in that room and a person takes over. These services
authenticate anonymously, since the visitor has no account.

---

## 6. Agent Actions — what they are (the audit trail)

This is the screen most people ask about, so in full.

**An "agent action" is one governed tool/service call made by an agent.** There is no separate
"action" object you configure — actions are *produced*, one row per call, and never edited. The
Agent Actions screen is a read-only log (no add button).

Every action is recorded as an `AdkActionLog` row
([AdkEntities.xml:110-134](../moqui-adk/entity/AdkEntities.xml#L110-L134)).

### 5.1 The three fields that describe an action

**`verbClass` — what kind of call it was**

| Value | Icon | Meaning |
|---|---|---|
| `read` | 👁 eye | Service verb is one of `get, find, search, view, list, check, calculate, validate, count, export` |
| `write` | ✏️ pencil | Anything else — `create`, `update`, `delete`, `store`, `send`, … |
| `delegate` | 🔗 share | A coordinator handed the request to a team member |

**`decision` — what governance did about it**

| Value | Colour | Meaning |
|---|---|---|
| `allowed` | green | Ran immediately |
| `blocked` | red | Refused; the **Reason** column says why |
| `pending` | orange | Write held for human approval; an Approval row was created |
| `approved` | green | A pending write that a human approved — the service then ran |
| `rejected` | red | A pending write a human refused — never ran |
| `delegated` | green | Coordinator → specialist hand-off |

**Reason** — the human-readable explanation, e.g. *"This agent is read-only and may not run
`create#FinDoc`."*, *"'x' is not in this agent's allowed-service list."*, *"Cross-tenant access
denied: agent may only act on its own company."*

### 5.2 Row detail
Tap any row for Service, Tool, Type, Decision, Reason, When, Tokens, **Result** (short summary of
what the call returned) and **Arguments** (the exact JSON the agent wanted to send — this is what
you review before approving a write).

Delegated calls carry `parentConfigId` (the coordinator) alongside `configId` (the specialist), so
a team's work reads as a tree.

### 5.3 How an action is produced — end to end

1. The LLM emits a function call on its MCP toolset.
2. It lands in `mcp#ToolsCall` ([McpServices.xml](../moqui-mcp/service/McpServices.xml)), which
   resolves *which agent* is calling (from MCP headers `adk_config_id` / `adk_owner_party_id`).
3. The service name is repaired if the LLM guessed (`verb#Noun` → the unique matching `growerp.*`
   service; wrong package fixed; missing `#` fixed). Unresolvable names get suggestions back.
4. **`AdkGovernanceServices.govern#AgentAction`**
   ([AdkGovernanceServices.xml:16-193](../moqui-adk/service/AdkGovernanceServices.xml#L16-L193))
   decides, in this order:
   1. **Classify** read vs. write from the service verb.
   2. **Pin the tenant** — if the target accepts `ownerPartyId`, force it to the agent's company. A
      conflicting value supplied by the LLM ⇒ `blocked`.
   3. **Scope** — `readOnly` + write ⇒ blocked. `scoped` ⇒ match the allow-list globs.
   4. **Token budget** — if the company runs on the *system* LLM key, sum this month's
      `tokensTotal`; over `SystemSettings.llmSystemTokenLimit` ⇒ blocked, with a "add your own API
      key" message.
   5. **Write policy** — `block` ⇒ blocked, `approve` ⇒ `pending`.
5. **An `AdkActionLog` row is always written**, whatever the decision. This is why blocked attempts
   are visible — the log is the evidence, not just a success trail.
6. `pending` also creates an `AdkApproval` row and posts an approval card to the agent's approval
   chat room.
7. `allowed` ⇒ the service runs in a new transaction; `record#AgentResult` then attaches the result
   summary and token counts to the same log row.

Chat turns and coordinator delegations are logged too (`AdkManager.logChatTurn` / `logDelegations`),
which is where the token numbers on non-tool rows come from.

### 5.4 Reading it in practice
- **Debugging "the agent did nothing"** → filter for `blocked` and read the Reason. Nine times out
  of ten it is a missing entry in the scoped allow-list.
- **Debugging cost** → the Actions dashboard card totals tokens; System Usage breaks it down per
  tenant for system-key users.
- **Auditing** → the log is owner-scoped, so a company sees only its own rows; nothing is deletable
  from the UI.

> Note for developers: a second, older model `AgentActionLog` (with `actionType` and an
> `ActionResult` enum) still exists in `growerp_models`. It belongs to the legacy SystemMessage-based
> agent stack and is **not** what the Agent Actions screen shows.

---

## 7. Approvals — human-in-the-loop

When a `writePolicy=approve` agent tries a write, nothing is executed. Instead:

1. The action is logged `pending`, an `AdkApproval` row is created, and a card is posted to the
   approval chat room.
2. The agent tells the user it is awaiting approval.
3. **Approvals** screen: filter pending / approved / rejected. Open the row to see exactly which
   service and which arguments are proposed.
4. **Approve** re-runs the stored service with the stored arguments and flips the action log to
   `approved`. **Reject** discards it (`rejected`) — the service never runs.
5. Stale requests are swept to `expired` by `expire#AdkApprovals`.

Approval status values: `pending`, `approved`, `rejected`, `expired`.

---

## 8. Scheduled runs — Agent Jobs

- Saving a schedule-enabled agent creates/updates a Moqui `ServiceJob` named
  `adk_scheduled_<configId>` with the agent's cron expression.
- A master job `AdkScheduledAgents` runs every minute purely to **backfill** missing per-agent jobs;
  it does not run agents inline when they have their own cron expression. (Historically it did,
  which drained tokens every minute — fixed via `sync#AgentJob`.)
- The `_NA_` template rows and disabled agents are always left paused.
- A run calls the agent once with **Prompt for each scheduled run** (falling back to the
  instruction), then posts `[<agentName>] <result>` into the delivery chat room — creating the room
  and its members if needed — and pushes a live notification.
- The **Agent Jobs** screen shows Agent, Schedule, Last Run, Status and Lock, with **pause**,
  **resume** and **clear lock**. Clear the lock when a crashed run left `isLocked` set and the job
  stopped firing (`lockAgeMin` tells you how stale it is).

---

## 9. The Wiki — documentation agents read

Separate from RAG knowledge (§10), the platform ships a **wiki of agent-facing documentation**,
fetched with `moqui_get_help(uri="wiki:<type>:<name>")`. This is how an agent learns *how* to use a
service correctly instead of guessing parameters.

Two wiki spaces, seeded as Moqui `WikiSpace` + `DbResourceFile` markdown pages:

| Space | URI form | Content | Seed file |
|---|---|---|---|
| `MCP_SERVICE_DOCS` | `wiki:service:<Name>` | Per-service parameter and usage docs — currently `Product`, `ProductPrice`, `ProductFeature`, `ProductAssoc`, `Person`, `Message` | [McpServiceDocsData.xml](../moqui-mcp/data/McpServiceDocsData.xml) |
| `BUSINESS_PROCESSES` | `wiki:workflow:<Name>` | Step-by-step multi-step workflows with the exact tool calls — currently `Order-Entry`, `Order-Approval`, `Shipment-Receive` | [BusinessProcessesData.xml](../moqui-mcp/data/BusinessProcessesData.xml) |
| `MCP_PROMPTS` | (via `moqui_prompts_list` / `moqui_prompts_get`) | Reusable MCP prompt templates | [McpPromptsData.xml](../moqui-mcp/data/McpPromptsData.xml) |

A fourth space, `GROWERP_OKF`, holds the generated data-model bundle — see §11. Unlike the three
above it is **not** seeded; it appears only after you run the OKF export.

Also: the MCP server's **root instructions** (the "how to use this server" text every MCP client
receives on connect) are themselves loaded from the wiki, with a hard-coded fallback if the page is
missing.

Asking for an unknown page returns a helpful miss, not an error:
*"No documentation found for … Available documentation is in the MCP_SERVICE_DOCS (`wiki:service:*`)
and BUSINESS_PROCESSES (`wiki:workflow:*`) wiki spaces."* Asking for `wiki:screen:*` returns an
explicit note that Moqui screens are not used in GrowERP.

### Adding or editing wiki pages
Pages live in the database, so they are edited through the **Wiki** screen — in the agents app
(`/wiki`) and the admin app (`ADMIN_ADK_WIKI`) — or by extending the seed XML. When seeding, three
gotchas bite:

1. Page content must be a nested `<fileData><![CDATA[…]]></fileData>` element on
   `DbResourceFile`. Bare text between the tags loads as `NULL` **with no error**.
2. A child page needs a `WikiPage` row with `wikiSpaceId` + `pagePath` (e.g. `pagePath="Order-Entry"`)
   plus a matching `WikiPageHistory` row — the DbResource alone is not discoverable.
3. `publishedVersionName` must match the `versionName` you wrote (`v1`), or the page resolves empty.

Write workflow pages the way an agent consumes them: numbered steps, each naming the exact tool and
arguments to call.

---

## 10. Knowledge (RAG)

**Knowledge** screen: add a note, upload a file, **import products**, or delete a document.
Documents are chunked, embedded and stored per company; agents retrieve from them with
`searchKnowledge`. The list shows Title, Type and chunk count.

Source types: `note`, `upload`, `product`, `policy`, `chat`, `okf`.

Embedding requires a Gemini key — the company key in System Setup, a tenant `LlmConfig`, or
`GOOGLE_API_KEY`. Without one, documents can still be listed but ingestion is skipped.

The OKF bundle can be ingested the same way (`ingest#OkfBundle`, source type `okf`) — see §11.

---

## 11. OKF — the curated domain-knowledge bundle

**OKF (Open Knowledge Format)** is how agents learn GrowERP's *data model* — which entities exist,
their columns, and how they relate. It is distinct from both the wiki (§9, how-to prose) and RAG
knowledge (§10, your company's own documents): OKF is generated from the live schema and is the same
for every tenant.

**OKF has no dedicated screen of its own.** There is nothing to configure — it is a generated file
bundle that agents read through tools. It surfaces in the UI in two places, and **only after you run
the corresponding step**:

| Screen | Shows OKF when | What you see |
|---|---|---|
| **Wiki** | after `export#OkfBundle` has created the `GROWERP_OKF` wiki space | the bundle browsable as wiki pages; the Wiki dashboard card counts its pages |
| **Knowledge** | after `ingest#OkfBundle` has run (needs an embedding key) | documents with source type `okf`, with chunk counts |

Until then the bundle exists only as files on disk, the wiki and knowledge screens show nothing, and
the `okf_*` tools return *"No OKF bundle found (wiki space 'GROWERP_OKF' does not exist). Run the OKF
export first."* This is the normal state of a freshly loaded backend — export and ingest are
deliberate admin steps, **not** part of seed loading.

### Where it lives

| Piece | Location |
|---|---|
| The bundle itself | `moqui/runtime/growerp-okf/growerp/` — `index.md`, `tables/` (446 entity concepts), `datasets/`, `notes/`, plus `log.md` and `viz.html` |
| Hosted as (after export) | Moqui `WikiSpace` **`GROWERP_OKF`**, whose `rootPageLocation` points at `growerp.md`; the sibling `growerp/` directory is the bundle root |
| Exporter | `export#OkfBundle` — [OkfServices100.xml](../backend/service/growerp/100/OkfServices100.xml) + [OkfExport.groovy](../backend/service/OkfExport.groovy) |
| Agent-facing tools | `okf_index` / `okf_load_concept` / `okf_follow` in [McpServices.xml](../moqui-mcp/service/McpServices.xml) |
| RAG ingest | `ingest#OkfBundle` in [AdkKnowledgeServices.xml](../moqui-adk/service/AdkKnowledgeServices.xml) |

The bundle is **generated output and is not tracked in the growerp repo** — it lands in the
`moqui/runtime` clone. Every developer therefore has to run the export themselves.

### Concept format
Each concept is a markdown file with YAML frontmatter — `type`, `title`, `description`, `resource`
(the live REST URL for that entity), `tags`, `timestamp` — followed by a `# Schema` table
(column, type, PK, description), a `# Relationships` section of links to other concepts, and a
`# Citations` source list.

### Enabling it (one-time, and after schema changes)

Run the exporter once against a running backend. It creates the `GROWERP_OKF` wiki space, writes the
bundle, and idempotently creates a `WikiPage` row per page so the wiki serves it:

```
growerp.100.OkfServices100.export#OkfBundle
```

Call it from the MCP client (`moqui_execute_service`), from the `Okf/Export` REST endpoint, or from
the Moqui service runner. All parameters are optional and default sensibly:

| Parameter | Default | Notes |
|---|---|---|
| `wikiSpaceId` | `GROWERP_OKF` | An existing space keeps its own `rootPageLocation` |
| `rootPageLocation` | `growerp-okf` under the runtime dir | Only used when creating the space |
| `packagePrefixes` | `mantle.,growerp.` | Keeps the export away from thousands of framework entities |
| `includeViewEntities` | `false` | |
| `baseUrl` | webapp root | Used for the frontmatter `resource:` link |

Returns `wikiSpaceId`, `outputPath` and `entityCount` (currently **446** entities).

**Re-run it after entity/schema changes** — the bundle is a snapshot, so new or altered entities are
invisible to agents until re-exported. Regenerating is safe and idempotent; it overwrites only its
own generated prefixes (`tables/`, `datasets/`).

Optionally follow with `ingest#OkfBundle` (§10) to also put the bundle in the RAG index.


### Verifying it works

```
okf_index                              → the bundle index (Datasets / Tables sections)
okf_load_concept  tables/Party.md      → frontmatter + # Schema table + # Relationships
okf_follow        tables/OrderHeader.md → ~29 linked concepts
```

Or over REST: `e1/moqui.resource.wiki.WikiPage?wikiSpaceId=GROWERP_OKF` should return rows with a
non-null `publishedVersionName`, and
`growerp.100.OkfServices100.get#OkfPageText(wikiSpaceId: GROWERP_OKF, pagePath: 'tables/Party')`
should return non-empty `pageText`. An empty `pageText` with rows present means the published
version name does not match the stored version — the classic wiki symptom.

### How an agent uses it — progressive disclosure
1. **`okf_index`** — read `index.md` to see which concepts exist.
2. **`okf_load_concept`** — load one concept by bundle-relative path, e.g. `tables/OrderHeader.md`.
   Load only what is needed; the bundle is far too large to read whole.
3. **`okf_follow`** — resolve one concept's markdown links into a list of navigable neighbours, so
   the agent can walk relationships instead of guessing entity names.

Per the OKF spec the reader is deliberately tolerant: broken links, unknown types and missing fields
never error. A missing concept returns a "not found, use `okf_index`" message with `isError: false`.
Paths are canonicalized (`.`/`..` resolved) and anything escaping the bundle root or carrying a URL
scheme is rejected.

**Prefer OKF over `searchKnowledge` for data-model and domain-structure questions** — that guidance
is baked into the tool descriptions the LLM sees.

### Known gaps in the bundle

The export is internally consistent — 446 concepts, 2244 relationship links, **zero broken links**,
and every relationship that targets a concept in the bundle is a real navigable link. The gaps are
all *coverage* gaps that follow from the export parameters:

**1. Framework entities are dead ends (the significant one).** With the default
`packagePrefixes=mantle.,growerp.`, 28 `moqui.*` entities are referenced 516 times but have no
concept file, so they render as plain code instead of links and `okf_follow` cannot reach them. The
worst offenders are the most-referenced targets in the entire model:

| Absent entity | Referenced |
|---|---|
| `moqui.basic.Enumeration` | 275 |
| `moqui.basic.Uom` | 70 |
| `moqui.basic.StatusItem` | 50 |
| `moqui.security.UserAccount` | 25 |
| `moqui.basic.Geo` | 18 |

Practical effect: an agent tracing "what are the valid `statusId` values for an order?" follows the
relationship and hits a dead end. Widen the export to fix it:

```
export#OkfBundle  packagePrefixes: "mantle.,growerp.,moqui.basic.,moqui.security."
```

That alone resolves 438 of the 516 dangling references. (Broken links are legal under the OKF spec
and consumers tolerate them, so this degrades gracefully rather than erroring.)

**2. View entities are excluded** (`includeViewEntities=false` by default), so entities that exist
only as views are absent. Pass `includeViewEntities: true` if agents need them.

**3. Field descriptions are mostly empty** — 3708 of 4079 schema rows have no description, because
the underlying Moqui entity definitions carry none. Columns and types are complete; the *semantics*
of a field often are not. This is a source-data limitation, not an exporter bug.

**4. Entities only.** The bundle covers the data model. Services, REST endpoints and business
processes are not OKF concepts — workflows live in the separate `BUSINESS_PROCESSES` wiki space
(§9) and are not linked from the bundle graph.

### Maintenance gotchas
Only relevant if you hand-edit the bundle or change the exporter:
- Wiki *serving* needs `WikiPage` rows with a non-null `publishedVersionName`. The exporter creates
  them; loose files dropped under `rootPageLocation` are invisible to the wiki.
- Inter-concept links must be **relative** (`X.md`, `../tables/X.md`). Absolute paths render zero
  edges in the OKF reference visualizer, even though the spec recommends them.

---

## 12. Memory

The platform keeps a rolling per-user summary (`AdkMemory`: `summaryText` + `factsJson`) that is
injected into the agent at the start of the next session. Mention a preference, start a new chat,
and the assistant still knows it. Nothing to configure.

---

## 13. Walkthrough: the built-in demo team

**AI Agents → Load agent demo** (flask icon) clones five template agents into your company. It is
idempotent, and refuses to run for the GROWERP system tenant.

| Agent | Configuration | Demonstrates |
|---|---|---|
| Operations Assistant | coordinator, router, read-only | Routing by member description |
| Inventory Specialist | read-only | Safe autonomous reads + the action log |
| Support Specialist | read-only, website chat | RAG over policy documents |
| Sales Specialist | scoped allow-list, `writePolicy=approve` | Tool scoping + approvals |
| Ops Digest | scheduled `0 0 9 * * ?` | Scheduled autonomous runs |

Full script in [Agent_Control_Center_Demo.md](./Agent_Control_Center_Demo.md).

---

## 14. Best practices

1. **Start read-only.** Prove the agent reasons correctly before letting it write anything.
2. **Scope tightly.** An agent that creates tasks should have exactly the task services in its
   allow-list and nothing else. Verify with the Actions log — blocked rows tell you what is missing.
3. **Keep a human in the loop** for anything financial or outbound (orders, invoices, email, Substack
   publishing): `writePolicy=approve` plus a real approval chat room.
4. **Write descriptions for routing.** Coordinators route on member *descriptions*. A vague
   description is the single most common cause of wrong delegation.
5. **Set a token limit** (System Setup) for companies on the shared system key, and watch the Actions
   card / System Usage.
6. **Document workflows in the wiki** rather than stuffing every procedure into the system prompt —
   it costs fewer tokens and is shared across agents.

---

## 15. Verifying a setup

With the backend running, inspect live data read-only (MCP `moqui_rest_call`, or REST GET):

| Check | Path |
|---|---|
| Agents for a company | `e1/moqui.adk.AdkAgentConfig?ownerPartyId=<owner>` |
| Team links | `e1/moqui.adk.AdkAgentTeamMember?ownerPartyId=<owner>` |
| Recent actions | `e1/moqui.adk.AdkActionLog?ownerPartyId=<owner>&orderByField=-actionTime&pageSize=20` |
| Pending approvals | `e1/moqui.adk.AdkApproval?status=pending` |
| Scheduled jobs | `e1/moqui.service.job.ServiceJob?jobName=adk_scheduled_<configId>` |
| Knowledge docs | `e1/moqui.adk.AdkKnowledgeDoc?ownerPartyId=<owner>` |

Common symptoms:

| Symptom | Likely cause |
|---|---|
| Agent says it can't do something | `blocked` row in Agent Actions — read the Reason |
| Nothing happens on a write | `writePolicy=approve`; look in Approvals |
| Scheduled agent stopped running | Job locked — clear the lock on Agent Jobs |
| Coordinator picks the wrong specialist | Member descriptions too vague |
| Knowledge upload has 0 chunks | No LLM key for embedding |
| `okf_*` tools say "No OKF bundle found" | Export never run — `export#OkfBundle` (§11) |
| OKF absent from Wiki / Knowledge screens | Export (wiki) and ingest (knowledge) are separate steps |
| External MCP tools missing | Server disabled, or attached before the agent was saved |
