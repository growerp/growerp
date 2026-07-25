# GrowERP Freelance — User Guide

GrowERP Freelance is a GrowERP frontend for freelancers and small service
businesses: manage clients, log time against tasks, invoice that time, and
keep the books — with optional CRM, marketing/outreach and a public website.
Runs on Android, iOS, web, Linux and Windows, backed by a Moqui server.

Live demo: [freelance.growerp.org](https://freelance.growerp.org)

## Getting started

1. Open the app. If no company exists yet you'll see a prompt to register one.
2. **Register new company and admin** creates your company and its first
   admin user. A temporary password is emailed to you.
3. **Login** signs in with an existing account; **Forgot password** resets
   it by email.
4. Pick your language from the login screen's selector.

The admin can add other users (assistants, clients, suppliers) from **CRM**
or **Orders**.

## Menu overview

What you see depends on your role. Non-admins (assistants) only get
**Main**, **Tasks** and **About** — enough to log their own time. Admins
also get:

- **CRM** — Opportunities, Leads, Customers
- **Marketing** — Content Plans, Content, Personas, Landing Pages, Assessments
- **Outreach** — Campaigns, Automation, Platforms, Messages
- **Catalog** — Products, Categories
- **Orders** — Sales/Purchase Orders, Customers, Suppliers
- **Website** — public site settings
- **Acct Sales / Acct Purchase** — invoices and payments both directions
- **Acct Ledger** — chart of accounts, transactions, journals
- **Acct Reports** — revenue/expenses, balance sheet, balance summary
- **Acct Setup** — periods, item types, payment types
- **System Setup** — AI provider/model settings

Your profile and company details are reachable from the drawer.

## Core workflow: tasks, time and invoicing

### 1. Create a task

**Tasks → Tasks → +**: name, description, **Third Party** (the client),
**Assignee** (who does the work), **Hourly rate (client billing)**, and
status. Rate changes only affect hours logged afterward — already-invoiced
hours keep their original rate.

### 2. Log time

Open a task → **TimeEntries → +**: date, hours, optional comments. New
entries start **in process**.

### 3. Approve hours (admin)

Admins click **Approve** on each entry once ready to bill. Only approved,
un-invoiced entries can be invoiced. Entries lock once invoiced.

### 4. Invoice the hours (admin)

From **Tasks**, click **Invoice approved hours** and choose:
- **Sales invoice to client** — one invoice line per task, at that task's
  hourly rate, pulling in all of the client's approved/un-invoiced hours.
- **Purchase invoice for assistant** — pick the assistant and a pay rate;
  used for self-billing/outsourcing.

If nothing qualifies (no approved hours, missing rate), the app says why.

### 5. Track hours

**Tasks → Assistant Hours** shows in-process/approved/invoiced hours per
assistant. Admins see everyone; others see only their own.

## Clients, orders and accounting

- **CRM** for leads/opportunities, **Orders** for sales/purchase orders,
  **Catalog** for products and services.
- **Acct Sales/Purchase**, **Acct Ledger** and **Acct Reports** cover
  invoicing, bookkeeping and financial reporting. Invoices/orders support
  PDF printing.

## Marketing, outreach and website

Content plans, personas, landing pages and assessments (**Marketing**);
campaigns, automation and platform connections (**Outreach**); a
configurable public site (**Website**).

## AI assistant

The chat icon on the dashboard opens an AI assistant that can look up data
and navigate the app. Configure providers/models under **System Setup**.

## Backend

Requires a running Moqui backend (moqui.org). See the main
[GrowERP README](../../../README.md) for setup instructions.
