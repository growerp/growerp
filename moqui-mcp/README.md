# Moqui MCP: AI Agents in the Enterprise

**Give AI agents real jobs in real business systems.**

## What This Is

Moqui MCP connects AI agents to [Moqui Framework](https://www.moqui.org/), the open-source ERP
backend of [GrowERP](https://www.growerp.com/). Through MCP (Model Context Protocol), agents
discover and execute Moqui services, inspect live data read-only through the REST API, follow
documented business-process workflows, and search company knowledge.

GrowERP uses a Flutter frontend; the Moqui web UI is **not** used. This component therefore
exposes a service-based toolset (no screen browsing/rendering) — the same operations the
Flutter apps perform through REST.

**This isn't a chatbot bolted onto an ERP. It's AI with direct access to business operations.**

## What Agents Can Do

- **Discover** growerp.* services by keyword, with parameter details
- **Execute** services: orders, invoices, shipments, parties, products (respecting authorization)
- **Inspect** any entity or REST endpoint read-only for debugging and analysis
- **Follow** step-by-step business workflows (order entry, approval, shipment receive)
- **Search** the company's ingested knowledge base (RAG) and the curated OKF domain-knowledge bundle

All operations respect Moqui's security model. Agents see only what their user account permits,
and every service execution passes the optional [moqui-adk](../moqui-adk) governance gate
(read-only / scoped / approval-required policies with a full audit trail).

## MCP Tools

| Tool | Purpose |
|------|---------|
| `moqui_search_services` | Find growerp.* services by keyword query |
| `moqui_get_service_details` | Get a service's input/output parameters, types, and descriptions |
| `moqui_execute_service` | Execute a growerp.* service with parameters (governed, authorized) |
| `moqui_rest_call` | Read-only (GET) Moqui REST API: `e1/{Entity}`, `m1/…`, `s1/moqui`, `s1/mantle`, swagger discovery |
| `moqui_get_help` | Wiki docs: `wiki:service:<Name>` and `wiki:workflow:<Name>` (e.g. `Order-Entry`) |
| `searchKnowledge` | RAG search over the tenant's ingested company documents (via moqui-adk) |
| `okf_index` / `okf_load_concept` / `okf_follow` | Navigate the curated OKF domain-knowledge bundle |
| `moqui_prompts_list` / `moqui_prompts_get` | MCP prompt templates |

## Getting Started

```bash
# From the growerp root (component is symlinked by setup-backend.sh)
cd moqui
./gradlew build
java -jar moqui.war load types=seed,seed-initial,install no-run-es
java -jar moqui.war no-run-es

# MCP endpoint (Streamable HTTP): http://localhost:8080/mcp
# Legacy HTTP+SSE endpoint (google-adk McpToolset): http://localhost:8080/mcp/sse
```

Example Claude Code registration (`.mcp.json`):

```json
{
  "mcpServers": {
    "moqui": {
      "type": "http",
      "url": "http://127.0.0.1:8080/mcp",
      "headers": { "Authorization": "Basic <base64 user:password>" }
    }
  }
}
```

## Architecture

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   AI Agent      │────▶│   MCP Servlet    │────▶│ Moqui Services  │
│ (ADK / Claude)  │◀────│  (JSON-RPC 2.0)  │◀────│  + Entity/REST  │
└─────────────────┘     └──────────────────┘     └─────────────────┘
                                │
                        ┌───────┴───────┐
                        ▼               ▼
                ┌──────────────┐ ┌──────────────┐
                │  Governance  │ │  Wiki Docs   │
                │ (moqui-adk)  │ │ + Knowledge  │
                └──────────────┘ └──────────────┘
```

- **MCP Servlet** (`EnhancedMcpServlet`, `/mcp/*`): JSON-RPC 2.0, dual transport
  (Streamable HTTP and legacy HTTP+SSE), session management, authentication via Moqui
  Basic auth / API key
- **Service layer**: direct Moqui service invocation with artifact authorization
- **Governance**: optional per-agent trust gate + audit log provided by moqui-adk
- **Wiki Docs**: service docs (`MCP_SERVICE_DOCS`) and business-process workflows
  (`BUSINESS_PROCESSES`) served via `moqui_get_help`

## Security

Production deployments should:

- Create dedicated service accounts for AI agents
- Use Moqui artifact authorization to limit permissions
- Enable comprehensive audit logging
- Consider human-in-the-loop for sensitive operations (moqui-adk `Require approval` write policy)
- Start with read-only access, expand incrementally

## License

Public domain under CC0 1.0 Universal plus Grant of Patent License, consistent with Moqui Framework.

## Links

- [Moqui Framework](https://github.com/moqui/moqui-framework)
- [MCP Specification](https://modelcontextprotocol.io/)
- [GrowERP](https://github.com/growerp/growerp)
