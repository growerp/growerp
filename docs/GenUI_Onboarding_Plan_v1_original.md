# GenUI Onboarding — Plan v1 (Original, Not Implemented)

> **Superseded by Plan v2.** This was the original design using Gemini native function-calling + custom `AssistantBloc` + sidebar. Replaced by the standard `genui` Flutter package approach (see `GenUI_Onboarding_Plan_v2_genui.md`).

## Context

GrowERP needs a conversational onboarding for new users (appsUsed.isEmpty) that avoids dropping them into a complex ERP menu on day one. Instead, a full-screen Gemini-powered chat flow gathers business context and produces a personalized `MenuConfiguration`. After completion, a collapsible sidebar summarizes what was configured.

---

## Architecture Overview

```
Phase 1 (Full-screen)           Phase 2 (Sidebar)
┌────────────────────────┐      ┌────────────────────────┐
│  OnboardingScreen      │ ───► │  AssistantSidebar       │
│  (blocks main app)     │      │  (summary panel,        │
│  Gemini function-call  │      │   collapsible)          │
│  GenUI widgets         │      └────────────────────────┘
└────────────────────────┘
```

Single `AssistantBloc` (provided at `TopApp` level) controls mode:
`hidden` → `fullScreen` → `sidebar`

---

## Gemini Function-Calling Pattern

Gemini supports native function calling. Request shape (extends existing `GeminiAiUtil.groovy`):

```json
{
  "contents": [...],
  "tools": [{
    "function_declarations": [
      { "name": "show_welcome", "description": "...", "parameters": {...} }
    ]
  }],
  "tool_config": { "function_calling_config": { "mode": "ANY" } }
}
```

Response when tool called:
```json
candidates[0].content.parts[0].functionCall = { "name": "...", "args": {...} }
```

Flutter sends full conversation history each turn (stateless backend).

---

## Tool Set (6 tools, Onboarding)

| Tool | Widget | Purpose |
|------|--------|---------|
| `show_welcome` | WelcomeCard | Intro message + CTA button |
| `ask_question` | QuestionCard | Free-text field |
| `show_options` | OptionsCard | Single or multi-select chips |
| `collect_profile` | ProfileFormCard | Multi-field FormBuilder form |
| `preview_menu` | MenuPreviewCard | Grid of menu items + Confirm/Adjust |
| `finalize_menu` | — (triggers completion) | Saves config + transitions sidebar |

Gemini uses `tool_config: {mode: "ANY"}` so it always calls a tool (no free text).

---

## Files to Create / Modify

### Backend

**New:** `backend/service/growerp/100/OnboardingServices100.xml`
- Service `chat#Onboarding`
- Input: `appId`, `messages` (JSON array), `historyJson` (full conversation)
- Extends `GeminiAiUtil.callGeminiApi` with `functionDeclarations` + `toolConfig: ANY`
- Parses `candidates[0].content.parts[0].functionCall` → `{name, args}`
- If `finalize_menu`: sets `isDone: true`, returns `menuConfig`
- Returns: `{toolCall: {name, args}, isDone, menuConfig?, errorMessage?}`

**Modify:** `backend/service/GeminiAiUtil.groovy`
- Add optional `functionDeclarations` param to `callGeminiApi`
- Add optional `toolConfig` param (default: `AUTO`, onboarding uses `ANY`)
- Parse `functionCall` in response alongside existing text parsing

**Modify:** `backend/service/growerp.rest.xml`
- Add `POST /rest/s1/growerp/100/OnboardingChat`

---

### growerp_models

**New:** `flutter/packages/growerp_models/lib/src/models/onboarding_models.dart`
```dart
@freezed class GenUIToolCall { name, args: Map<String, dynamic> }
@freezed class OnboardingChatResponse { toolCall?, isDone, menuConfig?, errorMessage? }
@freezed class OnboardingMenuConfig { currency?, timezone?, menuItems[] }
@freezed class OnboardingMenuItem { label, route, icon? }
@freezed class OnboardingHistoryItem { role, content, toolName?, toolArgs? }
```

**Modify:** `flutter/packages/growerp_models/lib/src/rest_client.dart`
- Add: `@POST("rest/s1/growerp/100/OnboardingChat") Future<OnboardingChatResponse> chatOnboarding(@Body() Map<String,dynamic> body)`

**Modify:** `flutter/packages/growerp_models/lib/src/models.dart`
- Export `onboarding_models.dart`

Run `melos build` after.

---

### growerp_core — new domain `domains/onboarding/`

**AssistantBloc** (`blocs/assistant_bloc.dart`)
```
Events: AssistantStart(isNewUser), AssistantTransitionToSidebar, AssistantToggle, AssistantHide
States: AssistantState { mode: hidden|fullScreen|sidebar, isCollapsed: bool }
```

**OnboardingBloc** (`blocs/onboarding_bloc.dart`)
```
Events: OnboardingStart(appId), OnboardingAnswer(result, displayText, lastModelContent), OnboardingSkip
States: OnboardingState { status: initial|loading|step|complete|skipped|failure,
                           currentTool?, messages[], history[], lastModelContent? }
```
- Each `OnboardingAnswer` appends `[assistant_tool_use, tool_result]` pair to history
- Calls `restClient.chatOnboarding({appId, messages: history})`
- On `finalize_menu` → emits `complete(menuConfig)`

**Widgets** (`widgets/`)
- `welcome_card.dart` — title + body text + CTA button
- `question_card.dart` — text field + submit
- `options_card.dart` — Wrap of FilterChip, single or multi-select + Next button
- `profile_form_card.dart` — FormBuilder fields + Submit
- `menu_preview_card.dart` — GridView of icon+label tiles + Confirm/Adjust buttons
- `genui_widget_renderer.dart` — switch on `GenUIToolCall.name` → widget

**Views** (`views/`)
- `onboarding_screen.dart` — full-screen Stack overlay:
  - LinearProgressIndicator header (step / 6)
  - Animated body: GenUIWidgetRenderer(currentTool) + chat history timeline above
  - Skip footer → dispatches `OnboardingSkip`
  - BlocListener on OnboardingBloc: `complete` → save MenuConfig + dispatch `AssistantTransitionToSidebar`
- `assistant_sidebar.dart` — collapsible right panel:
  - Shows configured items: business type, currency, menu items list
  - Toggle button (chevron_right / chevron_left)
  - AnimatedContainer width: 0 ↔ 280

**Barrel:** `onboarding/onboarding.dart`

---

### growerp_core — integration

**Modify:** `domains/domains.dart`
- `export 'onboarding/onboarding.dart';`

**Modify:** `domains/common/widgets/top_app.dart`
- Add `AssistantBloc` to `_TopAppState` (created in `initState`, closed in `dispose`)
- Add to `MultiBlocProvider`
- Wrap router's `builder` with `AssistantOverlay`:

```dart
class AssistantOverlay extends StatelessWidget {
  Widget build(context) => BlocBuilder<AssistantBloc, AssistantState>(
    builder: (context, state) {
      if (state.mode == AssistantMode.fullScreen)
        return Stack(children: [child, OnboardingScreen()]);
      if (state.mode == AssistantMode.sidebar)
        return Row(children: [Expanded(child: child), AssistantSidebar()]);
      return child;
    });
}
```

**Modify:** `domains/authenticate/views/login_dialog.dart`
- In `AuthStatus.authenticated` handler, after `TrialWelcomeHelper`:
```dart
final isNewUser = state.authenticate?.user?.appsUsed?.isEmpty ?? false;
if (isNewUser && context.mounted) {
  context.read<AssistantBloc>().add(AssistantStart(isNewUser: true));
}
```
- Then proceed with existing `Navigator.pop()` / `context.go('/')` logic

---

## Conversation History Format (Gemini)

```json
[
  {"role": "user", "parts": [{"text": "Start onboarding for admin app"}]},
  {"role": "model", "parts": [{"functionCall": {"name": "show_welcome", "args": {...}}}]},
  {"role": "user", "parts": [{"functionResponse": {"name": "show_welcome", "response": {"result": "acknowledged"}}}]},
  ...
]
```

`OnboardingHistoryItem.toMessagePair()` builds the `model + user/functionResponse` pair.

---

## Sidebar Summary Content

After `finalize_menu` completes, `AssistantSidebar` displays:
- Business type selected
- Currency / timezone set
- List of menu items added
- "Adjust" link → re-opens a simplified version of `preview_menu` step
- Collapse chevron button

No live AI in sidebar Phase 2 — static summary only.

---

## Verification

1. Start backend: `java -jar moqui.war no-run-es`
2. Register new company (fresh tenant, appsUsed will be empty)
3. Login → `AssistantStart(isNewUser: true)` fires → full-screen OnboardingScreen appears over blank main app
4. Walk 6 Gemini tool steps: welcome → business type → role → modules → preview → finalize
5. On finalize: menu saved to backend via `MenuConfigSave`, sidebar appears with summary
6. Collapse/expand sidebar works
7. Logout + re-login → onboarding does NOT retrigger (appsUsed no longer empty)
8. Non-new users → AssistantBloc stays `hidden`

---

## Build Order

1. Backend: `OnboardingServices100.xml` + `GeminiAiUtil.groovy` + REST route
2. `growerp_models`: models + rest_client → `melos build`
3. `growerp_core`: AssistantBloc → OnboardingBloc → widgets → views → top_app + login_dialog
