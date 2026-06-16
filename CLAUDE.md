# CLAUDE.md

Guidance to Claude Code (claude.ai/code) for this repo.

Behavioral guidelines to reduce common LLM coding mistakes. Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.

## Architecture

GrowERP: multi-platform ERP (Android, iOS, Web, Linux, Windows). Flutter frontend, Moqui backend. All comms via REST APIs.

**Two Flutter package categories** (all under `flutter/packages/`):
1. **Building blocks** (`growerp_*`) — domain-specific reusable packages (e.g., `growerp_core`, `growerp_models`, `growerp_catalog`). Lower-level packages are deps of higher-level ones; `growerp_models` is base.
2. **Applications** — end-user apps composed from building blocks (e.g., `admin`, `hotel`, `freelance`, `elearner`).

**State management**: BLoC (`flutter_bloc`) throughout. Each domain entity follows:
```
growerp_[domain]/lib/src/[entity]/
├── blocs/        # [Entity]Bloc, [Entity]Event, [Entity]State
├── views/        # [Entity]List, [Entity]Dialog
├── widgets/      # [Entity]_list_styled_data.dart
└── integration_test/  # [Entity]Test
```

**Code generation**: Data models use `freezed` + `json_serializable`. API clients use `retrofit`. Run `melos build` after changing annotated files.

**Backend**: Moqui components in `moqui/runtime/component/`. `growerp` component (source at `backend/`) provides multi-company ERP. See `docs/Flutter_Moqui_REST_Backend_Interface.md` for REST API details.

**Backend repo structure** — all on `growerp` branch of growerp forks:
- `moqui/` → growerp/moqui-framework (submodule of growerp root)
- `moqui/runtime/` → growerp/moqui-runtime (cloned by `setup-backend.sh`, not a submodule)
- `moqui/runtime/component/mantle-udm/` → growerp/mantle-udm (submodule of moqui-runtime)
- `moqui/runtime/component/mantle-usl/` → growerp/mantle-usl (submodule of moqui-runtime)
- `moqui/runtime/component/moqui-fop/` → growerp/moqui-fop (submodule of moqui-runtime)
- `moqui/runtime/component/moqui-mcp/` → growerp/moqui-mcp (submodule of moqui-runtime)
- `moqui/runtime/component/moqui-adk/` → growerp/moqui-adk (submodule of moqui-runtime)

Custom components tracked in growerp root, symlinked by `setup-backend.sh`:
- `backend/` → symlinked as `moqui/runtime/component/growerp`
- `pop-rest-store/` → symlinked as `moqui/runtime/component/PopRestStore`
- `mantle-stripe/` → symlinked as `moqui/runtime/component/mantle-stripe`

## Key Docs

- `docs/GrowERP_Design_Patterns.md` — canonical patterns and naming conventions
- `docs/GrowERP_Code_Templates.md` — ready-to-use code templates
- `docs/GrowERP_AI_Instructions.md` — detailed AI development guidance
- `docs/Building_Blocks_Development_Guide.md` — creating new building blocks
- `docs/basic_explanation_of_the_frontend_REST_Backend_data_models.md` — data model integration

## Flutter Commands

All melos commands run from `flutter/`. Workspace defined in `flutter/pubspec.yaml`.

```bash
cd flutter

# One-time setup
dart pub global activate melos
export PATH="$PATH":"$HOME/.pub-cache/bin"

# Bootstrap (run after cloning or adding packages)
melos clean && melos bootstrap

# Code generation (Freezed, Retrofit — run after model changes)
melos build

# Localization
melos l10n

# Lint
melos analyze

# Run all integration tests (requires running backend on port 8080)
melos test

# Run tests with explicit backend URL
BACKEND_URL=http://localhost:8080 melos test

# Run tests for a single package
cd packages/growerp_catalog/example
flutter test integration_test --dart-define=BACKEND_PORT=8080

# Headless tests via Docker (Linux desktop + xvfb, no Android emulator needed)
cd flutter && ./build_run_all_tests.sh

# Headless tests for a single package
./build_run_all_tests.sh catalog
```

## Backend (Moqui)

```bash
# One-time clone setup (initialise all nested submodules + link custom components)
git submodule update --init --recursive
bash setup-backend.sh

# First-time build (from moqui/ dir)
cd moqui
./gradlew build
java -jar moqui.war load types=seed,seed-initial,install no-run-es

# Reset database
./gradlew cleandb
java -jar moqui.war load types=seed,seed-initial,install no-run-es

# Start backend (admin at http://localhost:8080/vapps, user: SystemSupport, pass: moqui)
java -jar moqui.war no-run-es

# Sync upstream moqui changes into growerp forks, then update growerp root
bash sync-upstream.sh    # merges upstream → each growerp fork (runs from repo root)
bash sync-submodules.sh  # updates growerp root submodule pointers + commits
git push
```

## Debugging backend data (MCP)

When the backend is running, the `moqui` MCP server exposes `moqui_rest_call` — a read-only
(GET) tool to inspect live data via Moqui's REST API. Use it to check what's actually stored
when debugging. `path` is relative to `/rest/`:
- `e1/{Entity}/{id}` — any entity by name (e.g. `e1/mantle.party.Party/100000`), filter/page
  via `queryParameters` (e.g. `{pageSize:'10', statusId:'...', orderByField:'lastName'}`)
- `m1/{Entity}/{master}/{id}` — entity plus dependent records
- `s1/moqui/...`, `s1/mantle/...` — Moqui Tools / Mantle USL Service REST APIs
- Discover: `service.swagger/moqui.json`, `service.swagger/mantle.json`, `entity.swagger`

Read-only (no create/update/delete) and restricted to the SystemSupport account.

## Conventions

- **Models**: Use `@freezed` with `Equatable`. `fromJson` handles both wrapped (`json['entity']`) and unwrapped JSON.
- **Forms**: Use `FormBuilder` with `FormBuilderValidators`. All interactive widgets need `Key`.
- **BLoC events**: Standard set: `Fetch`, `Update`, `Delete`. Status enum: `initial`, `loading`, `success`, `failure`.
- **Error display**: `HelperFunctions.showMessage(context, message, Colors.red)` in BLoC listener.
- **Integration tests**: In `example/integration_test/`. Use `CommonTest` utilities. Test class has `add`, `update`, `delete`, `check` static methods.
- **Menu**: Configured per app via building block composition — see `docs/GrowERP_Extensibility_Guide.md`.

## Missing Flutter/Dart

If `flutter` or `dart` not on PATH:

```bash
FLUTTER_DIR="/tmp/flutter_install"
mkdir -p "$FLUTTER_DIR" && cd "$FLUTTER_DIR"
wget -q https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.33.0-stable.tar.xz
tar xf flutter_linux_3.33.0-stable.tar.xz
export FLUTTER_ROOT="$FLUTTER_DIR/flutter"
export PATH="$FLUTTER_ROOT/bin:$PATH"
```