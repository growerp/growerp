# AI-Assisted Vertical Creation Guide

How to create a new GrowERP vertical (or extend one) with an AI assistant. Written
for **both** a human following along and an AI agent (e.g. Claude Code) doing it on
the user's behalf. Companion to [Vertical_Development_Guide.md](Vertical_Development_Guide.md).

There are two AI paths:

- **One-shot CLI** — `growerp createApp --describe "…"` lets Gemini pick the name and
  blocks, then runs the deterministic scaffold. Best when the user can hand over a
  single description and has `GOOGLE_API_KEY` set.
- **Assistant-guided** — an AI agent interviews the user, decides extend-vs-new, then
  runs `growerp createApp <name> -b <blocks>` (deterministic, no API key needed) and
  verifies the result. Best for an interactive session. The rest of this guide is the
  script for that path.

## Step 1 — Interview

Ask only what changes the block set. Map answers to blocks:

| Question | If yes, add |
|---|---|
| What does the business do? (always) | `user_company` (baseline) |
| Do they sell products or services? | `catalog` |
| Do they invoice / track payments? | `order_accounting` |
| Do they hold physical stock? | `inventory` |
| Do they work from tasks / to-dos? | `activity` |
| Do they manage a sales pipeline? | `sales` |
| Do they run content marketing? | `marketing` |
| Do they run outbound campaigns? | `outreach` |
| Do they sell or capture leads online? | `website` |
| Do they teach courses / training? | `courses` |
| Want an AI assistant in the app? (default yes) | `adk` |

Baseline for any answer: `user_company` + `catalog` + `order_accounting`. See the full
positioning table in [Vertical_Development_Guide.md](Vertical_Development_Guide.md).

## Step 2 — Decide: extend vs new

- **Extend an existing vertical** when an app already covers the identity (menu +
  dashboard) and the user just wants more capability. Cheaper — no new package. Follow
  **Recipe A** in the Vertical Development Guide.
- **Create a new vertical** only when the app needs its own identity: a distinct menu,
  dashboard, app id, and store branding. Follow **Recipe B** below.

Default to extending if an existing `appId` fits.

## Step 3 — Run the scaffold (new vertical)

```bash
cd flutter/packages/growerp
dart run bin/growerp.dart createApp <name> -b <block1,block2,...> -d <growerpRoot>
```

- `<name>`: lowercase, letters/digits/underscore, starts with a letter.
- `-b`: comma-separated block keys from the catalog. Omit for the SMB default
  (`catalog,order_accounting,activity,adk`). `user_company` is always added.
- `-d`: the GrowERP root (e.g. `/data/growerp`). Defaults to `~/growerp`.

Expected output ends with `✅ Vertical "<name>" created successfully!` and a
numbered next-steps list. The command creates:

- `flutter/packages/<name>/` — full app package (platform folders renamed).
- `moqui/runtime/component/growerp/data/Growerp<Name>AppSeedData.xml` — the seed.
- two lines in `flutter/pubspec.yaml` (`workspace:` and `melos: packages:`).

## Step 4 — Bootstrap, seed, run

```bash
cd flutter && melos bootstrap              # expect: "Got dependencies!"
cd flutter && dart analyze packages/<name> # expect: "No issues found!"
cd moqui && java -jar moqui.war load location=component://growerp/data/Growerp<Name>AppSeedData.xml
# restart backend, then:
cd flutter/packages/<name> && flutter run  # expect: dashboard renders after login
```

Note: the seed `load` needs exclusive access — stop the running backend first, or the
loader fails with `transaction log file btm1.tlog is locked`.

## Step 5 — Contract checklist (an AI must verify these)

- [ ] **applicationId triple agrees**: `App<Pascal>` in `app_settings.json` and the
  `growerp.Application` seed row; lowercase `<name>` in `MenuConfigBloc` and
  `MenuConfiguration.appId`.
- [ ] **Every `MenuItem.widgetName` is registered** — cross-check the seed's widget
  names against the app's widget registrations. Unregistered → silent failure on tap.
- [ ] **Workspace registration** — `<name>` appears in **both** the `workspace:` list
  and the `melos: packages:` list in `flutter/pubspec.yaml`.
- [ ] **Seed loaded** — after loading, confirm via the read-only REST API:
  `GET rest/e1/growerp.menu.MenuConfiguration/<UPPER>_DEFAULT` returns the config.
- [ ] **Compiles** — `dart analyze packages/<name>` is clean.

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| Splash screen never resolves to the app | Menu config missing, or `appId` mismatch between `MenuConfigBloc` and `MenuConfiguration.appId` |
| A menu item taps to a blank/error screen | `MenuItem.widgetName` not registered in the app (widget contract) |
| Compile error: `…Localizations` undefined | A block delegate referenced but its package not depended on / imported |
| `transaction log file btm1.tlog is locked` on seed load | Backend still running — stop it before `java -jar moqui.war load` |
| New package not resolved by `melos bootstrap` | Missing from `flutter/pubspec.yaml` `workspace:` list |

## Under the hood

The block registry (verified widget names, provider signatures, delegates, default
menu rows) is
[app_blocks.dart](../flutter/packages/growerp/lib/src/growerp/app_blocks.dart). The
generator is
[create_app.dart](../flutter/packages/growerp/lib/src/growerp/create_app.dart); the AI
`--describe` path is
[generate_spec.dart](../flutter/packages/growerp/lib/src/growerp/generate_spec.dart) +
[vertical_spec.dart](../flutter/packages/growerp/lib/src/growerp/vertical_spec.dart).
