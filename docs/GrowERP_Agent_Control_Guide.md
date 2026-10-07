# GrowERP Agent Control Guide

How to control what GrowERP's AI agents may do, what they cost, when they run and how you check up on them. One section per control lever:

- **What it does** and **where to set it**, for company admins.
- **Enforced by**, for developers: the service or file that actually applies the rule.
- **Gaps**: limits you should know about.

This guide covers *control*. For the full feature tour (chat, knowledge, OKF, memory, wiki) see [Agent Control Center and Moqui MCP](AGENT_CONTROL_CENTER_AND_MCP_GUIDE.md). For a step-by-step end-user walkthrough see the [Agent Control Center User Guide](Agent_Control_Center_User_Guide.md).

---

## 1. The control model

Every agent action passes through the same gate, whoever started it:

```
  you in AI Chat ──┐
  a schedule ──────┼──► agent (LLM) ──► tool call ──► governance gate ──► GrowERP service
  the task loop ───┤                                  (govern#AgentAction)
  website visitor ─┘                                   │
                                                       ├─ blocked  → agent is told why
                                                       ├─ pending  → approval request, nothing runs
                                                       └─ allowed  → runs as the agent's user, logged
```

Five questions decide what happens:

| Question | Control | Section |
|---|---|---|
| Who is acting? | the agent's own user | 2 |
| Which services may it touch? | tool mode, allow list, company pin | 3 |
| May it change data without asking? | write policy, approvals | 4 |
| How much may it spend? | token allowance, LLM-call cap | 5 |
| When does it run by itself? | schedules, task loop | 6, 7 |

Everything it does is logged (section 11).

### Chat rooms

An agent talks to you in up to three chat rooms: the **results** room (scheduled runs), the **approval** room (approval cards) and the **task inbox** (task loop). All three are chosen the same way in the agent dialog:
- one of your company's group chat rooms, by name, or
- **New room (created automatically)**, the default.

A new room is created the first time it is needed, named "ADK: <agent>", "Approvals: <agent>" or "Tasks: <agent>". The company admin is added as a member, so the room shows in the chat list, and the room is saved on the agent. A room of another company is never used.

**Enforced by.** `AdkGovernanceServices.ensure#AgentChatRoom`, used by `run#ScheduledAgent`, `govern#AgentAction` and the task loop.

---

## 2. Identity: the agent's own user

**What it does.** An agent never acts as you or as the system administrator. Each company gets an agent person, `AGENT_<company>` ("AI Agent"). It is an employee of the company and has a login account with no password (`agent-AGENT_<company>`). Data the agent creates or changes is recorded under that user.

**Where to set it.** Nothing to set; it is created automatically. An agent may name a different party in `agentPartyId`; this is not shown in the screens.

**Enforced by.**
- `AdkGovernanceServices.ensure#AgentUser` creates the person, the employee relationship and the user, and adds the user to `GROWERP_M_EMPLOYEE`.
- `moqui-mcp/service/McpServices.xml` wraps every service call in `ec.user.internalLoginUser(agentUsername)`.

**Gaps.** A write that you *approve* (section 4) runs as **you**, the approver, not as the agent user. So it gets your company and your audit name.

---

## 3. Tool access: which services an agent may reach

Set these in **AI Agents → (agent) → Permissions & governance**.

| Control | Values | Default for a new agent |
|---|---|---|
| **Tool mode** (`toolMode`) | `readOnly`: only read services (get, find, search, list, check, …); write tools are not even offered.<br>`scoped`: only services matching the allow list.<br>`full`: any `growerp.*` service. | `readOnly` |
| **Service allow list** (`serviceAllowlist`) | Comma-separated globs, e.g. `*list#OutreachMessages,*create#MasterContent`. Used only in `scoped` mode. | empty |
| **Web search** (`webSearch`) | Adds Google Search (Gemini agents only). | off |
| **Tools & integrations** | External MCP servers attached to the agent (section 9). | none |

**Company pin.** Whatever the agent sends, a service that takes `ownerPartyId` always gets the agent's own company. An attempt to name another company is blocked: "Cross-tenant access denied".

**In-process tools.** Email (`sendEmail`), GitHub and Substack write tools are only given to agents whose tool mode is not `readOnly`. **Task-loop agents never get them** (section 7). These tools do **not** pass the write policy, so tool mode is the only control on them.

**Enforced by.**
- `AdkGovernanceServices.govern#AgentAction`: read/write classification by service verb, allow-list globs, company pin.
- `AdkManager.buildMcpToolset`: keeps the write tool out of a read-only agent's tool list.
- `AdkManager.assembleFunctionTools`: in-process write tools.

**Gaps.**
- Legacy agents saved before governance existed have an empty tool mode, which is treated as `full`.
- An entity-auto service such as `create#Product` counts as a write by its verb prefix; check the allow list matches the service name the agent really calls.

---

## 4. Write policy and approvals

**What it does.** Decides what happens when an allowed write comes in.

| Write policy (`writePolicy`) | Effect |
|---|---|
| `block` | The write is refused; the agent is told. |
| `approve` (default) | The write is **held**. An approval request is created and the agent is told "queued for approval". Nothing runs until a person decides. |
| `allow` | The write runs immediately, **except** the services below. |

**Always held for approval**, even with `allow`: `create#Order`, `update#Order`, `create#Invoice`, `update#Invoice`, `create#Payment`, `update#Payment`, `create#Shipment`. They serve both sales and purchasing, and only a parameter tells the two apart, so an allow list cannot separate them safely.

**Where to set it.**
- **Write policy** in the agent dialog.
- **Approval chat room** (`approvalChatRoomId`): each request is also posted there as a card. Pick a room (see *Chat rooms* below).
- Decide under **AI Agents → Approvals**. Approve runs the stored service with the stored parameters and records the result; reject never runs it.

**Task loop.** A held write from a task-loop run is linked to its task. The task waits ("Needs your approval") and goes back to the queue as soon as you decide (section 7).

**Enforced by.**
- `govern#AgentAction` writes `moqui.adk.AdkApproval` (status pending) and an `AdkActionLog` row (decision pending).
- `approve#AdkApproval` / `reject#AdkApproval` are reached through REST `AdkApproval` (PUT); they check that the approval belongs to your company.

**Gaps.**
- An approved write runs as the approver (section 2).
- `expire#AdkApprovals` exists, but nothing sets `expireTime` and no job calls it, so pending requests stay pending until decided.

---

## 5. Cost control

| Control | What it does | Where |
|---|---|---|
| **Monthly token allowance** | When a company's tokens this month reach its limit, new runs and further tool calls are blocked. Limit: with your own API key, your own-key limit (0 = unlimited); otherwise the company's monthly limit, else the system default (seed: 100 000 tokens). | System Setup (company AI settings) |
| **LLM calls per run** (`maxLlmCalls`) | The agent stops after this many model calls in one run ("Max number of llm calls limit of N exceeded"). Default 10. | Agent dialog |
| **LLM Usage** | Tokens per company and per agent. | AI Agents → LLM Usage |

**Enforced by.**
- `AdkGovernanceServices.check#TokenAllowance` runs from `govern#AgentAction` on every call, and from `AdkManager.allowanceBlock` before a run.
- `AdkManager.defaultRunConfig` sets `maxLlmCalls`.
- Usage is summed from `AdkActionLog.tokensTotal` (view `AdkOwnerTokenSummary`).

See [LLM and API Key Architecture](GrowERP_LLM_And_API_Key_Architecture.md) for keys, providers and the default model.

**Gap.** A service that returns a very large result costs tokens in proportion. For example, `get#Product` with images and long descriptions cost about 0.77 M input tokens for a single "how many products" question. Point such agents at summary services, or keep the LLM-call cap low.

---

## 6. Scheduling

**What it does.** Runs an agent by itself on a schedule. Each run uses the **schedule prompt** (or the instruction when the prompt is empty) and posts the result in the **results chat room**.

**Where to set it.**
- In the agent dialog: **Enable scheduled runs**, **Change** (schedule picker), **Prompt for each scheduled run**, **Results chat room**.
- Watch and manage runs under **AI Agents → Agent Jobs**: pause, resume, clear a stuck lock.

**Rules.**
- The schedule is stored as a cron expression in the **server time zone (UTC)**. The screen converts to and from your local time.
- Only one run of an agent at a time: a run lock means a check never overlaps a run still in progress.
- An agent with `[[...]]` placeholders in its instruction, a disabled agent, or a shared catalog template (`_NA_`) is never scheduled.
- A stale lock (server restarted mid-run) blocks the job; clear it in Agent Jobs.

**Enforced by.**
- `AdkSchedulerServices.sync#AgentJob` creates or updates one Moqui `ServiceJob` per agent (`adk_scheduled_<id>`).
- The seed job `AdkScheduledAgents` (`run#AllScheduledAgents`, every minute) pauses jobs of agents that are no longer scheduled and adds missing ones.
- `run#ScheduledAgent` performs the run. A task-loop agent is handed to `AdkLoopServices.run#AgentLoop` instead.

---

## 7. Task loop: an agent that works an inbox

**What it does.** Turns a scheduled agent into a worker you hand jobs to and that reports back. It follows the "loop engineering" pattern: inbox → trigger → ticket → work → report → reply.

| Part | In GrowERP |
|---|---|
| **Inbox** | (a) New messages in the agent's **task inbox chat room**, and (b) open **to-dos assigned to "AI Agent"** in Tasks. |
| **Trigger** | The agent's schedule; switching the loop on sets every 10 minutes. |
| **Ticket** | Every request becomes a to-do Activity *before* any work starts: name = first line, description = your text word for word. |
| **Work** | One agent run per task, at most **3 tasks per check**. The run sees the request and all comments on the task. |
| **Report** | In the same run: a short plain-English message in the inbox room (`#<task id> Done / Question / Needs your approval / Problem`) plus an email. Technical detail goes into the task's comments. |
| **Reply** | Answer in the room starting with `#<task id>`, or just answer if the agent is waiting on a question from you, or add a comment on the task. |

**Task states.** The task's own status is shown in brackets.

| State | Meaning | What re-queues it |
|---|---|---|
| queued | waiting for the next check | — |
| working (In Progress) | the agent is on it | — |
| waiting: question (On Hold) | the agent asked you something, with a default | your reply or comment |
| waiting: approval (On Hold) | a write is held under Approvals | your approve/reject decision |
| waiting: error (On Hold) | the run failed (LLM-call cap, token limit, model error, restart) | a comment |
| done (Complete) | finished, proof in the comments | a new comment re-opens it |

**Never waits.** A question or a held write parks only that task; the loop carries on with other tasks.

**Claims by id, never by date.** Each chat message is recorded once in `AdkLoopInbox`. The first check of a room takes the existing messages as history, so old chat is never turned into tasks.

**Where to set it.** AI Agents → (agent):

1. Enable scheduled runs.
2. Switch on **Task loop**.
3. Pick the **Task inbox chat room** (see *Chat rooms* below). A new room is named "Tasks: <agent>".
4. Set the **Report email** (optional). By default reports go to the email of whoever asked. No email server configured → the admin gets the usual "email not configured" notice, and the report still reaches the room and the task.

**Recommended settings for a loop agent.**
- Write policy **approve**.
- Tool mode `full` or `scoped`, depending on what you hand it.
- `maxLlmCalls` around 20.
- A clear instruction about your business.

The prompt the loop adds tells the agent to do reversible work itself, to ask instead of deleting, publishing, emailing, spending or touching secrets, and to report proof.

**Enforced by.**
- `moqui-adk/service/AdkLoopServices.xml`: `run#AgentLoop`, `claim#LoopInbox`, `route#ChatMessage`, `work#LoopTask`, `report#LoopTask`, `requeue#LoopTask`.
- Entities `AdkLoopTask` and `AdkLoopInbox`.
- `AdkApproval.workEffortId` links held writes to their task.
- Task comments use REST `ActivityNote` (`ActivityServices100.get#ActivityNotes` / `create#ActivityNote`) and the **Comments** button in the task dialog.

**Gaps.**
- Rules such as "never email anyone else" are in the prompt. The hard limits are the write policy, the tool mode and the missing in-process write tools.
- A task that stays in the error state is not retried by itself; add a comment.

---

## 8. Teams and delegation

**What it does.** A **coordinator** agent hands work to its **members**:
- as a tool (`delegationMode` = `tool`, the default; the coordinator keeps control), or
- by transfer (`transfer`; the member takes over the conversation).

Workflow agents run members in sequence, in parallel or in a loop (`loopMaxIterations` caps the loop).

**Control points.**
- Each member keeps its **own** tool mode, allow list and write policy; the gate records both the member and the coordinator (`parentConfigId`).
- A member must belong to the same company as the coordinator.
- Routing is decided by the member's **description**: always give each member a one-line "use for …" description (a member without one breaks routing).

**Where to set it.** Agent dialog → Team / orchestration (role, orchestration type, members). Team name groups agents in the list and for download/upload.

See [Agent Teams Overview](AI_Agent_Teams_Overview.md), [Marketing Agent Team](Marketing_Agent_Team_User_Guide.md) and [Partner Scout](Partner_Scout_Agent_User_Guide.md).

---

## 9. External MCP servers (Tools & integrations)

**What it does.** Gives an agent the tools of a remote MCP server (SSE or streamable HTTP).

**Where to set it.**
- Register the server under **AI Agents → Tools & Integrations** (name, URL, transport, headers).
- Attach it in the agent dialog.

**Controls.**
- Headers (API keys) are encrypted at rest and never returned by the API.
- A server only works for agents of the company that registered it; cross-company links are skipped and logged.
- Agent test runs leave external servers out.

**Gaps.** Calls to an external server do **not** pass `govern#AgentAction`: no write policy, no approvals, no action log. Attach a server only to agents you trust with everything that server can do.

**Enforced by.** `AdkManager.loadExternalMcpToolsets` (company guard) and the entities `AdkMcpServer` / `AdkAgentMcpServer`.

---

## 10. Website chat

**What it does.** One agent (`websiteChat` = Y) answers visitors on your public website.

**Controls.**
- Keep it `readOnly`: it answers from your knowledge base.
- It can hand a conversation to a person (`requestHumanHandoff`). That sets the room's `agentActive` to N, so the agent stops replying and your team is notified.

**Enforced by.** `AdkChatServices.reply#WebsiteChatAgent`, `escalate#WebsiteChat` and `HandoffTool`.

---

## 11. Audit: the action log

**What it does.** Every governed call writes one `AdkActionLog` row:
- the agent and its coordinator, and the session
- the tool and service, and the arguments
- read or write (`verbClass`)
- the **decision** (allowed / blocked / pending / approved / rejected) and the reason
- a result summary, and tokens in, out and total.

Each agent run also writes an `agentRun` row with its tokens.

**Where to see it.** AI Agents → **Agent Actions** (open a row for detail). Approvals show the pending subset.

Section 6 of [Agent Control Center and Moqui MCP](AGENT_CONTROL_CENTER_AND_MCP_GUIDE.md) explains how to read the log.

---

## 12. Shared agent catalog

- Agents owned by `_NA_` are **templates**: never scheduled and never run themselves. A company copies one; the copy is its own agent with its own controls.
- A template with `[[...]]` placeholders stays inactive until the company fills them in.
- Promotion into the catalog never copies the API key, agent party or chat room IDs (including the task-loop settings): a company's own IDs must not leak into a shared template.
- A company can **nominate** its own agent for the catalog; only GrowERP support promotes it. `catalogPublished` = N hides a template.

---

## 13. Recommended presets

| Purpose | Tool mode | Write policy | Other |
|---|---|---|---|
| Analyst / digest | `readOnly` | (n/a) | schedule + results room |
| Task-loop assistant | `full` or `scoped` | `approve` | task loop on, `maxLlmCalls` ≈ 20, report email |
| Trusted automation (one job) | `scoped` with a tight allow list | `allow` | money services are still held |
| Website chat | `readOnly` | (n/a) | knowledge base filled, handoff on |

---

## 14. Related documents

- [Agent Control Center and Moqui MCP: Comprehensive Guide](AGENT_CONTROL_CENTER_AND_MCP_GUIDE.md): feature tour, toolset, chat, knowledge, OKF, memory
- [Agent Control Center User Guide](Agent_Control_Center_User_Guide.md): screens step by step
- [Agent Control Center Demo](Agent_Control_Center_Demo.md): demo walkthrough with the Operations Team
- [Agent Teams Overview](AI_Agent_Teams_Overview.md)
- [Marketing Agent Team User Guide](Marketing_Agent_Team_User_Guide.md)
- [Partner Scout Agent User Guide](Partner_Scout_Agent_User_Guide.md)
- [GrowERP Security Model](GrowERP_Security_Model.md): user groups, menus, REST authorization
- [LLM and API Key Architecture](GrowERP_LLM_And_API_Key_Architecture.md)
- [Moqui MCP User Guide](Moqui_MCP_User_Guide.md)
- [MCP Server Documentation](../moqui-mcp/MCP_SERVER_DOCUMENTATION.md)
- [moqui-adk README](../moqui-adk/README.md)
