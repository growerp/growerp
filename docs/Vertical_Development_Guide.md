# Vertical Development Guide

The fastest way to extend an existing GrowERP vertical or build a new one.

A **vertical** is an end-user app (admin, hotel, freelance, …) composed
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

Add a building block to an app already running. Example: add **hr** to freelance.

1. **Dependency** — add to `flutter/packages/freelance/pubspec.yaml`:
   ```yaml
   growerp_hr: ^1.0.0
   ```
2. **Wire in `lib/main.dart`** — one import plus one entry in each of the three lists.
   In freelance these are top-level helpers passed to `TopApp`: `delegates`,
   `getFreelanceBlocProviders(...)` and `freelanceWidgetRegistrations`
   ([freelance/lib/main.dart](../flutter/packages/freelance/lib/main.dart)):
   ```dart
   import 'package:growerp_hr/growerp_hr.dart';
   // delegates:                     HrLocalizations.delegate,
   // getFreelanceBlocProviders:     ...getHrBlocProviders(restClient),
   // freelanceWidgetRegistrations:  getHrWidgets(),
   ```
   (Provider signature differs per block — `(restClient, applicationId)` for
   user_company/catalog/inventory/order_accounting/activity; `(restClient,
   [applicationId])` (optional, defaults to `AppAdmin`) for website/marketing;
   `(restClient)` for sales/outreach/courses/hr/insurance; none for rental/adk.
   See the registry.)
3. **Menu rows** — add `MenuItem` row(s) to the app's `MenuConfiguration` in
   [GrowerpMenuSeedData.xml](../backend/data/GrowerpMenuSeedData.xml), using a
   `widgetName` the block registers (e.g. `MyHrView`):
   ```xml
   <growerp.menu.MenuItem menuItemId="FREELANCE_HR" menuConfigurationId="FREELANCE_DEFAULT"
       title="HR" route="/hr" iconName="badge" widgetName="MyHrView" sequenceNum="55"/>
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

The seed path `moqui/runtime/component/growerp/data/` is the symlink to
[backend/data/](../backend/data/) — commit the seed file there.

### After the scaffold

The scaffold produces a running app; these are still manual before it ships:

- **Welcome email** — add `GrowerpEmailWelcomeIntro<Name>` and
  `GrowerpEmailWelcomeFirstStep<Name>` `LocalizedMessage` rows to
  [GrowerpL10nData.xml](../backend/data/GrowerpL10nData.xml); without them the
  `…Default` text is sent.
- **App icon** — render the app's label onto the shared tree template (see an existing
  app's `assets/icon/icon.png`), then `dart run flutter_launcher_icons` in the package.
- **Release & stores** — add the app to `defaultApps` and `storeApps` in
  [release_config.json](../flutter/release/release_config.json) (CI build matrix,
  version bumps, store jobs), to the `apps` input description in the store workflows,
  and to the swarm `apps.conf` in the server repo. Store listings, bundle ids and
  per-app secrets (e.g. `WINDOWS_<APP>_PRODUCT_ID`) are set up per store.
- **Native config** — iOS/macOS `Info.plist` purpose strings and entitlements are
  copied from freelance; adjust them if the app uses blocks with other native plugins.

## Recipe C — AI-assisted (`--describe`)

Let an LLM pick the name and blocks from a plain-language description, then run the
same deterministic scaffold. Requires `GOOGLE_API_KEY` (override the model with
`GEMINI_MODEL`, default `gemini-3.8-flash`):

```bash
dart run bin/growerp.dart createApp --describe "small bakery with a webshop" -d /data/growerp
```

The AI only chooses a name, title and block keys — it never emits widget names or
routes, so the widgetName↔registry contract stays intact. It prints the proposed spec
for confirmation (y/N) before generating anything. See
[AI_Assisted_Vertical_Creation_Guide.md](AI_Assisted_Vertical_Creation_Guide.md).

## Recipe D — no block fits (new business domain)

When the business needs a domain no block covers, build the block first, then
scaffold the app on it. Example: **facility management**. Map the needs to the
catalog first — most are usually covered already:

| Need | Block |
|---|---|
| Sites, rooms, equipment | `inventory` (locations, assets) |
| Service contracts, invoicing | `catalog` + `order_accounting` |
| Ad-hoc jobs | `activity` |
| Client request portal | `website` |
| Work orders, preventive maintenance plans, SLAs | **missing → new block `facility`** |

Before designing entities, check Mantle for an existing model (here
`mantle.product.maintenance.AssetMaintenance` and `mantle.work.effort.WorkEffort`) and
build on it.

1. **Build the block** — follow
   [Building_Blocks_Development_Guide.md](Building_Blocks_Development_Guide.md). Lay it
   out like the recent `hr` and `insurance` blocks, with the backend in the main
   `growerp` component (not a separate component):
   - entities: `backend/entity/FacilityEntities.xml`
   - services: `backend/service/growerp/100/FacilityServices100.xml`
   - REST resources: [growerp.rest.xml](../backend/service/growerp.rest.xml)
   - models + API mixin: `growerp_models` (`lib/src/models/`, `lib/src/rest_client/facility_api.dart`)
   - Flutter block: `flutter/packages/growerp_facility/` with
     `getFacilityWidgets()`, `getFacilityBlocProviders(...)`, `FacilityLocalizations`
   - tests: bloc unit tests in `test/` and a Spock spec in `backend/src/test/groovy/`
     (see [ADR 0001](adr/0001-flutter-unit-test-standard.md),
     [ADR 0002](adr/0002-backend-spock-test-standard.md))

   `growerp createPackage <name>` can scaffold the Flutter package, but it also creates
   a separate Moqui component `growerp-<name>`. Move that backend code into `backend/`
   as above. A separate component would need its own `setup-backend.sh` symlink and CI
   volume mount.
2. **Register the block** in
   [app_blocks.dart](../flutter/packages/growerp/lib/src/growerp/app_blocks.dart):
   package, version, import, a one-line `description` (the `--describe` AI reads it),
   widget/provider functions, `providerTakesAppId`, delegate and a default `menuItem`
   whose `widgetName` the block really registers. Add it to the block catalog below.
3. **Scaffold the app** with Recipe B, now including the new block:

   ```bash
   dart run bin/growerp.dart createApp facility \
     -b facility,inventory,catalog,order_accounting,activity,website,adk -d /data/growerp
   ```

   Then do the [After the scaffold](#after-the-scaffold) steps.

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
| `hr` | Employees, onboarding, departments, job titles, leave requests | Businesses with staff to manage |
| `insurance` | Policies, coverages, renewals, carrier commission, claims, client portal | Insurance agencies |
| `rental` | Rental timeline (Gantt), seasonal rates, utilisation stats | Equipment/asset hire — add with `inventory` + `order_accounting`; no menu item of its own (Gantt is the dashboard) |
| `adk` | AI assistant chat (dashboard FAB) | Recommended on every vertical |

The authoritative per-block wiring (import, provider signature, delegate, default
menu row) lives in
[app_blocks.dart](../flutter/packages/growerp/lib/src/growerp/app_blocks.dart).
