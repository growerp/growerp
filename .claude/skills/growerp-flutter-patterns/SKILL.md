---
name: growerp-flutter-patterns
description: GrowERP conventions for bloc, freezed models, retrofit/dio REST client and bloc unit tests. Use when creating or editing a *_bloc.dart / *_event.dart / *_state.dart, a model or enum in growerp_models, a RestClient *_api.dart mixin method, or a test/**/*_bloc_test.dart. Overrides generic Flutter bloc/freezed/retrofit advice (no Cubit, no freezed union states, no DTO→domain layer).
---

# GrowERP Flutter patterns (bloc / freezed / retrofit / dio)

Full templates: [docs/GrowERP_Code_Templates.md](../../../docs/GrowERP_Code_Templates.md) and
[docs/GrowERP_Design_Patterns.md](../../../docs/GrowERP_Design_Patterns.md). This file is the short
rule set plus gotchas the docs don't cover. When docs and code disagree, copy the nearest existing
bloc in the same package (reference: `growerp_order_accounting/lib/src/accounting/gl_account/`).

## Bloc

- `Bloc` with events, never `Cubit`. Files: `[entity]_bloc.dart` with `part` event + state.
- Events: `[Entity]Fetch` (searchString, refresh, limit=20), `[Entity]Update`, `[Entity]Delete`;
  extend `Equatable`. Search uses a separate `[Entity]SearchChanged` event.
- State: ONE class + `enum [Entity]Status { initial, loading, success, failure }`, fields
  `status`, list, `message`, `hasReachedMax`, `copyWith`, `Equatable` props. No sealed/freezed states.
- Constructor takes `RestClient` (most blocs positional: `GlAccountBloc(this.restClient)`; the
  docs template's named param is outdated — match the package).
- Transformers: Fetch → `droppable` + `throttle(100ms)`; SearchChanged → empty fires at once,
  ≥3 chars `debounce(300ms)` + `switchMap`. Copy from `gl_account_bloc.dart`. The debounce/cancel
  is what makes `CommonTest.enterText` (fires `onChanged` twice) safe — a list screen without a
  bloc must guard its loader with a request id.
- Paging: `start = state.list.length` unless initial/refresh/search; on refresh emit `loading`
  with an empty list first so stale rows don't show.
- Errors: `on DioException catch (e)` → `emit(failure, message: await getDioError(e))`
  (`growerp_core/lib/src/services/get_dio_error.dart`).
- Success messages are l10n keys, `'glAccountUpdateSuccess:${name}'`, translated in the view via
  the package's `translate[Entity]BlocMessage` (`src/common/translate_bloc_messages.dart`). Add new
  keys there and in `intl_en.arb` (metadata `@key` in English ARB only), then `melos l10n`.
- View: `BlocConsumer`; listener shows failure with
  `HelperFunctions.showMessage(context, message, Colors.red)`, success in green.
- Entity dialogs `Navigator.pop()` on ANY `success`. A background/aggregate fetch outside the CRUD
  flow must emit its own status value (e.g. `summarySuccess`) or it pops the page under the dialog.

## Freezed models (growerp_models)

Freezed 3 shape (reference `models/gl_account_model.dart`; the docs' `extends Equatable` /
`const factory` template is outdated — 141 of 151 models use freezed equality, no Equatable):

```dart
@freezed
abstract class GlAccount with _$GlAccount {
  GlAccount._();
  factory GlAccount({
    String? glAccountId,
    String? accountName,
    @Default([]) List<GlAccount> children,
  }) = _GlAccount;

  factory GlAccount.fromJson(Map<String, dynamic> json) =>
      _$GlAccountFromJson(json['glAccount'] ?? json);
}

// list wrapper returned by the REST client
@freezed
abstract class GlAccounts with _$GlAccounts {
  factory GlAccounts({@Default([]) List<GlAccount> glAccounts}) = _GlAccounts;
  factory GlAccounts.fromJson(Map<String, dynamic> json) => _$GlAccountsFromJson(json);
}
```

- `fromJson` unwraps `json['entity'] ?? json` — accepts wrapped and unwrapped.
- Scalars nullable; lists `@Default([])`. Never a real-value default (`@Default('legacy')`):
  partial update objects get fully populated and the PATCH overwrites the backend value.
- `DateTime?` fields need `@DateTimeConverter()` (server UTC ↔ local). `Uint8List` images:
  `@Uint8ListConverter()`.
- Backend field name differs → `@JsonKey(name: 'customerStatus')`.
- After any annotated change: `cd flutter && melos build`; commit generated `*.g.dart` / `*.freezed.dart`.

## Enums

Enum carries the backend value + a null-safe lookup + a converter in
`growerp_models/lib/src/json_converters.dart` (see `LeadStatus` / `LeadStatusConverter`):

```dart
enum LeadStatus {
  assigned('CUSTOMER_ASSIGNED');
  final String value;
  const LeadStatus(this.value);
  static LeadStatus? getByValue(String value) { /* loop, return null if unknown */ }
  @override
  String toString() => value;
}
```

Unknown backend values map to null — don't use `unknownEnumValue`. Platform strings: Dart
lowercase vs DB UPPERCASE, normalize on write and every read.

## Retrofit REST client

- Methods go in the domain mixin `growerp_models/lib/src/rest_client/[domain]_api.dart`, which
  `RestClient` mixes in. Path `rest/s1/growerp/100/[Entity]` — must match `backend/service/growerp.rest.xml`.
- `@GET` with `@Query` (start, limit, search, ...); `@POST`/`@PATCH`/`@DELETE` with
  `@Field() required X x` (+ `@Field() required String applicationId` where the backend needs it).
- Return typed list wrappers (`Future<GlAccounts>`), not `Map`/`dynamic`. If a method must return
  `dynamic`, the body can arrive as a raw JSON String — `jsonDecode` it when `is String`.
- Backend side: a declared Map in-param silently drops undeclared sub-fields — add new model fields
  to the service definition too.

## Bloc unit tests

- `test/[domain]/[entity]_bloc_test.dart`; shared fixtures in `test/shared/mocks.dart`, which
  re-exports `package:growerp_models/testing.dart` (`MockRestClient`, `dioError(message)`).
- `bloc_test` + `mocktail` (not mockito). `registerFallbackValue` in `setUpAll`.
- Stub with exact args (`when(() => restClient.getGlAccount(start: 0, limit: 20, ...))`).
- Throttled Fetch: `wait:` longer than the throttle (150ms for 100ms).
- Match states with a `TypeMatcher` helper (`isA<XState>().having(...)`) rather than full equality.
- Test names: `Event_condition_expectedResult`. A test exposing an open bug: `skip:` with the
  issue number, never delete it.
- Run: `cd flutter/packages/<pkg> && flutter test test/`; all packages: `cd flutter && melos run test_unit`.
- Template: `docs/GrowERP_Code_Templates.md` § 4b. Rules and what was adopted from the
  `flutter-testing` skill: `docs/adr/0001-flutter-unit-test-standard.md`.
