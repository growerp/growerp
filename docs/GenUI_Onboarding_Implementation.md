# GenUI Onboarding Implementation

GrowERP uses Google's [genui](https://pub.dev/packages/genui) Flutter package together with a Moqui/Gemini backend to drive a conversational onboarding flow for new tenants. This is a standard A2UI implementation: the backend streams A2UI JSONL and the Flutter `A2uiTransportAdapter` renders it as native widgets.

## Overview

When a new user logs in with no `appsUsed` configured, `login_dialog.dart` opens `OnboardingDialog`. The dialog conducts a short conversation — typically 4-6 turns — and produces a personalised `MenuConfiguration` that becomes the user's main navigation menu.

## Architecture

```
Flutter                          Moqui (Groovy)                Gemini
──────                           ──────────────                ──────
OnboardingDialog
  │ POST /rest/s1/growerp/100/OnboardingChat
  │  { applicationId,    ──► onboardingChat.groovy
  │    systemPrompt,             │ flattens history → prompt
  │    messages (history) }      │ POST generateContent    ──► gemini-3.5-flash
  │                              │                         ◄── A2UI JSONL text
  │  { jsonl }              ◄──  └ returns jsonl field
  │
  ├─ _adapter.addChunk(jsonl)
  ├─ SurfaceController maps catalogId+name → CatalogItem
  └─ Surface widget renders current surface
```

## Key Files

### Backend
| File | Purpose |
|------|---------|
| `backend/service/growerp/100/OnboardingServices100.xml` | Service definitions: `chat#Onboarding`, `save#Onboarding` |
| `backend/service/onboardingChat.groovy` | Calls Gemini 3.5 Flash, returns A2UI JSONL |
| `backend/service/onboardingSave.groovy` | Persists menu config + conversation log |
| `backend/service/growerp.rest.xml` | REST endpoints: `POST /OnboardingChat`, `POST /OnboardingSave` |

**API key**: set env `GEMINI_API_KEY` or Moqui user preference `GEMINI_API_KEY`.

### Flutter (`growerp_core`)
| File | Purpose |
|------|---------|
| `domains/onboarding/views/onboarding_dialog.dart` | Full dialog: wires `A2uiTransportAdapter` + `SurfaceController` + `Conversation` |
| `domains/onboarding/catalog/onboarding_catalog.dart` | Builds `Catalog` with all `CatalogItem`s; catalogId `com.growerp.onboarding` |
| `domains/onboarding/catalog/onboarding_prompts.dart` | Per-app system prompts via `PromptBuilder.chat()` |
| `domains/onboarding/widgets/welcome_card.dart` | Free-text business description input |
| `domains/onboarding/widgets/options_card.dart` | Single/multi-select chip questions |
| `domains/onboarding/widgets/menu_preview_card.dart` | Shows AI-proposed menu, confirm or adjust |
| `domains/onboarding/widgets/finalize_menu_widget.dart` | Terminal widget — triggers menu save |
| `domains/onboarding/bloc/onboarding_bloc.dart` | Minimal cubit — holds `applicationId` only; conversation state owned by genui |

### Models (`growerp_models`)
`OnboardingMenuConfig`, `OnboardingMenuItem` — carry the finalised menu from Gemini back to Flutter.

## genui Package Wiring

```dart
_adapter     = A2uiTransportAdapter();
_controller  = SurfaceController(catalogs: [catalog]);
_conversation = Conversation(controller: _controller, transport: _adapter);

// Feed each Gemini response into the adapter:
_adapter.addChunk(jsonl);

// Render the latest surface:
Surface(surfaceContext: _controller.contextFor(state.surfaces.last))
```

`CatalogItem` registers each widget with a name, a JSON schema (shown to Gemini in the system prompt), and a `widgetBuilder`. Gemini emits `createSurface` messages referencing those names; `SurfaceController` resolves them.

## Conversation Flow

Gemini responds with **one widget per turn**:

1. `WelcomeCard` — greeting + open-ended business description field
2. `OptionsCard` (×2–3) — AI-generated questions derived from the description
3. `MenuPreviewCard` — proposed menu (4–7 items); user confirms or asks for adjustment
4. `FinalizeMenu` — invisible terminal widget; triggers `_handleCompletion`

## Completion

`_handleCompletion` in `onboarding_dialog.dart`:
1. Loads the default `MenuConfiguration` for the app
2. Resets any stale user-specific version
3. Clones the default as a user-specific menu
4. Minimises items whose routes were not selected by Gemini
5. Saves conversation log via `save#Onboarding`
6. Dispatches `MenuConfigLoad(userVersion: true)` to refresh the dashboard
7. Pops the dialog

## Supported Apps

System prompts exist for: `AppAdmin`, `AppHotel`, `AppFreelance`. Add a new entry to `OnboardingPrompts._appInstructions` to support additional apps.

## Adding a New Widget

1. Create widget in `domains/onboarding/widgets/`
2. Add static `catalogItem(...)` factory returning a `CatalogItem` with name + schema + builder
3. Register it in `buildOnboardingCatalog()` in `onboarding_catalog.dart`
4. Reference the widget name in the relevant app prompt in `onboarding_prompts.dart`
