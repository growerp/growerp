# Vertical Development Guide

The fastest way to extend an existing GrowERP vertical or build a new one.

A **vertical** is an end-user app (admin, hotel, freelance, elearner, …) composed
from `growerp_*` building blocks. This guide is the source of truth for creating
and extending them. For creating a *building block* (a new domain library) instead,
see [Building_Blocks_Development_Guide.md](Building_Blocks_Development_Guide.md) and
`growerp createPackage`.

## Architecture in one page

A vertical is a thin shell over building blocks:

- **`lib/main.dart`** — wires the blocks: an app id, a dashboard, and three lists
  (widget registrations, bloc providers, localization delegates).
- **`assets/cfg/app_settings.json`** — one meaningful field, `applicationId`.
- **`pubspec.yaml`** — the subset of `growerp_*` packages the app depends on.
- **Backend seed** — a `growerp.Application` row plus a `MenuConfiguration` and its
  `MenuItem` rows.

**Menus are backend data, not code.** At startup the app calls
`MenuConfigBloc(restClient, '<appId>')`, which fetches the app's `MenuConfiguration`
by `appId` (service `get#MenuConfiguration` in
[MenuServices100.xml](../backend/service/growerp/100/MenuServices100.xml)). Each
`MenuItem.widgetName` is resolved at navigation time through `WidgetRegistry`. So the
contract is: **a menu item names a widget string → the app must register that string.**

## The two coupling contracts (read before you start)

1. **The applicationId triple** — three values that must agree:
   | Where | Value | Example |
   |---|---|---|
   | `app_settings.json` `applicationId` | `App<Pascal>` | `AppBakery` |
   | `growerp.Application` seed row | `App<Pascal>` | `AppBakery` |
   | `MenuConfigBloc('<appId>')` + `MenuConfiguration.appId` | lowercase | `bakery` |

2. **The widgetName ↔ registry contract** — every `MenuItem.widgetName` in the seed
   must match a string the app registers (via a block's `get<Block>Widgets()` or the
   app-specific map in `main.dart`). A wrong name **fails silently until the menu item
   is tapped**. Only use widget names that exist — the block registry in
   [app_blocks.dart](../flutter/packages/growerp/lib/src/growerp/app_blocks.dart)
   lists a verified default per block.

## Recipe A — extend an existing vertical (fastest path)

Add a building block to an app already running. Example: add **inventory** to freelance.

1. **Dependency** — add to `flutter/packages/freelance/pubspec.yaml`:
   ```yaml
   growerp_inventory: ^1.9.0
   ```
2. **Wire in `lib/main.dart`** — one import plus one entry in each of the three lists:
   ```dart
   import 'package:growerp_inventory/growerp_inventory.dart';
   // extraDelegates:        InventoryLocalizations.delegate,
   // extraBlocProviders:    ...getInventoryBlocProviders(widget.restClient, widget.applicationId),
   // widgetRegistrations:   getInventoryWidgets(),
   ```
   (Provider signature differs per block — `(restClient, applicationId)` for
   user_company/catalog/inventory/order_accounting/activity, `(restClient)` for the
   rest. See the registry.)
3. **Menu rows** — add `MenuItem` row(s) to the app's `MenuConfiguration` in
   [GrowerpMenuSeedData.xml](../backend/data/GrowerpMenuSeedData.xml), using a
   `widgetName` the block registers (e.g. `LocationList`):
   ```xml
   <growerp.menu.MenuItem menuItemId="FREELANCE_INVENTORY" menuConfigurationId="FREELANCE_DEFAULT"
       title="Inventory" route="/inventory" iconName="warehouse" widgetName="LocationList" sequenceNum="55"/>
   ```
4. **Reload** — `melos bootstrap`, reload the menu seed, restart the backend.

## Recipe B — new vertical with `growerp createApp`

```bash
cd flutter/packages/growerp
dart run bin/growerp.dart createApp bakery -b catalog,order_accounting,inventory -d /data/growerp
```

The command copies platform/build boilerplate from the freelance donor (renaming the
package, app class, bundle ids and the Android kotlin package), generates
`main.dart` / `pubspec.yaml` / `app_settings.json` / dashboard from the chosen blocks,
emits a per-app seed file (`GrowerpBakeryAppSeedData.xml`), and registers the package
in `flutter/pubspec.yaml`. `user_company` is always included; omit `-b` for the SMB
default (`catalog,order_accounting,activity,adk`). Then follow the printed steps:

```bash
cd flutter && melos bootstrap
cd moqui && java -jar moqui.war load location=component://growerp/data/GrowerpBakeryAppSeedData.xml
# restart backend, then:
cd flutter/packages/bakery && flutter run
```

## Recipe C — AI-assisted (`--describe`)

Let an LLM pick the name and blocks from a plain-language description, then run the
same deterministic scaffold. Requires `GOOGLE_API_KEY` (override the model with
`GEMINI_MODEL`, default `gemini-2.0-flash`):

```bash
dart run bin/growerp.dart createApp --describe "small bakery with a webshop" -d /data/growerp
```

The AI only chooses a name, title and block keys — it never emits widget names or
routes, so the widgetName↔registry contract stays intact. It prints the proposed spec
for confirmation (y/N) before generating anything. See
[AI_Assisted_Vertical_Creation_Guide.md](AI_Assisted_Vertical_Creation_Guide.md).

## Block catalog (SMB positioning)

Baseline for every vertical: **user_company** + **catalog** + **order_accounting**.
Add blocks by business type:

| Block | Adds | Use for |
|---|---|---|
| `user_company` | Companies, users, customers, leads | Always (baseline) |
| `catalog` | Products, categories, subscriptions | Anyone selling goods/services |
| `order_accounting` | Orders, invoices, payments, ledger | The invoicing/accounting backbone |
| `inventory` | Warehouse locations, assets | Stock-holding retail/wholesale |
| `activity` | Tasks, to-dos | Services businesses, task-driven work |
| `sales` | CRM opportunities, pipeline | Sales-driven teams |
| `marketing` | Content, personas, landing pages | Content-led marketing |
| `outreach` | Campaigns, automation, messaging | Agencies, outbound |
| `website` | Storefront, web forms | Selling / capturing leads online |
| `courses` | Courses, media, participants | Education, training, e-learning |
| `adk` | AI assistant chat (dashboard FAB) | Recommended on every vertical |

The authoritative per-block wiring (import, provider signature, delegate, default
menu row) lives in
[app_blocks.dart](../flutter/packages/growerp/lib/src/growerp/app_blocks.dart).
