# GrowERP Integration Test Infrastructure

This directory contains the Docker-based CI infrastructure for running GrowERP Flutter integration tests headlessly on **Linux desktop** with `xvfb` (virtual framebuffer) and a Moqui backend.

## Architecture Overview

The test environment is orchestrated by Docker Compose with three services:

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│     sut      │────▶│    moqui     │────▶│   postgres   │
│ (test runner)│     │  (backend)   │     │  (database)  │
│ Linux + xvfb │     │              │     │              │
└──────────────┘     └──────────────┘     └──────────────┘
   flutter test -d linux
   --dart-define=BACKEND_URL=http://moqui
```

- **sut** — Flutter test runner container; runs integration tests on Linux desktop with a virtual framebuffer (`xvfb`) at phone screen resolution (412×732 by default)
- **moqui** — GrowERP Moqui backend, configured for the `test` instance purpose and seeded with test data
- **moqui-database** — PostgreSQL 17.2, providing the database for Moqui

### Key Design Decisions

- **Linux desktop instead of Android emulator** — eliminates ADB, socat tunnels, Gradle APK builds, and emulator boot time. Tests connect to Moqui directly via Docker DNS (`http://moqui`).
- **Compile-time URL injection** — backend URL is passed via `--dart-define=BACKEND_URL=http://moqui` instead of sed-patching `app_settings.json` files. This is immune to volume mount overwrites and APK asset caching issues.
- **Phone screen emulation** — `tester.view.physicalSize` is set via `--dart-define=SCREEN_WIDTH=412 --dart-define=SCREEN_HEIGHT=732` to trigger the `MOBILE` responsive breakpoint (width ≤ 500).

## Directory Structure

```
ci/
├── README.md                    # This file
├── Dockerfile                   # Test runner image (Flutter SDK + Linux desktop deps + xvfb)
├── docker-compose-test.yml      # Compose file defining all three services
└── test/
    └── run_tests.sh             # Main test orchestration script
```

## How It Works

### 1. Environment Setup

The entry point script `build_run_all_tests.sh` (in the parent `flutter/` directory):

1. Starts the backend services (`moqui-database`, `moqui`) via Docker Compose
2. Waits for Moqui to be ready (polling its `/status` endpoint)
3. Launches the `sut` container to execute the tests

### 2. Test Runner Container (Dockerfile)

The test runner image is built from `ghcr.io/cirruslabs/flutter:stable` and includes:

- Flutter SDK with Linux desktop support enabled
- `xvfb` for headless display, GTK3 and build dependencies
- Melos for monorepo package management
- All packages bootstrapped, built, and localized

### 3. Test Execution (run_tests.sh)

The `test/run_tests.sh` script inside the `sut` container:

1. **Bootstraps the workspace** — ensures melos dependencies are resolved
2. **Verifies Moqui connectivity** — polls `$BACKEND_URL/status`
3. **Creates the initial GrowERP admin user** — on a fresh database, seed data creates the `GROWERP` owner party but no user accounts. The script calls the `Register` REST endpoint to create an admin user (`test0@example.com`) so that subsequent tests start from a known state.
4. **Runs tests** via `xvfb-run` using one of three modes:
   - **Single test file**: `TEST_FILE=path/to/test.dart`
   - **Package filter**: `PACKAGE_FILTER=catalog`
   - **All tests**: `melos run test-headless`

### 4. Backend URL Resolution

The backend URL reaches the Flutter app through compile-time defines:

```
docker-compose-test.yml
  └─ environment: BACKEND_URL=http://moqui
      └─ run_tests.sh
          └─ melos run test-headless
              └─ flutter test -d linux --dart-define=BACKEND_URL=http://moqui
                  └─ build_dio_client.dart checks String.fromEnvironment('BACKEND_URL')
                      └─ Dio baseUrl = "http://moqui/"  ✓ Direct Docker DNS
```

This eliminates the previous sed-patching approach which was fragile due to Docker volume mounts overwriting patched files.

## Usage

### Run All Tests

```bash
cd flutter
./build_run_all_tests.sh
```

### Run Tests for a Specific Package

```bash
./build_run_all_tests.sh catalog        # packages matching "catalog"
./build_run_all_tests.sh marketing      # packages matching "marketing"
```

### Run a Single Test File

```bash
./build_run_all_tests.sh packages/growerp_core/example/integration_test/dynamic_menu_test.dart
```

### Run via Docker Compose Directly

```bash
cd flutter

# Start backend
docker compose -f ci/docker-compose-test.yml up -d moqui-database moqui

# Run tests with optional filters
PACKAGE_FILTER=catalog docker compose -f ci/docker-compose-test.yml up sut

# Or run a specific test file
TEST_FILE=packages/growerp_core/example/integration_test/dynamic_menu_test.dart \
  docker compose -f ci/docker-compose-test.yml up sut

# Tear down
docker compose -f ci/docker-compose-test.yml down
```

### Run Tests Locally (without Docker)

```bash
cd flutter

# Start Moqui backend on port 8080 (see moqui/ directory)
# Then run tests directly:
BACKEND_URL=http://localhost:8080 SCREEN_WIDTH=412 SCREEN_HEIGHT=732 \
  melos run test
```

### GitHub Actions CI

Tests run automatically on push to `master`/`development` and on pull requests. See `.github/workflows/test.yml`. Manual runs can filter by package via the `package_filter` input.

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `BACKEND_URL` | `http://moqui` | REST backend URL (passed via `--dart-define`) |
| `CHAT_URL` | `ws://moqui` | WebSocket URL (passed via `--dart-define`) |
| `SCREEN_WIDTH` | `412` | Logical screen width in px for phone emulation |
| `SCREEN_HEIGHT` | `732` | Logical screen height in px for phone emulation |
| `PACKAGE_FILTER` | *(empty)* | Only test packages matching this string |
| `TEST_FILE` | *(empty)* | Run a single test file |

## Resource Limits

| Service | Memory Limit |
|---------|-------------|
| sut (test runner) | 4 GB |
| moqui | 1.5 GB |
| postgres | 512 MB |
| **Total** | **~6 GB** |

## Troubleshooting

### Tests can't reach Moqui backend
- Backend URL is injected via `--dart-define=BACKEND_URL=http://moqui`
- Verify Moqui is ready: `docker compose -f ci/docker-compose-test.yml exec moqui curl -sf http://localhost/status`
- Check moqui logs: `docker compose -f ci/docker-compose-test.yml logs moqui`

### Display errors on Linux desktop
- The `sut` container uses `xvfb-run` for a virtual display
- If running locally without Docker: `xvfb-run flutter test -d linux integration_test/my_test.dart`

### Tests render in tablet/desktop layout instead of phone
- Ensure `SCREEN_WIDTH` and `SCREEN_HEIGHT` are set (defaults: 412×732)
- The `MOBILE` breakpoint triggers at width ≤ 500 (see `top_app.dart`)

### Stale build artifacts
- Run `flutter clean` in the package directory, or `melos exec -- flutter clean` for all packages
- The test-headless script cleans all packages before a full run

## Related Documentation

- [Integration Test Guide](../../docs/Integration_Test_Guide.md)
- [GrowERP Design Patterns](../../docs/GrowERP_Design_Patterns.md)
- [Release Process](../../docs/GrowERP_Version_Management_and_Release_Process.md)
