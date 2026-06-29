# Plan: GrowERP CI Monitor ADK Agent

## Context
GitHub Actions integration tests for growerp/growerp emit Flutter exceptions in job summaries.
The agent should: fetch the latest failed CI run → extract the first mobile Flutter exception →
locate the source → generate a fix → push to a new branch → create a PR → email the commit author.
Uses the existing Moqui ADK infrastructure (Java/Groovy, NOT Python ADK).

---

## Files to Create / Modify

### 1. NEW — `GithubTool.groovy`
**Path:** `moqui/runtime/component/moqui-adk/src/main/groovy/org/moqui/adk/GithubTool.groovy`

Follow `EmailTool.groovy` exactly: `package org.moqui.adk`, `@Schema` annotations from
`com.google.adk.tools.Annotations.Schema`, static methods, each runs in a background Thread
(same `Map<String, Object>[] result = [null]` / `Throwable[] err = [null]` pattern).
Token: `System.getenv('GITHUB_TOKEN') ?: System.getProperty('growerp.github.token')`.

**Seven static methods:**

| Method | GitHub API call | Notes |
|---|---|---|
| `getLatestTestRun()` | `GET /repos/growerp/growerp/actions/workflows/test.yml/runs?per_page=5&status=failure` | Returns runId, conclusion, headCommitAuthor/Email/Message |
| `getTestExceptions(runId, format)` | List artifacts → download zip (2-step: 302 redirect to S3, no auth on S3 leg) → parse `test_output.log` | Strips Docker prefix `s/^[^|]*\| *//`; extracts blocks between `══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞═════` markers; returns only app-level frames (skip `package:flutter/`, `dart:`) |
| `getFileContent(path, ref)` | `GET /repos/growerp/growerp/contents/{path}?ref={ref}` | Decode with `Base64.getMimeDecoder()` (GitHub wraps base64 with newlines); returns `{content, sha}` |
| `createBranch(branchName, fromSha)` | `POST /repos/growerp/growerp/git/refs` | body `{ref:"refs/heads/{name}", sha:fromSha}` |
| `updateFileContent(path, commitMessage, content, sha, branch)` | `PUT /repos/growerp/growerp/contents/{path}` | Encode content to base64 inside tool (agent passes plain text); include `sha` only if non-empty |
| `createPullRequest(title, body, head, base)` | `POST /repos/growerp/growerp/pulls` | Returns `{prUrl, prNumber}` |
| `addComment(prNumber, body)` | `POST /repos/growerp/growerp/issues/{prNumber}/comments` | Works for both PRs and issues |

**Redirect pattern for artifact zip download:**
```groovy
conn.setInstanceFollowRedirects(false)
String location = conn.getHeaderField('Location')
// Fetch location WITHOUT Authorization header (S3 pre-signed URL rejects extra auth)
HttpURLConnection s3conn = new URL(location).openConnection()
byte[] zipBytes = s3conn.inputStream.bytes
```

**Thread timeouts:** `getTestExceptions` = 90 000 ms; all others = 20–30 000 ms.

---

### 2. MODIFY — `AdkManager.groovy`
**Path:** `moqui/runtime/component/moqui-adk/src/main/groovy/org/moqui/adk/AdkManager.groovy`

After line 129 (existing `EmailTool readEmails` registration, before `if (mcpToolset)`), add:
```groovy
allTools.addAll(com.google.adk.tools.FunctionTool.create(GithubTool.class, 'getLatestTestRun'))
allTools.addAll(com.google.adk.tools.FunctionTool.create(GithubTool.class, 'getTestExceptions'))
allTools.addAll(com.google.adk.tools.FunctionTool.create(GithubTool.class, 'getFileContent'))
allTools.addAll(com.google.adk.tools.FunctionTool.create(GithubTool.class, 'createBranch'))
allTools.addAll(com.google.adk.tools.FunctionTool.create(GithubTool.class, 'updateFileContent'))
allTools.addAll(com.google.adk.tools.FunctionTool.create(GithubTool.class, 'createPullRequest'))
allTools.addAll(com.google.adk.tools.FunctionTool.create(GithubTool.class, 'addComment'))
```
No import needed — same package.

---

### 3. NEW — `CiMonitorAgentData.xml`
**Path:** `moqui/runtime/component/moqui-adk/data/CiMonitorAgentData.xml`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<entity-facade-xml type="seed">
  <moqui.adk.AdkAgentConfig
      adkAgentConfigId="CI_MONITOR_AGENT"
      agentName="GrowERP CI Monitor"
      modelName="gemini-2.0-flash"
      llmProvider="gemini"
      enabled="Y"
      scheduleEnabled="N"
      description="Monitors GitHub Actions CI and creates fix PRs for Flutter exceptions"
      schedulePrompt="Check for CI failures and create a fix PR for the first Flutter exception found."
      instruction="[see system prompt below]"/>
</entity-facade-xml>
```

**System prompt** (value of `instruction`):
```
You are the GrowERP CI Monitor Agent.
Token budget is limited — handle ONE exception per run.

STEP 1 — getLatestTestRun(). If conclusion != 'failure', say "CI green" and stop.
  Save: runId, headCommitAuthor, headCommitEmail, headCommitMessage.

STEP 2 — getTestExceptions(runId, format="mobile").
  If empty, try format="desktop". If still empty, say "no Flutter exceptions found" and stop.
  Use ONLY the first exception. Save: exceptionType, message, stackTrace (app frames only), packageSlice.

STEP 3 — Identify affected file from app-level stack frames (frames containing "growerp" or "flutter/packages").
  Path pattern: flutter/packages/<packageName>/lib/src/<file>.dart
  Call getFileContent(path=<affected path>, ref="main").
  Read only the relevant method/widget section.

STEP 4 — Analyse root cause. Generate a minimal targeted fix. Do NOT refactor, rename, or change test files.

STEP 5 — Get HEAD SHA: call getFileContent(path="README.md", ref="main"). Use its sha as branch base.

STEP 6 — createBranch(branchName="fix/ci-flutter-<exceptionType>-<unix_ts>", fromSha=<sha from step 5>).

STEP 7 — Get current file SHA: call getFileContent(path=<affected path>, ref="main").
  Call updateFileContent(path=<path>, commitMessage="fix: resolve <exceptionType> in <pkg>",
    content=<full corrected file>, sha=<file sha>, branch=<branch>).

STEP 8 — createPullRequest(title="fix(ci): resolve <exceptionType> in <pkg>",
  body="## Problem\nCI run <runId> ...\n**Exception:** `<type>`: <msg>\n**Root cause:** <2 sentences>\n## Fix\n<description>\n## Stack trace\n```\n<frames>\n```\n🤖 Auto-generated by GrowERP CI Monitor",
  head=<branch>, base="main"). Save prUrl, prNumber.

STEP 9 — sendEmail(toAddresses=<headCommitEmail>,
  subject="[GrowERP CI] Fix PR created for your commit",
  body="Hi <headCommitAuthor>,\n\nCI run <runId> triggered by '<headCommitMessage>' had a Flutter exception.\nFix PR: <prUrl>\n\nPlease review and merge.\n\nGrowERP CI Monitor",
  fromAddress="", ownerPartyId="{tenantId}").

Reply: "Created PR #<prNumber>: <prUrl> for <exceptionType> in <pkg>. Notified <headCommitEmail>."

Rules:
- Never call same tool twice with same args.
- If any tool returns success=false, report error and stop.
- Only fix ONE exception per run.
```

---

### 4. MODIFY — `component.xml`
**Path:** `moqui/runtime/component/moqui-adk/component.xml`

Add one line after the existing `AdkSchedulerData.xml` load-data:
```xml
<entity-factory load-data="data/CiMonitorAgentData.xml"/>
```

---

## Prerequisites for Runtime
- `GITHUB_TOKEN` env var — PAT with scopes: `repo` + `workflow` (read artifacts, create branches/PRs)
- `GOOGLE_API_KEY` env var — for gemini-2.0-flash
- Email server configured for the ownerPartyId (existing infrastructure)

---

## Verification

### "Test with first mobile error" (as requested)

1. Rebuild component: `cd moqui/runtime/component/moqui-adk && ../../gradlew build`
2. Restart Moqui with `GITHUB_TOKEN` set
3. Load seed data (auto on startup, or: `java -jar moqui.war load types=seed`)
4. Open `/adk` DevUI → select "GrowERP CI Monitor"
5. Send: `Check for CI failures and create a fix PR for the first Flutter exception found.`
6. Observe agent calls `getLatestTestRun()` → `getTestExceptions(runId, "mobile")` → reads file → creates branch → creates PR → emails author

### Manual artifact test (no full backend needed)
```groovy
// In Moqui Groovy eval, substitute a real run ID from GitHub UI:
def result = GithubTool.getTestExceptions('12345678', 'mobile')
println result
```

---

## Notes / Risks
- `getTestExceptions` downloads a zip into memory (can be 10–50 MB). If heap is tight, increase JVM `-Xmx`.
- Default `maxLlmCalls(12)` in AdkManager may be tight for 7–9 tool calls. If agent truncates, bump to 20 in `runOneOff`.
- Artifacts expire after 7 days — agent returns a clear error if expired.
- The `sha` for `getFileContent("README.md")` gives the blob SHA, NOT the commit SHA needed for `createBranch`. Need the latest commit SHA of `main`: use `GET /repos/growerp/growerp/git/ref/heads/main` → `object.sha`. Add a private helper `getMainSha()` in GithubTool, or add it as a public tool method called in step 5 instead.
  → **Fix**: replace step 5 with a dedicated `getMainSha()` tool method: `GET /repos/growerp/growerp/git/ref/heads/main` returns `{object: {sha: "..."}}`; use that sha for `createBranch`.
