# Dev setup and reference

Moved out of `CLAUDE.md`: one-time setup, less common commands and reference material.

## Backend repo structure

All on `growerp` branch of growerp forks:
- `moqui/` → growerp/moqui-framework (submodule of growerp root)
- `moqui/runtime/` → growerp/moqui-runtime (cloned by `setup-backend.sh`, not a submodule)
- `moqui/runtime/component/mantle-udm/` → growerp/mantle-udm (submodule of moqui-runtime)
- `moqui/runtime/component/mantle-usl/` → growerp/mantle-usl (submodule of moqui-runtime)
- `moqui/runtime/component/moqui-fop/` → growerp/moqui-fop (submodule of moqui-runtime)

Custom components tracked in growerp root, symlinked by `setup-backend.sh`:
- `backend/` → symlinked as `moqui/runtime/component/growerp`
- `pop-rest-store/` → symlinked as `moqui/runtime/component/PopRestStore`
- `mantle-stripe/` → symlinked as `moqui/runtime/component/mantle-stripe`
- `moqui-adk/` → symlinked as `moqui/runtime/component/moqui-adk`
- `moqui-mcp/` → symlinked as `moqui/runtime/component/moqui-mcp`

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

# Run all unit tests (test/ dirs, no backend; JSON results + coverage per package)
melos run test_unit
python3 ci/bloc_coverage.py   # reprint the bloc coverage report (test_unit prints it at the end)

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

# Backend Spock tests (backend/src/test/groovy) + coverage report
./gradlew :runtime:component:growerp:test
(cd runtime/component/growerp && python3 ci/service_coverage.py)
# beside a running dev backend: own H2 db (load it once with the same env var);
# never a second `java -jar moqui.war` from moqui/, it deletes the shared execwartmp
entity_ds_database=growerptest ./gradlew :runtime:component:growerp:test

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
