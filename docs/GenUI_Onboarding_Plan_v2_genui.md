# GenUI Onboarding — Plan v2 (Implemented)

> **This plan was implemented.** Uses the standard `genui` Flutter package (`A2uiTransportAdapter` + `SurfaceController`) with Gemini 2.5 Flash via Moqui. See `GenUI_Onboarding_Implementation.md` for the as-built description.

# GenUI Onboarding — Phase 1: Full-Screen Conversational Setup

## Context

New GrowERP tenants face an empty, complex ERP with no navigation configured. This plan implements a **Gemini-powered GenUI onboarding** using the official [`genui`](https://pub.dev/packages/genui) Flutter package (`labs.flutter.dev`). The LLM drives a conversational wizard that produces a personalized `MenuConfiguration`, saved to the backend.

**Core principle:** Gemini generates all question text, option labels, and menu items dynamically from what the user types. No hardcoded lists. The Flutter widgets are generic `CatalogItem` renderers; Gemini fills every field.

**LLM:** Gemini Flash (`gemini-2.5-flash`) via Moqui backend proxy — API key stays server-side.

### Existing screens — how they integrate

The current post-registration flow has three sequential steps. This plan **collapses steps 2 and 3** into one unified full-screen experience:

| Step | Screen | Status |
|------|--------|--------|
| 1 | `TenantSetupDialog` — collects company name, currency, demo data. Triggered by `apiKey == 'setupRequired'`. Submits via `AuthBloc` → backend `complete#TenantSetup`. | **Keep unchanged** — it's part of the auth flow; cannot be moved into genui. |
| 2 | `TrialWelcomeDialog` / `TrialWelcomeHelper.showTrialWelcomeIfNeeded` — modal showing 14-day trial info. | **Remove** — absorbed into the GenUI dialog header (static, no LLM needed). |
| 3 | GenUI onboarding — conversational business setup + menu generation. | **New** (this plan). |

After this plan: step 1 completes → `authenticated` → `appsUsed.isEmpty` → GenUI dialog opens (header shows trial welcome, Surface runs the business conversation). The `TrialWelcomeHelper` call in `login_dialog.dart` is deleted.

Phase 1 = full-screen onboarding dialog (triggers on `appsUsed.isEmpty` after login).
Phase 2 = collapsible sidebar copilot (`isCompact: true`, same Catalog/Surface, added later).
Phase 3 = global command bar inline (future).

**Architecture:**
```
Flutter (genui Conversation + Surface)
  → POST /rest/s1/growerp/100/OnboardingChat  {messages, systemPrompt, classificationId}
      → Moqui (onboardingChat.groovy)
          → GeminiAiUtil.callGeminiApi (text generation, A2UI JSONL output)
          ← raw A2UI JSONL string
      ← {jsonl: "...A2UI JSONL..."}
  ← A2uiTransportAdapter yields JSONL → SurfaceController parses → Surface rebuilds
  → user confirms FinalizeMenu widget
  → POST /rest/s1/growerp/100/OnboardingSave  {classificationId, menuConfig, conversation}
      → saves MenuConfig + ChatRoom conversation record
```

---

## Current State

| Item | Status |
|------|--------|
| `onboarding_models.g.dart` | Stale — will be deleted and replaced |
| `rest_client.g.dart` has old stub | Stale — will be replaced |
| `backend/service/growerp/100/OnboardingServices100.xml` | **Does not exist** |
| `growerp_core/src/domains/onboarding/` | **Does not exist** |
| `login_dialog.dart` trigger | Not wired |
| `genui` package | **Not yet added as dependency** |

---

## Step 1 — Add `genui` dependency

**File:** `flutter/packages/growerp_core/pubspec.yaml`

```yaml
dependencies:
  genui: ^0.9.0
```

Run `melos bootstrap` after adding.

---

## Step 2 — Models: `onboarding_models.dart`

**File:** `flutter/packages/growerp_models/lib/src/models/onboarding_models.dart`

With `genui`, the LLM conversation state is owned by `Conversation` — no custom message models needed. Only the **save step** needs models: the confirmed menu config passed to `OnboardingSave`.

Delete the stale `onboarding_models.g.dart` first (`--delete-conflicting-outputs` handles it).

```dart
import 'package:json_annotation/json_annotation.dart';
part 'onboarding_models.g.dart';

@JsonSerializable(explicitToJson: true)
class OnboardingMenuConfig {
  final String name;
  final String classificationId;  // AppAdmin | AppHotel | AppFreelance | ...
  final List<OnboardingMenuItem> menuItems;
  const OnboardingMenuConfig({required this.name, required this.classificationId, required this.menuItems});
  factory OnboardingMenuConfig.fromJson(Map<String, dynamic> j) => _$OnboardingMenuConfigFromJson(j);
  Map<String, dynamic> toJson() => _$OnboardingMenuConfigToJson(this);
}

@JsonSerializable(explicitToJson: true)
class OnboardingMenuItem {
  final String title;
  final String? iconName;
  final String route;
  final String widgetName;
  final int? sequenceNum;
  final String? tileType;
  const OnboardingMenuItem({required this.title, this.iconName, required this.route,
    required this.widgetName, this.sequenceNum, this.tileType});
  factory OnboardingMenuItem.fromJson(Map<String, dynamic> j) => _$OnboardingMenuItemFromJson(j);
  Map<String, dynamic> toJson() => _$OnboardingMenuItemToJson(this);
}
```

**Export in** `flutter/packages/growerp_models/lib/src/models/models.dart`:
```dart
export 'onboarding_models.dart';
```

---

## Step 3 — REST Client Annotations

**File:** `flutter/packages/growerp_models/lib/src/rest_client.dart`

Two endpoints — chat (returns A2UI JSONL) and save (persists result):

```dart
/// Returns A2UI JSONL text for genui's A2uiTransportAdapter to parse.
/// Body: {messages: [...], systemPrompt: "...", classificationId: "..."}
@POST("rest/s1/growerp/100/OnboardingChat")
Future<Map<String, dynamic>> chatOnboarding(@Body() Map<String, dynamic> body);

/// Persists confirmed menu config + conversation to backend.
/// Body: {classificationId: "...", menuConfig: {...}, conversation: [...]}
@POST("rest/s1/growerp/100/OnboardingSave")
Future<void> saveOnboarding(@Body() Map<String, dynamic> body);
```

Regenerate: `cd flutter/packages/growerp_models && dart run build_runner build --delete-conflicting-outputs`

---

## Step 4 — Backend

### 4a. REST endpoints — `backend/service/growerp.rest.xml`

After the `ChatRoom` block (line ~781), inside `<resource name="100">`:
```xml
<resource name="OnboardingChat">
    <method type="post">
        <service name="growerp.100.OnboardingServices100.chat#Onboarding" />
    </method>
</resource>
<resource name="OnboardingSave">
    <method type="post">
        <service name="growerp.100.OnboardingServices100.save#Onboarding" />
    </method>
</resource>
```

### 4b. Service definitions — `backend/service/growerp/100/OnboardingServices100.xml`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<services xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:noNamespaceSchemaLocation="http://moqui.org/xsd/service-definition-2.1.xsd">

  <!-- Called each conversation turn. Returns A2UI JSONL for genui to render. -->
  <service verb="chat" noun="Onboarding" authenticate="true">
    <in-parameters>
      <parameter name="messages"      type="List"   required="true" />
      <parameter name="systemPrompt"  type="String" required="true" />
      <parameter name="classificationId" required="true" />
    </in-parameters>
    <out-parameters>
      <parameter name="jsonl" />  <!-- raw A2UI JSONL string -->
    </out-parameters>
    <actions>
      <script location="component://growerp/service/onboardingChat.groovy" />
    </actions>
  </service>

  <!-- Called once when user confirms the menu. Saves config + chat log. -->
  <service verb="save" noun="Onboarding" authenticate="true">
    <in-parameters>
      <parameter name="classificationId" required="true" />
      <parameter name="menuConfig"   type="Map"  required="true" />
      <parameter name="conversation" type="List" required="true" />
    </in-parameters>
    <actions>
      <script location="component://growerp/service/onboardingSave.groovy" />
    </actions>
  </service>

</services>
```

### 4c. Chat Groovy script — `backend/service/onboardingChat.groovy`

No function calling. `GeminiAiUtil.callGeminiApi` (existing method, unchanged) with text generation. Flutter sends the full system prompt (generated by `PromptBuilder` from the `genui` Catalog) + conversation history. Backend just calls Gemini and returns the raw JSONL text.

```groovy
import org.moqui.context.ExecutionContext

ExecutionContext ec = context.ec ?: context

// Load existing GeminiAiUtil (no changes needed to it)
def aiUtil = new GroovyShell(new Binding([ec: ec]))
    .evaluate(new File("component://growerp/service/GeminiAiUtil.groovy"))

// Build full prompt: system prompt (from Flutter's PromptBuilder) + conversation
// messages format: [{role:"user"|"model", parts:[{text:"..."}]}]
// Flatten to a single text prompt for GeminiAiUtil.callGeminiApi
def fullPrompt = systemPrompt + "\n\n" +
    messages.collect { msg ->
        def role = msg.role == "model" ? "Assistant" : "User"
        def text = msg.parts?.find { it.text }?.text ?: ""
        "${role}: ${text}"
    }.join("\n")

try {
    jsonl = aiUtil.callGeminiApi(ec, fullPrompt,
        [model: "gemini-2.5-flash", maxOutputTokens: 1024, jsonMode: false])
} catch (Exception e) {
    ec.message.addError("Gemini error: ${e.message}")
}
```

**Note:** `GeminiAiUtil.callGeminiApi` is reused unchanged. No new methods needed.

### 4d. Save Groovy script — `backend/service/onboardingSave.groovy`

Saves menu config to backend + persists conversation as a private ChatRoom for support access.

```groovy
import org.moqui.context.ExecutionContext

ExecutionContext ec = context.ec ?: context

// 1. Save MenuConfiguration via existing service
ec.service.sync().name("growerp.100.GeneralServices100.save#MenuConfiguration")
    .parameters([classificationId: classificationId, menuConfig: menuConfig])
    .call()

// 2. Persist conversation to ChatRoom (support app can read it)
def ownerResult = ec.service.sync()
    .name("growerp.100.GeneralServices100.get#RelatedCompanyAndOwner").call()

// Room name: first 60 chars of user's first message + app + date
def firstUserText = conversation.find { it.role == "user" }
    ?.parts?.find { it.text }?.text?.take(60) ?: classificationId
def roomName = "Onboarding: ${firstUserText} [${classificationId}] ${new Date().format('yyyy-MM-dd')}"

def roomResult = ec.service.sync()
    .name("growerp.100.ChatServices100.create#ChatRoom")
    .parameters([chatRoomName: roomName, isPrivate: 'Y',
                 ownerPartyId: ownerResult.ownerPartyId])
    .call()

conversation.each { msg ->
    def role  = msg.role == "model" ? "[Gemini]" : "[User]"
    def text  = msg.parts?.find { it.text }?.text ?: ""
    if (text) {
        ec.service.sync().name("growerp.100.ChatServices100.create#ChatMessage")
            .parameters([chatRoomId: roomResult.chatRoomId,
                         content: "${role} ${text}",
                         fromUserId: ec.user.userId])
            .call()
    }
}
```

**API key:** `GEMINI_API_KEY` — same env var used by all other AI services.

---

## Step 5 — genui Catalog and CatalogItems

**New directory:** `flutter/packages/growerp_core/lib/src/domains/onboarding/`

The `Catalog` tells Gemini which widgets it can generate (via A2UI format in system prompt). Each `CatalogItem` has a JSON schema, a data class, and a builder.

### 5a. `catalog/onboarding_catalog.dart`

```dart
import 'package:genui/genui.dart';
import '../widgets/welcome_card.dart';
import '../widgets/options_card.dart';
import '../widgets/menu_preview_card.dart';
import '../widgets/finalize_menu_widget.dart';

Catalog buildOnboardingCatalog({required void Function(OnboardingMenuConfig) onFinalize}) =>
  Catalog(components: [
    WelcomeCardItem.catalogItem,
    OptionsCardItem.catalogItem,
    MenuPreviewCardItem.catalogItem,
    FinalizeMenuCatalogItem.build(onFinalize: onFinalize),
  ]);
```

### 5b. `widgets/welcome_card.dart`

```dart
class WelcomeCardData {
  final String greeting;
  final String inputPrompt;
  final String? hintText;
  WelcomeCardData.fromJson(Map<String, dynamic> j)
    : greeting = j['greeting'], inputPrompt = j['inputPrompt'], hintText = j['hintText'];
}

class WelcomeCardItem extends StatelessWidget {
  static CatalogItem get catalogItem => CatalogItem(
    name: 'WelcomeCard',
    description: 'Free-text welcome card. inputPrompt must invite a sentence about the user\'s business.',
    schema: {'type':'object','required':['greeting','inputPrompt'],
      'properties':{'greeting':{'type':'string'},'inputPrompt':{'type':'string'},'hintText':{'type':'string'}}},
    builder: (ctx, props, ctrl) => WelcomeCardItem(data: WelcomeCardData.fromJson(props), controller: ctrl),
  );
  // ... widget build: greeting headline + FormBuilderTextField + submit button
  // On submit: ctrl.sendUserMessage("User description: ${controller.text}")
}
```

### 5c. `widgets/options_card.dart`

```dart
// CatalogItem schema: {question, options: string[], multiSelect: bool}
// On submit: ctrl.sendUserMessage("Selected: ${selected.join(', ')}")
// Reuses FilterChip (Flutter SDK)
```

### 5d. `widgets/menu_preview_card.dart`

```dart
// CatalogItem schema: {headline, menuItems: [{title, iconName, route, widgetName, sequenceNum}]}
// Reuses DashboardCard from growerp_core/templates/dashboard_card.dart for tiles
// "Looks good!" → ctrl.sendUserMessage("confirmed")
// "Adjust" → FormBuilderTextField → ctrl.sendUserMessage("adjust: ${comment}")
```

### 5e. `widgets/finalize_menu_widget.dart`

```dart
// CatalogItem schema: {name, classificationId, menuItems: [...]}
// This widget is never shown to user — it triggers onFinalize callback when rendered
// onFinalize called with parsed OnboardingMenuConfig
// Then Flutter calls saveOnboarding + MenuConfigSave
```

---

## Step 6 — genui Conversation Setup

**File:** `flutter/packages/growerp_core/lib/src/domains/onboarding/views/onboarding_dialog.dart`

`OnboardingDialog` receives the `Authenticate` object so the header can show trial welcome info without re-reading state.

```dart
class OnboardingDialog extends StatefulWidget {
  const OnboardingDialog({super.key, required this.authenticate});
  final Authenticate authenticate;

  @override
  State<OnboardingDialog> createState() => _OnboardingDialogState();
}

class _OnboardingDialogState extends State<OnboardingDialog> {
  late final Catalog _catalog;
  late final SurfaceController _surfaceCtrl;
  late final Conversation _conversation;

  @override
  void initState() {
    super.initState();
    final restClient = context.read<RestClient>();
    final classificationId = context.read<OnboardingBloc>().classificationId;

    _catalog = buildOnboardingCatalog(
      onFinalize: (menuConfig) => _handleCompletion(menuConfig),
    );
    _surfaceCtrl = SurfaceController(catalogs: [_catalog]);

    final systemPrompt = OnboardingPrompts.forApp(classificationId, _catalog);

    _conversation = Conversation(
      controller: _surfaceCtrl,
      transport: A2uiTransportAdapter(
        onSend: (messages) async* {
          final result = await restClient.chatOnboarding({
            'classificationId': classificationId,
            'systemPrompt': systemPrompt,
            'messages': messages.map((m) => m.toJson()).toList(),
          });
          yield result['jsonl'] as String;
        },
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) =>
      _conversation.sendRequest(ChatMessage.user(TextPart('Start onboarding.'))));
  }

  void _handleCompletion(OnboardingMenuConfig menuConfig) async {
    await context.read<RestClient>().saveOnboarding({
      'classificationId': menuConfig.classificationId,
      'menuConfig': menuConfig.toJson(),
      'conversation': _conversation.messages.map((m) => m.toJson()).toList(),
    });
    context.read<MenuConfigBloc>().add(MenuConfigSave(MenuConfiguration(
      appId: menuConfig.classificationId,
      name: menuConfig.name,
      menuItems: menuConfig.menuItems.map((item) => MenuItem(
        title: item.title, iconName: item.iconName, route: item.route ?? '',
        widgetName: item.widgetName, sequenceNum: item.sequenceNum ?? 10,
        tileType: item.tileType ?? 'navigation',
      )).toList(),
    )));
    if (mounted) Navigator.of(context).pop();
  }

  Widget _buildHeader() {
    final days = widget.authenticate.evaluationDays ?? 14;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(
              'Your $days-day free trial has started!',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Skip'),
          ),
        ]),
        const SizedBox(height: 4),
        Text(
          "Let's set up your workspace — takes about 2 minutes.",
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        const LinearProgressIndicator(value: null),  // indeterminate until Surface loads
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        body: SafeArea(
          child: Column(children: [
            _buildHeader(),
            Expanded(
              child: Surface(
                surfaceContext: _surfaceCtrl.contextFor('onboarding'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
```

**Reuse:**
- `LoadingIndicator` from `growerp_core` — shown while Surface has no content yet
- `DashboardCard` from `growerp_core/templates/dashboard_card.dart` — reused inside `MenuPreviewCard`
- `FormBuilderTextField` from `flutter_form_builder` — in `WelcomeCard` and `MenuPreviewCard` adjust input
- `FilterChip` (Flutter SDK) — in `OptionsCard`

---

## Step 7 — App-Specific System Prompts

**File:** `flutter/packages/growerp_core/lib/src/domains/onboarding/catalog/onboarding_prompts.dart`

`PromptBuilder` from `genui` generates the A2UI format spec from the Catalog. We prepend app-specific instructions.

```dart
import 'package:genui/genui.dart';

class OnboardingPrompts {
  static String forApp(String classificationId, Catalog catalog) {
    final catalogSpec = PromptBuilder.chat(
      catalog: catalog,
      systemPromptFragments: [_appInstructions[classificationId] ?? _appInstructions['AppAdmin']!],
    ).systemPromptJoined();
    return catalogSpec;
  }

  static const _appInstructions = {
    'AppAdmin': '''
You are GrowERP Business Setup Assistant.

Flow:
1. WelcomeCard — ask: "Tell us about your business — what do you sell or do, and who are your customers?"
2. OptionsCard x2-3 — generate questions + options FROM their description. No fixed lists.
   e.g. physical goods → invent options about stock; clients → invent options about invoicing.
3. MenuPreviewCard — pick 4-7 widgets from:
   AdminDashboard (route:/), ShowCompanyDialog (route:/companies),
   ActivityList (route:/crm), OpportunityList (route:/crm),
   ProductList (route:/catalog), AssetList (route:/inventory),
   SalesOrderList (route:/orders), PurchaseOrderList (route:/orders),
   OutgoingShipmentList (route:/inventory), WorkOrderList (route:/manufacturing),
   SalesInvoiceList (route:/acct-sales), PurchaseInvoiceList (route:/acct-purchase),
   LedgerTreeForm (route:/acct-ledger), RevenueExpenseChart (route:/acct-reports),
   UserListEmployee (route:/companies), ContentPlanList (route:/marketing),
   CourseList (route:/courses), WebsiteDialog (route:/website)
4. FinalizeMenu — classificationId = 'AppAdmin'
Rules: ONE widget per response. Generate every label from context. No GrowERP jargon.''',

    'AppHotel': '''
You are GrowERP Hotel Setup Assistant.

Flow:
1. WelcomeCard — ask: "Tell us about your property — room count, guest type, extra services?"
2. OptionsCard x2 — generate questions from THEIR answer (B&B admin pain vs large hotel departments).
3. MenuPreviewCard — always include GanttForm first, then pick from:
   GanttForm (route:/, room calendar), ShowCompanyDialog (route:/myHotel),
   AssetList (route:/rooms), ProductList (route:/rooms),
   SalesOrderRentalList (route:/reservations), CompanyUserListCustomer (route:/reservations),
   CheckInList (route:/checkInOut), CheckOutList (route:/checkInOut),
   SalesInvoiceList (route:/acct-sales), PurchaseInvoiceList (route:/acct-purchase),
   LedgerTreeForm (route:/acct-ledger), RevenueExpenseChart (route:/acct-reports),
   UserListCompany (route:/myHotel), WebsiteDialog (route:/myHotel)
4. FinalizeMenu — classificationId = 'AppHotel'
Rules: ONE widget per response. Hotel language: "Front Desk" not "CheckInList".''',

    'AppFreelance': '''
You are GrowERP Freelance Setup Assistant.

Flow:
1. WelcomeCard — ask: "Tell us about your work — services, clients, how you manage projects now?"
2. OptionsCard x2 — generate questions from THEIR answer (payment stress, client tracking, leads).
3. MenuPreviewCard — always include FreelanceDbForm first, then pick 3-5 from:
   FreelanceDbForm (route:/), ActivityList (route:/tasks),
   OpportunityList (route:/crm), UserListCustomer (route:/crm),
   SalesOrderList (route:/orders), SalesInvoiceList (route:/acct-sales),
   PurchaseInvoiceList (route:/acct-purchase), RevenueExpenseChart (route:/acct-reports),
   ContentPlanList (route:/marketing), WebsiteDialog (route:/website),
   ProductList (route:/catalog)
4. FinalizeMenu — classificationId = 'AppFreelance'
Rules: ONE widget per response. Use: "Clients" not "Customers", "Projects" not "Orders".''',
  };
}
```

**Adding a new app:** add one entry to `_appInstructions`. No other changes.

---

## Step 8 — Provider Registration

**File:** `flutter/packages/growerp_core/lib/src/get_core_bloc_providers.dart`

`OnboardingBloc` is now minimal — it only holds `classificationId` for the dialog to read. The conversation state is owned by genui's `Conversation` inside the dialog's `State`.

```dart
BlocProvider<OnboardingBloc>(
  create: (context) => OnboardingBloc(classificationId),
),
```

`OnboardingBloc` has no events — just a cubit holding `classificationId`:
```dart
class OnboardingBloc extends Cubit<void> {
  OnboardingBloc(this.classificationId) : super(null);
  final String classificationId;
}
```

---

## Step 9 — Barrel Exports

1. `flutter/packages/growerp_core/lib/src/domains/onboarding/onboarding.dart`:
   ```dart
   export 'catalog/onboarding_catalog.dart';
   export 'catalog/onboarding_prompts.dart';
   export 'views/onboarding_dialog.dart';
   export 'widgets/welcome_card.dart';
   export 'widgets/options_card.dart';
   export 'widgets/menu_preview_card.dart';
   export 'widgets/finalize_menu_widget.dart';
   export 'bloc/onboarding_bloc.dart';
   ```
2. Add to `flutter/packages/growerp_core/lib/src/domains/domains.dart`:
   ```dart
   export 'onboarding/onboarding.dart';
   ```

---

## Step 10 — Trigger in `login_dialog.dart`

**File:** `flutter/packages/growerp_core/lib/src/domains/authenticate/views/login_dialog.dart`

Replace the `AuthStatus.authenticated` listener block (lines 92–107). The old block:

```dart
case AuthStatus.authenticated:
  if (context.mounted) {
    await TrialWelcomeHelper.showTrialWelcomeIfNeeded(
      context: context,
      authenticate: state.authenticate,
    );
  }
  if (context.mounted) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go('/');
    }
  }
```

Replace with:

```dart
case AuthStatus.authenticated:
  final auth = state.authenticate!;
  if (context.mounted && (auth.user?.appsUsed.isEmpty ?? false)) {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => MultiBlocProvider(
        providers: [
          BlocProvider<OnboardingBloc>.value(
              value: context.read<OnboardingBloc>()),
          BlocProvider<MenuConfigBloc>.value(
              value: context.read<MenuConfigBloc>()),
        ],
        child: OnboardingDialog(authenticate: auth),
      ),
    );
  }
  if (context.mounted) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go('/');
    }
  }
```

**Changes:**
- `TrialWelcomeHelper.showTrialWelcomeIfNeeded` call removed — trial welcome is now in `OnboardingDialog._buildHeader()`
- `OnboardingDialog` shown only when `appsUsed.isEmpty` (new users who haven't configured their menu)
- `authenticate` passed directly; no extra BLoC reads inside the dialog for auth state
- Existing `canPop` / `context.go('/')` navigation unchanged — runs after dialog completes (or is skipped)

---

## Step 11 — Support App: Onboarding Conversation View

Conversations saved as private ChatRooms (name prefix `"Onboarding:"`). `SYSTEM_SUPPORT` already has blanket access to all private rooms (existing logic in `ChatServices100.xml` lines 63-126).

### 11a. Add `namePrefix` filter to `get#ChatRoom`

**File:** `backend/service/growerp/100/ChatServices100.xml`

Add optional `namePrefix` in-parameter; append LIKE condition to existing query. One-line change in the entity find block.

### 11b. Add `namePrefix` to `ChatRoomFetch` event

**File:** `growerp_chat/lib/src/chat_room/bloc/chat_room_event.dart`

Add optional `namePrefix` field to `ChatRoomFetch`. BLoC passes it to REST call. One field addition.

### 11c. New view — `OnboardingConversationList`

**File:** `flutter/packages/support/lib/src/onboarding/views/onboarding_conversation_list.dart`

Reuses `ChatRoomBloc` (fetch with `namePrefix: 'Onboarding:'`), `ChatDialog`, `ChatMessageBloc` — no new infra. On tap: open `ChatDialog` for that room.

### 11d. Menu seed data

**File:** `backend/data/GrowerpMenuSeedData.xml` — add inside `SUPPORT_DEFAULT`:
```xml
<growerp.menu.MenuItem menuItemId="SUPPORT_ONBOARDING"
    menuConfigurationId="SUPPORT_DEFAULT"
    title="Onboarding Conversations" route="/onboarding"
    iconName="onboarding" widgetName="OnboardingConversationList" sequenceNum="25"/>
```

---

## Critical Files Summary

| File | Action |
|------|--------|
| `growerp_core/pubspec.yaml` | add `genui: ^0.9.0` (Step 1) |
| `growerp_models/lib/src/models/onboarding_models.dart` | **CREATE** simplified (Step 2) |
| `growerp_models/lib/src/models/models.dart` | add export |
| `growerp_models/lib/src/rest_client.dart` | add `chatOnboarding` + `saveOnboarding` (Step 3) |
| `backend/service/growerp.rest.xml` | add OnboardingChat + OnboardingSave resources (Step 4a) |
| `backend/service/growerp/100/OnboardingServices100.xml` | **CREATE** (Step 4b) |
| `backend/service/onboardingChat.groovy` | **CREATE** (Step 4c) |
| `backend/service/onboardingSave.groovy` | **CREATE** (Step 4d) |
| `backend/service/GeminiAiUtil.groovy` | **no changes** — reused as-is |
| `growerp_core/src/domains/onboarding/catalog/onboarding_catalog.dart` | **CREATE** (Step 5a) |
| `growerp_core/src/domains/onboarding/catalog/onboarding_prompts.dart` | **CREATE** (Step 7) |
| `growerp_core/src/domains/onboarding/widgets/welcome_card.dart` | **CREATE** (Step 5b) |
| `growerp_core/src/domains/onboarding/widgets/options_card.dart` | **CREATE** (Step 5c) |
| `growerp_core/src/domains/onboarding/widgets/menu_preview_card.dart` | **CREATE** (Step 5d) |
| `growerp_core/src/domains/onboarding/widgets/finalize_menu_widget.dart` | **CREATE** (Step 5e) |
| `growerp_core/src/domains/onboarding/views/onboarding_dialog.dart` | **CREATE** (Step 6) |
| `growerp_core/src/domains/onboarding/bloc/onboarding_bloc.dart` | **CREATE** minimal cubit (Step 8) |
| `growerp_core/src/domains/onboarding/onboarding.dart` | **CREATE** barrel (Step 9) |
| `growerp_core/src/domains/domains.dart` | add export |
| `growerp_core/src/get_core_bloc_providers.dart` | add `OnboardingBloc` cubit |
| `growerp_core/src/domains/authenticate/views/login_dialog.dart` | add trigger (Step 10) |
| `backend/service/growerp/100/ChatServices100.xml` | add `namePrefix` filter (Step 11a) |
| `growerp_chat/lib/src/chat_room/bloc/chat_room_event.dart` | add `namePrefix` (Step 11b) |
| `support/lib/src/onboarding/views/onboarding_conversation_list.dart` | **CREATE** (Step 11c) |
| `backend/data/GrowerpMenuSeedData.xml` | add SUPPORT_ONBOARDING item (Step 11d) |

---

## Verification

1. **Codegen:** `cd flutter/packages/growerp_models && dart run build_runner build --delete-conflicting-outputs` — no errors.

2. **Backend chat test:**
   ```bash
   curl -X POST http://localhost:8080/rest/s1/growerp/100/OnboardingChat \
     -H "api_key: <session_token>" -H "Content-Type: application/json" \
     -d '{"classificationId":"AppAdmin","systemPrompt":"...","messages":[{"role":"user","parts":[{"text":"Start."}]}]}'
   # Expect: {"jsonl": "{\"v\":\"0.9\",\"op\":\"set\",...\"type\":\"WelcomeCard\"...}"}
   ```

3. **Flutter analyze:** `cd flutter && melos analyze` — zero errors.

4. **Manual onboarding test:** Log in as fresh user (`appsUsed=[]`). Verify full-screen dialog with genui `Surface` renders `WelcomeCard`. Step through conversation. Confirm menu. Verify dashboard loads with generated config.

5. **Support app test:** Log in as `SYSTEM_SUPPORT`. Open "Onboarding Conversations". Verify completed session appears as `"Onboarding: <description> [AppAdmin] <date>"`. Tap → `ChatDialog` shows all turns.

---

## Phase 2 Extension (Future)

- `OnboardingDialog` → `OnboardingPanel` (collapsible sidebar, `isCompact: true` widgets)
- Same `Catalog` and `onSend` transport — only the `Surface` container changes
- Add screen context to `systemPrompt` for contextual copilot awareness
