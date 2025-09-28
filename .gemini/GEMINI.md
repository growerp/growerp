# GrowERP AI Coding Agent Instructions

This guide provides essential knowledge for AI coding agents working in the GrowERP codebase. It covers architecture, workflows, conventions, and integration points to maximize productivity and code quality.

## 🏛️ Big Picture Architecture
GrowERP is an open-source, multi-platform ERP system designed to streamline business operations. It runs on Android, iOS, Web, Linux, and Windows, using Flutter for the frontend and Moqui for the backend. Comprehensive documentation and support are available at [https://www.growerp.com](https://www.growerp.com).
  1. Packages starting with `growerp_` are domain-related building blocks (e.g., `growerp_core`, `growerp_models`, `growerp_user_company`). These implement business logic and can be composed into applications.
  2. Other packages are complete applications for end users, built by composing building blocks. These can be built and deployed directly.
  State management uses BLoC (`flutter_bloc`).
**Backend**: Backend components are located in `moqui/runtime/component/`. This includes the `growerp` component, which contains GrowERP-specific functions and provides multi-company functionality. Other Moqui components in this directory provide entities, services, and REST APIs. Data flows via REST between frontend and backend.
**Integration**: Communication is via REST APIs (see `docs/basic_explanation_of_the_frontend_REST_Backend_data_models.md`).

## 🛠️ Developer Workflows
  ```bash
  dart pub global activate melos # one-time setup
  melos clean
  melos bootstrap
  melos build
  melos l10n
  ```
  - Locally: `melos test`
  - Headless (Docker): `./build_run_all_tests.sh`
  - Emulator and backend services are started via Docker Compose for headless runs.
**Backend (Moqui)**: All commands run from the `moqui` directory:
  - Initial setup:
    ```bash
    ./gradlew build
    java -jar moqui.war load types=seed,seed-initial,install no-run-es
    ```
  - Clean and rebuild database:
    ```bash
    ./gradlew cleandb
    java -jar moqui.war load types=seed,seed-initial,install no-run-es
    ```
  - Start backend:
    ```bash
    java -jar moqui.war no-run-es
    ```
## missing flutter and or dart execute:
```sh
  #!/bin/bash
        FLUTTER_DIR="/tmp/flutter_install"
        mkdir -p "$FLUTTER_DIR"
        cd "$FLUTTER_DIR"
        wget -q --show-progress https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.35.4-stable.tar.xz # Replace with desired version
        tar xf flutter_linux_3.19.6-stable.tar.xz
        export FLUTTER_ROOT="$FLUTTER_DIR/flutter"
        export PATH="$FLUTTER_ROOT/bin:$PATH"
```

## 📦 Project-Specific Conventions
- **Package Hierarchy**: Lower-level packages (e.g., `growerp_models`) are dependencies for higher-level domain packages.
- **State Management**: Use BLoC for all business logic and UI state. Events and states are defined per domain.
- **UI Composition**: Use shared templates/components from `growerp_core`.
- **Testing**: Integration tests are in each package's `example/integration_test/` directory. Emulator setup is standardized.
- **Configuration**: App-wide config via `global_configuration` package and JSON files.
- **Menu System**: Menus are configured per app via building block composition (see `GrowERP_Extensibility_Guide.md`).

## 🔗 Integration Points & External Dependencies
- **REST API**: All frontend-backend communication is via REST. Data models are defined in `growerp_models` and mapped to backend entities.
- **Stripe**: Payment integration documented in `docs/Stripe_Payment_Processing_Documentation.md`.
- **Chat/Notification**: Integrated via dedicated packages and backend services.

## 📚 Key Files & Directories
- `README.md`, `docs/README.md`: High-level and extensibility documentation
- `flutter/packages/`: All Flutter building blocks
- `moqui/`: Backend components and configuration
- `docker/`: Docker Compose files for local/dev/test environments
- `docs/`: Architecture, extensibility, and integration guides

## 📝 Example Patterns
- **Adding a Domain Package**: Create in `flutter/packages/`, depend on `growerp_core` and `growerp_models`, implement BLoC, UI, and tests.
- **Extending Backend**: Add a Moqui component in `moqui/`, define entities/services, expose REST endpoints.
- **Integration Test**: Add tests in `example/integration_test/`, run via Docker emulator.

---
For more details, see the guides in `docs/`, package-level `README.md` files, and the Obsidian vault at `GrowERPObs/`.
