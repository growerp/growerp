# AI-Native Implementation — Phase 2: Conversational Depth (prefill + submit)

Status: **core implemented** (branch `feat/adk-phase2-prefill-submit`). This doc is the
implementation plan + what shipped + remaining loose ends.

## Context
Phase 1 (agent trust foundation) and the `growerp_adk` package + `agents` app are shipped.
Phase 2 makes chat *do*, not just *open*. Before this, the chat agent emitted `growerp-action`
directives that **navigate** or open a **dialog by id** only — the `CONTEXT_PREAMBLE` said
"WRITES ARE USER-CONFIRMED: you only NAVIGATE." So "create a customer named X, email Y" opened
an **empty** create dialog and the user re-typed everything.

The roadmap's other Phase-2 item — *auto-derived `screenCatalog`* — was **already done**
(`adk_chat_view.dart` seeds it from `WidgetRegistry.getWidgetCatalog()`, built from each block's
`get*WidgetsWithMetadata()`). So Phase 2 reduced to **prefill + submit**.

Goal: the agent opens a create/edit dialog **pre-filled** with the field values it resolved; the
human **reviews and taps Save**. Writes stay user-confirmed (the person acts → no governance gate
on this path). e.g. `{"action":"dialog","widget":"UserDialog","params":{"firstName":"John","email":"j@x.com","_aiPrefill":true}}`.

## Root cause (why it didn't work)
`_runAction` (`growerp_adk/lib/src/adk_chat_view.dart`) forwards the directive `params` (a flat
map) to `WidgetRegistry.getWidget(widget, params)`. But the registry builders expected a **typed
entity** or an **id to fetch** — e.g. `UserDialog(args?['user'] as User?)` / metadata builder read
only `partyId/id`. A params map of field values had no `user` object → builder yielded an empty
dialog; prefill lost.

## Changes (implemented)

### 1. `entityFromArgs<T>()` helper — `growerp_core/lib/src/services/widget_registry.dart`
Builds a typed entity from a directive's flat `params`: strips reserved nav keys
(`key,route,tab,tabIndex,role,dialog,id,_aiPrefill`), coerces numeric/bool strings, and returns
`null` (caller keeps its default) when there are no usable fields or `fromJson` throws. Plus
`isAiPrefill(args)`.

### 2. Prefill-from-args in the registry builders
When `params` carry field values (and no id), construct the entity via the model's existing
`fromJson` and pass it to the dialog. Pattern applied to (representative files):
- `growerp_user_company/lib/src/get_user_company_widgets.dart` — `UserDialog`, `ShowCompanyDialog`.
- `growerp_catalog/lib/src/get_catalog_widgets.dart` — `ProductDialog`, `CategoryDialog`.
Each keeps the existing id→fetch path; the create branch now prefills. The id-open path can also
carry field values to stage changes.

### 3. Dialogs prefill in *create* mode
`growerp_user_company/lib/src/user/views/user_dialog.dart`: `initState` filled the field
controllers only `if (partyId != null)` (edit). Now name/email/telephone/url populate from the
passed user in create mode too. `ProductDialog`/`CategoryDialog` use `FormBuilder` `initialValue`
from the entity, so they prefill automatically — no change needed.

### 4. Advertise prefillable fields — `WidgetMetadata.parameters`
The create dialogs' metadata now list prefillable field names (e.g. `firstName,lastName,email`
for `UserDialog`; `productName,description,price` for `ProductDialog`) so the catalog tells the
agent exactly which `params` keys to emit. Reuses the existing `WidgetMetadata` shape.

### 5. Teach the agent — `moqui-adk/.../AdkManager.groovy` `CONTEXT_PREAMBLE`
On a CREATE/EDIT request with user-supplied values: resolve referenced records with read-only
tools, then emit a `dialog` directive whose `params` are the field values (names from the
widget's catalog `parameters`) plus `"_aiPrefill":true`. Still never call a write service from
interactive chat — the dialog Save is the write.

## Critical files
- `flutter/packages/growerp_core/lib/src/services/widget_registry.dart` — `entityFromArgs`, `isAiPrefill`.
- `flutter/packages/growerp_user_company/lib/src/get_user_company_widgets.dart` and `.../user/views/user_dialog.dart`.
- `flutter/packages/growerp_catalog/lib/src/get_catalog_widgets.dart`.
- `flutter/packages/growerp_adk/lib/src/adk_chat_view.dart` — `_runAction` / `ChatMenuEntry.fromDirective` (params already plumbed; verified pass-through with value types preserved).
- `moqui/runtime/component/moqui-adk/src/main/groovy/org/moqui/adk/AdkManager.groovy` — `CONTEXT_PREAMBLE`.

Reuse: models' `fromJson` (wrapped/unwrapped JSON per CLAUDE.md); existing `WidgetMetadata`
(`parameters`,`keywords`); `getKeyFromArgs`/`parseRole` next to the new helper.

## Verification
1. Chat (agents/admin): "add an employee John Doe, email john@x.com" → `UserDialog` opens with
   first/last name + email pre-filled → Save → confirm the person exists (UserList search or
   `moqui_rest_call e1/mantle.party.Person`).
2. "create product Widget priced 9.99" → `ProductDialog` pre-filled → Save → verify.
3. Edit prefill: "open product DEMO_1 and set price 5" → opens DEMO_1 with price staged → Save.
4. Regression: plain nav ("show products") and id-open ("edit product DEMO_1") still work;
   `melos analyze` clean; existing adk integration test green.

Note: the agent preamble change needs the backend rebuilt (`gradlew build`) to take effect; an
LLM key must be configured for the chat to emit directives.

## Commits
- root `55b34e90` — prefill create/edit dialogs from chat directive params (Flutter).
- moqui-adk `5091d5a` — teach chat agent to prefill (CONTEXT_PREAMBLE).
Branch `feat/adk-phase2-prefill-submit` (not pushed).

## Remaining loose ends (deferred)
- Optional **"AI-filled — review & Save" banner** when `_aiPrefill` is set (flag is recognized/
  stripped but not yet surfaced as UI). Would need an `aiPrefilled` bool threaded from builder →
  dialog.
- **Numeric/Decimal coercion** edge: a model whose `fromJson` rejects a coerced value loses that
  object's prefill (graceful empty form). Verify `Product.price` prefills on the emulator; adjust
  coercion if a converter needs strings.
- Emulator end-to-end verification (needs rebuilt backend + LLM key).
- Extend prefill to more create dialogs (orders, opportunities, GL accounts) as needed.
