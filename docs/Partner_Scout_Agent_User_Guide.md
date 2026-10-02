# Partner Scout Agent User Guide

The **Partner Scout** is an AI agent that looks for ERP implementation freelancers in a
country you choose and prepares a first contact with each of them. It searches the web,
scores what it finds, stores every good candidate as a lead, and writes a personal outreach
message in an outreach campaign. It never sends anything: you review the message and decide.

It was built for AntWebsystems to find local partners who implement GrowERP for small
companies with the *revenue-first* method ("flip the ERP script, solve sales first", see
[growerp.org/content/revenue-first](https://www.growerp.org/content/revenue-first)). Any
company can use it for its own partner recruitment: a general version is in the agent catalog
(see §3).

See also: [Agent Control Center User Guide](Agent_Control_Center_User_Guide.md) for the
general agent screens.

---

## 1. What one run does

1. Searches the web for independent ERP consultants and small implementation firms (Odoo,
   ERPNext, Dolibarr, SAP Business One, Business Central, Zoho, iDempiere and similar) in the
   country of the run. It also considers bookkeepers and digital agencies that set up
   business systems.
2. Scores each candidate 1–10 on SME focus, proven implementations, independence, CRM and
   e-commerce experience, local presence and a public business contact. It keeps 6 or more.
3. Skips anyone already in your CRM.
4. Puts the outreach messages in the campaign **Partner Recruitment *country***. It creates
   the campaign on the first run for a country, and never starts it.
5. For each new candidate it creates:
   * a **Lead** (person plus company, with website or profile link and country);
   * a **research note** in the lead's **Communications**: a *Comment* with the score, why
     they fit and the evidence links;
   * an **outreach message** of at most 150 words, status *Pending*: an *Email* when the
     candidate lists a public address, otherwise *LinkedIn* (for the send queue).

It creates no opportunity: one is created automatically when the candidate answers. By default
it finds at most 5 new candidates per run. A run takes about 2–3 minutes.

## 2. Before you start

| Requirement | Where |
|---|---|
| A GrowERP version with agent web search (the release after 1.19.8) | — |
| Your own Gemini API key | **System Setup → AI Settings** |
| Optional: a Google Calendar booking page | **Booking page URL** in the Google Workspace settings |

The free monthly AI allowance is too small for research agents: a run uses up to 40 AI calls.
Without your own key the run stops with *Free monthly LLM allowance used*.

## 3. Installing the agent

**GrowERP company:** nothing to install. **GrowERP Partner Scout** comes with the seed data
(`backend/data/GrowerpPartnerScoutAgentData.xml`), so after a database refresh it is under
**Agent Control → AI Agents**, team **GrowERP Marketing Team**, at the first login.

**Any other company:** add the general version from the agent catalog.

1. Open **Agent Control → AI Agents** and tap the **Agent catalog** icon.
2. Under **Marketing**, check **Partner Scout** and tap **Add selected**. Companies that get
   the marketing team with their demo data already have it, inactive.
3. Open the new agent. Its instruction and scheduled-run prompt contain fill-ins in double
   square brackets, for example `[[YOUR COMPANY: name, country and a one-line description]]`
   and `[[COUNTRY]]`. Replace each one, brackets included, with your own text.
4. Save. The agent dialog shows which fill-ins are left.

While any `[[...]]` fill-in is left, the agent is saved but **inactive**: it does not answer in
chat and its schedule does not run. It becomes active at the first save without them. Keep the
single-bracket parts such as `[country]` and `[name]`: the agent fills those in itself during a
run.

## 4. Running it

The agent is not scheduled by default. To run it **once**, tap **Run** in the agent dialog,
type the country and number as the prompt (for example *Find up to 5 new partners in Vietnam.*),
turn **Simulate writes** off and tap **Run**. The summary table appears in the dialog; the
leads, notes and messages are stored. You can also ask it in **AI Chat**. See
[Running an Agent](Agent_Control_Center_User_Guide.md#running-an-agent).

To run it on a schedule:

1. Tap the **Edit** icon next to the agent.
2. Tick **Enable scheduled runs**, tap **Change** next to the schedule and pick, for example,
   *Daily*, only **Mon**, at 08:00 in your time. The popup shows the next runs.
3. Change **Prompt for each scheduled run** to the country and number you want, for example
   *Find up to 5 new ERP implementation freelancer partners in Malaysia.*
4. Optional: enter a **Chat Room ID for delivery** to get the agent's summary table in chat.
5. Save. The run appears under **Agent Control → Jobs** with its last status.

One country per run works best. To cover several countries, change the scheduled-run prompt each
week, or run it once per extra country as described above.

Before scheduling, tap **Run** in the agent dialog and run it once with **Simulate writes**
on. You see which candidates it finds and the leads, notes and messages it would create,
without anything being stored. See
[Running an Agent](Agent_Control_Center_User_Guide.md#running-an-agent).

## 5. Working with the results

1. **Check the person.** Open the lead in **CRM → Leads** and tap **Communications**. The
   *Partner Scout research* note has the score and evidence links: check that the person
   really is independent and active. Delete the lead and its message if not.
2. **Edit the message.** Open **Outreach → Messages**, filter on the campaign *Partner
   Recruitment country*, and rewrite each *Pending* message in your own words. Only pending
   messages can be edited.
3. **Send.**
   * *Email:* start the campaign in **Outreach → Campaigns**. The automation sends pending
     emails from your company's mail server, within the campaign's daily limit (10).
   * *LinkedIn:* open the **LinkedIn send queue**, copy the text, send it from your own
     account and mark it sent.
4. **Follow the conversation.** Every sent message appears in the lead's **Communications**:
   emails automatically, LinkedIn messages when you mark them sent. Each draft ends with
   *Pick a time for a 20-minute call:* and your booking link (the line is left out when no
   booking page is set). A Meet call the candidate books there shows up as a *Video call*,
   with the Gemini meeting notes added after the call.
5. **When they answer**, set the message to *Responded*. GrowERP then creates an opportunity
   for that same lead in **CRM → Opportunities**.

A lead the agent found once is never proposed again, so delete a lead only when you want it
to be found again.

## 6. The settings, and why they are set this way

| Setting | Value | Why |
|---|---|---|
| Search the web | on | The agent needs Google Search to find people. Gemini only. |
| Max AI calls per run | 40 | Every search, check and save is a call. The default of 10 is not enough for one candidate. |
| Tool mode | scoped | It may only call the seven services in the allow list. |
| Allowed services | get#Companies, get#User, list#OutreachCampaigns, create#OutreachCampaign, create#User, create#CommunicationEvent, create#OutreachMessage | Check for duplicates, find or create the campaign, create the lead, its research note and its pending message. It cannot send, start a campaign or change a status. |
| Write policy | allow | These writes need no approval, because nothing leaves your system until you start the campaign or send by hand. |

The agent works as your company's **AI Agent** user: everything it creates belongs to your
company and shows up in your CRM like any other record.

## 7. Safety

* **It never sends anything.** The instruction forbids e-mail and messaging, and it has no
  other way to reach people.
* **Public business data only.** It never makes up names, e-mail addresses, phone numbers or
  links; when something is unknown the field stays empty. Still check the evidence links
  before you write to anyone.
* **Privacy.** You are contacting people about a business proposal based on their public
  business profile. Send one personal message, honour a "no", and do not add them to a
  mailing list without consent.

## 8. Changing what it looks for

Open the agent and edit the **Instruction**. The sections are in capitals (METHOD, GROWERP
ADVANTAGES, TARGETS, SCORE, PER CANDIDATE, RULES), so you can change, for example, the
target ERP products or the scoring without touching the rest.

Three rules for the instruction text:

* No curly braces `{ }`: the agent reads `{word}` as a variable and the run fails with
  *Context variable not found*. Use `[word]`.
* No `<` or `>`: saving and uploading reject them.
* At most about 4,000 characters.

## 9. Troubleshooting

| Symptom | Cause and fix |
|---|---|
| *Free monthly LLM allowance used* | Add your own Gemini key in **System Setup → AI Settings**. |
| *Max number of llm calls limit of 10 exceeded* | **Max AI calls per run** is empty. Set it to 40. |
| *Context variable not found: …* | Curly braces in the instruction. Replace `{x}` with `[x]`. |
| *HTML not allowed including less-than* | `<` or `>` in the instruction or uploaded file. Remove them. |
| Run finished but no new messages | Every candidate it found was already in your CRM, or scored below 6. Change the country or widen the TARGETS section. |
| Email messages go to *Failed* | No outgoing mail server for your company. Enter the SMTP settings in the company settings, then retry the failed messages. |
| Pending emails are not sent | The campaign is not started. Start it in **Outreach → Campaigns**. |
| Records exist but are not in your lists | Your server runs a version before agents worked as the company's AI Agent user. Update GrowERP. |
