# Agent Control Center User Guide

The **Agent Control Center** is your central hub for configuring, managing, and orchestrating autonomous AI agents within the GrowERP platform. With the Agent Control Center, you can create agents ranging from simple scheduled tasks to complex multi-agent orchestrations.

## Accessing the Agent Control Center
1. Log in to your GrowERP Admin interface.
2. Open the main menu.
3. Navigate to **Agent Control** (located under the administration or settings group).
4. The list of all currently configured ADK agents will be displayed.

## Agent List View
The main screen lists all your configured agents. For each agent, you can see:
* **Name**: The agent's assigned name.
* **Model**: The underlying LLM model (e.g., `gemini-3.7-flash`).
* **Instruction**: A preview of the agent's system prompt.
* **Schedule**: The cron schedule (if enabled).

From this view, you can:
* Use the **Search bar** to quickly find a specific agent.
* Tap the **+** button (floating action button) to create a new agent.
* Tap the **Edit** icon next to an agent to modify its configuration.
* Tap the **Delete** icon next to an agent to remove it permanently.

---

## Creating and Configuring an Agent

When you tap the **+** button or edit an existing agent, you will open the Agent Configuration Dialog. This dialog is divided into several sections:

### 1. Basic Information
* **Agent Name**: A descriptive, unique name for the agent (required).
* **Model**: The AI model the agent will use. Defaults to `gemini-3.7-flash`.
* **LLM Provider**: The provider hosting the model (e.g., `gemini`, `openai`, `anthropic`). Defaults to `gemini`.
* **Instruction (System Prompt)**: The exact instructions detailing what the agent should do, its persona, and rules to follow.
* **Description**: An optional brief summary of the agent's purpose.
* **API Key**: If left blank, the agent uses the server default API key for the chosen LLM Provider. You can enter a specific key if this agent needs its own billing/rate limits.

### 2. Permissions & Governance
This section controls how much access the agent has to the GrowERP system and what actions it can perform automatically.

* **Tool Access**:
  * `Read-only`: The agent can only read data (fetch reports, list items).
  * `Scoped (allow-list)`: The agent can access specific services defined in the "Allowed services" field (e.g., `growerp.*#get*, mantle.order.*`).
  * `Full`: The agent has unrestricted access to all available tools and services.
* **Write Policy**:
  * `Block writes`: The agent cannot modify data under any circumstances.
  * `Require approval`: Any write action (create, update, delete) will generate an approval request.
  * `Allow (auto-run)`: The agent can perform write actions autonomously.
* **Approval Chat Room ID**: If the write policy requires approval, enter the ID of the chat room where the approval requests will be sent to human operators.
* **Answer website chat**: This agent replies to the public website chat (one agent per company).
* **Search the web**: Gives the agent Google Search (Gemini only), for research agents such as the [Partner Scout](Partner_Scout_Agent_User_Guide.md).
* **Max AI calls per run**: Cost cap per run; empty means 10. Raise it for agents that search and save many records.

Whatever the tool access, an agent's actions run as your company's **AI Agent** user, so everything it reads and creates stays inside your company.

### 3. Team / Orchestration
GrowERP agents can work together. An agent can either be a specialist doing the actual work, or a coordinator managing other agents.

* **Role**:
  * `Specialist`: The default role. The agent executes tasks directly.
  * `Coordinator`: The agent manages a team of specialists to accomplish complex workflows.
* **Orchestration Type (Coordinators only)**:
  * `Router`: The LLM coordinator picks the best specialist for the user's prompt.
  * `Sequential` / `Parallel` / `Loop`: Advanced workflow structures.
* **Max Loop Iterations**: Safety cap for loop workflows (prevents infinite agent loops).
* **Team Members**: If the agent is a coordinator, you can add other specialist agents to its team using the "Add specialist…" dropdown. **Note:** You must save a new coordinator agent first before you can assign team members to it.

### 4. Scheduled Runs
Agents can be triggered automatically on a recurring schedule.

* **Enable scheduled runs**: Toggle this on to make the agent a scheduled task.
* **Cron Expression**: Define the schedule using standard cron syntax (e.g., `0 0 9 * * ?` for every day at 9am). Quick schedules are available via the clock icon.
* **Prompt for each scheduled run**: The explicit prompt given to the agent when the schedule triggers (e.g., "Summarize the orders from the last 24 hours").
* **Chat Room ID for delivery**: If provided, the agent will post the result of its scheduled run to this chat room. If left blank, the run will only be logged.

A schedule only runs while the agent is **active**. An agent added from the agent catalog
with `[[...]]` fill-ins left in its instruction is saved but inactive (marked in the agent
list), and its schedule does not run until every fill-in is replaced. Under **Agent Jobs** you
can pause and resume a schedule; a job whose agent was deleted, unscheduled or made inactive is
paused automatically within a minute.

---

## Running an Agent

To run an agent one time, without a schedule, open the saved agent and tap **Run** next to
Cancel. It always runs the **saved** version of the agent, so save your changes first.

* **Prompt**: leave it empty to use the agent's prompt for scheduled runs, or type a one-off
  task, for example *Find up to 5 new partners in Vietnam.*
* **Simulate writes** (on by default): every create, update or delete goes through the
  permission rules but is not executed. Email, GitHub and Substack tools and external MCP
  servers are left out, because they cannot be simulated. Turn it off for a real run that
  changes data.
* **Check only** runs the rule checks, without any AI call. Errors are problems the next run
  will hit for sure, for example `{name}` in the instruction (read as a variable that does not
  exist) or scheduled runs without a cron expression. Warnings are likely problems, such as an
  allowed service that matches nothing, web search with a provider other than Gemini, or
  `[[...]]` fill-ins that keep the agent inactive.
* **Run** runs the agent once with the prompt. It takes as long as a scheduled run, often a few
  minutes.

The result shows the number of AI calls against the agent's limit, the tokens used and the
duration. Then it lists every tool call with its outcome (**ok**, **simulated**, **approval**
or **blocked**) and the agent's answer. When a run fails you get the error and, for common
mistakes, a fix. The tokens count toward your AI usage like any other run. The result appears
only in this dialog; nothing is posted to the agent's delivery chat room.

The same rule checks also run when you save an agent or upload a team: an agent with errors
is not saved. Open `[[...]]` fill-ins are only a warning: the agent is saved but stays
inactive until they are replaced.

For a back-and-forth instead of a single run, select the agent in **AI Chat**.

## MCP Servers (external tools)

Agents reach Moqui/GrowERP through a built-in MCP (Model Context Protocol) toolset
automatically. You can also give an agent extra tools by registering **external MCP
servers** and attaching them to agents.

### Registering a server
1. Open **MCP Servers** (under Agent Control / the Agents menu).
2. Tap **+** to register one, or tap a row to edit it. Fields:
   * **Server name**: a label for the server (required).
   * **URL**: the server's endpoint, e.g. `https://host/mcp/sse` (required).
   * **Transport**: `SSE` (Server-Sent Events) or `HTTP` (streamable HTTP).
   * **Auth headers**: optional name/value pairs sent on connect (e.g.
     `Authorization: Bearer …`). Header values are stored encrypted and are never shown
     again — re-enter a value to change it.
   * **Enabled**: turn the whole server on/off without deleting it.

Servers are scoped to your company; other tenants never see or use them.

### Attaching a server to an agent
1. Create and **save** the agent first (attachment needs a saved agent).
2. Re-open the agent and find the **MCP servers** section.
3. Use **Attach MCP server…** to add one of your registered servers; the agent gains that
   server's tools on its next run. Use the remove icon to detach.

Changes take effect immediately — the agent is rebuilt in the background, no restart needed.
The same governance applies: an external server's tools are still subject to the agent's
Tool Access and Write Policy.

## Best Practices
* **Start Small**: Use the `Read-only` tool mode when testing a new agent to prevent accidental data modifications.
* **Be Specific**: Write clear and highly specific system instructions.
* **Use Scopes**: If an agent needs to create specific records (like tasks or emails), use the `Scoped` tool mode and only allow-list the exact services required.
* **Monitor with Approvals**: Use the `Require approval` write policy for critical actions to keep a human in the loop.
