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
* **Model**: The underlying LLM model (e.g., `gemini-2.5-flash`).
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
* **Model**: The AI model the agent will use. Defaults to `gemini-2.5-flash`.
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

## Best Practices
* **Start Small**: Use the `Read-only` tool mode when testing a new agent to prevent accidental data modifications.
* **Be Specific**: Write clear and highly specific system instructions.
* **Use Scopes**: If an agent needs to create specific records (like tasks or emails), use the `Scoped` tool mode and only allow-list the exact services required.
* **Monitor with Approvals**: Use the `Require approval` write policy for critical actions to keep a human in the loop.
