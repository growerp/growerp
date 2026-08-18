# GrowERP LLM & API Key Architecture

**Status:** Active
**Supersedes:** `GrowERP_AI_Integration_Guide.md` (retired — folded in below)

This is the architectural reference for how GrowERP talks to LLMs: which subsystems
call which model, where API keys live and how they're resolved, how the model name
is chosen, and how the monthly token quota is set and enforced. For a list of
individual AI-powered *features* (marketing content generation, onboarding chat,
video creation), see section 6 below — that catalog used to live in its own guide
and has been merged into this document.

---

## 1. Three independent LLM subsystems

GrowERP talks to LLMs through three separate code paths. They do not share a
runtime, and (with one exception, see §3) they do not share API-key resolution:

| Subsystem | Where | What it's for | Provider wired up |
|---|---|---|---|
| **ADK agent runtime** | `moqui-adk/` (`AdkManager.groovy`) | Chat agents, scheduled agents, tool-using agents (Agent Control Center) | Gemini only |
| **Backend content-gen scripts** | `backend/service/GeminiAiUtil.groovy` + 7 `generate*WithAI.groovy` scripts | One-shot marketing/CRM content generation | Gemini, Anthropic, OpenAI |
| **moqui-mcp agent tasks** | `moqui-mcp/service/AgentServices.xml` | Storefront/product AI tasks (`ProductStoreAiConfig`) | OpenAI-compatible HTTP (Bearer auth) |

The ADK runtime calls Gemini's `generateContent` REST API through the `google-adk`
Java library (`com.google.adk.models.Gemini`). The content-gen scripts all go
through `GeminiAiUtil.callLlmApi()`, which dispatches on the configured provider
to Gemini `generateContent`, the Anthropic Messages API
(`POST /v1/messages`, `x-api-key` + `anthropic-version` headers) or the OpenAI
chat completions API (`POST /v1/chat/completions`, `Authorization: Bearer`) —
raw `HttpURLConnection` in every case, no SDK and no extra jars. The file keeps
its historical name; `callGeminiApi()` is retained as a delegate so existing
callers did not have to change.

The moqui-mcp path is entirely separate: `call#OpenAiChatCompletion`
(`AgentServices.xml:52-116`) reads `apiKey`/`endpointUrl`/`modelName` straight off a
`moqui.mcp.agent.ProductStoreAiConfig` row and POSTs to an OpenAI-compatible
endpoint with a Bearer token. It does not touch `LlmConfig`, `SystemSettings`, or
`GeminiAiUtil` at all — a fully independent key store.

**Multi-provider note:** the Agent Control Center's "LLM Provider" field is a
dropdown over the providers that have an API key in System Setup, but only
`gemini` is wired to a working runner — picking another provider shows a warning
in the dialog saying the agent will register but not answer. In `AdkManager.initConfig()`
(`AdkManager.groovy:200-215`), any non-`gemini` value is stored in a side
`providerRegistry` map and the function returns without building an agent — the
log line even says so: *"HTTP routing not yet implemented"*. Setting `llmProvider`
to `openai` on an ADK agent silently produces a disabled agent, not an OpenAI-backed
one.

---

## 2. Model selection

| Subsystem | Config field | Precedence | Default |
|---|---|---|---|
| ADK | `AdkAgentConfig.modelName` (per-agent) | explicit value on the agent row → `gemini-3.5-flash-lite` | `gemini-3.5-flash-lite` |
| Content-gen | `SystemSettings.aiModelName` + `aiProvider` (per-tenant), `SystemDefault.aiModelName` + `aiProvider` (GrowERP wide) | explicit override → tenant `SystemSettings` → `SystemDefault` (`defaultId='SYSTEM'`) → per-user Moqui preference (`GEMINI_MODEL`) → env var → system property → `DEFAULT_MODEL` | `gemini-3.5-flash-lite` |

Content-gen resolution is `GeminiAiUtil.resolveModelConfig(ec, ownerPartyId,
explicitModel, explicitProvider)`, called from `callLlmApi()`. It returns the model
**and** its provider, always taken from the same level — a tenant that picked only a
model must not inherit the system default's provider, or its model would be posted to
the wrong vendor's endpoint. When a stored row has no `aiProvider` (written before the
field existed) the provider is inferred from the model id by `providerForModel()`:
`claude*` → anthropic, `gpt*`/`o<digit>*` → openai, everything else → gemini. All seven
`generate*WithAI.groovy` scripts now call the util instead of duplicating the chain.

**UI:** one shared model list, `llmModels` in
`growerp_core/lib/src/domains/common/llm_models.dart` — three Gemini and three Claude
ids, plus an "Other model…" entry that reveals a provider dropdown and a free-text
model id (this is how an OpenAI model is picked). It drives three screens:

- **System Setup** (tenant default, `system_setup_dialog.dart`) — the dropdown only
  offers models whose provider has an API key row in the form; a saved model whose key
  row was removed stays selectable, marked `(no API key)`.
- **System Defaults** (GrowERP wide, support app,
  `system_defaults_dialog.dart`) — the full list, since keys are per tenant and there
  is nothing to filter on.
- **ADK agent config** (`adk_agent_config_dialog.dart`) — provider dropdown limited to
  providers with a key, model presets limited to that provider.

---

## 3. API key storage & resolution

### Where keys are stored

| Entity | Scope | Purpose |
|---|---|---|
| `growerp.general.SystemSettings.geminiApiKey` | per-tenant | **Deprecated.** Legacy flat field, one-time-migrated to `LlmConfig` via `migrate#GeminiApiKeyToLlmConfig` (`GeneralServices100.xml`). Still read as a fallback in a few older XML services. |
| `growerp.general.LlmConfig` | per-tenant, per-provider (PK `ownerPartyId`+`llmProvider`) | **Current** tenant key store, `apiKey` field encrypted. Configured via System Setup → "LLM provider API keys". |
| `moqui.adk.AdkAgentConfig.apiKey` | per-agent | Optional override — lets one specific agent use a different key than the tenant default. |

### ADK key-resolution precedence

Multiple entry points in `AdkManager.groovy` each resolve a key, with slightly
different precedence depending on context:

- **`initConfig()`** (`AdkManager.groovy:200-323`) — takes an already-resolved
  `apiKey` param; only checks `apiKey ?: env GOOGLE_API_KEY ?: env GEMINI_API_KEY`
  (line 217) and disables the agent if all are empty. Callers are responsible for
  resolving the key before calling this.
- **`lazyInit()`** (`AdkManager.groovy:370-436`) — on startup, for each enabled
  `AdkAgentConfig` row: `cfg.apiKey` → tenant `LlmConfig` (lines 401-409). Separately
  computes a *default* key for the shared interactive agent: env vars → first
  `gemini`-provider config's borrowed key (lines 390-413).
- **`ensureInteractiveDefault()`** (`AdkManager.groovy:441-473`) — the shared
  interactive-chat runner's key: env vars (`GOOGLE_API_KEY`/`GOOGLE_GENAI_API_KEY`/
  `GEMINI_API_KEY`) → any tenant's `gemini` `LlmConfig` row → a seed key borrowed
  from a specialised agent (e.g. the CI Monitor).
- **`resolveTenantKey()`** (`AdkManager.groovy:500-541`) — used for per-tenant
  interactive agents: env vars → this tenant's `LlmConfig` → **any** tenant's
  `gemini` `LlmConfig` → this tenant's `AdkAgentConfig.apiKey` → **any** tenant's
  `AdkAgentConfig.apiKey`. (The "any tenant" fallbacks exist so a single shared
  system key, entered once, lights up chat for every tenant that hasn't configured
  their own.)
- **`ensureAgentBuilt()`** (`AdkManager.groovy:1160-1181`) — lazy per-config build:
  `cfg.apiKey` → `resolveTenantKey(cfg.ownerPartyId)`.

Net effect: an explicit key on the agent row always wins; after that, the tenant's
own `LlmConfig` row; after that, the system falls back to *any* available Gemini
key in the system (by design, so a single admin-entered key can serve every tenant
until they bring their own).

### Content-gen key resolution

`GeminiAiUtil.resolveApiKey(ec, ownerPartyId, provider, explicitKey)` is the single
entry point; every `generate*WithAI.groovy` script reaches it through `callLlmApi()`:

```
options.apiKey                                   (batch/cron callers)
  ?: LlmConfig(ownerPartyId, provider).apiKey     (System Setup, per provider)
  ?: gemini:    user preference GEMINI_API_KEY / env GEMINI_API_KEY / GOOGLE_API_KEY
     anthropic: env ANTHROPIC_API_KEY
     openai:    env OPENAI_API_KEY
  ?: throw "No API key configured for LLM provider '<provider>'"
```

The tenant `LlmConfig` step closes an earlier gap: content-gen used to read only the
per-user `GEMINI_API_KEY` preference and ignore the tenant key store entirely, so keys
entered in System Setup were unused unless a caller passed them in explicitly.
`GoogleCalendarServices100.xml` (`extract#FollowUpTodos`) still resolves the key itself
and passes it as `options.apiKey`, which is harmless — an explicit key always wins.

---

## 4. Token limits — how they're set and enforced

**Field:** `SystemDefault.llmMonthlyTokenLimit` (integer, GrowERP wide, monthly), on
the single `defaultId='SYSTEM'` row. Set by system support only, in the Support App
→ System Defaults (`support/lib/src/system_defaults/views/system_defaults_dialog.dart`,
REST `SystemDefault`, service `update#SystemDefault` guarded by `check#SupportUser`).
Empty or 0 = unlimited; seeded at 100000. The limit is applied *per tenant* — every
tenant on the system key gets that many tokens per calendar month.

Before Aug 2026 this lived on `SystemSettings.llmSystemTokenLimit`, which each tenant
could edit for itself through System Setup — a cap the capped party could raise.

**Who it applies to:** only tenants using the *shared system* Gemini key — i.e. no
own key configured. Checked in `AdkGovernanceServices.xml` (`govern#AgentAction`,
lines 113-121):

```
hasCustomLlm = AdkAgentConfig.apiKey present?  OR  tenant LlmConfig(gemini) row present?
if hasCustomLlm → skip the quota check entirely (tenant pays their own Google bill)
```

**Enforcement:** `govern#AgentAction` (`AdkGovernanceServices.xml:16`) runs before
every agent tool/service call (chat, scheduled task, or MCP tool). When quota
applies (lines 121-146):

1. Compute start-of-current-month timestamp (recomputed fresh on every call — no
   cached counter).
2. Sum `AdkActionLog.tokensTotal` for this tenant since that timestamp
   (`entity-find` iterator over all matching rows).
3. If `totalUsed >= llmMonthlyTokenLimit` → `decision = 'blocked'`, message tells the
   agent/user to add their own API key.

**Where the token counts come from:** `AdkManager.extractTokensFromEvents()`
(`AdkManager.groovy:712-724`) reads Gemini's `usageMetadata`
(`promptTokenCount`/`candidatesTokenCount`/`totalTokenCount`) off each response
event and sums them. `logChatTurn()` (`AdkManager.groovy:730-760`) writes the
result into `AdkActionLog.tokensIn/tokensOut/tokensTotal`
(`AdkEntities.xml:110-133`) asynchronously, on a background daemon thread, after
each chat turn completes.

**Visibility:** `AdkSystemUsageView` (Support App, cross-tenant) shows the raw
`AdkActionLog` rows — service name, tenant, tokens in/out, decision. There's no
aggregate "X / Y tokens used this month" bar anywhere today; to see if a tenant is
close to their limit you'd sum the log yourself or wait for the block message.

**Gap:** this quota only gates the ADK governance path. The backend content-gen
scripts (`generate*WithAI.groovy`) have no token-quota check of any kind — they'll
call Gemini regardless of `llmMonthlyTokenLimit`.

---

## 5. Quick reference

**Environment variables**

| Var | Read in | Purpose |
|---|---|---|
| `GOOGLE_API_KEY` | `AdkManager.groovy` (multiple entry points) | Highest-precedence Gemini key for the ADK runtime |
| `GOOGLE_GENAI_API_KEY` | `AdkManager.groovy` | Alternate name for the same, checked second |
| `GEMINI_API_KEY` | `AdkManager.groovy`; `GeminiAiUtil.resolveApiKey` | Gemini key fallback for both ADK and content-gen paths |
| `ANTHROPIC_API_KEY` | `GeminiAiUtil.resolveApiKey` | Anthropic key fallback when the tenant has no `LlmConfig` row (content-gen only) |
| `OPENAI_API_KEY` | `GeminiAiUtil.resolveApiKey` | OpenAI key fallback when the tenant has no `LlmConfig` row (content-gen only) |
| `GEMINI_MODEL` | `AdkManager.groovy:230`; `GeminiAiUtil.resolveModelConfig` | Env-level model override, below tenant/system-default config in precedence |

**Entities**

| Entity | PK | Key fields | Notes |
|---|---|---|---|
| `growerp.general.SystemSettings` | `ownerPartyId` | `geminiApiKey` (deprecated), `aiModelName`, `aiProvider` | Tenant-wide settings row |
| `growerp.general.SystemDefault` | `defaultId` (`SYSTEM`) | `llmMonthlyTokenLimit`, `aiModelName`, `aiProvider` | GrowERP wide defaults; system support only |
| `growerp.general.LlmConfig` | `ownerPartyId` + `llmProvider` | `apiKey` (encrypted) | Current per-tenant, per-provider key store |
| `moqui.adk.AdkAgentConfig` | `adkAgentConfigId` | `ownerPartyId`, `modelName`, `apiKey`, `llmProvider` | One row per ADK agent; `apiKey`/`modelName` override the tenant default |
| `moqui.adk.AdkActionLog` | `adkActionLogId` | `ownerPartyId`, `tokensIn`, `tokensOut`, `tokensTotal`, `decision` | Audit trail; source of truth for the monthly quota sum |

---

## 6. Feature catalog (content-generation scripts)

The services below all go through the content-gen path (§1, §3) — `GeminiAiUtil`
key/model resolution applies to each.

- **`GeminiAiUtil.groovy`** (`backend/service/GeminiAiUtil.groovy`) — shared HTTP
  helper (`call#GeminiApi` service). Retry/backoff on `429`, JSON-response cleanup,
  and the model/key resolution described in §2–3.
- **Onboarding chat** (`onboardingChat.groovy`, `onboardingSave.groovy`) — multi-turn
  setup dialogue; strict alternating user/model turns; streams A2UI JSONL widgets to
  the Flutter GenUI onboarding view; transcript saved as a private `ChatRoom` with
  `SYSTEM_SUPPORT` attached.
- **Marketing persona** (`generatePersonaWithAI.groovy`) — generates an ideal-customer
  avatar (`growerp.marketing.MarketingPersona`).
- **Content plan** (`generateContentPlanWithAI.groovy`) — PNP (Pain-News-Prize)
  weekly content plan targeting a persona; creates a `ContentPlan` + `SocialPost`
  drafts.
- **Social post drafting** (`draftSocialPostWithAI.groovy`) — publish-ready copy with
  hook, hashtags, and a "Signal of Interest Elicitor" closing question.
- **Course media** (`generateCourseMediaWithAI.groovy`) — multichannel campaign
  material (LinkedIn, Medium/Substack, email nurture sequence, YouTube script,
  Twitter/X thread, in-app help) from course details.
- **Video from script** (`generateVideoFromScript.groovy`) — Gemini composes a video
  prompt from a script, then Vertex AI (Veo 2 / Imagen) renders video or a keyframe/
  storyboard fallback. Note: this script has no `ownerPartyId` in scope, so it can't
  use the tenant `SystemSettings.aiModelName` override — it only sees the plain
  default/env/user-pref chain.
- **Landing page + assessment** (`generateLandingPageWithAI.groovy`) — one Gemini
  call produces a full landing page schema plus a 15-question Business Readiness
  Assessment (best-practice + qualification questions, scoring thresholds).

**Frontend wiring:** `[Flutter UI] → [BLoC] → [RestClient] → [Moqui XML REST] →
[Groovy script]`, REST endpoints under `rest/s1/growerp/100/`. Multi-step flows
(landing page, course media) expose loading-state BLoCs (e.g.
`LandingPageGenerationBloc`: `researchingBusiness` → `generatingContent` →
`creatingXml`/`importing`).
