# GrowERP Integration Test Infrastructure

This directory contains the Docker-based CI infrastructure for running GrowERP Flutter integration tests headlessly against a real Android emulator and Moqui backend.

## Architecture Overview

The test environment is orchestrated by Docker Compose with four services:

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│     sut      │────▶│   emulator   │     │    moqui     │────▶│   postgres   │
│ (test runner)│     │  (Android)   │     │  (backend)   │     │  (database)  │
└──────────────┘     └──────────────┘     └──────────────┘     └──────────────┘
      │                                         ▲
      └─────────────────────────────────────────┘
                    REST API (http://moqui)
```

- **sut** — the Flutter test runner container; connects to the emulator via ADB, installs the app, and executes integration tests
- **emulator** — a headless Android emulator (API 34, x86_64) with software rendering and snapshot support for fast startup
- **moqui** — the GrowERP Moqui backend, configured for the `test` instance purpose and seeded with test data
- **moqui-database** — PostgreSQL 17.2, providing the database for Moqui

## Directory Structure

```
ci/
├── README.md                    # This file
├── Dockerfile                   # Test runner image (Flutter SDK + tools)
├── docker-compose-test.yml      # Compose file defining all four services
├── emulator/                    # Headless Android emulator image
│   ├── Dockerfile               # Emulator image definition (Ubuntu + Android SDK)
│   ├── README.md                # Emulator-specific documentation
│   ├── entrypoint.sh            # Starts ADB redirect and emulator
│   ├── run_emulator.sh          # Launches emulator binary with correct flags
│   ├── adb_redirect.sh          # Forwards ADB ports to host network interface
│   ├── prepare_snapshot.sh      # One-time script to boot and save a CI snapshot
│   └── hardware/                # AVD hardware configuration files
│       └── config_34.ini        # Hardware config for API 34
└── test/
    ├── run_tests.sh             # Main test orchestration script
    └── set_app_settings.sh      # (Deprecated) URL patching now done in Dockerfile
```

## How It Works

### 1. Environment Setup

The entry point script `build_run_all_tests.sh` (in the parent `flutter/` directory) performs these steps:

1. Copies the `flutter/` directory to `/tmp/growerp` for an isolated test run (avoids modifying source files)
2. Copies `moqui/runtime/component` for the Moqui container volume mount
3. Starts the backend services (`moqui-database`, `moqui`, `emulator`) via Docker Compose
4. Waits for Moqui to be ready (polling its `/status` endpoint)
5. Launches the `sut` container to execute the tests

### 2. Test Runner Container (Dockerfile)

The test runner image is built from `ghcr.io/cirruslabs/flutter:stable` and includes:

- Flutter SDK with Android build tools pre-installed
- Pre-cached Android SDK components (build-tools 35.0.0, platforms 34/36, NDK, CMake)
- Melos for monorepo package management
- All packages bootstrapped, built, and localized
- `app_settings.json` files pre-configured to point at `http://moqui` (the Docker network hostname)

### 3. Emulator Container

The emulator runs a headless Android API 34 (x86_64) instance with:

- Swiftshader software rendering (no GPU required)
- Snapshot support for fast CI startup
- ADB ports forwarded to the container network interface
- Health check that verifies `sys.boot_completed` via ADB

See [emulator/README.md](emulator/README.md) for build and configuration details.

### 4. Test Execution (run_tests.sh)

The `test/run_tests.sh` script is the main test orchestrator inside the `sut` container:

1. **Resolves the emulator** — discovers the emulator container's IP via DNS, connects via ADB
2. **Waits for the device** — polls `adb devices` until the emulator reports as online and fully booted
3. **Patches app_settings.json** — rewrites `databaseUrlDebug` and `chatUrlDebug` to use Docker hostnames
4. **Runs tests** using one of three modes:
   - **Single test file**: `TEST_FILE=path/to/test.dart` runs a specific test
   - **Package filter**: `PACKAGE_FILTER=catalog` runs tests for matching packages
   - **All tests**: runs `melos run test-headless` across all packages

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

# Start backend and emulator
docker compose -f ci/docker-compose-test.yml up -d moqui-database moqui emulator

# Run tests with optional filters
PACKAGE_FILTER=catalog docker compose -f ci/docker-compose-test.yml up sut

# Or run a specific test file
TEST_FILE=packages/growerp_core/example/integration_test/dynamic_menu_test.dart \
  docker compose -f ci/docker-compose-test.yml up sut

# Tear down
docker compose -f ci/docker-compose-test.yml down
```

## Test Structure

Integration tests live in each package's `example/integration_test/` directory:

```
packages/
├── growerp_core/example/integration_test/
├── growerp_catalog/example/integration_test/
├── growerp_user_company/example/integration_test/
├── growerp_order_accounting/example/integration_test/
├── growerp_chat/example/integration_test/
├── growerp_inventory/example/integration_test/
├── growerp_marketing/example/integration_test/
├── growerp_sales/example/integration_test/
├── growerp_activity/example/integration_test/
├── growerp_courses/example/integration_test/
├── growerp_outreach/example/integration_test/
└── growerp_website/example/integration_test/
```

Tests are Flutter integration tests that run on the Android emulator, communicating with the Moqui backend over Docker networking.

## Resource Limits

The Docker Compose file enforces memory limits to prevent OOM issues:

| Service | Memory Limit |
|---------|-------------|
| sut (test runner) | 6 GB |
| emulator | 4 GB |
| moqui | 1.5 GB |
| postgres | 512 MB |

The Gradle daemon is disabled (`-Dorg.gradle.daemon=false`) to prevent memory accumulation across test runs. The Moqui JVM heap is capped at 768 MB.

## Troubleshooting

### Emulator fails to start
- Ensure `/dev/kvm` is available on the host (required for x86_64 emulation)
- The emulator container runs in `privileged` mode with the KVM device mounted
- Check emulator health: `docker compose -f ci/docker-compose-test.yml ps`

### Tests can't connect to emulator
- The test runner resolves `emulator` via Docker DNS; verify the emulator container is healthy
- ADB connection timeout is 300 seconds; check `docker logs emulator` for startup issues

### Tests can't reach Moqui backend
- `app_settings.json` files must contain `http://moqui` as the backend URL
- The run_tests.sh script patches these automatically at runtime
- Verify Moqui is ready: `docker compose -f ci/docker-compose-test.yml exec moqui curl -sf http://localhost/status`

### Permission errors removing /tmp/growerp
- Docker creates files as root; the build script attempts `sudo rm -rf` if needed
- Alternatively: `sudo rm -rf /tmp/growerp`

### Stale emulator lock files
- The entrypoint script automatically cleans up `*.lock` files from previous runs
- If the emulator still fails, manually remove: `docker compose -f ci/docker-compose-test.yml down -v`

## Related Documentation

- [GrowERP Version Management and Release Process](../../docs/GrowERP_Version_Management_and_Release_Process.md)
- [Release Tools](../release/README.md)
- [Emulator Image](emulator/README.md)
