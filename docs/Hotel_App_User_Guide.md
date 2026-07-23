---
title: "GrowERP Hotel — User Guide"
author: "GrowERP"
date: "2026"
---

# GrowERP Hotel — User Guide

## 1. Introduction

GrowERP Hotel is a property-management app for small and mid-size hotels, guesthouses
and B&Bs. It runs on Android, iOS, web, Linux and Windows from a single Flutter
codebase, talking to a Moqui ERP backend over REST.

With it you can:

- Maintain a catalog of room types and individual rooms
- See room availability on a visual timeline (Gantt chart) and book directly from it
- Set seasonal (date-banded) room rates and a per-night tourist/lodging tax
- Take reservations through their full lifecycle: created → approved (checked in) →
  completed (checked out)
- Run daily check-in and check-out lists
- Track housekeeping status per room
- Monitor occupancy, ADR (average daily rate) and RevPAR (revenue per available room)
- Manage invoicing, payments and the general ledger
- Manage company data, employees, customers, suppliers and the public booking website

This guide walks through the app screen by screen, in the order you would typically
use them when setting up and running a hotel.

## 2. Getting Started

### 2.1 Logging in

On first launch, the app shows a splash screen while it loads its menu configuration
from the backend. You then land on the login screen, where you can:

- **Log in** with an existing username and password
- **Register a new company** — creates a new hotel company and its first
  administrator user
- **Request a password reset**

The backend URL is normally pre-configured for your deployment. If you need to point
the app at a different backend (for example a test server), press and hold the title
on the home screen to open the backend-URL override dialog.

### 2.2 The main menu

The menu is server-driven and can be customized per deployment, but a typical Hotel
app menu looks like this:

| Menu | Contains |
|---|---|
| **Main** | Dashboard — the room availability Gantt chart |
| **My Hotel** | Company profile, Employees, Website |
| **Rooms** | Rooms, Room Types, Rates |
| **Reservations** | Reservations, Customers, Purchase Orders, Suppliers |
| **In/Out** | Check In, Check Out |
| **Housekeeping** | Room cleaning board |
| **Statistics** | Occupancy, ADR, RevPAR |
| **Acct Sales** | Sales Invoices |
| **Accounting** | Accounting dashboard (invoices, payments, ledger) |

On a phone the same items appear in a bottom navigation bar / drawer; on tablet and
desktop they appear as a persistent side menu.

## 3. Setting Up Your Hotel

Do these steps once, when you first set up the app for your property.

### 3.1 Company profile

**My Hotel → Company** shows your company's legal name, address, currency and other
profile details. Fill these in first — they appear on invoices and the public website.

### 3.2 Employees

**My Hotel → Employees** lists staff with access to the app. Add an employee, set
their name and email, and the system sends them an invitation to set a password.
Roles (e.g. front desk, housekeeping, admin) determine what they can see and do.

### 3.3 Room types (products)

**Rooms → Room Types** is your room catalog — the *kinds* of rooms you sell (e.g.
"Single Room", "Double Room", "Suite"), each with a base price, description and
photos. This is the same product catalog used elsewhere in GrowERP, filtered to
rental-type products.

Create one room type per category you rent out. The base price set here is what
applies on any night that isn't covered by a seasonal rate (see §4.2).

### 3.4 Rooms (assets)

**Rooms → Rooms** is your physical room inventory — the actual, bookable rooms (e.g.
"101", "102", "Suite A"), each linked to a room type. This is what shows as a row on
the Gantt chart and in the housekeeping board. Add one entry per physical room.

## 4. Room Rates and Tourist Tax

**Rooms → Rates** manages pricing.

### 4.1 Seasonal (date-banded) rates

By default a room type is sold at its base price (set on the Room Types screen) every
night. To charge a different price for a date range — high season, a weekend, an
event — add a seasonal rate band:

1. Go to **Rooms → Rates**.
2. Press **+ (add new)**.
3. Choose the **room type** the band applies to.
4. Set the **from** and **thru** dates (thru date is exclusive — the band covers every
   night up to, not including, the thru date).
5. Enter the **nightly rate**.
6. Save.

Bands are listed in date order, per room type, and are shown on the Rates screen with
their room type, start date and price. You can add as many bands as you need — for
example a "shoulder season" band followed immediately by a "high season" band — and
delete a band with its delete action.

When a guest books a stay that spans several nights, each night is priced by whichever
band covers it; nights that fall outside every band use the room type's base price.

**Example:** with bands 275/night from day 30–33 and 150/night from day 33–35, and the
base price at 50, a 7-night stay starting on day 29 is priced night-by-night as:
`50, 275, 275, 275, 150, 150, 50`.

### 4.2 Tourist / lodging tax

The **Tourist tax per night** field on the Rates screen is a single, per-company
setting — one flat amount charged per room, per night, on top of the room rate (a
common requirement in many jurisdictions). Enter the amount and press **Save**; it
applies to every future quote and reservation until changed. Set it to `0` to disable
it.

The tax always scales with the number of nights and the number of rooms booked, and
appears as its own line item ("Tourist tax") on the reservation and its invoice,
separate from the room charge.

## 5. Booking a Reservation

### 5.1 From the dashboard (Gantt chart)

The **Main** dashboard shows every room as a row and time (day/week/month) across the
top, with a bar for each existing reservation. It's the fastest way to see
availability and book:

1. Use the search box to filter rooms/reservations by guest name, company or
   reservation number.
2. Press **+ (add new)** to open the reservation dialog directly from the chart.
3. Pick the **customer** (or create a new one from the dialog).
4. Pick the **room type**.
5. Pick the **start date** and the number of **nights**.
6. The dialog shows the computed nightly rate, room total, tourist tax and grand
   total, applying any seasonal bands automatically.
7. Save to create the reservation.

### 5.2 From the Reservations list

**Reservations → Reservations** lists all bookings as sales orders. Reservations
follow the standard GrowERP order lifecycle:

| Status | Meaning |
|---|---|
| **Created** | Booked, not yet checked in |
| **Approved** | Guest has checked in |
| **Completed** | Guest has checked out |

Opening a reservation shows its guest, room, dates, room charge and tax lines, and its
current status; you can change the status here as well as from the check-in/check-out
lists.

### 5.3 Customers

**Reservations → Customers** lists guest companies/individuals. Add a customer here or
inline from the reservation dialog.

### 5.4 Purchase orders & suppliers

**Reservations → Purchase Orders / Suppliers** manage what you buy from vendors
(linens, supplies, maintenance) — separate from guest reservations, using the same
order tooling.

## 6. Check-In and Check-Out

**In/Out** gives front-desk staff a focused daily list instead of the full
reservations screen.

- **Check In** lists reservations with status **Created** — guests due to arrive.
  Open one and change its status to **Approved** to check the guest in.
- **Check Out** lists reservations with status **Approved** — guests currently in
  house. Open one and change its status to **Completed** to check the guest out.

Both lists refresh from the backend, so a reservation moves off the Check In list and
onto the Check Out list as soon as it's approved, and disappears once completed.

## 7. Housekeeping

**Housekeeping** shows a table of every room with:

- **Room** and **Type**
- **Occupied** — yes/no, based on today's reservations
- **Status** — Clean (green) or Dirty (red)

Actions:

- Tap a room's status to **toggle** it between Clean and Dirty as housekeeping
  services it.
- The header shows a running count: `Rooms: N   To clean: N`.
- **All rooms clean** (checkmark button) resets every room to Clean in one action —
  use it at the end of a cleaning round. It's disabled when nothing needs it.
- **Refresh** reloads the board from the backend.

Status changes are saved immediately and persist across reloads and staff sessions.

## 8. Statistics

**Statistics** reports the numbers a date-range rental business runs on, for a chosen
period:

- **Occupancy** — percentage of available room-nights that were sold
- **ADR** (average daily rate) — average price per occupied room-night
- **RevPAR** (revenue per available room) — room revenue divided by *all* available
  room-nights, occupied or not
- **Room revenue** — total room charges in the period
- **Room days sold / available** — occupied vs. total room-nights
- **Rooms** — total room count

Pick a **From** and **Thru** date at the top (defaults to the trailing 30 days) and
press **Refresh** to recompute. With no reservations in the period, occupancy, ADR and
RevPAR all show 0%.

## 9. Accounting

**Accounting** opens the accounting dashboard: sales invoices, purchase invoices,
payments and the general ledger, shared with the rest of GrowERP.

- **Acct Sales → Sales Invoices** lists invoices generated from reservations. Approve
  or send an invoice once a reservation's charges are final.
- Payments recorded against an invoice update the reservation's and the ledger's
  balance automatically.
- Use the full **Accounting** dashboard for a company-wide view of receivables,
  payables and financial reports.

## 10. Website

**My Hotel → Website** configures the public booking page linked to your company —
branding, room listings and content shown to prospective guests browsing online.

## 11. Typical Daily Workflow

A front-desk day typically looks like:

1. **Morning:** check **Check Out** for departures; complete each as guests leave.
2. Check **Housekeeping**; rooms vacated overnight or that morning need cleaning —
   confirm status flips to Clean as they're serviced.
3. **Afternoon:** check **Check In** for arrivals; approve each as guests arrive.
4. Take new bookings from the **dashboard** as calls/walk-ins come in.
5. **End of day / week:** review **Statistics** for occupancy and revenue, and
   **Acct Sales** for invoices needing approval or follow-up.

## 12. Troubleshooting

- **A screen shows a loading spinner indefinitely / an error banner.** Check network
  connectivity to the backend; use the room/refresh button on the screen, or restart
  the app.
- **A new seasonal rate doesn't seem to apply.** Confirm the room type matches
  exactly and the stay's dates fall within the band's from/thru range (the thru date
  itself is not included).
- **Tourist tax missing from a quote.** Confirm it was saved on the Rates screen (the
  Save button, not just typed in) — it is a single value per company.
- **A reservation won't move to Check Out.** It must first be **Approved** (checked
  in) — bookings still in **Created** status appear only in Check In.

---

*GrowERP is public-domain software (CC0 1.0 Universal). For backend setup, developer
documentation and the REST API reference, see the `docs/` folder in the GrowERP
repository.*
