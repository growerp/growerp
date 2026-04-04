# Migrating from `master` to `moqui4`: Submodule-Based Backend

## Overview

The `master` branch embedded the entire Moqui framework (~2000+ files) directly inside the `moqui/` directory of this repository. The `moqui4` branch replaces that with a **Git submodule**, so the repo stores only a commit-hash pointer. This dramatically reduces repo size and makes syncing upstream Moqui changes trivial.

The `moqui4` branch also upgrades to **Moqui 4.x** (Java 21, Shiro 2.x, Jakarta WebSocket).

---

## Repository Structure

### Before (`master`) — Physical Files

```
growerp1/
└── moqui/                  # 2000+ framework files tracked directly
    ├── framework/
    └── runtime/
        └── component/
            ├── growerp/        # GrowERP backend (tracked directly)
            ├── PopRestStore/   # E-commerce component (tracked directly)
            ├── mantle-stripe/  # Stripe integration (tracked directly)
            ├── mantle-udm/
            ├── mantle-usl/
            └── moqui-fop/
```

### After (`moqui4`) — Git Submodules

```
growerp1/
├── moqui/                  # ← git submodule → growerp/moqui-framework
│   └── runtime/            # ← nested submodule → growerp/moqui-runtime
│       └── component/
│           ├── growerp     → symlink → /growerp1/backend/
│           ├── PopRestStore → symlink → /growerp1/pop-rest-store/
│           ├── mantle-stripe → symlink → /growerp1/mantle-stripe/
│           ├── mantle-udm/ # ← submodule → growerp/mantle-udm
│           ├── mantle-usl/ # ← submodule → growerp/mantle-usl
│           └── moqui-fop/  # ← submodule → growerp/moqui-fop
├── backend/                # GrowERP component (tracked in root)
├── pop-rest-store/         # E-commerce component (tracked in root)
└── mantle-stripe/          # Stripe integration (tracked in root)
```

GrowERP's own components (`backend/`, `pop-rest-store/`, `mantle-stripe/`) remain physically tracked in the root repo. `setup-backend.sh` creates the symlinks so Moqui can find them.

---

## One-Time Setup After Checking Out `moqui4`

```bash
# 1. Pull all submodule source (downloads Moqui framework + runtime + components)
git submodule update --init --recursive

# 2. Symlink GrowERP components into Moqui's component directory
bash setup-backend.sh

# 3. Build and seed the database
cd moqui
./gradlew build
java -jar moqui.war load types=seed,seed-initial,install no-run-es
```

Start the backend:

```bash
java -jar moqui.war no-run-es
# Admin UI: http://localhost:8080/vapps  (user: SystemSupport / pass: moqui)
```

---

## Syncing Upstream Moqui Changes

This is where the submodule approach pays off. On `master` you had to manually copy upstream framework changes. On `moqui4`, two scripts handle everything:

```bash
# Step 1: Merge latest upstream moqui/mantle/* into each growerp fork
bash sync-upstream.sh

# Step 2: Update growerp1's submodule pointers and commit
bash sync-submodules.sh        # commit only
bash sync-submodules.sh --push # commit + push

git push
```

`sync-upstream.sh` merges upstream changes into these five growerp forks (all on the `growerp` branch):

| Submodule | Upstream |
|-----------|----------|
| moqui-framework | moqui/moqui-framework |
| moqui-runtime | moqui/moqui-runtime |
| mantle-udm | moqui/mantle-udm |
| mantle-usl | moqui/mantle-usl |
| moqui-fop | moqui/moqui-fop |

You can also sync a single repo:

```bash
bash sync-upstream.sh mantle-usl
```

---

## Other Changes in `moqui4`

### Moqui 4.x / Java 21 Compatibility

| Area | Change |
|------|--------|
| **Shiro 2.x** | `org.apache.shiro.util.SimpleByteSource` → `org.apache.shiro.lang.util.SimpleByteSource` |
| **Entity sequences** | `ec.entityFacade.getNextSeqId()` → `ec.entityFacade.sequencedIdPrimary()` |
| **Logger** | Inline scripts use `ec.logger.*` instead of bare `logger.*` |
| **Jakarta WebSocket** | `ChatEndpoint.groovy` compiled into `backend/lib/` via `backend/build.gradle` |

### Gradle Compatibility

- `jcenter()` replaced with `mavenCentral()` in `mantle-stripe`
- Deprecated `jar` task properties fixed for Gradle 7+/9

### CI/CD

- GitHub Actions uses **Java 21** for the Moqui build
- Docker Compose test config has `pull_policy: never` on the Moqui service — the image is always built from local source, never pulled from Docker Hub
- Backend Docker image build command:
  ```bash
  cd moqui && ./gradlew build getPostgresJdbc
  cd docker/simple && bash docker-build.sh ../.. growerp/growerp-moqui eclipse-temurin:21-jdk
  ```
