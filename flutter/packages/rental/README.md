# GrowERP Rental — User Guide

GrowERP Rental is a GrowERP frontend for equipment-hire businesses: see
availability on a Gantt-style calendar, book rentals, check equipment out
and back in, invoice and get paid, and track how well your fleet is
utilised. Runs on Android, iOS, web, Linux and Windows, backed by a
Moqui server.

## Getting started

1. Open the app. If no company exists yet you'll see a prompt to register
   one.
2. **Register new company and admin** creates your company and its first
   admin user. A temporary password is emailed to you.
3. **Login** signs in with an existing account; **Forgot password** resets
   it by email.
4. Pick your language from the login screen's selector.

The admin can add other users, customers and suppliers from **My
Company** or **Rentals**.

## Menu overview

- **Main** — Gantt-style calendar showing what's booked and what's free
- **My Company** — company, employees, website
- **Equipment** — Equipment (individual assets), Equipment Types
  (rentable products), Rates
- **Rentals** — rental orders, customers, purchase orders, suppliers
- **Pickup/Return** — check equipment out to a customer and back in
- **Tasks** — to-do items
- **CRM** — sales opportunities
- **Acct Sales** — sales invoices, incoming payments, customers
- **Acct Purchase** — purchase invoices, outgoing payments, suppliers
- **Acct Ledger** — chart of accounts, transactions, journals
- **Utilisation** — equipment usage statistics
- **Acct Setup** — accounting periods
- **Marketing** — content plans
- **About**

Your profile and company details are reachable from the drawer.

## Core workflow: list, book, hand over, return

### 1. List equipment

**Equipment → Equipment Types → +** creates the rentable product
(e.g. "Excavator, mini"). Add individual serialized units under
**Equipment**, and set day/week/month pricing under **Rates**.

### 2. Book a rental

Check the **Main** Gantt calendar for open dates, then create the
booking under **Rentals → +**: customer, equipment, rental period. A
new customer can be added on the spot.

### 3. Hand over and return

On the start date, use **Pickup/Return → Pickup** to check the
equipment out to the customer. On return, use **Return** to check it
back in — this is what frees the equipment up again on the calendar.

### 4. Invoice and get paid

Generate the **Sales Invoice** from the rental order under **Acct
Sales**, then record the **Incoming Payment** once the customer pays.
Outsourced or subcontracted equipment follows the same pattern under
**Acct Purchase**.

### 5. Track utilisation

**Utilisation** shows how much each piece of equipment has been rented
out versus sitting idle, to help with pricing and fleet decisions.

## Accounting

**Acct Ledger** (chart of accounts, transactions, journals) and **Acct
Setup** (accounting periods) round out the bookkeeping side. Invoices
support PDF printing.

## Backend

Requires a running Moqui backend (moqui.org). See the main
[GrowERP README](../../../README.md) for setup instructions.
