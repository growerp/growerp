# GrowERP User Manual — Marketing, Outreach & CRM

This manual explains how to use the three lead-generation and sales modules of the
GrowERP admin app, from first setup to closing a deal:

- **Marketing** — create targeted content, capture and warm up leads
  (personas, content plans, social content, email sequences, engagements,
  landing pages, assessments).
- **Outreach** — contact prospects directly across platforms
  (campaigns, platform accounts, message log, send queue).
- **CRM** — work the resulting leads to a sale
  (to-do list, leads, customers, opportunities, pipeline board).

All three are top-level items in the admin app menu. On desktop they appear in the
left navigation rail; on a phone they are in the drawer menu. Most screens follow the
same pattern: a **search bar** at the top, a **table of records**, a **+ button** to add,
and **tap a row** to open the detail dialog.

> **Audience:** business users of the admin app. No technical knowledge required.
> Where a feature depends on one-time technical setup (e-mail server, platform API
> keys), this is called out in a "Setup required" note.

---

## 1. The big picture — how the modules work together

```
MARKETING                    OUTREACH                  CRM
─────────                    ────────                  ───
Persona ─→ Content Plan ─→ Social Content
                │                                     
    published posts get reactions                     
                ↓                                     
          Engagements ──convert──────────────────────→ Lead + follow-up To Do
                                                          │
Landing Page + Assessment ───qualified visitor───────→ Lead (scored warm/hot)
Website Forms ───────────────submission──────────────→ Lead
                │                                         │
        Email Sequences (automatic nurturing e-mails)     │
                                                          ↓
                             Campaigns ──messages──→   Opportunity ─→ Pipeline ─→ Won
```

A **lead** in GrowERP is a person record (visible under CRM → Leads) with contact
details but no login account. Every capture channel — website form, assessment,
chat, engagement conversion, LinkedIn import — creates the same kind of lead, so
everything ends up in one CRM list regardless of where it came from.

---

## 2. CRM

Open **CRM** in the main menu. It has five tabs.

### 2.1 My To Do, tasks

Your personal work list. Each row is a task with a name, status, assignee and an
optional "third party" (the lead or customer the task is about).

- **Add a task:** press **+**, fill in name, select assignee and optionally a
  third party, set a start/end date, save.
- **Change status:** open the task and move it along
  *In Planning → In Progress → Complete* (or *On Hold / Cancelled*).
- **Automatic tasks:** the system creates tasks for you in two situations:
  - When you set or change the **Next step** field of an opportunity, a matching
    to-do task is created automatically.
  - When you **convert a social engagement to a lead** (see §3.5), a
    "Follow up …" task is created in status *In Progress* with the new lead
    attached as third party.
- **Time registration:** inside a task you can record time entries (used for
  billing in other modules).

### 2.2 Opportunities

A potential sale. Each opportunity has an amount, an estimated close probability,
a **stage** (Prospecting, Qualification, Proposal, Negotiation, Closing,
Closed Won, Closed Lost) and a **Next step** text.

- **Add:** press **+**, give it a name, expected amount, probability, pick the
  lead/account it belongs to, choose the stage.
- **Next step:** whenever you fill in or change *Next step*, GrowERP creates a
  to-do task with that text so the step cannot be forgotten. The task is linked
  to the opportunity.
- **Search:** by name or ID in the top bar.

### 2.3 Pipeline

The same opportunities as a **kanban board**, one column per stage, with the money
total per column and a **funnel chart** summarising the whole pipeline.

- **Move a deal:** press-and-hold an opportunity card and drag it to another
  column — the stage updates immediately.
- **Close a deal:** drag it to *Closed Won* or *Closed Lost*.
- **Open the detail:** tap a card.

### 2.4 Leads

All captured leads: name, e-mail, phone, source company. Rows come from the website
form, assessments, chat, engagement conversion, LinkedIn import or manual entry.

- **Add manually:** press **+** and fill in at least first name, last name, e-mail.
- **Promote:** open a lead and change its role when it becomes a paying customer,
  or create an opportunity for it from the CRM → Opportunities tab.

### 2.5 Customers

Same screen as Leads but filtered to the customer role — people/companies that buy
from you. Orders and invoices elsewhere in the app link to these records.

### 2.6 Marketing dashboard tile

On the **main dashboard** the *Marketing* tile shows a live summary: the sales
funnel by stage, leads created in the last 7/30 days, active e-mail sequence
enrollments and campaign counts. Tap it to jump into the CRM/marketing screens.

---

## 3. Marketing

Open **Marketing** in the main menu. Recommended working order for a new company:
Personas → Content Plans → Content → (publish) → Engagements, with Email Sequences,
Landing Pages and Assessments as your capture-and-warm-up machinery.

### 3.1 Personas

A persona (customer avatar) describes your ideal customer: demographics, pain
points, goals, tone of voice. Everything AI-generated downstream (content plans,
posts, landing pages) is written *for* the selected persona.

- **Create with AI:** press **+**, describe your business, and let the generator
  propose the persona; edit and save.
- You can maintain several personas for different market segments.

### 3.2 Content Plans

A weekly content schedule per persona, based on the *Pain–News–Prize* formula
(address a pain, share news, offer value).

- **Generate:** press **+**, pick a persona, and the AI proposes a themed weekly
  plan of post headlines.
- Open a plan to see its posts and their schedule.

### 3.3 Content

The content hub: author a piece of content **once**, then adapt it per platform
(LinkedIn, X/Twitter, Facebook, …) as variants inside the same content record.

- **Draft with AI:** from a headline, the draft service writes the full post text;
  review, humanise, and mark the platform variant *Scheduled* or *Published*.
- Post statuses: *Draft → Scheduled → Published*.

### 3.4 Email Sequences

Automatic nurture e-mails: a series of steps, each with a delay (in days), a
subject and an HTML/text body. Contacts are enrolled once and then receive the
steps automatically.

- **Create:** press **+**, name the sequence, add steps with *delay days*,
  *subject* and *body*. Use `{name}` in subject/body to personalise.
  Wrap links as `{track:https://your-url}` to count clicks.
- **Activate:** set status *Active*. A background job runs every 15 minutes and
  sends any step that is due.
- **Enroll people:** link the sequence to a **website form** (§5.1) — every
  submission is enrolled automatically. Enrollment is deduplicated per e-mail
  address per sequence.
- **Tracking:** the list shows enrollment counts; opens and clicks are counted per
  enrollment. Every e-mail automatically carries an unsubscribe link; unsubscribed
  contacts stop receiving the sequence immediately.

> **Setup required:** an outgoing e-mail server must be configured for the system
> (System Setup). Without it, sequences still advance their state but no mail
> leaves the building.

### 3.5 Engagements

A manual log of social-media interactions on your posts — likes, comments, shares,
DM replies. This is where content turns into pipeline.

- **Record:** press **+**, pick the platform and type (*Like / Comment / Share /
  DM reply*), enter the person's user name and optionally a profile URL and a note
  (e.g. what their comment said). Status starts as *New*.
- **Convert to lead:** open an engagement and choose **Convert to lead**, supplying
  an e-mail address if you have one. GrowERP then:
  1. creates a lead (visible in CRM → Leads),
  2. creates a **"Follow up &lt;name&gt;"** to-do task in *In Progress* with the lead
     attached, and
  3. sets the engagement status to *Contacted*.
- Work the follow-up task from CRM → My To Do, tasks.

### 3.6 Landing Pages

Conversion pages hosted on your generated website, usually the destination of an
outreach message or social post.

- **Generate with AI:** press **+** or use *Generate landing page*, pick the
  persona/offer, and the generator drafts the page sections and call-to-action.
- The call-to-action typically points to an **assessment** (below) or a signup.

### 3.7 Assessments

Interactive questionnaires ("scorecards") that qualify visitors. A visitor answers
the questions, gets a score, and is stored as a lead with a **cold / warm / hot**
rating.

- **Build:** create the assessment, add questions and answer options, and set the
  scoring thresholds that decide cold/warm/hot.
- **Publish:** link it from a landing page; visitors complete it in the browser.
- **Results:** the *Leads* view inside Assessments lists every respondent with
  score and rating; respondents receive their results by e-mail automatically.
  Warm and hot leads are your priority call list — they also appear in
  CRM → Leads.

---

## 4. Outreach

Open **Outreach** in the main menu. This module sends direct messages/e-mails to
prospects at scale, within daily limits.

### 4.1 Platforms

One-time configuration per channel (e-mail, LinkedIn, X/Twitter, …): credentials
or API keys, whether the platform is enabled, and a **daily send limit**.

> **Setup required:** without an enabled platform configuration, campaigns cannot
> send on that channel.

### 4.2 Campaigns

An outreach campaign groups a target audience, a base message template, the
platforms to use, and per-platform overrides (e.g. a shorter LinkedIn variant of
the e-mail text). A campaign can link a **landing page**, so every message carries
your conversion link.

- **Create:** press **+**, name the campaign, write the base message (use
  placeholders such as the recipient name), select platforms, set daily limits,
  optionally attach a landing page.
- **Execute:** open the campaign and use the execution dialog to run it; messages
  are generated per recipient and platform.
- **Metrics:** each campaign tracks messages sent, responses and leads generated.

### 4.3 Automation

Rules that keep campaigns running without manual clicks — scheduled execution and
follow-up behaviour. Review this screen after creating a campaign if you want it
to run hands-off.

### 4.4 Messages

The complete log of individual outreach messages: recipient, platform, content,
sent date and status (*Pending / Sent / Responded / Failed*). Use it to check what
a specific prospect received, and to spot failures.

### 4.5 Send Queue (LinkedIn)

LinkedIn does not allow fully automated sending, so LinkedIn messages go into a
**send queue**: the app prepares the personalised text, you copy it and send it
from your own LinkedIn account, then mark the item done. The queue respects the
daily limit configured on the platform.

- **Lead import:** the LinkedIn lead-import dialog lets you paste/import prospect
  lists which become leads and queue entries.

### 4.6 Unsubscribes

Every outreach e-mail carries an unsubscribe link automatically. A prospect who
unsubscribes is excluded from further sends — no action needed from you.

---

## 5. Capturing leads on your website

Your company website (Organization → Website) is generated by GrowERP and has
built-in capture channels. All of them create leads in CRM → Leads.

### 5.1 Web Forms

Build lead-capture forms without code, under **Organization → Web Forms**.

- **Create:** press **+**, name the form, set the title, submit-button label and
  thank-you message, and add fields (text, e-mail, phone, textarea; mark required
  ones). Optionally select an **e-mail sequence** — every submitter is then
  enrolled automatically (§3.4).
- **Embed:** put this line anywhere in a website page's content:

  ```html
  <div data-growerp-form="FORM_ID"></div>
  ```

  The form renders there with your fields; submissions create a lead and store the
  submitted values (visible per form).

### 5.2 Website chat

The public chat widget on your website lets visitors start a conversation; a
visitor who leaves contact details becomes a lead and their messages arrive in the
app's chat.

### 5.3 SEO

Each website page can carry its own browser title and meta description (edited in
the page content dialog), so your content pages rank properly. The store pages emit
correct titles, descriptions and social-sharing (Open Graph) tags automatically.

---

## 6. AI marketing agents (optional)

Under **Agent Control** you can enable a pre-configured team of five AI marketing
agents (outreach personaliser, SDR, lead triage, content & social, weekly ops
digest): press the **rocket button** in the top bar of the agent list and confirm.
The agents are added to your company with schedules off, except the weekly digest.
Review each agent's configuration before enabling its schedule.

---

## 7. End-to-end walkthrough (15 minutes)

1. **Marketing → Personas**: generate a persona for your target segment.
2. **Marketing → Content Plans**: generate this week's plan for that persona.
3. **Marketing → Content**: draft one post with AI, publish it on LinkedIn
   manually, mark it *Published*.
4. Someone comments on the post → **Marketing → Engagements**: record it
   (*Comment*, their name, note).
5. **Convert to lead** with their e-mail →
   check **CRM → Leads** (new lead) and **CRM → My To Do, tasks**
   ("Follow up …", *In Progress*).
6. Call them; it's promising → **CRM → Opportunities**: create an opportunity,
   amount €5 000, stage *Qualification*, next step "send proposal Tuesday"
   (a to-do task appears automatically).
7. **CRM → Pipeline**: drag the deal through *Proposal → Negotiation →
   Closed Won* as it progresses.
8. Meanwhile, **Organization → Web Forms** + an **Email Sequence** nurture the
   colder visitors of your website into the same funnel.

---

## 8. Troubleshooting

| Symptom | Likely cause / fix |
|---|---|
| Sequence e-mails not arriving | No outgoing e-mail server configured (System Setup), or the sequence is *Paused*. Enrollment state still advances; configure mail and future steps will send. |
| Form doesn't appear on website page | The `data-growerp-form` div is missing or has the wrong form ID; check the ID on the Web Forms screen. |
| Campaign not sending on a platform | Platform disabled or daily limit reached — check Outreach → Platforms. |
| Lead exists but no follow-up task visible | Refresh the CRM → My To Do list; tasks created by conversions/next-steps are set to *In Progress*. |
| Expected leads missing from list | Use the search bar — the list is paged; also check the Customers tab if the person was already promoted. |
