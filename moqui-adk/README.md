# moqui-adk

Google ADK (Agent Development Kit) embedded as a Moqui Framework component. Runs LLM agents via the Google ADK Java SDK and serves the official ADK Angular DevUI at `/adk/`.

---

## What This Is

A native Moqui component that integrates the [Google ADK Java SDK](https://github.com/google/adk-java) into any Moqui application:

- **ADK DevUI** — the official Angular chat interface served by Moqui at `http://…/adk/`
- **Google ADK Java SDK** — `LlmAgent` + `Runner` handle agent execution and session management
- **Persistent sessions** — conversation history and session state survive Moqui restarts (stored in `AdkSession` / `AdkSessionEvent` entities)
- **Multi-tenant agents** — each company (`ownerPartyId`) can have its own agent config running simultaneously
- **Dynamic agent creation** — create, edit, and delete named agents at runtime via REST API (`/adk/configs`) or the Flutter `AdkAgentListView` UI — no restart required
- **Scheduled agents** — give an agent a cron expression and it runs automatically, posting results to a GrowERP chat room
- **Moqui MCP tools** — every agent is wired to the [moqui-mcp](../moqui-mcp) Model Context Protocol tools, so agents can search and execute Moqui services (and browse screens) to answer real ERP questions
- **Default `growerp-agent`** — used when no custom agent is configured: a GrowERP/Moqui assistant with the Moqui MCP tools plus a `getCurrentTime` example tool
- **Moqui dashboard** — status overview and configuration screen at `/vapps/adk/`
- **Knowledge Base (RAG) & Memory** — per-tenant document ingestion, embeddings, and rolling cross-session memory summaries
- **UI Prefilling** — agent can prefill create/edit dialogs directly in the frontend UI
- No extra processes, no Python, no extra ports — everything runs inside Moqui

---

## Prerequisites

| Requirement | Version |
|-------------|---------|
| Java | 21+ |
| Moqui Framework | 4.x (growerp fork) |
| Gradle | via `moqui/gradlew` |
| Google Gemini API key | [Get one free](https://aistudio.google.com/app/apikey) |

The Google ADK runtime JARs (`google-adk:1.3.0` and transitive deps) are declared in the Moqui framework `build.gradle` as `runtimeOnly` dependencies — they ship inside `moqui.war` and are **not** bundled in the component `lib/` directory.

---

## Installation

### 0. Add ADK runtime dependency to Moqui framework

The component compiles against `google-adk` but does **not** bundle the JARs. They must be declared in the Moqui framework so they ship inside `moqui.war`.

In `moqui/framework/build.gradle`, add to the `dependencies` block:

```groovy
// Google ADK — required by moqui-adk component for LLM agent support
runtimeOnly 'com.google.adk:google-adk:1.3.0' // Apache 2.0
```

> This is already present in the growerp fork of moqui-framework. Skip this step if using that fork.

### 1. Add as submodule of moqui-runtime

```bash
cd moqui/runtime
git submodule add -b growerp https://github.com/growerp/moqui-adk.git component/moqui-adk
git commit -m "add moqui-adk submodule"
```

### 2. Build

From the Moqui root (builds framework WAR + extracts Angular DevUI assets):

```bash
cd moqui
./gradlew build
```

This runs the `extractAdkBrowserAssets` task which:
- Downloads `google-adk-dev:1.3.0` (contains the pre-built Angular SPA)
- Extracts the browser assets to `component/moqui-adk/screen/adk-ui/`
- Patches `index.html` `<base href>` to `/adk/`
- Patches `assets/config/runtime-config.json` `backendUrl` to `/adk`

The component produces a single JAR: `lib/moqui-adk-1.0.0.jar` (~30 KB).

### 3. Load seed data (first run only)

```bash
java -jar moqui.war load types=seed,seed-initial,install no-run-es
```

This registers the `AdkScheduledAgents` ServiceJob (cron every minute) and security seed data.

### 4. Start Moqui

```bash
# With API key via environment variable (simplest):
GOOGLE_API_KEY=AIza... java -jar moqui.war no-run-es

# Or without key (configure via UI after start):
java -jar moqui.war no-run-es
```

---

## Configuration

### Option A — Environment variable (recommended for development)

Set any of the following before starting Moqui:

```bash
export GOOGLE_API_KEY=AIza...
# alternatives: GOOGLE_GENAI_API_KEY or GEMINI_API_KEY
java -jar moqui.war no-run-es
```

The default `growerp-agent` is used automatically. No UI config needed.

### Option B — Moqui Admin UI

1. Log in at `http://localhost:8080/vapps` (user: `SystemSupport` / `moqui`)
2. Navigate to **ADK → Configuration**
3. Fill in the form:

| Field | Description | Default |
|-------|-------------|---------|
| Owner Party ID | Tenant/company this agent belongs to (blank = global) | _(blank = global)_ |
| Agent Name | Leave blank to use the built-in `growerp-agent` | _(blank = growerp-agent)_ |
| Model | Gemini model ID | `gemini-2.0-flash` |
| API Key | Your Google Gemini API key | — |
| System Instruction | Agent persona / constraints | — |

4. Click **Save Configuration**

Config takes effect immediately (no restart). Multiple configs can be active simultaneously — one per tenant. DB config takes priority over env vars.

### Option C — Flutter `AdkAgentListView` (recommended for end-users)

The Flutter `growerp_core` package ships a ready-made management screen. Push it onto the navigator stack or add it to your route table:

```dart
// Route table
GoRoute(path: '/adk/agents', builder: (_, __) => const AdkAgentListView())

// Or push directly
Navigator.push(context, MaterialPageRoute(
  builder: (_) => const AdkAgentListView(),
));
```

The screen lets users:
- **List** all agents for their tenant
- **Create** a new named agent with a custom system prompt, model, optional API key, and optional schedule
- **Edit** an existing agent's configuration (API key only updated when a new one is entered)
- **Delete** an agent

All changes take effect immediately on the backend — no restart required.

---

## Dynamic Agent Creation

Any named agent can be created at runtime without redeploying Moqui. The `update#AgentConfig` service upserts an `AdkAgentConfig` record and calls `AdkManager.initConfig()` to register a new `Runner` + `LlmAgent` in the live registry.

### Via Flutter UI

Use `AdkAgentListView` (see Configuration → Option C above).

### Via the REST API directly

```bash
# Create a new agent
POST /adk/configs
Content-Type: application/json
Authorization: Bearer <token>

{
  "agentName":   "sales-agent",
  "modelName":   "gemini-2.0-flash",
  "instruction": "You are a sales assistant. Help users find products and place orders.",
  "apiKey":      "AIza..."          # optional — omit to reuse server default
}
# → { "adkAgentConfigId": "10001" }

# List agents for the authenticated tenant
GET /adk/configs

# Delete an agent
DELETE /adk/configs/10001
```

Once created, the agent is immediately available at `/adk/apps/sales-agent/…` and in the DevUI dropdown.

To update an existing agent, `POST /adk/configs` again with the same `agentName`. Omitting `apiKey` preserves the stored key.

### Via Moqui service call (e.g. from screen actions, Camel routes, scripts)

```
service: moqui.adk.AdkServices.update#AgentConfig
  agentName:   "sales-agent"
  modelName:   "gemini-2.0-flash"
  instruction: "You are a sales assistant…"
  ownerPartyId: "PARTY_001"   # optional — scopes agent to one tenant
  apiKey:       "AIza…"       # optional — omit to reuse existing/env key
```

---

## Scheduled Agents

An agent can be given a cron schedule. Every minute, the `AdkScheduledAgents` ServiceJob fires `run#AllScheduledAgents`, which finds all agents with `scheduleEnabled = Y` and runs each one asynchronously. The result is posted as a message to the configured GrowERP chat room.

### "Time every minute" example

1. Create an agent via the Flutter dialog or REST API:

```json
{
  "agentName":          "TimeBot",
  "instruction":        "When asked, report the current time clearly.",
  "scheduleEnabled":    "Y",
  "scheduleExpression": "0 * * * * ?",
  "schedulePrompt":     "What is the current time?",
  "scheduleChatRoomId": "<your-chat-room-id>"
}
```

2. Every minute, Moqui runs `TimeBot` with the prompt `"What is the current time?"` and posts the reply to the specified chat room.

### Schedule fields on `AdkAgentConfig`

| Field | Type | Description |
|-------|------|-------------|
| `scheduleExpression` | text-short | Quartz cron expression (e.g. `0 * * * * ?` = every minute, `0 0 9 * * ?` = daily at 9am) |
| `scheduleEnabled` | Y/N | Whether the schedule is active |
| `schedulePrompt` | text-medium | Prompt sent to the agent on each scheduled run. Defaults to `"Perform your scheduled task."` |
| `scheduleChatRoomId` | id | GrowERP `ChatRoom.chatRoomId` to post results to. If blank, the result is only logged. |

### How it works

```
Moqui Quartz — every minute
  → run#AllScheduledAgents
      finds all AdkAgentConfig where scheduleEnabled=Y and enabled=Y
      → async: run#ScheduledAgent(adkAgentConfigId)
                  create one-off ADK session (userId='scheduler')
                  AdkManager.runAgent(prompt)
                  if scheduleChatRoomId set:
                    create#growerp.general.ChatMessage(chatRoomId, content=result)
                  else: log result
```

The ServiceJob is registered by `data/AdkSchedulerData.xml` (loaded during `seed` data load). The job respects Moqui's scheduler pause/resume via the `paused` field on the `ServiceJob` record.

---

## Usage

### ADK DevUI (primary interface)

Navigate to `http://localhost:8080/adk/` — the official Google ADK Angular interface:

1. Select **growerp-agent** (or any custom agent) from the dropdown
2. Click **+ New Session**
3. Type a message, e.g. `list product services` or `What time is it in Tokyo?`
4. The agent calls the Moqui MCP tools (or `getCurrentTime`) and replies via Gemini

The Trace / Events / State / Sessions tabs show full invocation details.

Sessions persist across Moqui restarts — conversation history is stored in the database.

### Moqui Dashboard

Navigate to `http://localhost:8080/vapps` → **ADK → Dashboard** — shows agent name, model, and configuration status with a link to the DevUI.

---

## Architecture

```
Browser / Flutter
  │
  ├── GET  /adk/              → Angular DevUI (index.html)
  ├── GET  /adk/main-*.js     → Angular static assets
  │
  ├── GET  /adk/list-apps     ─┐
  ├── POST /adk/apps/…/sessions│ AdkDevServlet (Jakarta Servlet)
  ├── POST /adk/run_sse        │
  ├── GET  /adk/configs        │  ← dynamic agent management
  ├── POST /adk/configs        │
  ├── DEL  /adk/configs/{id}  ─┘
  │                                 │
  │                         AdkManager (Groovy singleton)
  │                         registry: configId → Runner
  │                         tenantRegistry: ownerPartyId → configId
  │                                 │
  │              ┌──────────────────┼──────────────────┐
  │              │                  │                  │
  │         Runner (tenant A)  Runner (tenant B)  Runner (global)
  │         LlmAgent           LlmAgent           growerp-agent (default)
  │              │                                      │
  │              │              all agents ──► Moqui MCP tools (moqui-mcp, SSE)
  │              └── shared: MoquiSessionService ──► AdkSession / AdkSessionEvent (DB)
  │                                 │
  │                                 ▼
  │                       Gemini API (google.generativeai)
  │
  └── /vapps/adk/*         → Moqui screens (dashboard, configuration)

Moqui Quartz scheduler (every minute)
  → AdkScheduledAgents ServiceJob
      → run#AllScheduledAgents
          → run#ScheduledAgent (per scheduleEnabled=Y config)
              → AdkManager.runAgent(schedulePrompt)
              → create#growerp.general.ChatMessage (→ chat room WebSocket)
```

### Session persistence

ADK Java 1.3.0 ships only `InMemorySessionService` and `VertexAiSessionService`. This component provides **`MoquiSessionService`** — a custom `BaseSessionService` implementation that stores sessions and events in Moqui's own database:

- `AdkSession` — one row per session (state JSON, userId, configId, timestamps)
- `AdkSessionEvent` — one row per event/message (full event JSON in chronological order)

`MoquiSessionService` is shared across all runners in the registry, so any runner can read any session after a restart.

> **Invariant — `appendEvent` must also update the in-memory `Session`.** ADK's `BaseSessionService.appendEvent` default does three things: ignore partial (streaming) events, apply the event's `stateDelta` to the live `session.state()`, and add the event to the live `session.events()`. `MoquiSessionService` overrides `appendEvent` to persist to the DB, so it **must replicate that in-memory behavior as well**. If it only writes to the DB, the running invocation never sees function-call/response events on the next LLM turn, and the agent re-issues the same tool call in a loop until `maxLlmCalls` is hit.

### Key files

| File | Role |
|------|------|
| `src/…/AdkDevServlet.groovy` | Jakarta Servlet at `/adk` and `/adk/*` — serves Angular SPA, ADK REST API, and `/adk/configs` CRUD |
| `src/…/AdkManager.groovy` | Registry facade: multi-agent `configId→Runner` map, tenant routing, session ownership |
| `src/…/MoquiSessionService.groovy` | Persistent `BaseSessionService` backed by `AdkSession` + `AdkSessionEvent` entities |
| `src/…/HelloTimeAgent.groovy` | Example agent — tells current time for a city using a function tool |
| `src/…/AdkSessionHolder.groovy` | In-memory event log for the Moqui inspector panel |
| `screen/adk-ui/` | Extracted Angular DevUI assets (build artifact, gitignored) |
| `screen/Adk/dashboard.xml` | Moqui status dashboard |
| `screen/Adk/Configuration.xml` | Agent config form |
| `service/AdkServices.xml` | `update#AgentConfig`, `create#Session`, `run#Agent` Moqui services |
| `service/AdkSchedulerServices.xml` | `run#AllScheduledAgents`, `run#ScheduledAgent` — scheduled execution + chat delivery |
| `entity/AdkEntities.xml` | `AdkAgentConfig` (+ schedule fields), `AdkSession`, `AdkSessionEvent` entities |
| `MoquiConf.xml` | Servlet registration + screen facade |
| `build.gradle` | `extractAdkBrowserAssets` task + `adkDevAssets` configuration |
| `data/AdkSecuritySeedData.xml` | Auth rules for `/adk/*` + `AdkUsers` user group |
| `data/AdkSchedulerData.xml` | `AdkScheduledAgents` ServiceJob seed (cron every minute) |

### ADK REST API (implemented by AdkDevServlet)

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/adk/list-apps` | Returns registered agent names |
| `POST` | `/adk/apps/{app}/users/{uid}/sessions` | Create session (routed to tenant's runner) |
| `GET` | `/adk/apps/{app}/users/{uid}/sessions` | List sessions |
| `GET` | `/adk/apps/{app}/users/{uid}/sessions/{sid}` | Get session |
| `DELETE` | `/adk/apps/{app}/users/{uid}/sessions/{sid}` | Delete session + events |
| `POST` | `/adk/run` | Synchronous run — returns JSON event array |
| `POST` | `/adk/run_sse` | Streaming run — Server-Sent Events |
| `GET` | `/adk/configs` | List agent configs for the authenticated tenant |
| `POST` | `/adk/configs` | Create or update an agent config (upsert by agentName) |
| `DELETE` | `/adk/configs/{configId}` | Delete an agent config |
| `GET`/`POST`| `/adk/knowledge` | Manage knowledge documents and product catalogs |
| `GET`/`POST`| `/adk/memory` | Get or trigger memory summaries |

---

## Knowledge Base & Memory (RAG)

The ADK includes a full Retrieval-Augmented Generation (RAG) and long-term memory system:

### Knowledge Base
- **Ingestion**: Upload documents or ingest product catalogs via the REST API (`/adk/knowledge`). 
- **Embeddings**: Documents are automatically chunked and embedded using `gemini-embedding-001` (configurable).
- **Search**: The agent's MCP tools include `searchKnowledge` to retrieve relevant chunks via in-database cosine similarity search (no external vector database required).
- **Tenant Isolation**: All knowledge is strictly scoped to the specific `ownerPartyId`.

### Memory
- **Rolling Summaries**: Every few turns, the system asynchronously summarizes the conversation.
- **Cross-session Recall**: These summaries are stored as `AdkMemory` and injected into the agent's system prompt on subsequent sessions, allowing the agent to remember user preferences and past context.

### UI Prefilling
When users request to create or edit records, the agent can intelligently emit directives to prefill the frontend UI dialogs (using `_aiPrefill: true`), keeping the user in control of final confirmation and saving.

---

## Default agent (`growerp-agent`)

When no custom agent is configured, `AdkManager.initConfig()` builds a built-in `growerp-agent`: a GrowERP/Moqui assistant whose system instruction tells it to answer ERP questions using the Moqui MCP tools, and to stop calling tools once it has enough information to answer (this avoids tool-call loops). Its tools are:

- the **Moqui MCP toolset** (`moqui_search_services`, `moqui_get_service_details`, `moqui_execute_service`, screen browsing, …) served by [moqui-mcp](../moqui-mcp)
- a **`getCurrentTime`** example function tool, ported from the [ADK Java quickstart](https://github.com/google/adk-java), demonstrating `FunctionTool.create(Class, methodName)` + `@Schema` parameter annotations

Source: [`src/main/groovy/org/moqui/adk/HelloTimeAgent.groovy`](src/main/groovy/org/moqui/adk/HelloTimeAgent.groovy) (the `getCurrentTime` tool)

Try asking: `list product services`, `What time is it in London?`, or `who am I?`

### Tool-call iteration cap

`AdkManager.defaultRunConfig()` sets `maxLlmCalls(12)` so a single chat turn can make at most 12 LLM calls. This is a safety net: if a model ever loops on tool calls, the run stops with an error instead of hanging the backend. Legitimate multi-step tool use stays well under this limit.

---

## Adding a Custom Agent

### Single global agent (Moqui Admin UI)

Go to **ADK → Configuration**, enter a custom **Agent Name**, **Model**, **API Key**, and **System Instruction**, then save. The runner reinitializes immediately. Leave **Owner Party ID** blank to apply globally.

For an agent with custom Groovy tools, extend `AdkManager.initConfig()` to detect your agent name and wire in your `LlmAgent` with `FunctionTool` entries.

### Dynamic agents at runtime (no code changes)

Use the Flutter `AdkAgentListView` or `POST /adk/configs` — see [Dynamic Agent Creation](#dynamic-agent-creation) above.

### Per-tenant agents (multi-company)

Call `update#AgentConfig` once per tenant with their `ownerPartyId`:

```
service: moqui.adk.AdkServices.update#AgentConfig
  ownerPartyId: "PARTY_001"
  agentName: "sales-agent"
  modelName: "gemini-2.0-flash"
  apiKey: "AIza..."
  instruction: "You are a sales assistant for Acme Corp..."
```

Each tenant's users will be routed to their own `Runner` + `LlmAgent` instance. Session history is isolated per session (tracked by `configId` in `AdkSession`).

---

## Entities

| Entity | Purpose |
|--------|---------|
| `moqui.adk.AdkAgentConfig` | Agent config: ownerPartyId, name, model, API key, instruction, enabled flag, schedule fields (`scheduleExpression`, `scheduleEnabled`, `schedulePrompt`, `scheduleChatRoomId`) |
| `moqui.adk.AdkSession` | Persistent session: userId, configId, state JSON, timestamps |
| `moqui.adk.AdkSessionEvent` | Individual event/message JSON for a session (ordered by eventTime) |
| `moqui.adk.AdkKnowledgeDoc` | Document metadata for the Knowledge Base |
| `moqui.adk.AdkKnowledgeChunk` | Text chunks with vector embeddings (`embeddingJson`) for cosine search |
| `moqui.adk.AdkMemory` | Per-user/tenant rolling memory summaries for cross-session recall |

Session state and full conversation history are stored in the database and survive Moqui restarts.

---

## Troubleshooting

### DevUI shows "Failed to load agents"

The servlet isn't responding. Check:
- Moqui started without errors (`grep -i 'adk\|error' /tmp/moqui.log`)
- `screen/adk-ui/index.html` exists (run `./gradlew build` if missing)

### Error: "API key must either be provided…"

No API key configured. Set `GOOGLE_API_KEY` env var or configure via **ADK → Configuration** or `POST /adk/configs`.

### Agent listed but session creation fails (503)

`AdkManager` not initialized. Check Moqui log for init errors. Try reloading `/adk/` to trigger lazy init.

### `ClassNotFoundException` on startup

Component not built. Run:

```bash
cd moqui && ./gradlew :runtime:component:moqui-adk:build
```

Then restart Moqui.

### screen/adk-ui/ is empty

Run the Gradle extraction task:

```bash
cd moqui && ./gradlew :runtime:component:moqui-adk:extractAdkBrowserAssets
```

### Sessions lost after restart

Sessions are now persisted by default via `MoquiSessionService`. If sessions are still lost, check:
- `AdkSession` and `AdkSessionEvent` tables exist (re-run `load types=seed,seed-initial,install`)
- No DB errors in Moqui log when `appendEvent` is called

### Scheduled agent not running

Check:
- Seed data was loaded (`AdkScheduledAgents` row exists in `moqui.service.job.ServiceJob`)
- `scheduleEnabled = Y` and `enabled = Y` on the `AdkAgentConfig` record
- Moqui scheduler is active (check `moqui-conf.xml` for `<service-facade scheduler-thread-count="..." />`)
- Moqui log for `AdkScheduler:` lines

### Scheduled result not appearing in chat room

Check:
- `scheduleChatRoomId` is set on the config and refers to a valid `growerp.general.ChatRoom` record
- At least one `ChatRoomMember` exists for that room (the service uses the first member as `fromUserId`)
- Moqui log for `AdkScheduler: no fromUserId resolved…` warnings

---

## Development

### ADK class patches

The `patches/` directory contains compiled `.class` files that override classes in the embedded `google-adk` JAR (e.g. `Runner`, `McpToolset`, `SseServerParameters`). These cannot live in the component `lib/` — they must be on the JVM classpath **before** the WAR's own JARs, which means they must sit in the Moqui working directory (next to `moqui.war`) so that `java -cp . moqui.war` picks them up first.

The `copyAdkPatches` Gradle task (run automatically as part of `jar`) copies them there:

```bash
cd moqui
./gradlew :runtime:component:moqui-adk:copyAdkPatches
```

### Rebuild after Groovy changes

```bash
cd moqui
./gradlew :runtime:component:moqui-adk:build
# restart Moqui to pick up the new JAR
```

Screen XML, service XML, and data XML hot-reload without rebuild.

### Rebuild the full WAR (framework changes)

```bash
cd moqui && ./gradlew build
java -jar moqui.war no-run-es
```

### Commit and push

```bash
cd moqui/runtime/component/moqui-adk
git add -A && git commit -m "your change"
git push origin growerp

# Update submodule pointer in moqui-runtime
cd ../..
git add component/moqui-adk
git commit -m "bump moqui-adk submodule"
git push origin growerp
```

---

## Links

- [Google ADK Java SDK](https://github.com/google/adk-java)
- [ADK Java Quickstart](https://google.github.io/adk-docs/get-started/quickstart-java/)
- [Get a Gemini API Key](https://aistudio.google.com/app/apikey)
- [Moqui Framework](https://github.com/moqui/moqui-framework)
- [GrowERP](https://github.com/growerp/growerp)

---

## License

Public domain under CC0 1.0 Universal plus Grant of Patent License, consistent with Moqui Framework.
