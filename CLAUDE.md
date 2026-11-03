# CLAUDE.md

Guidance for Claude Code in this repo. Bias toward caution; use judgment on trivial tasks.

## Working rules
- **Think first**: state assumptions; if unclear or several readings exist, ask — don't pick silently. Push back when a simpler way exists.
- **Simplicity**: minimum code for the request. No speculative features, single-use abstractions, unrequested config, or handling for impossible cases.
- **Surgical changes**: touch only what the request needs; match existing style; don't refactor or reformat adjacent code. Remove only orphans your change created; mention other dead code, don't delete it.
- **Verify**: turn tasks into checkable goals (bug → failing test first, refactor → tests green before and after). For multi-step work, state a short plan with a check per step.

## Architecture

GrowERP: multi-platform ERP (Android, iOS, Web, Linux, Windows). Flutter frontend, Moqui backend. All comms via REST APIs.

**Two Flutter package categories** (all under `flutter/packages/`):
1. **Building blocks** (`growerp_*`) — domain-specific reusable packages (e.g., `growerp_core`, `growerp_models`, `growerp_catalog`). Lower-level packages are deps of higher-level ones; `growerp_models` is base.
2. **Applications** — end-user apps composed from building blocks (e.g., `admin`, `hotel`, `freelance`).

**State management**: BLoC (`flutter_bloc`) throughout. Each domain entity follows:
```
growerp_[domain]/lib/src/[entity]/
├── blocs/        # [Entity]Bloc, [Entity]Event, [Entity]State
├── views/        # [Entity]List, [Entity]Dialog
├── widgets/      # [Entity]_list_styled_data.dart
└── integration_test/  # [Entity]Test
```

**Code generation**: Data models use `freezed` + `json_serializable`. API clients use `retrofit`. Run `melos build` after changing annotated files.

**Backend**: Moqui components in `moqui/runtime/component/`. `growerp` component (source at `backend/`) provides multi-company ERP. See `docs/Flutter_Moqui_REST_Backend_Interface.md` for REST API details. Fork/submodule layout and component symlinks: `docs/agents/dev-setup.md`.

## Key Docs

- `docs/GrowERP_Security_Model.md` — user groups, menu-driven access, REST authorization
- `docs/GrowERP_Design_Patterns.md` — canonical patterns and naming conventions
- `docs/GrowERP_Code_Templates.md` — ready-to-use code templates
- `docs/GrowERP_AI_Instructions.md` — detailed AI development guidance
- `docs/Building_Blocks_Development_Guide.md` — creating new building blocks
- `docs/basic_explanation_of_the_frontend_REST_Backend_data_models.md` — data model integration
- `docs/agents/dev-setup.md` — one-time setup, all Flutter/backend commands, upstream sync, MCP data debugging, installing Flutter

## Commands

```bash
cd flutter && melos build          # after freezed/retrofit changes
melos analyze
melos run test_unit                # unit tests, no backend
cd packages/<pkg>/example && flutter test integration_test --dart-define=BACKEND_PORT=8080
# backend Spock tests, from moqui/ (beside a running dev backend use own H2 db;
# never a second `java -jar moqui.war` from moqui/ — it deletes shared execwartmp)
entity_ds_database=growerptest ./gradlew :runtime:component:growerp:test
```

Inspect live backend data: `moqui` MCP `moqui_rest_call` (read-only) — see `docs/agents/dev-setup.md`.

## Conventions

- **Models**: `@freezed abstract class X with _$X` (freezed equality, no `Equatable`). `fromJson` handles both wrapped (`json['entity']`) and unwrapped JSON. Full bloc/model/REST/bloc-test rules: `.claude/skills/growerp-flutter-patterns/SKILL.md`.
- **Forms**: Use `FormBuilder` with `FormBuilderValidators`. All interactive widgets need `Key`.
- **BLoC events**: Standard set: `Fetch`, `Update`, `Delete`. Status enum: `initial`, `loading`, `success`, `failure`.
- **Error display**: `HelperFunctions.showMessage(context, message, Colors.red)` in BLoC listener.
- **Unit tests**: In `test/` of each package, run by the CI status job (row "Flutter Unit tests" + bloc coverage page). Every bloc has a `test/<entity>/<entity>_bloc_test.dart` (bloc_test + mocktail, `MockRestClient` from `package:growerp_models/testing.dart`); a new or changed bloc gets its tests too. A test reproducing an open bug stays, skipped with the issue URL. Standard: `docs/adr/0001-flutter-unit-test-standard.md`.
- **Backend tests**: Spock specs in `backend/src/test/groovy/`, one per service file, each on its own tenant via `GrowerpTestSupport.tenant()`; new spec → `include` in `backend/build.gradle`. Open bug → `@PendingFeature(reason = '<issue url>')`. Coverage (services called + code blocks run) on the status page. Standard: `docs/adr/0002-backend-spock-test-standard.md`.
- **Bug fixes: test first**: (1) extend the existing test (or create one if none) so it reproduces the bug and fails on the current code; (2) then fix the code until it passes; (3) put test + fix back into the pull request (red→green evidence in the description) and leave it open for approval — no merge. Exception: when hansbak (repo owner) explicitly says so, merge straight to master; for anyone else the PR stays open.
- **Integration tests**: In `example/integration_test/`. Use `CommonTest` utilities. Test class has `add`, `update`, `delete`, `check` static methods.
- **Menu**: Configured per app via building block composition — see `docs/GrowERP_Extensibility_Guide.md`.

## Agent docs

- Issues: GitHub growerp/growerp via `gh` — `docs/agents/issue-tracker.md`
- Triage labels (needs-triage, needs-info, ready-for-agent, ready-for-human, wontfix) — `docs/agents/triage-labels.md`
- Domain: root `GLOSSARY.md` + `docs/adr/` — `docs/agents/domain.md`
