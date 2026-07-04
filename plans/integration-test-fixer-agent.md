# Daily "Integration Test Fixer" ADK agent (replaces GrowERP CI Monitor)

## Context

After manually root-causing and fixing the whole Integration Tests CI baseline (runs 28544005444 → 28615996222, commits da6eff52/3ad7b9f8/890e26a7), Hans wants that triage job automated: an Agent Control Center (moqui-adk) agent that runs **daily**, checks the nightly Integration Tests run, root-causes failures, and creates a fix PR when the fix is clear — replacing the old **'GrowERP CI Monitor'** agent, following its pattern. Runs on **Gemini** (`gemini-2.5-flash`) — Anthropic/Fable support in moqui-adk is deferred (AdkManager only builds Gemini models today).

## Existing pieces to reuse

- **Old agent seed**: `moqui-adk/data/CiMonitorAgentData.xml` (`CI_MONITOR_AGENT`, owner GROWERP) — loaded as `seed` via `moqui-adk/component.xml` line 12. Its 9-step instruction (getLatestTestRun → getTestExceptions → getFileContent → analyse → branch → updateFileContent → PR → email) is the pattern to keep.
- **GitHub tools** (in-process FunctionTools, auto-attached to every agent by `AdkManager.assembleFunctionTools`): `getLatestTestRun` (targets `test.yml` = Integration Tests workflow), `getTestExceptions` (parses the `summarize` job log, per mobile/desktop slice), `getMainSha`, `getFileContent`, and write tools `createBranch`/`updateFileContent`/`createPullRequest`/`addComment`/`sendEmail` (available because `toolMode` ≠ `readOnly`). Source: `moqui-adk/src/main/groovy/org/moqui/adk/GithubTool.groovy`. Needs `GITHUB_TOKEN` (env / `growerp.general.SystemSettings.githubToken`) + `GOOGLE_API_KEY`.
- **Daily-schedule pattern**: `GROWERP_OPS_DIGEST` in `backend/data/GrowerpMarketingAgentsData.xml`: `scheduleEnabled="Y" scheduleExpression="0 0 9 * * ?" schedulePrompt=...`. The per-agent ServiceJob `adk_scheduled_<id>` is created by `AdkSchedulerServices.sync#AgentJob` (auto via create/update service, or backfilled within a minute by the master loop).

## Changes

### 1. Fix GithubTool default branch (bug: hardcodes `main`, repo uses `master`)
`moqui-adk/src/main/groovy/org/moqui/adk/GithubTool.groovy`:
- Add `resolveBaseBranch()`: `GITHUB_BRANCH` env → `growerp.github.branch` system property → `'master'` default (mirror `resolveRepo()` style).
- `getMainSha` line ~331: `git/ref/heads/${resolveBaseBranch()}`; update its @Schema description.
- `createPullRequest` line ~522: `base: base ?: resolveBaseBranch()`.
- Also update instruction references (`ref='main'`) in the new agent seed to use `master`.

### 2. Replace the agent seed record
Rewrite `moqui-adk/data/CiMonitorAgentData.xml` (keep file name so `component.xml` stays untouched) with ONE new record:
- `adkAgentConfigId="INTEGRATION_TEST_FIXER"`, `agentName="Integration Test Fixer"`, `ownerPartyId="GROWERP"`, `modelName="gemini-2.5-flash"`, `llmProvider="gemini"`, `enabled="Y"`.
- Schedule: `scheduleEnabled="Y" scheduleExpression="0 0 9 * * ?"` (daily 09:00, after the ~03:00 nightly CI run), `schedulePrompt` = "Check last night's Integration Tests run; triage failures and create a fix PR if a clear fix exists; email the digest."
- No `toolMode` (same as old agent → full in-process tools incl. GitHub writes + sendEmail).
- `instruction`: keep the old agent's step structure but upgrade with the triage method proven in this session:
  - If latest run green → short "CI green" email, stop.
  - Get exceptions for BOTH mobile and desktop slices; list ALL failures in the digest.
  - Classify before fixing: infra ("Service not found …" = missing component/mount, not a test bug), known flake classes (adjacent-tab/ensureVisible, autocomplete overlay obscuring buttons, `Bad state: No element` lazy finders, layout-dependent labels/keys like 'N' vs 'No', duplicate test-data names, external image 500s), genuine regression.
  - Fix at most ONE failure per run, only when the root cause is certain and the fix is a minimal single-file change; never modify files just to silence a test; branch `fix/ci-<type>-<timestamp>` from `master`, PR against `master` (never push master directly).
  - Always end with a `sendEmail` digest to the commit author (old STEP 9 pattern): run status, per-failure root-cause analysis, action taken (PR link) or recommendation.
- Header comment: note it replaces GrowERP CI Monitor and the required env vars.

### 3. Remove the old agent from the live local DB
Seed reload upserts by PK only, so the old row must be removed explicitly on existing databases:
- On the local backend: delete `CI_MONITOR_AGENT` via the ADK REST/service (`delete#AdkAgentConfig`) or entity REST; then load the new seed: `cd moqui && java -jar moqui.war load types=seed location=component://moqui-adk/data/CiMonitorAgentData.xml` (or create via `create#AdkAgentConfig` REST so `sync#AgentJob` fires immediately).
- Fresh databases (CI, new installs) just get the new record from component seed.

## Verification

1. Local backend running: confirm old agent gone and new one present — `GET rest/s1/growerp/100/AdkAgentConfig` (or entity REST `e1/moqui.adk.AdkAgentConfig`).
2. Confirm per-agent ServiceJob exists: `e1/moqui.service.job.ServiceJob/adk_scheduled_INTEGRATION_TEST_FIXER` with cron `0 0 9 * * ?` (appears ≤1 min after creation via master-loop backfill).
3. Manual run: call `AdkSchedulerServices.run#ScheduledAgent` with `adkAgentConfigId=INTEGRATION_TEST_FIXER` (needs `GITHUB_TOKEN` + `GOOGLE_API_KEY` on the backend). Expect: it fetches the latest run (currently green after 890e26a7) and reports "CI green" without touching GitHub; verify no branch/PR was created.
4. Compile check for the GithubTool change: `cd moqui && ./gradlew :runtime:component:moqui-adk:build`.
5. Commit `moqui-adk/` changes in the growerp root repo (vendored component) — do not push unless asked.
