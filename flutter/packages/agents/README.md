# GrowERP Agents App

GrowERP vertical for Android, iOS, Web, Linux and Windows (Flutter) for AI agent
governance: chat with ADK agents, review/approve agent jobs and actions, plus light
organization (company, employees, website) and system setup.

Built from these building blocks (`flutter/packages/growerp_*`):

- `growerp_user_company` — companies, users, employees
- `growerp_website` — public website
- `growerp_adk` — AI chat (`AdkChatView`), agents, MCP servers, jobs, approvals,
  action audit (`AdkAgentListView`, `AdkMcpServerListView`, `AdkJobListView`,
  `AdkApprovalsListView`, `AdkActionsListView`, `AdkKnowledgeView`)

App-specific: `AgentsDashboard` (reorderable, menu-driven dashboard) and
`SystemSetupDialog`.

The dashboard, menu and navigation are server-driven (`MenuConfigBloc`, applicationId
`agents`) and can be reordered/customized per user.

Backend: Moqui ERP (moqui.org) — see `docs/Flutter_Moqui_REST_Backend_Interface.md` in the
repo root for the REST API, and the root `CLAUDE.md` / `README.md` for setup.
