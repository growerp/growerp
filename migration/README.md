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
├── run.sh              runs the services of one version
├── 1.16.16/services.txt
├── ...
└── next/services.txt   migrations for the version not yet released
```

`services.txt` has one service per line, optionally followed by `name=value`
parameters (space separated, no spaces inside a value). Lines starting with `#`
describe the migration.

## Running

Run each version's migrations once, after that version is deployed. When a server
skips versions, run every version directory in between, oldest first. All services
are idempotent, so running one twice changes nothing.

```bash
MOQUI_PASSWORD=... migration/run.sh next https://backend.growerp.org
MOQUI_PASSWORD=... migration/run.sh 1.19.3          # default http://localhost:8080
```

`run.sh` posts each service to `/apps/tools/Service/ServiceRun/runJson` with basic
auth (`MOQUI_USER`, default `SystemSupport`) and prints the result. Each service
reports what it changed, for example `{"replaced": 3, "renamed": 3}`. A failing
service stops the run.

## Adding a migration

1. Write the service in the backend with `verb="migrate"`. Make it idempotent and
   give it out-parameters that count what it changed.
2. Add it to `next/services.txt` with a comment saying what it fixes.
3. When "update staging" creates the version, rename `next/` to that version
   (for example `git mv migration/next migration/1.21.1`) and start a new empty
   `next/`.

## Versions

| Version | Services |
|---|---|
| 1.16.16 | `migrate#GeminiApiKeyToLlmConfig` |
| 1.17.16 | `migrate#StaleLlmModelNames` |
| 1.18.0 | `migrate#UserGroups`, `migrate#RestAuthz` |
| 1.19.3 | `migrate#CourseProducts` |
| next | `migrate#AccountingSetupMenu` |

Versions before 1.21 are the first release tag that contained each service.
