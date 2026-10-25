# 1. Flutter unit-test standard

Date: 2026-10-25. Status: accepted.

## Context

Until October 2026 the Flutter workspace was tested only with integration tests
(`example/integration_test/`). They need a running Moqui backend and a display,
take hours across the CI slices, and a failure points at a screen rather than at
the code that broke. Only four packages had a `test/` directory and nothing ran it.

## Decision

Every package keeps backend-free unit tests in `test/`, and every bloc
(`lib/**/*_bloc.dart` extending `Bloc`) has handler-level tests.

- **Run**: `cd flutter && melos run test_unit` runs each `test/` dir with
  `--coverage` and writes `build/unit_test.json`. The CI `status` workflow runs it
  in the `unit-tests` job; the status page shows a "Flutter Unit tests" row
  (failures link to `failures.html#unit`), a bloc coverage line and
  `coverage.html` (from `flutter/ci/bloc_coverage.py`). A unit failure fails the
  run.
- **Libraries**: `bloc_test` + `mocktail`. No `mockito` (no code generation).
- **Mocks**: one shared `MockRestClient` and `dioError(message)` in
  `package:growerp_models/testing.dart` (not exported from the main barrel).
  Each package re-exports it from `test/shared/mocks.dart` and adds its own
  fixtures and mocks there; no mocks declared inside a test file.
- **Style** (from the `flutter-testing` skill, `.claude/skills/flutter-testing/`):
  - Arrange / Act / Assert. In `blocTest`: Arrange = `setUp` + `build` + `seed`,
    Act = `act` (one event), Assert = `expect` + `verify`.
  - Names `Method_Scenario_ExpectedBehavior`, e.g.
    `CategoryFetch_restThrowsDio_emitsFailure`.
  - States are matched with `isA<XState>().having(...)` helpers, not full
    `copyWith` state trees.
  - Every handler: success, `DioException` failure, plus its paging / list
    mutation rules.
  - Stub with the exact arguments the bloc must send; `any()` only where the
    value really does not matter.
  - No tests that only echo fields, `props` or generated code. Hand-written
    logic (converters, wrapped/unwrapped `fromJson`, CSV) is tested.
- **Bugs**: a test that reproduces an open bug is kept, inside a
  `group(..., skip: '<issue url>')` (blocTest's own `skip` counts states, it does
  not skip). Fixing the bug means removing the `skip`. A bug fix comes with a
  test that failed before it.
- **Template**: `docs/GrowERP_Code_Templates.md` § 4b.

## Rules of the flutter-testing skill not adopted

- Robot classes, `WidgetKeys` constants, `TestWrapper.pumpLocalizedWidget`: they
  are for widget tests, which this standard does not cover. The integration
  tests already use `CommonTest` + `<Entity>Test` static methods, which play the
  robot role.
- Patrol: the integration tests stay on the CommonTest / xvfb stack.
- Mock blocs registered with GetIt: GrowERP provides blocs with `BlocProvider`.
- "Fakes over mocks for repositories": GrowERP has no repository layer, blocs
  call the generated `RestClient` directly, so a mocktail mock of it is the
  practical seam.

## Consequences

- 68/68 blocs and the shared model logic are covered (about 800 tests, a few
  seconds per package). Writing them found 14 bugs, filed as issues #34–#47.
- A new or changed bloc needs its tests; reviewers can check the coverage page.
- Generated `*.g.dart` / `*.freezed.dart` files are not committed, so the CI job
  runs the bootstrap action (`melos build`) before testing.
