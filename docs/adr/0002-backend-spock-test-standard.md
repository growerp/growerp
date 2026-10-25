# 2. Backend Spock test standard

Date: 2026-10-25. Status: accepted.

## Context

The growerp Moqui component has about 630 `growerp.100.*` services, and the Flutter
integration tests were the only thing exercising them. Those tests are slow and need
a display. Six Spock specs existed (currency, subscriptions, website forms/chat,
communications, Substack, X), and nothing measured what the specs reached.

## Decision

Every service area of the component has a Spock spec in `backend/src/test/groovy/`
that calls the services the way the frontend does. A coverage report shows what
the specs reach.

- **Run**: backend not running against the same database, then
  `cd moqui && ./gradlew :runtime:component:growerp:test`. A new spec class is
  added to the `include` list in `backend/build.gradle`. The CI `status` workflow
  runs the specs in the `backend-tests` job on a freshly loaded H2 database.
- **Beside a dev backend**: the test JVM always uses its own Bitronix tx log
  (`backend/build/txlog`). Use a separate H2 database via the env var:
  `entity_ds_database=growerptest ./gradlew ...`, loaded once with
  `entity_ds_database=growerptest java -jar moqui.war load ...`. Never run a
  second `java -jar moqui.war` from `moqui/` while one is running: the war
  launcher deletes the shared `execwartmp`, which breaks the running backend.
- **Tenants**: `GrowerpTestSupport.tenant(ec, '<Key>')` registers a tenant the
  way the app does (`create#Tenant` + `complete#TenantSetup`, no demo data), with
  GROWERP set up first. It logs in as that tenant's admin. Tenants are found again
  by admin email, so reruns on the same database reuse them. Records a spec
  creates get a per-run suffix (`run`) in their names. Specs that check tenant
  isolation take a second tenant (`'<Key>Other'`).
- **Style**: one spec per service file, `Specification` with `@Shared ec`,
  `given/when/then` labels, features named as behaviour ("a purchase order is
  approved and its shipment received into a location"). Pass the maps the
  frontend sends (whole documents on update, `itemType`/`product` items, enum
  values such as `planning`, `FinDocApproved`). Assert `!ec.message.hasError()`
  after each write. Numbers come back as strings, so compare `as BigDecimal`.
- **Bugs**: a test that reproduces an open bug stays, annotated
  `@PendingFeature(reason = '<issue url>')`. It is reported as skipped while it
  fails and fails once the bug is fixed, which is the reminder to remove the
  annotation.
- **Coverage**: `cd backend && python3 ci/service_coverage.py` (`--json`,
  `--markdown`). Per service file it shows:
  - **called**: services the specs called, out of those defined.
    `ServiceCoverageExtension` (a Spock global extension) reads them from each
    spec's artifact execution history into `build/service-hits.json`.
  - **code**: the share of code blocks (JaCoCo probes) of the called services
    that ran. Moqui compiles service actions at runtime into classes named after
    the service (`growerp_100_X_get_Y`). Their code sits in a `run()` that
    Groovy 5 marks `@Generated`, which the JaCoCo report drops, so the
    `jacocoProbes` task reads the probes from `build/jacoco/test.exec` into
    `build/jacoco/probes.json`.
  - Compiled `src/main` Groovy is covered by lines in the regular JaCoCo report
    (`build/reports/jacoco/test/html`).

  The status page links `backend-coverage.html`, which includes the services
  not called yet.

## Consequences

- 8 new specs (party, catalog, inventory, activity, CRM, orders/invoices/payments,
  ledger) plus the 6 existing ones. 65 features pass, 4 are pending. 104 of 628
  services are called, and 44% of the code blocks of those services run.
- Writing the specs found bugs #48–#51, #53–#55. #48 was a cross-tenant hole:
  `entity-find-one` ignores non-key fields when the full primary key is given.
- Services that depend on external APIs (AI, mail providers, social platforms,
  Stripe) are not covered. Moqui's async services (`registerOnCommit`,
  `async="true"`) run on other threads and are not counted as called.
