# Data migrations

One-time services that bring existing data up to date after a release, kept per
version. A seed reload adds and updates rows but never removes or rewrites data
that tenants already copied or changed, such as cloned menus, user group
memberships or old settings. The migration services handle those cases.

The services themselves live in the backend component (`backend/service/...`,
verb `migrate`), because Moqui only loads services from there. This directory
records which ones belong to which version and runs them.

## Layout

```
migration/
├── README.md
├── run.sh              runs the services of one minor version
├── deploy.sh           runs those of a deployed version, used by the workflows
├── release.sh          moves next/ to the minor version of a new release
├── 1.16/services.txt   migrations of all 1.16.x versions
├── ...
└── next/services.txt   migrations for the version not yet released
```

`services.txt` has one service per line, optionally followed by `name=value`
parameters (space separated, no spaces inside a value). Lines starting with `#`
describe the migration.

## Running

Migrations are grouped per minor version: `1.21/` holds those of every 1.21.x.
After deploying a version, run its minor version directory. When a server skips
minor versions, run every directory in between, oldest first. All services are
idempotent, so running a directory again (after the next patch) changes nothing.

The workflows do this themselves with `deploy.sh <version> <url>`, which runs the
minor version directory of that version and retries while the new backend starts:

- **Update Staging**, job `migrate-staging`, after a new backend version is
  deployed: secret `TEST_SYSTEMSUPPORT_PASSWORD` (SystemSupport on backend.growerp.org).
- **Update Production**, when moqui is synced: the version production runs, its
  list taken from that version's tag. Secret `PROD_SYSTEMSUPPORT_PASSWORD` (SystemSupport
  on backend.growerp.com).

The store review backend is a copy of the staging database, so it is migrated
already. By hand:

```bash
MOQUI_PASSWORD=... migration/run.sh next https://backend.growerp.org
MOQUI_PASSWORD=... migration/run.sh 1.21            # default http://localhost:8080
```

`run.sh` posts each service to `/apps/tools/Service/ServiceRun/runJson` with basic
auth (`MOQUI_USER`, default `SystemSupport`) and prints the result. Each service
reports what it changed, for example `{"replaced": 3, "renamed": 3}`. A failing
service stops the run.

## Adding a migration

1. Write the service in the backend with `verb="migrate"`. Make it idempotent and
   give it out-parameters that count what it changed.
2. Add it to `next/services.txt` with a comment saying what it fixes.
3. Nothing else: when "update staging" builds a new backend version (for example
   1.21.3), `release.sh` appends `next/` to that minor version directory (`1.21/`),
   starts a new empty `next/` and rebuilds the table below, in the version commit.

## Versions

| Version | Services |
|---|---|
| 1.16 | `migrate#GeminiApiKeyToLlmConfig` |
| 1.17 | `migrate#StaleLlmModelNames` |
| 1.18 | `migrate#UserGroups`, `migrate#RestAuthz` |
| 1.19 | `migrate#CourseProducts` |
| 1.20 | `migrate#StaleLlmModelNames` |
| 1.21 | `migrate#AccountingSetupMenu` |
| next |  |

Directories before 1.21 hold the minor version of the first release tag that
contained each service.
