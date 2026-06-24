# Agent Control Center and Moqui MCP: Comprehensive Guide

The **Agent Control Center (ADK)** and **Moqui MCP** form the foundation of GrowERP's AI-native architecture. Together, they allow organizations to configure, manage, and orchestrate autonomous AI agents that perform real work directly within the ERP system. 

This guide consolidates the complete architecture, features, and operational workflows of these two deeply integrated systems.

---

## 1. Executive Summary

- **Agent Control Center (ADK)**: The UI and orchestration engine within GrowERP. It lets administrators create agents, assign roles (Coordinators vs. Specialists), define permissions (read-only, scoped, or approval-gated writes), schedule cron jobs, and ingest company documents for Retrieval-Augmented Generation (RAG).
- **Moqui MCP**: The underlying integration layer. It connects AI agents to the Moqui Framework using the Model Context Protocol (MCP). Unlike chatbots that only answer questions, Moqui MCP gives agents direct access to enterprise screens, services, and transactions using the structured **MARIA** (MCP Accessible Rich Internet Applications) format.

This isn't a chatbot bolted onto an ERP. It's AI with direct access to your business operations.

---

## 2. Architecture Overview

### How Agents Interact with GrowERP
Agents reach Moqui and GrowERP automatically through a built-in MCP toolset. The architecture follows a clear separation of concerns:

1. **The LLM (e.g., Gemini 2.5 Flash)** processes user requests and determines which tools to call.
2. **The Agent Control Center (ADK)** manages the agent's persona, its system prompt, its memory across sessions, and its assigned team members.
3. **Moqui MCP** acts as the secure bridge. It exposes Moqui services (e.g., `moqui_execute_service`) and screens (e.g., `moqui_browse_screens`) to the LLM as structured JSON-RPC endpoints.
4. **The Security Gate** ensures the LLM's tool calls are strictly governed by the agent's assigned permissions and the underlying user's artifact authorizations.

### The MARIA Format (Moqui MCP)
Enterprise screens are built for humans with visual context. AI agents need structured semantics. Moqui MCP solves this with **MARIA**, a JSON format based on W3C accessibility standards.

MARIA transforms Moqui screens into accessibility trees that LLMs naturally understand. For example, an agent sees a form, its required fields, and the available actions (like `createPerson`) without needing a vision model or browser automation. 

**Why MARIA beats browser automation (like Playwright):**
- **Latency & Token Cost**: Direct JSON-RPC round-trips with semantic-only payloads, saving massive token costs.
- **Reliability**: No brittle CSS selectors or DOM scraping. Stable semantic contracts.
- **Security**: Direct enforcement of fine-grained artifact authorization.

---

## 3. Agent Control Center Features

The Agent Control Center (accessible via the GrowERP Admin menu) is the central hub for AI governance.

### 3.1. Multi-Agent Orchestration
Agents can work together in teams to accomplish complex workflows. 
- **Specialist**: The default role. The agent executes specific tasks directly (e.g., Inventory Specialist).
- **Coordinator**: An agent that manages a team of specialists. Using orchestration types like `Router`, the coordinator LLM automatically picks the best specialist for the user's prompt based on the specialist's description.

### 3.2. Permissions & Governance (The Security Model)
Trust is the biggest blocker for AI in enterprise. GrowERP solves this with strict, granular controls.
- **Tool Access**: 
  - `Read-only`: Agent can only read data.
  - `Scoped`: Agent can only access specific allow-listed services (e.g., `growerp.*#get*`).
  - `Full`: Unrestricted access to available tools.
- **Write Policy (Human-in-the-loop)**:
  - `Block writes`: No modifications allowed.
  - `Require approval`: Any write action (create, update, delete) is paused and queued. It generates an approval request in a designated Chat Room for a human operator to review.
  - `Allow (auto-run)`: Agent performs writes autonomously.

### 3.3. RAG Knowledge Ingestion
Agents can be equipped with domain-specific knowledge (like company policies). The Control Center allows you to upload policy docs, which are chunked and embedded. Agents can then use the `searchKnowledge` MCP tool to retrieve answers securely based on the user's context.

### 3.4. Scheduled Autonomous Runs
Agents don't just react to chat messages; they can run autonomously. You can enable cron schedules for agents (e.g., an "Ops Digest" agent running at 9 AM daily) and have the results delivered directly to a chat room.

### 3.5. External MCP Servers
You can attach external MCP servers (via SSE or HTTP) to agents. For example, attaching a GitHub or specialized reporting MCP server instantly grants the agent those capabilities, still subject to the agent's Tool Access and Write Policy.

---

## 4. The Moqui MCP Toolset

Agents use specific tools to interact with the system. 

**Service Tools** (Primary tools in GrowERP deployments):
- `moqui_search_services`: Find Moqui services by keyword.
- `moqui_get_service_details`: Get a service's input/output parameters and types.
- `moqui_execute_service`: Execute a Moqui service (respecting authorizations).

**Screen Tools** (Used for browsing dynamic application hierarchies):
- `moqui_browse_screens`: Navigate screens and execute actions.
- `moqui_search_screens`: Find screens by name.
- `moqui_get_screen_details`: Get field metadata and dropdown options.

---

## 5. Walkthrough: The "Operations Assistant" Team

The system includes a built-in demo data set that perfectly illustrates these concepts. When loaded, it creates a team of five agents:

1. **Operations Assistant** *(Coordinator / Router)*: Receives the user's prompt and routes it to the correct specialist based on intent.
2. **Inventory Specialist** *(Read-only)*: Can only query stock levels. Safe to run autonomously.
3. **Support Specialist** *(RAG Knowledge)*: Uses the `searchKnowledge` tool to answer questions based on ingested company policy documents.
4. **Sales Specialist** *(Scoped + Require Approval)*: Handles sales quotes. When a user asks to "Create a quote," the agent prepares the API call, but because of the `Require approval` policy, the system pauses execution. A human must go to the **Approvals** screen, review the exact data the agent wants to write, and approve or reject it.
5. **Ops Digest** *(Scheduled)*: Runs via cron to summarize the previous day's orders, posting the results to a chat room.

### The Audit Trail
Every step an agent takes is logged in the **Agent Actions** view. This includes read operations, pending writes, and approvals, complete with token counts and parent-child delegation tracking. 

---

## 6. Best Practices for Deployment

1. **Start Small**: Use `Read-only` mode when testing new agents to prevent accidental data modification.
2. **Scope Tightly**: If an agent is designed to create tasks, assign it `Scoped` tool access and allow-list *only* the specific task creation service.
3. **Enforce Human-in-the-loop**: Use the `Require approval` write policy for any critical business action (like creating orders or sending invoices).
4. **Write Specific Personas**: The system prompt is the agent's operating manual. Be exhaustive in defining its rules, tone, and constraints.
