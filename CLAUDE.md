# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Architecture

GrowERP is a multi-platform ERP system (Android, iOS, Web, Linux, Windows) using Flutter for the frontend and Moqui for the backend. All frontend-backend communication is via REST APIs.

**Two categories of Flutter packages** (all under `flutter/packages/`):
1. **Building blocks** (`growerp_*`) — domain-specific reusable packages (e.g., `growerp_core`, `growerp_models`, `growerp_catalog`). Lower-level packages are dependencies of higher-level ones; `growerp_models` is the base.
2. **Applications** — end-user apps composed from building blocks (e.g., `admin`, `hotel`, `freelance`, `elearner`).

**State management**: BLoC (`flutter_bloc`) throughout. Each domain entity follows this structure:
```
growerp_[domain]/lib/src/[entity]/
├── blocs/        # [Entity]Bloc, [Entity]Event, [Entity]State
├── views/        # [Entity]List, [Entity]Dialog
├── widgets/      # [Entity]_list_styled_data.dart
└── integration_test/  # [Entity]Test
```

**Code generation**: Data models use `freezed` + `json_serializable`. API clients use `retrofit`. Run `melos build` after changing annotated files.

**Backend**: Moqui components in `moqui/runtime/component/`. The `growerp` component (source at `backend/`) provides multi-company ERP functionality. See `docs/Flutter_Moqui_REST_Backend_Interface.md` for REST API details.

**Backend repo structure** — git submodules (all on `growerp` branch of growerp forks):
- `moqui/` → growerp/moqui-framework
- `moqui/runtime/` → growerp/moqui-runtime
- `moqui/runtime/component/mantle-udm/` → growerp/mantle-udm
- `moqui/runtime/component/mantle-usl/` → growerp/mantle-usl
- `moqui/runtime/component/moqui-fop/` → growerp/moqui-fop

Custom components tracked in growerp1 root and symlinked by `setup-backend.sh`:
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

All melos commands run from the `flutter/` directory. The workspace is defined in `flutter/pubspec.yaml`.

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

# Sync upstream moqui changes into growerp forks, then update growerp1
bash sync-upstream.sh    # merges upstream → each growerp fork (runs from repo root)
bash sync-submodules.sh  # updates growerp1 submodule pointers + commits
git push
```

## Conventions

- **Models**: Use `@freezed` with `Equatable`. `fromJson` handles both wrapped (`json['entity']`) and unwrapped JSON.
- **Forms**: Use `FormBuilder` with `FormBuilderValidators`. All interactive widgets need a `Key`.
- **BLoC events**: Standard set is `Fetch`, `Update`, `Delete`. Status enum: `initial`, `loading`, `success`, `failure`.
- **Error display**: `HelperFunctions.showMessage(context, message, Colors.red)` in BLoC listener.
- **Integration tests**: In `example/integration_test/`. Use `CommonTest` utilities. Test class has `add`, `update`, `delete`, `check` static methods.
- **Menu**: Configured per app via building block composition — see `docs/GrowERP_Extensibility_Guide.md`.

## Missing Flutter/Dart

If `flutter` or `dart` is not on PATH:

```bash
FLUTTER_DIR="/tmp/flutter_install"
mkdir -p "$FLUTTER_DIR" && cd "$FLUTTER_DIR"
wget -q https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.33.0-stable.tar.xz
tar xf flutter_linux_3.33.0-stable.tar.xz
export FLUTTER_ROOT="$FLUTTER_DIR/flutter"
export PATH="$FLUTTER_ROOT/bin:$PATH"
```
