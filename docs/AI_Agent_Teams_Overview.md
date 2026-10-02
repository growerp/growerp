# Agent Teams Overview

GrowERP is an AI-native ERP: every install includes governed, auditable agent teams built on Google's **Agent Development Kit (ADK)**, managed from the Agent Control Center in the GrowERP Agents app. Today there are two ready-to-run teams in the shared **agent catalog**, all fully open source and customizable — pick individual agents from it, or describe a new one, without waiting on a code change.

## 1. Marketing Agent Team

Six specialist agents that run outbound marketing and top-of-funnel sales work with no human in the loop for routine tasks. There is no coordinator — each agent has a narrow job and is schedule-triggered or invoked directly.

- **Outreach Personalizer** — fills in empty outreach message bodies for the active campaign so every contact gets a tailored message.
- **Sales Development Rep** — handles inbound website-chat visitors: explains your company (it adapts to whichever company loaded it), qualifies the lead, encourages the next step (trial, demo, or signup), and hands off hot leads to a human.
- **Lead Triage** — ranks new replies and opportunities by priority and drafts suggested follow-ups for review.
- **Content and Social** — produces a weekly content piece and adapts it to every enabled social platform.
- **Marketing Ops Digest** — sends a daily summary of sends, replies, pipeline movement and won opportunities.
- **Partner Scout** — finds implementation partners in a country, adds them as leads with a research note and an outreach draft; stays inactive until its `[[...]]` fill-ins (your company, product, pitch) are replaced.

## 2. GrowERP Operations Team

A real, production preset covering the company's own core ERP domains — not a demo. A coordinator
routes to read-only digests for Sales, Purchasing, Inventory, Finance and HR, plus three
approval-gated assistants that draft (never auto-create) a purchase order, a sales quote/order, or
a replenishment order for out-of-stock items. Finance and HR stay read-only always — period-close
and leave-approval are compliance-sensitive actions left to a human.

## Picking agents from the agent catalog

Neither team has to be loaded all-or-nothing: the **agent catalog** (Agent Control Center → AI
Agents → catalog icon) lists every agent individually, grouped by category, with a risk badge, so an
admin picks just the Inventory digest, or just the Sales Development Rep, and nothing else. **Suggest a function** in the same screen lets an admin describe a capability in
their own words and get an AI-checked, feasibility-verified draft — grounded in the company's real
services, never a fabricated one — ready to review before it becomes a real agent.

The catalog is shared by every GrowERP company: GrowERP support maintains it (publish,
categorize, upload contributed teams) and the public [AI Agents](https://www.growerp.com/content/ai-agents)
website page lists every published agent live, with forms to request a new agent or contribute one.

See [AGENT_CONTROL_CENTER_AND_MCP_GUIDE.md §16-20](./AGENT_CONTROL_CENTER_AND_MCP_GUIDE.md#16-growerp-operations-team) for the full reference.

## Built for governance, not just automation

Both teams run under the same Agent Control Center: writes can require approval, every action is logged to an audit trail, and agents/tools/knowledge bases are all managed from one screen.
