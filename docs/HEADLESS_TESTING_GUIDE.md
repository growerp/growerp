# Headless Integration Testing Procedure

This document describes the current headless integration testing workflow for GrowERP, designed for rapid iteration by preserving running containers.

## Architecture

The testing environment consists of four Docker services orchestrated via `flutter/ci/docker-compose-test.yml`:

1.  **`moqui-database`**: PostgreSQL 17.2 database for the backend.
2.  **`moqui`**: The Java-based ERP backend.
    *   **Image**: `growerp/growerp-moqui:latest`.
    *   **Code Override**: Local component code (`../moqui/runtime/component`) is mounted into the container at `/opt/moqui/runtime/component`. This ensures the backend runs your latest local logic without needing a rebuild.
3.  **`emulator`**: Android emulator (`growerp/android-emulator`) for running Flutter integration tests.
    *   **Restart Policy**: `unless-stopped` - automatically restarts if it crashes.
    *   **Health Check**: Monitors emulator boot status to ensure it's ready before tests start.
4.  **`sut` (System Under Test)**: The test runner.
    *   **Image**: `growerp/flutter-test-runner:latest` (built from `flutter/ci/Dockerfile`).
    *   **Baked-in Code**: Source code, dependencies, and build artifacts are baked into the Docker image at build time (no volume mount). This ensures a clean, reproducible environment for each test run.
    *   **Pre-installed SDK Components**: The image pre-installs all Android SDK components during `docker build` to avoid runtime downloads:
        *   Android SDK licenses (auto-accepted)
        *   `build-tools;35.0.0`, `platforms;android-34`, `platforms;android-36`
        *   `ndk;28.2.13676358`, `cmake;3.22.1`
        *   Flutter Android artifacts (`flutter precache --android`)
    *   **Command**: Executes `ci/test/run_tests.sh`.
    *   **Dependency**: Waits for emulator to be healthy (`service_healthy`) before starting.

## Workflow (`build_run_all_tests.sh`)

The script `flutter/build_run_all_tests.sh` orchestrates the process with a focus on speed and state preservation.

### 1. Backend & Emulator Startup (Detached)
First, the script ensures the supporting infrastructure is running:
```bash
docker compose -f ci/docker-compose-test.yml up -d moqui-database moqui emulator
```
*   **Persistent State**: If containers are already running, they are **reused**. They are NOT destroyed or recreated unless their configuration in `docker-compose-test.yml` has changed.
*   **Startup time**: Fast (instant if already running).
*   **Emulator Health**: The emulator service includes a health check that monitors boot status (`sys.boot_completed`). The sut container waits for this health check to pass before starting tests.

### 2. Test Execution (Foreground)
Then, the script runs the actual tests:
```bash
docker compose -f ci/docker-compose-test.yml up sut
```
*   **Emulator Readiness**: The test runner (`ci/test/run_tests.sh`) performs additional verification:
    *   Resolves the emulator IP via Docker DNS (`getent hosts emulator`)
    *   Connects via `adb` with retry logic (up to 30 attempts)
    *   Waits for device boot completion with timeouts (300s for device detection, 180s for boot)
    *   Verifies the device is accessible before running tests
*   **Filters**: Accepts a package filter argument (e.g., `./build_run_all_tests.sh catalog`), passed as `PACKAGE_FILTER` environment variable.
*   **Execution**: The `sut` container starts, runs `test/run_tests.sh` inside the container, streams logs to the console, and exits when tests complete.
*   **Image Rebuild Required**: Since code is baked into the Docker image (no volume mount), you must rebuild the image after code changes:
    ```bash
    cd flutter && docker compose -f ci/docker-compose-test.yml build sut
    ```

## Usage

**Run all tests:**
```bash
./flutter/build_run_all_tests.sh
```

**Run specific package tests:**
```bash
./flutter/build_run_all_tests.sh catalog
```

## Maintenance

Since containers are not automatically destroyed:
*   **To reset the environment**: You must manually run:
    ```bash
    cd flutter && docker compose -f ci/docker-compose-test.yml down -v
    ```
*   **To rebuild the test runner image** (after code or Dockerfile changes):
    ```bash
    cd flutter && docker compose -f ci/docker-compose-test.yml build sut
    ```
*   **To update Docker images**: Run `docker pull growerp/growerp-moqui:latest` or `docker pull growerp/android-emulator:latest`.
