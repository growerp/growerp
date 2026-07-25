# GrowERP Marketing — User Guide

GrowERP Marketing is a GrowERP frontend for marketing teams: run a CRM
pipeline, plan and generate content, manage personas and email sequences,
publish landing pages and assessments, and run multi-platform social
outreach — with an AI agent that can look things up and act on your
behalf (with your approval). Runs on Android, iOS, web, Linux and
Windows, backed by a Moqui server.

## Getting started

1. Open the app. If no company exists yet you'll see a prompt to register
   one.
2. **Register new company and admin** creates your company and its first
   admin user. A temporary password is emailed to you.
3. **Login** signs in with an existing account; **Forgot password** resets
   it by email.
4. Pick your language from the login screen's selector.

The admin can add other users (marketers, leads, customers) from **CRM**.

## Menu overview

- **CRM** — To Do/Tasks, Opportunities, Pipeline (kanban board), Leads,
  Customers
- **Marketing** — Content Plans, Content, Personas, Email Sequences,
  Engagements, Landing Pages, Assessments
- **Outreach** — Campaigns, Automation, Platforms, Messages, Send Queue
- **Orders** — Sales Orders, Customers
- **Agent Control** — AI Agents, MCP Servers, Agent Jobs, Approvals,
  Agent Actions, Knowledge, Wiki
- **Organization** — Company, Employees, Website
- **System Setup** — AI provider/model settings

Your profile and company details are reachable from the drawer. The
dashboard's tiles mirror this menu with live mini-charts for pipeline,
outreach and orders.

## Core workflow: plan, publish, promote

### 1. Plan and generate content

**Marketing → Content Plans → +** groups a set of content around a goal.
Under **Content**, generate or add individual pieces (posts, articles)
and target them at a **Persona** so tone and messaging fit the audience.

### 2. Capture leads

Publish a **Landing Page** or **Assessment** to collect visitor
details, or add contacts directly under **CRM → Leads**. An
**Email Sequence** can nurture new leads automatically over time.

### 3. Run outreach campaigns

**Outreach → Campaigns → +**: pick content, target platforms
(**Platforms**) and let **Automation** schedule posts through the
**Send Queue**. **Messages** holds inbound replies; **Engagements**
(under Marketing) tracks likes/comments/shares per post.

### 4. Work the pipeline

Promote a lead to an **Opportunity** and track it on the **Pipeline**
kanban board through to close, then convert it into a **Sales Order**
under **Orders**.

## AI agents

**Agent Control** is where automation lives: **AI Agents** to chat with
or configure, **MCP Servers** for the tools an agent can use, **Agent
Jobs** for scheduled/recurring runs, **Approvals** for any action an
agent needs a human to confirm, and **Agent Actions** for a full audit
trail of what agents have done. **Knowledge** and **Wiki** hold the
reference material agents (and your team) draw on. The chat icon on the
dashboard opens the assistant directly.

## Backend

Requires a running Moqui backend (moqui.org). See the main
[GrowERP README](../../../README.md) for setup instructions.
