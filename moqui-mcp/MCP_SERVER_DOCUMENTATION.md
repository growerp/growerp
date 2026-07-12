# Moqui MCP Server Documentation

## Overview

The Moqui MCP Server provides a direct interface for AI agents to interact with the [Moqui Framework](https://www.moqui.org/) ERP backend of GrowERP via the Model Context Protocol (MCP). Agents can securely discover and execute services, inspect data read-only via the REST API, follow documented business workflows, and search company knowledge — without browser automation or raw API scraping.

GrowERP uses a Flutter frontend; the Moqui web UI is **not** used, so this server exposes a service-based toolset (no screen browsing/rendering).

Component: **moqui-mcp-2 v1.1.0** (server version 2.1.0). MCP endpoint: `http://<host>:8080/mcp`.

---

## 1. Core Architecture

```mermaid
flowchart LR
    Agent[AI Agent] <-->|JSON-RPC 2.0| Servlet[EnhancedMcpServlet]
    Servlet <-->|Session/Auth| SessionAdapter[McpSessionAdapter]
    Servlet <-->|Dispatch| ToolAdapter[McpToolAdapter]
    Servlet <-->|SSE Push| SseTransport[SseTransport]
    ToolAdapter <-->|Delegation/Auth| Services[Moqui Services]
    Services <-->|Governance/Audit| Adk[moqui-adk]
```

### 1.1 Transport

The server supports two transport modes:
- **HTTP POST** (`/mcp`): Synchronous JSON-RPC 2.0. Works with any MCP client, including Claude Desktop, the GrowERP Flutter client, and direct curl.
- **SSE** (`/mcp/sse`): Server-Sent Events for real-time notifications (tool execution events, subscribed resource changes). `SseTransport` manages keep-alive and fan-out to active sessions.

### 1.2 Protocol Version Negotiation

Supported MCP protocol versions (in order of preference):
- `2025-11-25`, `2025-06-18`, `2024-11-05`, `2024-10-07`, `2023-06-05`

The server echoes back `2025-06-18` as its preferred version. Clients requesting an unsupported version receive an error.

---

## 2. Exposed MCP Tools

Tools are registered in `McpServices.xml` (`list#Tools`) and dispatched by `mcp#ToolsCall`.

Note: the former screen tools (`moqui_browse_screens`, `moqui_search_screens`,
`moqui_get_screen_details`, `moqui_render_screen`) were removed — Moqui screens are not used
in GrowERP. Calls to those names return a hint pointing at the service tools.

### Documentation Tool

#### `moqui_get_help`
Retrieve Wiki documentation for a service or a multi-step business process workflow.
- `uri` (required): Help URI, e.g. `wiki:service:Product`, `wiki:workflow:Order-Entry`

### Service Tools

#### `moqui_search_services`
Search the service registry by name, noun, or verb. Returns each match with description, required params, and optional params. Searches `growerp.*` services by default.
- `query` (required): Keyword, e.g. `product`, `order`, `create#growerp`

#### `moqui_get_service_details`
Get full input/output parameter details (types, descriptions, required flags) for a specific service.
- `serviceName` (required): Full name, e.g. `update#growerp.product.Product`

#### `moqui_execute_service`
Execute a Moqui service directly with parameters, subject to the calling user's RBAC permissions.
- `serviceName` (required): Full service name
- `parameters` (optional): Input parameter map

### Prompt Tools

#### `moqui_prompts_list`
List all available MCP prompt templates from `McpPromptsData.xml`.

#### `moqui_prompts_get`
Retrieve and render a specific prompt template with provided arguments.
- `name` (required): Prompt name
- `arguments` (optional): Template arguments

---

## 3. MCP Protocol Coverage

Beyond tools, the server implements the full MCP spec surface:

| MCP Method | Handler Service | Notes |
|---|---|---|
| `initialize` | `mcp#Initialize` | Protocol negotiation, loads Wiki root instructions |
| `ping` | `mcp#Ping` | Health check |
| `tools/list` | `list#Tools` | Returns registered tool schemas |
| `tools/call` | `mcp#ToolsCall` | Dispatches to all tool handlers |
| `resources/list` | `mcp#ResourcesList` | Discovers Moqui entities by RBAC |
| `resources/read` | `mcp#ResourcesRead` | Queries entity data |
| `resources/templates/list` | `mcp#ResourcesTemplatesList` | Entity URI templates |
| `resources/subscribe` | `mcp#ResourcesSubscribe` | SSE-based resource watch |
| `resources/unsubscribe` | `mcp#ResourcesUnsubscribe` | Cancel subscription |
| `prompts/list` | `mcp#PromptsList` | List prompt templates |
| `prompts/get` | `mcp#PromptsGet` | Render prompt template |
| `roots/list` | `mcp#RootsList` | Root navigation hints |
| `sampling/createMessage` | `mcp#SamplingCreateMessage` | Client-side sampling |
| `elicitation/create` | `mcp#ElicitationCreate` | Human-in-the-loop input |

### Resources API
Resources expose Moqui entities scoped to the authenticated user's RBAC permissions via `ArtifactAuthzCheckView`. Entities the user can VIEW appear as `entity://<EntityName>` URIs. A special `moqui://mcp/instructions` resource is available to `McpUser` group members.

---

## 4. Agent Runtime

`AgentServices.xml` hosts an embedded agent runtime for background autonomous tasks using OpenAI-compatible APIs (VLLM, Ollama, OpenAI).

### 4.1 Message Types

| Type | Purpose |
|------|---------|
| `SmtyAgentTask` | CommEvent-based conversation with full thread history |
| `SmtyLlmRequest` | Single async request with callback (new pattern) |
| `SmtyLlmResponse` | Stored response for audit/callback |

### 4.2 Task Flow

**`SmtyAgentTask` (conversation thread pattern):**
1. Create `SystemMessage` (type `SmtyAgentTask`) with `rootCommEventId`.
2. `poll#AgentQueue` picks it up every 30 seconds (cron: `0/30 * * * * ?`).
3. `run#AgentTaskTurn` loads thread history from `CommunicationEvent` records, calls LLM.
4. Tool calls: saved as `CommunicationEvent`, executed via `call#McpToolWithDelegation`, results saved back.
5. Re-queues a new `SmtyAgentTask` turn until LLM returns a final response.

**`SmtyLlmRequest` (callback pattern):**
1. Any service calls `process#LLMRequest` with a prompt and `callbackServiceName`.
2. Poller picks it up, calls LLM with prompt directly, no thread history.
3. Response saved as `SmtyLlmResponse`; `callbackServiceName` invoked with `llmResponse`, `llmResponseSystemMessageId`, `llmRequestSystemMessageId`.

### 4.3 Tool Delegation

`call#McpToolWithDelegation` briefly impersonates `runAsUserId` via `ec.user.internalLoginUser()`, executes the tool through `McpToolAdapter`, then restores the agent identity. This ensures the agent operates with the target user's RBAC permissions, not the agent's own.

### 4.4 AI Configuration

`ProductStoreAiConfig` (keyed by `productStoreId` + `aiConfigId`) stores per-store LLM configuration:
- `endpointUrl`, `apiKey` (encrypted), `modelName`
- `temperature`, `maxTokens`
- `serviceTypeEnumId`: `AistOpenAi`, `AistVllm`, `AistAnthropic`, `AistOllama`

`call#OpenAiChatCompletion` is a generic OpenAI-compatible client; the same service handles VLLM and Ollama endpoints.

---

## 5. Security Model

Security uses Moqui's native artifact authorization — agents cannot bypass business rules.

### 5.1 User Groups

| Group | Purpose |
|-------|---------|
| `McpUser` | Human users accessing MCP (can use all MCP services, REST path `/mcp`) |
| `MCP_ALL_ACCESS` | Testing — broad access |
| `AgentUsers` | Autonomous agent accounts; allowed to call `call#McpToolWithDelegation` only |
| `ADMIN` | Always has access to all MCP services (`AUTHZT_ALWAYS`) |

### 5.2 Built-in Accounts

| Account | Username | Group | Purpose |
|---------|----------|-------|---------|
| `MCP_USER` | `mcp-user` | `McpUser` | Default human MCP access account |
| `AGENT_CLAUDE` | `agent-claude` | `AgentUsers` | Autonomous agent runner; impersonates target users via delegation |

`AGENT_CLAUDE_PARTY` (`partyId`) is a Person party used as `fromPartyId` in `CommunicationEvent` records created by the agent.

### 5.3 Artifact Groups

| Group | Members | Authorized To |
|-------|---------|---------------|
| `McpServices` | `McpServices.*`, `mcp#Initialize`, `list#Tools`, `mcp#ToolsCall`, `mcp#Ping` | `McpUser` (allow), `ADMIN` (always) |
| `McpRestPaths` | `/mcp`, `/mcp/*` | `McpUser` |
| `AgentDelegationServices` | `AgentServices.call#McpToolWithDelegation` | `AgentUsers` |

### 5.4 REST API Lockdown (GrowERP)

GrowERP's `GrowerpRestApiDisableData.xml` (in the `growerp` component) applies `AUTHZT_DENY` on `ADMIN` and `ALL_USERS` for:
- `/rest/s1/moqui/...` — Moqui Tools API
- `/rest/s1/mantle/...` — Mantle USL API
- `/rest/s1/mantle/my/...` — Mantle My Info API

This forces all data access through the MCP endpoint or GrowERP-specific REST routes, maintaining semantic and audit trails.

---

## 6. Getting Started

### 6.1 Backend Setup

```bash
# Start Moqui with moqui-mcp component loaded
cd moqui
java -jar moqui.war no-run-es

# MCP endpoint: http://localhost:8080/mcp
# Admin: http://localhost:8080/vapps  (user: SystemSupport, pass: moqui)
```

Connect any MCP-compliant client (Claude Desktop, Claude Code, curl) to `http://localhost:8080/mcp`.

```bash
# Quick health check
curl -X POST http://localhost:8080/mcp \
  -H "Content-Type: application/json" \
  -u mcp-user:moqui \
  -d '{"jsonrpc":"2.0","id":1,"method":"ping","params":{}}'
```

### 6.2 Flutter Client Integration

**McpChatView** (`flutter/packages/growerp_core/lib/src/mcp/mcp_chat_view.dart`) provides an embedded chat UI for MCP interactions.

**Input syntax (service tools only — no screen browsing in Flutter):**
| Prefix | Tool invoked |
|--------|-------------|
| `svc <query>` | `moqui_search_services` |
| `svc! <name>` | `moqui_get_service_details` |
| `exec! <name> {json}` | `moqui_execute_service` |
| Any other text | First matches `menuItems` (in-app navigation chips), then `moqui_search_services` |

**Features:**
- JSON-RPC 2.0 over HTTP POST (no SSE required)
- Session management via `Mcp-Session-Id` header
- `McpMenuEntry` list for direct in-app navigation chips
- Formatted output rendering, auto-scroll, status indicators

**Menu registration** (`GrowerpMenuSeedData.xml`):
```xml
<growerp.menu.MenuItem menuItemId="CORE_EX_MCP" menuConfigurationId="CORE_EXAMPLE_DEFAULT"
    title="MCP Chat" route="/mcp" iconName="smart_toy" widgetName="McpChatView" sequenceNum="60"/>
```

---

## 8. Internal Organization

### 8.1 Source Code (`src/main/groovy/org/moqui/mcp/`)

**Servlet & Adapters:**
- **`EnhancedMcpServlet.groovy`**: HTTP entry point. Handles JSON-RPC 2.0, SSE upgrades, session lifecycle. Delegates to adapters.
- **`adapter/McpSessionAdapter.groovy`**: Session creation, lookup, activity tracking, statistics. Uses in-memory `ConcurrentHashMap` cache plus 30-second throttled DB updates.
- **`adapter/McpToolAdapter.groovy`**: JSON-RPC method → service routing and the cached growerp service-name list.
- **`adapter/MoquiNotificationMcpBridge.groovy`**: Bridges Moqui notification system to MCP SSE push events.
- **`transport/SseTransport.groovy`**: SSE connection fan-out, keep-alive (30s), max 100 concurrent connections.
- **`transport/MoquiMcpTransport.groovy`**: Low-level transport abstraction.

### 8.2 Services (`service/`)

- **`McpServices.xml`**: All JSON-RPC method handlers (`mcp#Initialize`, `mcp#ToolsCall`, `mcp#ResourcesList`, `mcp#GetHelp`, `mcp#RestCall`, `list#Tools`, prompts, resources subscribe/unsubscribe, roots, sampling, elicitation). This is the primary service file.
- **`AgentServices.xml`**: Agent Runtime services: `call#McpToolWithDelegation`, `call#OpenAiChatCompletion`, `process#LLMRequest`, `run#AgentTaskTurn`, `poll#AgentQueue`, `callback#CommunicationEvent`.
- **`Agent.secas.xml`**: SECA rules for agent event-driven triggers.
- **`UpdateAgentConfig.xml`**: Services for updating `ProductStoreAiConfig` records.
- **`service/org/moqui/mcp/McpTestServices.xml`**: Test/debug services.

### 8.3 Data Models (`entity/`)

- **`AgentEntities.xml`**:
  - `extend-entity SystemMessage` — adds fields: `requestedByPartyId`, `effectiveUserId`, `productStoreId`, `aiConfigId`, `rootCommEventId`, `parentSystemMessageId`, `callbackServiceName`, `callbackParameters`, `sourceTypeEnumId`, `sourceId`, `llmResponse`.
  - `ProductStoreAiConfig` — per-store AI gateway configuration (endpoint, API key, model, temperature, max tokens, system prompt template).
  - Seeds `AiServiceType` enumeration: `AistOpenAi`, `AistVllm`, `AistAnthropic`, `AistOllama`.
- **`McpCoreEntities.xml`**: Empty. MCP uses Moqui's built-in entities (authentication, audit logging, permissions) without custom schema additions.

### 8.4 Seed Data (`data/`)

- **`McpSecuritySeedData.xml`**: User groups (`McpUser`, `MCP_ALL_ACCESS`), artifact groups (`McpServices`, `McpRestPaths`), authorization rules, `MCP_USER` account.
- **`AgentData.xml`**: `AgentUsers` group, `AGENT_CLAUDE`/`AGENT_CLAUDE_PARTY`, `AgentDelegationServices` artifact group, `AgentQueuePoller` job (cron every 30s), `SmtyAgentTask`/`SmtyLlmRequest`/`SmtyLlmResponse` message types.
- **`AgentEnumData.xml`**: Additional agent-related enumerations.
- **`McpServiceDocsData.xml`**: Wiki service docs (`wiki:service:*`) plus the server root instructions page.
- **`McpPromptsData.xml`**: Pre-configured system prompts and behaviors.
- **`BusinessProcessesData.xml`**: Business workflow documents (`wiki:workflow:*`, served by `moqui_get_help`).

### 8.5 Tests (`test/`)

- **`test/client/McpTestClient.groovy`**: Groovy MCP client for integration tests.
- **`test/java/.../McpIntegrationTest.java`**, **`McpJavaClient.java`**: Java integration test suite.
- **`test/run-tests.sh`**: Test runner script.
