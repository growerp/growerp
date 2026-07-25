# GrowERP Agents — User Guide

GrowERP Agents is a GrowERP frontend for managing AI agents: chat with
them, give them tools, review what they've scheduled, approve or deny
anything sensitive before it happens, and audit everything they've
already done. Runs on Android, iOS, web, Linux and Windows, backed by a
Moqui server.

## Getting started

1. Open the app. If no company exists yet you'll see a prompt to register
   one.
2. **Register new company and admin** creates your company and its first
   admin user. A temporary password is emailed to you.
3. **Login** signs in with an existing account; **Forgot password** resets
   it by email.
4. Pick your language from the login screen's selector.

The admin can add other users from **Organization**, and configure the
AI provider/model under **System Setup** before agents can run.

## Menu overview

- **Main** — dashboard
- **AI Agents** — chat with an agent, or create/edit agent configurations
- **MCP Servers** — the tool connections an agent is allowed to use
- **Agent Jobs** — scheduled and recurring agent runs
- **Approvals** — actions an agent wants to take that need a human
  sign-off first
- **Agent Actions** — audit trail of every action an agent has taken
- **Knowledge** — reference material agents can search and cite
- **Wiki** — knowledge-base pages
- **Organization** — company, employees, website
- **System Setup** — AI provider/model configuration

Your profile and company details are reachable from the drawer.

## Core workflow: configure, chat, approve, audit

### 1. Configure an agent

Under **System Setup**, pick an AI provider and model. Under **AI
Agents → +**, create an agent, give it instructions, and under **MCP
Servers** grant it the specific tools/data sources it's allowed to use.

### 2. Chat with an agent

Open an agent from **AI Agents** (or the chat icon on the dashboard) and
talk to it directly — ask it to look something up, summarize, or
perform a task.

### 3. Approve sensitive actions

If an agent's instructions call for an action that needs sign-off
(e.g. sending an email, changing a record), it shows up under
**Approvals** instead of running immediately. Approve or deny it there;
denied actions don't execute.

### 4. Review scheduled work

**Agent Jobs** lists anything running on a recurring schedule (e.g. a
daily summary). Enable, disable or check the last run status here.

### 5. Audit what happened

**Agent Actions** is the full history: every action any agent has taken,
whether it needed approval, and the outcome — useful for spotting
mistakes or tightening an agent's permissions.

## Knowledge

**Knowledge** and **Wiki** hold the documents and pages agents search
before answering, so keeping them current directly improves answer
quality.

## Backend

Requires a running Moqui backend (moqui.org). See the main
[GrowERP README](../../../README.md) for setup instructions.
