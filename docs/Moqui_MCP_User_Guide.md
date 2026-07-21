# Moqui MCP User Guide

**Moqui MCP** connects AI clients — Claude Desktop, Claude Code, curl, or GrowERP's own Flutter
chat — directly to the GrowERP backend through the [Model Context Protocol](https://modelcontextprotocol.io)
(MCP). Through it, a client can discover and execute `growerp.*` services, inspect data read-only,
follow documented business workflows, and search company knowledge — no browser automation or
raw API scraping needed.

GrowERP uses a Flutter frontend; the Moqui web UI is **not** exposed over MCP, so every tool here
is service-based (no screen browsing/rendering).

For the technical/developer reference (protocol internals, source layout, entities), see
[moqui-mcp/MCP_SERVER_DOCUMENTATION.md](../moqui-mcp/MCP_SERVER_DOCUMENTATION.md). For attaching
external MCP servers to an ADK agent, see the
[Agent Control Center User Guide](./Agent_Control_Center_User_Guide.md#mcp-servers-external-tools).
For the full architecture, see the
[Agent Control Center & Moqui MCP Guide](./AGENT_CONTROL_CENTER_AND_MCP_GUIDE.md).

---

## Connecting to the server

- **Endpoint**: `http://<host>:8080/mcp`
- **Transport**: HTTP POST (synchronous JSON-RPC 2.0) works with any MCP client. An SSE stream is
  also available at `/mcp/sse` for real-time notifications.
- **Auth**: sign in as a Moqui user in the `McpUser` group. The default account for human/manual
  use is `mcp-user` / `moqui`.

Quick health check:

```bash
curl -X POST http://localhost:8080/mcp \
  -H "Content-Type: application/json" \
  -u mcp-user:moqui \
  -d '{"jsonrpc":"2.0","id":1,"method":"ping","params":{}}'
```

## Connecting an MCP client (Claude Desktop / Claude Code)

Point the client at the `/mcp` endpoint with basic auth, e.g. in Claude Desktop's
`claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "growerp": {
      "url": "http://localhost:8080/mcp",
      "headers": {
        "Authorization": "Basic bWNwLXVzZXI6bW9xdWk="
      }
    }
  }
}
```

(`bWNwLXVzZXI6bW9xdWk=` is `mcp-user:moqui` base64-encoded — use your own account's credentials
for anything beyond local testing.)

## Using GrowERP's built-in chat

The Flutter apps embed `McpChatView` (a chat screen that talks to the same MCP endpoint). Type:

| Input | Tool invoked |
|---|---|
| `svc <query>` | `moqui_search_services` |
| `svc! <name>` | `moqui_get_service_details` |
| `exec! <name> {json}` | `moqui_execute_service` |
| anything else | matches in-app navigation first, then falls back to `moqui_search_services` |

## Available tools

| Tool | Purpose |
|---|---|
| `moqui_search_services` | Find `growerp.*` services by keyword (noun/verb), e.g. `product`, `order` |
| `moqui_get_service_details` | Full input/output parameters for one service |
| `moqui_execute_service` | Run a `growerp.*` service with parameters, subject to your account's permissions |
| `moqui_rest_call` | Read-only (GET) REST inspection: `e1/{Entity}/{id}`, `m1/{Entity}/{master}/{id}`, `s1/moqui/...`, `s1/mantle/...`, plus swagger discovery |
| `moqui_get_help` | Wiki docs for a service (`wiki:service:<Name>`) or a multi-step business workflow (`wiki:workflow:<Name>`, e.g. `Order-Entry`) |
| `moqui_prompts_list` | List available MCP prompt templates |
| `moqui_prompts_get` | Render a specific prompt template with arguments |
| `searchKnowledge` | Search the company's ingested knowledge base (RAG) |
| `okf_index` / `okf_load_concept` / `okf_follow` | Navigate the curated OKF domain-knowledge bundle (data model, entities, relationships) |

## Worked example: find, inspect, execute

1. **Search**: `moqui_search_services(query="product")` — returns matching services with a short
   description and their required/optional parameters.
2. **Inspect**: `moqui_get_service_details(serviceName="growerp.100.CatalogServices100.get#Products")`
   — full parameter list before you commit to calling it.
3. **Execute**: `moqui_execute_service(serviceName="growerp.100.CatalogServices100.get#Products", parameters={...})`
   — runs the service, respecting your account's RBAC permissions.

For anything more than a single call, check `moqui_get_help(uri="wiki:workflow:Order-Entry")` first
— multi-step processes (order entry, approvals, shipment receive) are documented as exact tool-call
sequences.

## Permissions

Every call runs under your authenticated account's normal Moqui authorization — MCP does not grant
extra access. `moqui_rest_call` is GET-only (no create/update/delete). If a service or entity isn't
visible to your account outside MCP, it won't be visible through MCP either.
