/*
 * This software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 *
 * To the extent possible under law, author(s) have dedicated all
 * copyright and related and neighboring rights to this software to the
 * public domain worldwide. This software is distributed without any
 * warranty.
 *
 * You should have received a copy of the CC0 Public Domain Dedication
 * along with this software (see the LICENSE.md file). If not, see
 * <http://creativecommons.org/publicdomain/zero/1.0/>.
 */
package org.moqui.adk

import com.google.adk.agents.LlmAgent
import com.google.adk.agents.RunConfig
import com.google.adk.events.Event
import com.google.adk.runner.Runner
import com.google.adk.sessions.InMemorySessionService
import com.google.genai.types.Content
import com.google.genai.types.Part
import io.reactivex.rxjava3.core.Flowable
import org.moqui.context.ExecutionContextFactory
import org.slf4j.Logger
import org.slf4j.LoggerFactory

import java.util.concurrent.ConcurrentHashMap

/**
 * Registry facade over the Google ADK Java SDK.
 *
 * Supports multiple named agent configs (one per tenant/ownerPartyId).
 * Session state is persisted via MoquiSessionService (AdkSession + AdkSessionEvent entities)
 * so history survives Moqui restarts.
 *
 * Call initConfig() for each enabled AdkAgentConfig record.
 * All session/agent methods route to the correct Runner via the registry.
 */
class AdkManager {

    protected final static Logger logger = LoggerFactory.getLogger(AdkManager.class)

    static final String APP_NAME = 'moqui-adk'
    static final String DEFAULT_CONFIG = '__default__'

    /** Sanitize an agent name so it is valid as a Gemini function name.
     *  Gemini requires: starts with letter or underscore, alphanumeric + _ . : - only, max 128 chars. */
    private static String sanitizeAgentName(String raw) {
        if (!raw) return 'agent'
        // Replace any character that is NOT [a-zA-Z0-9_.:- ] with underscore, then spaces too
        String s = raw.replaceAll('[^a-zA-Z0-9_.:\\-]', '_')
        // Ensure starts with letter or underscore
        if (s && !Character.isLetter(s.charAt(0)) && s.charAt(0) != (char)'_') s = '_' + s
        // Truncate to 128
        if (s.length() > 128) s = s.substring(0, 128)
        return s ?: 'agent'
    }

    // configId → Runner (one per enabled AdkAgentConfig)
    private static final Map<String, Runner>   registry         = new ConcurrentHashMap<>()
    // configId → LlmAgent — kept alongside Runner so runOneOff can build a fresh Runner
    private static final Map<String, LlmAgent> agentRegistry    = new ConcurrentHashMap<>()
    // ownerPartyId → configId for per-tenant routing
    private static final Map<String, String>   tenantRegistry   = new ConcurrentHashMap<>()
    // sessionId → configId — in-memory cache rebuilt on demand from DB after restart
    private static final Map<String, String>   sessionOwn       = new ConcurrentHashMap<>()
    // sessionId → completed-turn count, for throttling rolling-memory summarisation
    private static final Map<String, Integer>  turnCounts       = new ConcurrentHashMap<>()
    // configIds currently mid-build — breaks team-membership cycles during coordinator assembly
    private static final Set<String>           buildingConfigs  = ConcurrentHashMap.newKeySet()
    // Summarise a session into AdkMemory every N completed turns (env-tunable). The
    // {memory} preamble of subsequent sessions is loaded from that summary (see
    // AdkDevServlet.buildContext), giving continuity across conversations.
    private static final int SUMMARIZE_EVERY_N_TURNS = {
        try { return Math.max(1, Integer.parseInt(System.getenv('ADK_SUMMARIZE_EVERY') ?: '2')) }
        catch (Exception ignore) { return 2 }
    }()
    // configId → {provider, apiKey} for non-Google providers (future HTTP runners)
    private static final Map<String, Map>      providerRegistry = new ConcurrentHashMap<>()

    private static volatile MoquiSessionService sharedSessionService
    // ADK ArtifactService backed by the AdkArtifact entity: large binaries (PDFs/images)
    // stay out of the conversation context; agents load them on demand (LoadArtifactsTool).
    private static volatile MoquiArtifactService sharedArtifactService
    private static volatile com.google.adk.tools.mcp.McpToolset mcpToolset
    // Set true at process exit (JVM shutdown hook / destroy). Guards tool-loading so an
    // in-flight google-adk McpToolset SSE connect isn't retried while the server tears down.
    private static volatile boolean shuttingDown = false
    private static final java.util.concurrent.atomic.AtomicBoolean shutdownHookRegistered =
            new java.util.concurrent.atomic.AtomicBoolean(false)
    // configId → per-agent McpToolset. Each carries an `adk_config_id` header so the
    // MCP governance gate can identify the calling agent and enforce its tenant/scope.
    private static final Map<String, com.google.adk.tools.mcp.McpToolset> configMcpToolsets = new ConcurrentHashMap<>()
    // configId → external (tenant-registered) McpToolsets attached to that agent. Closed and
    // rebuilt on reloadConfig; closed on destroy.
    private static final Map<String, List<com.google.adk.tools.mcp.McpToolset>> configExternalToolsets = new ConcurrentHashMap<>()
    private static volatile String mcpApiKey = null
    static  volatile Map<String, Object>  currentConfig = [:]

    static final String CONTEXT_PREAMBLE = '''\
You are running inside a GrowERP / Moqui ERP system.

Current execution context (always up-to-date for this session):
  User ID          : {userId}
  Username         : {username}
  Full name        : {userFullName}
  Organization     : {organizationName}
  Company pseudo ID: {companyPseudoId}
  Owner party ID   : {tenantId}
  Time zone        : {timeZone}
  Locale           : {locale}

Use this context when the user asks questions like "who am I?", "what company is this?",
"which tenant?", "what is my username?", "what is my company ID?", etc. — you MUST answer using exactly this template:
The current logged in user is {username} ({userFullName}). You are part of the {organizationName} organization (ID: {companyPseudoId}, owner: {tenantId}).
Do not call any tool for this.

MEMORY (continuity across conversations):
{memory}

STABLE DOMAIN KNOWLEDGE (OKF):
The curated OKF knowledge bundle holds stable domain knowledge: entity/data-model definitions
with schemas and relationships, business structure, module relationships. For questions like
"what fields does X have?", "what is related/joined to X?", "how is the data model structured?"
use 'okf_index' to orient, 'okf_load_concept' (path, e.g. 'tables/OrderHeader.md') to read one
concept, and 'okf_follow' to see a concept's related concepts. Load only the concepts you need;
cite the concept path in your answer. Prefer OKF over searchKnowledge for these questions.

COMPANY KNOWLEDGE (RAG):
Use the 'searchKnowledge' tool to answer questions about THIS company's own documents, policies,
procedures or product information that are NOT in the live ERP data. Pass the user's question as
'query'. Answer ONLY from the returned passages and cite them; if nothing relevant is returned,
say you don't have that information rather than guessing. Use the Moqui tools for live ERP data
(orders, parties, products), OKF for stable data-model/domain structure, and searchKnowledge for
documents/policies and bulk/operational content.

MOQUI SERVICES — how to run business logic:
Service names (verb#Noun, e.g. generate#MasterContent) are NOT tools — never call one as a tool.
Run them with the 'moqui_execute_service' tool: {serviceName:"...", parameters:{...}}. Never invent
or guess a service name (no getPending#X, updateContent#X): when unsure of the exact name use
'moqui_search_services' with a noun keyword first, then 'moqui_get_service_details' for its
parameters, then execute exactly the returned name. Prompts ('moqui_prompts_get') are documentation
templates, not services.

SCREEN NAVIGATION — opening operational app screens
The GrowERP front-end (Flutter) screens available in this session are listed in this
catalog (JSON: widgetName, description, keywords, parameters):
{screenCatalog}

When the user wants to reach or operate a screen — phrases like "enter/create/add",
"show/list/open/find", "edit", "approve", "receive" — choose the best-matching entry from
the catalog above (match the widgetName, keywords and description), respond with ONE short
sentence, then append a fenced action block the app executes (single object or an array):
```growerp-action
{"action":"navigate","widget":"<widgetName>","params":{...},"label":"<chip text>"}
```

Pick the action and widget from the catalog by intent:
- VIEW / LIST a kind of record → action "navigate" to the matching *List widget
  (omit `route`; the app resolves it from the widget name). e.g. "show products" →
  {"action":"navigate","widget":"ProductList"}.
- CREATE a new record → action "dialog" with that entity's *Dialog widget and NO id.
  e.g. "add a product" → {"action":"dialog","widget":"ProductDialog"}.
  PREFILL: read the field values from the USER'S message and put them in `params` (using the
  field names from that widget's catalog `parameters`), plus "_aiPrefill":true. The example
  below shows only the JSON SHAPE — the tokens in angle brackets are placeholders you MUST
  replace with the actual words from the user's message; never copy the placeholder text or any
  example name/email:
  {"action":"dialog","widget":"UserDialog","params":{"firstName":"FIRST_NAME_FROM_USER","lastName":"LAST_NAME_FROM_USER","email":"EMAIL_FROM_USER","role":"employee","_aiPrefill":true}}.
- OPEN / EDIT a specific record → action "dialog" with the *Dialog widget and the id in
  `params`, using the id parameter NAMED in that widget's catalog `parameters` (e.g.
  productId, partyId, locationId). e.g. "edit product DEMO_1" →
  {"action":"dialog","widget":"ProductDialog","params":{"productId":"DEMO_1"}}.
  You may also include field values to change alongside the id (same prefill rule).

Rules:
- Use only widgetNames present in the catalog; read each widget's `parameters` for the
  exact arg names it accepts (both id params and prefillable fields). Put inputs in `params`.
- `route` is optional and usually omitted (the app resolves it from the widget name).
- Emit the block ONLY when a screen should open; otherwise just answer in text.
- USE THE USER'S EXACT VALUES verbatim in `params`. Never invent, anonymize, or substitute a
  value the user gave — e.g. if the user says email info@hansbakker.com, the param MUST be
  "info@hansbakker.com", never a placeholder like test1@example.com.

For CREATE ("add"/"create"/"new"): build the directive ONLY from the values in the user's latest
message. Do NOT search for, resolve, open, or copy an existing record, and do NOT use any name or
email from these instructions or earlier turns — a new record uses ONLY what the user just typed.

For OPEN / EDIT of a record the user names (not by id): resolve its id with read-only tools first
(moqui_search_services / moqui_execute_service), then emit the directive with that id.

WRITES ARE USER-CONFIRMED: you only NAVIGATE / OPEN screens — never call a service that
performs a write (create/update/approve/receive/delete). The user submits the opened,
pre-filled dialog. Order/shipment specifics still work: "enter a sales order" →
{"widget":"SalesOrderList","params":{"openNew":true}}; "approve order <id>" →
{"widget":"SalesOrderList","params":{"finDocId":"<id>","presetStatus":"approved"}};
"receive shipment <id>" → {"widget":"IncomingShipmentList","params":{"finDocId":"<id>"}}.

'''

    // ── Initialisation ────────────────────────────────────────────────────────

    /**
     * Register (or replace) one named agent config.
     * ownerPartyId may be null for a global/default config.
     */
    static synchronized void initConfig(String configId, String ownerPartyId,
                                        String agentName, String modelName,
                                        String instruction, String apiKey,
                                        String llmProvider = 'gemini',
                                        String description = null) {
        String effectiveProvider = llmProvider ?: 'gemini'

        // Non-Google providers: store in side registry for future HTTP runner; skip Google ADK init
        if (effectiveProvider != 'gemini') {
            providerRegistry[configId] = [provider: effectiveProvider, apiKey: apiKey ?: '']
            // Only a general (unnamed) interactive agent claims the tenant's chat route;
            // named/scheduled agents (e.g. CI Monitor) must not hijack interactive chat.
            if (ownerPartyId && !agentName) tenantRegistry[ownerPartyId] = configId
            logger.info("Non-Google provider '${effectiveProvider}' registered for configId='${configId}' (tenant='${ownerPartyId ?: 'global'}') — HTTP routing not yet implemented")
            return
        }

        if (!apiKey && !System.getenv('GOOGLE_API_KEY') && !System.getenv('GEMINI_API_KEY')) {
            logger.warn("No API key provided or found in environment. Disabling ADK agent configId='${configId}'.")
            return
        }

        if (apiKey) System.setProperty('GOOGLE_API_KEY', apiKey)

        try {
            // Per-agent MCP toolset: identical to the shared one but tagged with this config's
            // id (and owner) so the MCP governance gate / searchKnowledge can resolve the
            // calling agent and its tenant.
            def agentMcpToolset = buildMcpToolset(configId, ownerPartyId)

            String envModel = System.getenv('GEMINI_MODEL') ?: System.getProperty('GEMINI_MODEL') ?: 'gemini-2.5-flash-lite'
            String modelId = modelName ?: envModel
            // google-genai reads the key from the GOOGLE_API_KEY/GEMINI_API_KEY *environment*
            // variable (not a System property), so a key from System Setup must be passed to the
            // Gemini model explicitly. Fall back to the model-name String (env-based) when no key.
            def modelArg = apiKey ?
                    com.google.adk.models.Gemini.builder().modelName(modelId).apiKey(apiKey).build() :
                    modelId
            LlmAgent agent

            // Read this agent's scoping so the in-process FunctionTools (Email/GitHub) honour it
            // too — a read-only agent gets no write tools. (The MCP toolset is gated server-side
            // by the governance service.)
            String toolMode = lookupToolMode(configId)
            boolean allowWrites = toolMode != 'readOnly'

            // In-process FunctionTools (read-only set + writes when allowed), plus the MCP toolset.
            List allTools = assembleFunctionTools(allowWrites)
            if (agentMcpToolset) allTools.add(agentMcpToolset)
            // External (tenant-registered) MCP servers attached to this agent.
            loadExternalMcpToolsets(configId, ownerPartyId).each { allTools.add(it) }

            if (!agentName) {
                agent = LlmAgent.builder()
                    .name('growerp-agent')
                    .description('GrowERP / Moqui ERP assistant with access to Moqui MCP tools')
                    .instruction(CONTEXT_PREAMBLE + '''\
You are GrowERP Assistant, an AI agent for the GrowERP / Moqui ERP system.
Answer the user's questions using the available Moqui MCP tools.

How to use the Moqui tools:
- Only 'growerp.*' services are callable. NEVER guess or invent a service name and never call
  a 'mantle.*', 'org.moqui.*' or other non-growerp service — it will be rejected. ALWAYS find
  the real service with 'moqui_search_services' first, then call exactly that name.
- Use 'moqui_search_services' with a keyword query to find relevant services. e.g. for orders,
  shipments, invoices or payments search "FinDoc" — the sales-order list is
  'growerp.100.FinDocServices100.get#FinDoc' with parameters {docType:"order", sales:true}.
- Use 'moqui_get_service_details' to learn a service's parameters.
- Use 'moqui_execute_service' to run a service.
- Use 'getCurrentTime' only when asked about the current time in a city.
- Use 'sendEmail' to send email; always pass ownerPartyId from your context ({tenantId}). Returns an error if email is not configured for this tenant.
- Use 'readEmails' to poll and read recent incoming email; always pass ownerPartyId from your context ({tenantId}). Returns an error if email is not configured.
- Use the GitHub tools ('getLatestTestRun', 'getTestExceptions', 'getMainSha', 'getFileContent', 'createBranch', 'updateFileContent', 'createPullRequest', 'addComment') to interact with GitHub. Always pass ownerPartyId from your context ({tenantId}) so that the tenant's GitHub token configuration is retrieved.

CRITICAL tool-use rules — follow exactly:
- After a tool returns a result, NEVER call that same tool again with the same arguments.
- As soon as a tool result contains the information needed, STOP calling tools and write
  a final, concise natural-language answer for the user (e.g. list the service names you found).
- Make at most a few tool calls per question; if you already have an answer, just answer.
''')
                    .model(modelArg)
                    .tools(allTools)
                    .build()
            } else {
                agent = LlmAgent.builder()
                        .name(sanitizeAgentName(agentName))
                        // A non-null description is REQUIRED when this agent is wrapped as an
                        // AgentTool by a coordinator (AgentTool.declaration NPEs on null), and it
                        // tells the coordinator's LLM when to delegate here.
                        .description(description ?: agentName ?: 'GrowERP agent')
                        .model(modelArg)
                        .instruction(CONTEXT_PREAMBLE + (instruction ?: ''))
                        .tools(allTools)
                        .build()
            }

            // Phase 4: a coordinator/workflow config replaces its base agent with an orchestrator
            // that delegates to its team members (router via AgentTool — each member keeps its own
            // McpToolset, so its scope/writePolicy/owner-pin still apply when the coordinator calls it).
            def orch = lookupOrchestration(configId)
            boolean isCoordinator = orch != null && (orch.role == 'coordinator' || orch.role == 'workflow')
            if (isCoordinator) {
                def orchestrated = buildOrchestrator(configId, ownerPartyId, agentName, modelArg, orch)
                if (orchestrated != null) agent = orchestrated
            }

            Runner runner = Runner.builder()
                    .agent(agent)
                    .appName(APP_NAME)
                    .sessionService(sharedSessionService ?: new InMemorySessionService())
                    .artifactService(sharedArtifactService ?: new com.google.adk.artifacts.InMemoryArtifactService())
                    .build()

            registry[configId]      = runner
            agentRegistry[configId] = agent
            // A general (unnamed) interactive agent OR a coordinator claims the tenant's chat route;
            // plain named/scheduled specialists (e.g. CI Monitor) must not hijack interactive chat.
            if (ownerPartyId && (!agentName || isCoordinator)) tenantRegistry[ownerPartyId] = configId
            currentConfig = [agentName: agent.name(), modelName: modelName, configId: configId]
            logger.info("ADK agent '${agent.name()}' registered as configId='${configId}' (tenant='${ownerPartyId ?: 'global'}')")
        } catch (Throwable t) {
            logger.warn("Failed to initialize ADK agent configId='${configId}': ${t.message}", t)
        }
    }

    /** Backward-compat: register a single global config. */
    static void init(String agentName, String modelName, String instruction, String apiKey) {
        initConfig(DEFAULT_CONFIG, null, agentName, modelName, instruction, apiKey)
    }

    /**
     * Generate a UserLoginKey for SystemSupport so the MCP SSE connection can authenticate
     * via 'api_key' header on every request (both SSE GET and subsequent POSTs).
     * Basic auth headers only work if the header survives through Moqui's web facade init;
     * api_key header is checked unconditionally in initFromHttpRequest.
     */
    private static String generateMcpApiKey(ExecutionContextFactory ecf) {
        // Must run in a fresh thread: ecf.getExecutionContext() returns the thread-local EC,
        // so calling it on the request thread would grab (and then destroy) the caller's EC.
        String[] result = [null]
        Thread t = new Thread({
            def ec = ecf.getExecutionContext()
            try {
                ec.user.internalLoginUser('SystemSupport')
                result[0] = ec.user.getLoginKey(8760f)  // 1-year expiry
                logger.info('Generated MCP API key for SystemSupport (valid 1 year)')
            } catch (Exception e) {
                logger.warn("Could not generate MCP API key, falling back to Basic auth: ${e.message}")
            } finally {
                ec.destroy()
            }
        }, 'adk-mcpkey-gen')
        t.start()
        t.join(5000L)
        return result[0]
    }

    static void initSessionService(ExecutionContextFactory ecf) {
        if (sharedSessionService == null) {
            sharedSessionService = new MoquiSessionService(ecf)
        }
        if (sharedArtifactService == null) {
            sharedArtifactService = new MoquiArtifactService(ecf)
        }
    }

    /**
     * Idempotent lazy init callable from the servlet (no Moqui service context needed).
     * Reads all enabled DB configs first, falls back to env vars, then defaults to HelloTimeAgent.
     */
    static void lazyInit(ExecutionContextFactory ecf) {
        initSessionService(ecf)
        // Close toolsets at the very start of JVM exit — before Moqui drains its worker pool —
        // so a pending McpToolset SSE connect is disposed (fails fast) instead of retry+timeout.
        if (shutdownHookRegistered.compareAndSet(false, true)) {
            Runtime.runtime.addShutdownHook(new Thread({
                shuttingDown = true
                closeAllToolsets()
            }, 'adk-shutdown'))
        }
        if (!registry.isEmpty()) return

        def cfgList = null
        try {
            def ec = ecf.getExecutionContext()
            boolean wasDisabled = ec.artifactExecution.disableAuthz()
            try { cfgList = ec.entity.find('moqui.adk.AdkAgentConfig').condition('enabled', 'Y').list() }
            finally { if (!wasDisabled) ec.artifactExecution.enableAuthz() }
        } catch (Exception ignored) {}

        // Key to use for the general default agent (env, else borrowed from a config).
        String defaultKey = System.getenv('GOOGLE_API_KEY') ?:
                            System.getenv('GOOGLE_GENAI_API_KEY') ?:
                            System.getenv('GEMINI_API_KEY') ?: ''
        String defaultModel = 'gemini-2.5-flash-lite'

        if (cfgList) {
            def ec2 = null
            try {
                ec2 = ecf.getExecutionContext()
                ec2.artifactExecution.disableAuthz()
                for (def cfg in cfgList) {
                    String resolvedApiKey = cfg.getString('apiKey') ?: ''
                    String provider = cfg.getString('llmProvider') ?: 'gemini'
                    if (!resolvedApiKey) {
                        def lc = ec2.entity.find('growerp.general.LlmConfig')
                            .condition('ownerPartyId', cfg.getString('ownerPartyId'))
                            .condition('llmProvider', provider).one()
                        resolvedApiKey = lc?.getString('apiKey') ?: ''
                    }
                    if (!defaultKey && resolvedApiKey && provider == 'gemini') {
                        defaultKey = resolvedApiKey
                        if (cfg.getString('modelName')) defaultModel = cfg.getString('modelName')
                    }
                    initConfig(cfg.getString('adkAgentConfigId'), cfg.getString('ownerPartyId'),
                            cfg.getString('agentName'), cfg.getString('modelName'),
                            cfg.getString('instruction'), resolvedApiKey, provider,
                            cfg.getString('description'))
                }
            } catch (Exception ignored) {
                for (def cfg in cfgList) {
                    if (!defaultKey && cfg.getString('apiKey')) defaultKey = cfg.getString('apiKey')
                    initConfig(cfg.getString('adkAgentConfigId'), cfg.getString('ownerPartyId'),
                            cfg.getString('agentName'), cfg.getString('modelName'),
                            cfg.getString('instruction'), cfg.getString('apiKey') ?: '',
                            cfg.getString('llmProvider') ?: 'gemini', cfg.getString('description'))
                }
            } finally {
                ec2?.destroy()
            }
        }

        // Always register a general-purpose default agent for INTERACTIVE CHAT, so chat
        // sessions are not served by a specialised/scheduled agent (e.g. the CI Monitor,
        // whose task instruction makes general questions return empty/odd answers).
        ensureInteractiveDefault(ecf, defaultKey, defaultModel)
    }

    /// Register the shared DEFAULT_CONFIG runner used for interactive chat, deriving
    /// its key from (in order) the gemini growerp.general.LlmConfig, env vars, then [seedKey].
    /// No-op when the runner already exists. Called by lazyInit and reloadInteractive.
    private static void ensureInteractiveDefault(ExecutionContextFactory ecf, String seedKey = null,
                                                 String model = 'gemini-2.5-flash-lite') {
        if (registry.containsKey(DEFAULT_CONFIG)) return
        // Precedence for the shared interactive runner: key saved via System Setup
        // (growerp.general.LlmConfig) → explicit env var → key borrowed from a specialised
        // agent (seedKey). The System Setup key must win over the env var so an admin/tenant
        // can always override a stale or server-wide key without a restart.
        String defaultKey = ''
        try {
            def ec = ecf.getExecutionContext()
            boolean wasDisabled = ec.artifactExecution.disableAuthz()
            try {
                def lcList = ec.entity.find('growerp.general.LlmConfig')
                        .condition('llmProvider', 'gemini').list()
                for (def lc in lcList) {
                    String k = lc.getString('apiKey')
                    if (k) { defaultKey = k; break }
                }
                logger.info("ensureInteractiveDefault: LlmConfig gemini rows={}, keyFound={}",
                        lcList?.size() ?: 0, (defaultKey ? true : false))
            } finally { if (!wasDisabled) ec.artifactExecution.enableAuthz() }
        } catch (Exception e) {
            logger.error("ensureInteractiveDefault: LlmConfig lookup failed: ${e.message}", e)
        }
        if (!defaultKey) defaultKey = System.getenv('GOOGLE_API_KEY') ?:
                            System.getenv('GOOGLE_GENAI_API_KEY') ?:
                            System.getenv('GEMINI_API_KEY') ?: ''
        if (!defaultKey) defaultKey = seedKey ?: ''
        logger.info("ensureInteractiveDefault: registering __default__ hasKey={} (seedKeyPresent={})",
                (defaultKey ? true : false), (seedKey ? true : false))
        initConfig(DEFAULT_CONFIG, null, null, model, '', defaultKey)
    }

    /// Ensure a general per-tenant interactive runner exists for [ownerPartyId] and owns
    /// the tenant's chat route. Built once per owner (configId 'INTERACTIVE_<owner>'); its
    /// McpToolset carries the owner so searchKnowledge can resolve the tenant. No-op when
    /// already registered. Falls back to the global default if no key can be found.
    static synchronized void ensureInteractiveForTenant(String ownerPartyId) {
        if (!ownerPartyId || sharedSessionService == null) return
        String cid = 'INTERACTIVE_' + ownerPartyId
        if (registry.containsKey(cid)) return
        // A coordinator (or already-built interactive agent) may already own this tenant's chat
        // route — don't shadow it with the generic interactive default.
        if (tenantRegistry.containsKey(ownerPartyId)) return
        String key = resolveTenantKey(ownerPartyId)
        if (!key) {
            logger.warn("ensureInteractiveForTenant: no gemini key for owner=${ownerPartyId}; " +
                    "interactive chat will use the global default (no tenant knowledge access)")
            return
        }
        // agentName=null → builds the general 'growerp-agent'; ownerPartyId set + unnamed →
        // claims tenantRegistry[owner] and its McpToolset carries adk_owner_party_id.
        initConfig(cid, ownerPartyId, null, 'gemini-2.5-flash-lite', '', key)
        logger.info("Registered per-tenant interactive agent configId='${cid}' (owner=${ownerPartyId})")
    }

    /// Resolve a gemini API key for [ownerPartyId]: this owner's LlmConfig → any gemini
    /// LlmConfig → a key borrowed from an AdkAgentConfig → env vars. Returns '' when none found.
    private static String resolveTenantKey(String ownerPartyId) {
        String key = ''
        try {
            def ec = sharedSessionService.ecf.getExecutionContext()
            boolean wasDisabled = ec.artifactExecution.disableAuthz()
            try {
                def lc = ec.entity.find('growerp.general.LlmConfig')
                        .condition('ownerPartyId', ownerPartyId)
                        .condition('llmProvider', 'gemini').one()
                key = lc?.getString('apiKey') ?: ''
                if (!key) {
                    for (def row in ec.entity.find('growerp.general.LlmConfig')
                            .condition('llmProvider', 'gemini').list()) {
                        String k = row.getString('apiKey')
                        if (k) { key = k; break }
                    }
                }
                // Fall back to a key stored directly on an AdkAgentConfig (this owner first,
                // then any gemini agent) — mirrors lazyInit's key-borrowing so the interactive
                // agent works even when only a scheduled agent (e.g. CI Monitor) holds the key.
                if (!key) {
                    def ac = ec.entity.find('moqui.adk.AdkAgentConfig')
                            .condition('ownerPartyId', ownerPartyId)
                            .condition('llmProvider', 'gemini').list()
                    for (def row in ac) { String k = row.getString('apiKey'); if (k) { key = k; break } }
                }
                if (!key) {
                    for (def row in ec.entity.find('moqui.adk.AdkAgentConfig')
                            .condition('llmProvider', 'gemini').list()) {
                        String k = row.getString('apiKey')
                        if (k) { key = k; break }
                    }
                }
            } finally { if (!wasDisabled) ec.artifactExecution.enableAuthz() }
        } catch (Exception e) {
            logger.warn("resolveTenantKey(${ownerPartyId}) failed: ${e.message}")
        }
        if (!key) key = System.getenv('GOOGLE_API_KEY') ?:
                         System.getenv('GOOGLE_GENAI_API_KEY') ?:
                         System.getenv('GEMINI_API_KEY') ?: ''
        return key
    }

    /// Drop the shared interactive/default runner and re-create it so a key change
    /// (e.g. saved in System Setup) takes effect on the next chat without a restart.
    /// Scheduled/specialised agent runners and the MCP toolset are left intact.
    static synchronized void reloadInteractive(ExecutionContextFactory ecf) {
        registry.remove(DEFAULT_CONFIG)
        agentRegistry.remove(DEFAULT_CONFIG)
        // Also drop per-tenant interactive runners (INTERACTIVE_<owner>) so a key
        // change OR removal in System Setup takes effect for tenant chat. They are
        // rebuilt on the next createSession via ensureInteractiveForTenant — which
        // re-resolves the current key, so a deleted key correctly stops the chat.
        def interactiveCids = registry.keySet().findAll { it.startsWith('INTERACTIVE_') }
        for (String cid in interactiveCids) {
            registry.remove(cid)
            agentRegistry.remove(cid)
            tenantRegistry.entrySet().removeIf { it.value == cid }
        }
        currentConfig = [:]
        ensureInteractiveDefault(ecf)
    }

    /// Rebuild a single named config (e.g. a coordinator after its team changed) so the
    /// running registry reflects the latest DB state without a restart.
    static synchronized void reloadConfig(String configId) {
        if (!configId) return
        registry.remove(configId)
        agentRegistry.remove(configId)
        ensureAgentBuilt(configId)
    }

    static boolean isInitialized() { !registry.isEmpty() }

    static List<String> listAgents() {
        registry.values().collect { it.agent().name() }.unique() ?: ['hello-time-agent']
    }

    // ── Session management ────────────────────────────────────────────────────

    static Map createSession(String userId, Map<String, Object> initialState = [:]) {
        String tenantId = initialState?.get('tenantId') as String
        // Interactive chat must run as a general per-tenant agent (NOT a scheduled/named
        // agent like the CI Monitor) so it carries the tenant owner for searchKnowledge.
        if (tenantId && tenantId != 'DEFAULT') ensureInteractiveForTenant(tenantId)
        String configId = resolveConfigId(tenantId)
        Runner runner   = registry[configId] ?: registry.values().find()
        if (!runner) throw new IllegalStateException('ADK not initialized — add an LLM API key in System Setup')

        def session = runner.sessionService()
                .createSession(APP_NAME, userId, initialState ?: [:], null)
                .blockingGet()

        sessionOwn[session.id()] = configId
        persistSessionConfigId(session.id(), configId)

        AdkSessionHolder.sessions[session.id()] = []
        AdkSessionHolder.logEvent(session.id(), 'session_created', 'Session created', [sessionId: session.id()])

        [id           : session.id(),
         appName      : APP_NAME,
         userId       : session.userId(),
         state        : session.state() ?: [:],
         events       : [],
         lastUpdateTime: System.currentTimeMillis()]
    }

    static Map getSession(String userId, String sessionId) {
        def runner = runnerForSession(sessionId)
        def sessionOpt = runner.sessionService()
                .getSession(APP_NAME, userId, sessionId, Optional.empty())
                .blockingGet()
        if (!sessionOpt) return null
        [id           : sessionOpt.id(),
         appName      : APP_NAME,
         userId       : sessionOpt.userId(),
         state        : sessionOpt.state() ?: [:],
         events       : [],
         lastUpdateTime: System.currentTimeMillis()]
    }

    static List<Map> listSessions(String userId) {
        // Use first available runner (sessions are shared via MoquiSessionService)
        def runner = registry.values().find()
        def response = runner?.sessionService()?.listSessions(APP_NAME, userId)?.blockingGet()
        response?.sessions()?.collect { s -> [id: s.id(), appName: APP_NAME, userId: s.userId()] } ?: []
    }

    static void deleteSession(String userId, String sessionId) {
        def runner = runnerForSession(sessionId)
        runner.sessionService().deleteSession(APP_NAME, userId, sessionId).blockingAwait()
        sessionOwn.remove(sessionId)
        turnCounts.remove(sessionId)
    }

    // ── Agent execution ───────────────────────────────────────────────────────

    static RunConfig defaultRunConfig() { RunConfig.builder().setMaxLlmCalls(30).build() }

    /**
     * After a completed interactive turn, fold the session into the rolling per-(owner,user)
     * AdkMemory every N turns. Runs async on a daemon thread (the summary needs an LLM call)
     * so it never delays the chat response; failures are logged and swallowed.
     */
    static void maybeSummarize(String sessionId) {
        if (!sessionId || sharedSessionService == null) return
        int n = turnCounts.merge(sessionId, 1, { a, b -> a + b })
        if (n % SUMMARIZE_EVERY_N_TURNS != 0) return
        def ecf = sharedSessionService.ecf
        Thread t = new Thread({
            def ec = ecf.getExecutionContext()
            try {
                boolean wasDisabled = ec.artifactExecution.disableAuthz()
                try {
                    ec.service.sync().name('AdkKnowledgeServices.summarize#AdkSession')
                            .parameters([adkSessionId: sessionId]).call()
                } finally { if (!wasDisabled) ec.artifactExecution.enableAuthz() }
            } catch (Exception e) {
                logger.warn("maybeSummarize(${sessionId}) failed: ${e.message}")
            } finally { ec.destroy() }
        }, 'adk-summarize')
        t.setDaemon(true)
        t.start()
    }

    /**
     * Record an explicit delegation row in AdkActionLog for each specialist (other than the
     * session's coordinator) that authored an event this turn — so Agent Actions shows
     * "Coordinator → Specialist" at a glance, not just inferred from per-member configIds.
     * Async/best-effort. No-op for single-agent sessions (only the agent itself authors).
     */
    static void logDelegations(String sessionId, Set<String> authors) {
        if (!sessionId || !authors || authors.isEmpty() || sharedSessionService == null) return
        String coordId = sessionOwn[sessionId] ?: lookupConfigIdFromDb(sessionId)
        if (!coordId) return
        def ecf = sharedSessionService.ecf
        Thread t = new Thread({
            def ec = ecf.getExecutionContext()
            try {
                boolean wasDisabled = ec.artifactExecution.disableAuthz()
                try {
                    def coord = ec.entity.find('moqui.adk.AdkAgentConfig')
                            .condition('adkAgentConfigId', coordId).one()
                    if (!coord) return
                    String owner = coord.ownerPartyId as String
                    String coordName = coord.agentName as String
                    for (String a in authors) {
                        if (!a || a == coordName || a == 'growerp-agent') continue
                        // map the responding agent name → a team member config of this owner
                        def member = ec.entity.find('moqui.adk.AdkAgentConfig')
                                .condition('ownerPartyId', owner).condition('agentName', a).one()
                        if (!member) continue
                        ec.service.sync().name('create#moqui.adk.AdkActionLog').parameters([
                                ownerPartyId: owner, configId: member.adkAgentConfigId,
                                parentConfigId: coordId, adkSessionId: sessionId,
                                toolName: a, serviceName: 'delegate', verbClass: 'delegate',
                                decision: 'delegated', reason: "${coordName} → ${a}",
                                actionTime: ec.user.nowTimestamp]).call()
                    }
                } finally { if (!wasDisabled) ec.artifactExecution.enableAuthz() }
            } catch (Exception e) {
                logger.warn("logDelegations(${sessionId}) failed: ${e.message}")
            } finally { ec.destroy() }
        }, 'adk-delegation-log')
        t.setDaemon(true)
        t.start()
    }

    /**
     * Extract token counts summed across all events that carry usageMetadata.
     * Returns [tokensIn, tokensOut, tokensTotal].
     */
    static long[] extractTokensFromEvents(List<Map> events) {
        long tokensIn = 0, tokensOut = 0, total = 0
        for (Map ev in events) {
            def um = ev.usageMetadata
            if (um instanceof Map) {
                tokensIn  += (um.promptTokenCount     ?: 0) as long
                tokensOut += (um.candidatesTokenCount ?: 0) as long
                total     += (um.totalTokenCount       ?: 0) as long
            }
        }
        if (total == 0 && (tokensIn > 0 || tokensOut > 0)) total = tokensIn + tokensOut
        [tokensIn, tokensOut, total] as long[]
    }

    /**
     * Record a top-level chat interaction in AdkActionLog with real token counts.
     * Must be called after the run completes so events are available.
     */
    static void logChatTurn(String sessionId, String text, List<Map> events) {
        if (!sessionId || sharedSessionService == null) return
        String coordId = sessionOwn[sessionId] ?: lookupConfigIdFromDb(sessionId)
        if (!coordId) return
        long[] tokens = extractTokensFromEvents(events)
        def ecf = sharedSessionService.ecf
        Thread t = new Thread({
            def ec = ecf.getExecutionContext()
            try {
                boolean wasDisabled = ec.artifactExecution.disableAuthz()
                try {
                    def coord = ec.entity.find('moqui.adk.AdkAgentConfig')
                            .condition('adkAgentConfigId', coordId).one()
                    if (!coord) return
                    String owner = coord.ownerPartyId as String
                    ec.service.sync().name('create#moqui.adk.AdkActionLog').parameters([
                            ownerPartyId: owner, configId: coordId,
                            adkSessionId: sessionId,
                            serviceName: 'chat', verbClass: 'chat',
                            decision: 'allowed', reason: 'User Chat Interaction',
                            argsJson: "{\"text\": \"${text.take(200).replace('"', '\\"')}\"}",
                            tokensIn: tokens[0], tokensOut: tokens[1], tokensTotal: tokens[2],
                            actionTime: ec.user.nowTimestamp]).call()
                } finally { if (!wasDisabled) ec.artifactExecution.enableAuthz() }
            } catch (Exception e) {
                logger.warn("logChatTurn(${sessionId}) failed: ${e.message}")
            } finally { ec.destroy() }
        }, 'adk-chat-log')
        t.setDaemon(true)
        t.start()
    }

    static List<Map> runAgent(String userId, String sessionId, String text) {
        if (shuttingDown) return []
        Content userContent = buildUserContent(text)
        List<Map> events = []
        Set<String> delegateNames = new HashSet<>()
        Throwable[] err  = [null]
        runnerForSession(sessionId).runAsync(userId, sessionId, userContent, defaultRunConfig())
            .blockingSubscribe(
                { Event e -> collectDelegateNames(e, delegateNames); events << eventToMap(e) },
                { Throwable t -> err[0] = t; logger.error("ADK runAgent error (session={}): {}", sessionId, t.message, t) }
            )
        if (err[0]) throw err[0]
        logChatTurn(sessionId, text, events)
        logDelegations(sessionId, delegateNames)
        maybeSummarize(sessionId)
        events
    }

    /** Names of specialists a coordinator delegated to this turn: event authors (workflow
     *  sub-agents) + function-call names (router AgentTools — the inner runner doesn't surface
     *  the specialist as an author, but the coordinator's functionCall is named after it). */
    private static void collectDelegateNames(Event e, Set<String> acc) {
        try {
            if (e.author()) acc.add(e.author())
            Optional<Content> co = e.content()
            if (co?.isPresent() && co.get().parts()?.isPresent()) {
                for (Part p in co.get().parts().get()) {
                    def fc = p.functionCall()
                    if (fc?.isPresent() && fc.get().name()?.isPresent()) acc.add(fc.get().name().get())
                }
            }
        } catch (Exception ignore) {}
    }

    /**
     * Run a one-off agent turn for the scheduler.
     * Uses a fresh InMemorySessionService to avoid the DB transaction isolation
     * issue: createSession writes to DB within an open (uncommitted) service
     * transaction; a subsequent runAsync on an IO thread cannot see it via
     * MoquiSessionService.getSession. In-memory sessions need no DB round-trip.
     */
    static List<Map> runOneOff(String configId, String userId, String text,
                               Map<String, Object> initialState = [:]) {
        if (shuttingDown) return []
        String cid = configId ?: DEFAULT_CONFIG
        LlmAgent agent = agentRegistry[cid] ?: agentRegistry.values().find()
        if (!agent) throw new IllegalStateException('ADK not initialized — add API key in ADK → Configuration')

        // The agent instruction embeds CONTEXT_PREAMBLE with {userId}/{username}/... placeholders
        // that ADK resolves from session state. Seed state with these keys so injectSessionState
        // does not throw "Context variable not found".
        def state = new java.util.concurrent.ConcurrentHashMap<String, Object>(initialState ?: [:])
        // {screenCatalog} and {memory} appear in the instruction preamble; scheduled/one-off
        // runs have no Flutter client or prior conversation history, so default them to avoid
        // "Context variable not found".
        state.putIfAbsent('screenCatalog', '[]')
        state.putIfAbsent('memory', '')

        def inMemSvc = new InMemorySessionService()
        def session  = inMemSvc.createSession(APP_NAME, userId, state, null).blockingGet()

        Runner oneOff = Runner.builder()
                .agent(agent)
                .appName(APP_NAME)
                .sessionService(inMemSvc)
                .artifactService(sharedArtifactService ?: new com.google.adk.artifacts.InMemoryArtifactService())
                .build()

        Content userContent = buildUserContent(text)
        List<Map> events = []
        Throwable[] err  = [null]

        oneOff.runAsync(userId, session.id(), userContent, defaultRunConfig())
              .blockingSubscribe(
                  { Event e -> events << eventToMap(e) },
                  { Throwable t -> err[0] = t; logger.error("ADK runOneOff error (config={}): {}", cid, t.message, t) }
              )

        if (err[0]) throw err[0]
        events
    }

    static void runAgentSse(String userId, String sessionId, String text,
                            Closure eventCallback, Closure doneCallback) {
        if (shuttingDown) { doneCallback(null); return }
        Content userContent = buildUserContent(text)
        Set<String> delegateNames = java.util.concurrent.ConcurrentHashMap.newKeySet()
        List<Map> collectedEvents = Collections.synchronizedList(new ArrayList<>())
        runnerForSession(sessionId).runAsync(userId, sessionId, userContent, defaultRunConfig())
            .subscribe(
                { Event e ->
                    def em = eventToMap(e)
                    collectDelegateNames(e, delegateNames)
                    collectedEvents.add(em)
                    eventCallback(em)
                },
                { Throwable t -> doneCallback(t) },
                {
                    logChatTurn(sessionId, text, collectedEvents)
                    logDelegations(sessionId, delegateNames)
                    maybeSummarize(sessionId)
                    doneCallback(null)
                }
            )
    }

    // ── Internal helpers ──────────────────────────────────────────────────────

    private static String resolveConfigId(String ownerPartyId) {
        if (ownerPartyId && tenantRegistry[ownerPartyId]) return tenantRegistry[ownerPartyId]
        // Fall back to the only/default registered config
        return registry.containsKey(DEFAULT_CONFIG) ? DEFAULT_CONFIG : (registry.keySet().find() ?: DEFAULT_CONFIG)
    }

    private static Runner runnerForSession(String sessionId) {
        String configId = sessionOwn[sessionId] ?: lookupConfigIdFromDb(sessionId) ?: DEFAULT_CONFIG
        if (configId && configId != DEFAULT_CONFIG) sessionOwn[sessionId] = configId  // cache it
        return registry[configId] ?: registry.values().find() ?: { throw new IllegalStateException('ADK not initialized — add an LLM API key in System Setup') }()
    }

    private static String lookupConfigIdFromDb(String sessionId) {
        if (!sharedSessionService) return null
        try {
            def ec = sharedSessionService.ecf.getExecutionContext()
            boolean wasDisabled = ec.artifactExecution.disableAuthz()
            try {
                def sv = ec.entity.find('moqui.adk.AdkSession').condition('adkSessionId', sessionId).one()
                return sv?.configId as String
            } finally {
                if (!wasDisabled) ec.artifactExecution.enableAuthz()
            }
        } catch (Exception ignored) { return null }
    }

    private static void persistSessionConfigId(String sessionId, String configId) {
        if (!sharedSessionService) return
        try {
            def ec = sharedSessionService.ecf.getExecutionContext()
            boolean wasDisabled = ec.artifactExecution.disableAuthz()
            try {
                def sv = ec.entity.find('moqui.adk.AdkSession').condition('adkSessionId', sessionId).one()
                if (sv && sv.configId != configId) { sv.configId = configId; sv.update() }
            } finally {
                if (!wasDisabled) ec.artifactExecution.enableAuthz()
            }
        } catch (Exception ignored) {}
    }

    private static Content buildUserContent(String text) {
        Content.builder().role('user').parts([Part.fromText(text)]).build()
    }

    static Map eventToMap(Event e) {
        Map m = [id: e.id(), invocationId: e.invocationId(), author: e.author()]

        Optional<Content> contentOpt = e.content()
        if (contentOpt.isPresent()) {
            Content c = contentOpt.get()
            m.content = [
                role : c.role().isPresent() ? c.role().get() : '',
                parts: c.parts().isPresent() ? c.parts().get().collect { Part p ->
                    p.text().isPresent() ? [text: p.text().get()] : [:]
                } : []
            ]
        }

        Optional<Boolean> partialOpt = e.partial()
        if (partialOpt.isPresent()) m.partial = partialOpt.get()

        // Capture token usage metadata when present
        try {
            def umOpt = e.usageMetadata()
            if (umOpt?.isPresent()) {
                def um = umOpt.get()
                m.usageMetadata = [
                    promptTokenCount    : um.promptTokenCount()?.orElse(null),
                    candidatesTokenCount: um.candidatesTokenCount()?.orElse(null),
                    totalTokenCount     : um.totalTokenCount()?.orElse(null),
                ]
            }
        } catch (Exception ignore) {}

        m
    }

    /** Build a per-agent MCP toolset whose SSE headers carry `adk_config_id` (and the
     *  tenant `adk_owner_party_id`) so the governance gate / searchKnowledge on the MCP
     *  server can resolve the calling agent and its tenant. */
    private static com.google.adk.tools.mcp.McpToolset buildMcpToolset(String configId, String ownerPartyId = null) {
        if (shuttingDown) return null
        if (mcpApiKey == null && sharedSessionService != null) {
            mcpApiKey = generateMcpApiKey(sharedSessionService.ecf)
        }
        Map<String, String> sseHeaders = ['Accept': 'application/json, text/event-stream']
        if (mcpApiKey) {
            sseHeaders['api_key'] = mcpApiKey
        } else {
            sseHeaders['Authorization'] = 'Basic ' + 'SystemSupport:moqui'.bytes.encodeBase64().toString()
        }
        if (configId && configId != DEFAULT_CONFIG) sseHeaders['adk_config_id'] = configId
        // Tenant owner — lets searchKnowledge resolve the company even for the general
        // per-tenant interactive agent (whose configId is not an AdkAgentConfig row).
        if (ownerPartyId) sseHeaders['adk_owner_party_id'] = ownerPartyId
        // Check system properties ('port' is commonly used by Moqui runner like -Dport=8081)
        String mcpInternalPort = System.getProperty('webapp_http_port') ?: System.getProperty('port') ?: System.getenv('webapp_http_port')
        String mcpInternalHost = System.getProperty('webapp_http_host') ?: System.getenv('webapp_http_host')
        
        // Moqui executable (moqui.war) parses port=8081 but doesn't set it in System properties.
        // We can extract it from the command line arguments.
        String sunJavaCommand = System.getProperty("sun.java.command")
        if (!mcpInternalPort && sunJavaCommand != null) {
            java.util.regex.Matcher match = sunJavaCommand =~ /(?:^|\s)port=(\d+)/
            if (match.find()) {
                mcpInternalPort = match.group(1)
            }
        }

        if ((!mcpInternalPort || !mcpInternalHost) && sharedSessionService != null && sharedSessionService.ecf instanceof org.moqui.impl.context.ExecutionContextFactoryImpl) {
            try {
                // Read from actual parsed XML config
                def confRoot = sharedSessionService.ecf.getConfXmlRoot()
                def webroot = confRoot.first("webapp-list")?.children("webapp")?.find { it.attribute("name") == "webroot" }
                if (webroot != null) {
                    if (!mcpInternalPort && webroot.attribute("http-port")) {
                        String parsedPort = webroot.attribute("http-port")
                        if (!parsedPort.startsWith("\$")) {
                            mcpInternalPort = parsedPort
                        } else if (parsedPort == "\${webapp_http_port:-8080}") {
                            mcpInternalPort = '8080' // default fallback if unexpanded
                        }
                    }
                    if (!mcpInternalHost && webroot.attribute("http-host")) {
                        String parsedHost = webroot.attribute("http-host")
                        if (!parsedHost.startsWith("\$")) {
                            mcpInternalHost = parsedHost
                        }
                    }
                }
            } catch (Exception e) {
                logger.warn("Could not read webapp http config from configuration", e)
            }
        }
        mcpInternalPort = mcpInternalPort ?: '8080'
        mcpInternalHost = mcpInternalHost ?: '127.0.0.1'
        if (mcpInternalHost == '0.0.0.0' || mcpInternalHost == '::') mcpInternalHost = '127.0.0.1'

        String sseUrl = "http://${mcpInternalHost}:${mcpInternalPort}/mcp/sse"
        logger.info("Initializing MCP Toolset connecting to: ${sseUrl}")
        def sseParams = com.google.adk.tools.mcp.SseServerParameters.builder()
                .url(sseUrl)
                .headers(sseHeaders)
                .build()
        def prior = configMcpToolsets[configId]
        if (prior != null) { try { prior.close() } catch (Exception ignore) {} }
        def ts = new com.google.adk.tools.mcp.McpToolset(sseParams)
        configMcpToolsets[configId] = ts
        if (mcpToolset == null) mcpToolset = ts   // keep a default reference for legacy paths
        return ts
    }

    /** Build a toolset for an external (tenant-registered) MCP server. Unlike buildMcpToolset
     *  this targets a third-party URL and sends only the server's own auth headers (from the
     *  encrypted headersJson map) — no SystemSupport credentials. */
    private static com.google.adk.tools.mcp.McpToolset buildExternalMcpToolset(def srv) {
        Map<String, String> sseHeaders = ['Accept': 'application/json, text/event-stream']
        String hj = srv.headersJson as String
        if (hj) {
            try {
                def parsed = new groovy.json.JsonSlurper().parseText(hj)
                if (parsed instanceof Map) parsed.each { k, v -> if (k && v != null) sseHeaders[k as String] = v as String }
            } catch (Exception e) {
                logger.warn("Bad headersJson for AdkMcpServer ${srv.adkMcpServerId}: ${e.message}")
            }
        }
        def sseParams = com.google.adk.tools.mcp.SseServerParameters.builder()
                .url(srv.url as String)
                .headers(sseHeaders)
                .build()
        return new com.google.adk.tools.mcp.McpToolset(sseParams)
    }

    /** Build the toolsets for every enabled external MCP server attached to this agent.
     *  Owner-guarded (a server must belong to the agent's tenant). Prior toolsets for the
     *  configId are closed first so reloadConfig doesn't leak SSE connections. */
    private static List<com.google.adk.tools.mcp.McpToolset> loadExternalMcpToolsets(String configId, String ownerPartyId) {
        List<com.google.adk.tools.mcp.McpToolset> out = []
        if (shuttingDown) return out
        if (!configId || configId == DEFAULT_CONFIG || sharedSessionService == null) return out
        def prior = configExternalToolsets.remove(configId)
        if (prior) prior.each { try { it?.close() } catch (Exception ignore) {} }
        try {
            def ec = sharedSessionService.ecf.getExecutionContext()
            boolean wasDisabled = ec.artifactExecution.disableAuthz()
            try {
                def links = ec.entity.find('moqui.adk.AdkAgentMcpServer')
                        .condition('configId', configId).condition('enabled', 'Y')
                        .orderBy('sequenceNum').list()
                for (def lnk in links) {
                    def srv = ec.entity.find('moqui.adk.AdkMcpServer')
                            .condition('adkMcpServerId', lnk.adkMcpServerId as String).one()
                    if (!srv || srv.enabled != 'Y') continue
                    // tenant guard: the server must belong to the agent's company
                    if (ownerPartyId && srv.ownerPartyId && (srv.ownerPartyId as String) != (ownerPartyId as String)) {
                        logger.warn("Skipping cross-tenant MCP server ${srv.adkMcpServerId} (owner ${srv.ownerPartyId}) on agent ${configId} (owner ${ownerPartyId})")
                        continue
                    }
                    try {
                        out.add(buildExternalMcpToolset(srv))
                    } catch (Exception e) {
                        logger.warn("Failed to build external MCP toolset ${srv.adkMcpServerId} for ${configId}: ${e.message}")
                    }
                }
            } finally { if (!wasDisabled) ec.artifactExecution.enableAuthz() }
        } catch (Exception e) {
            logger.warn("loadExternalMcpToolsets failed for ${configId}: ${e.message}")
        }
        if (out) configExternalToolsets[configId] = out
        return out
    }

    /** Read an agent's toolMode (readOnly | scoped | full) from its persisted config.
     *  Defaults to readOnly when unknown so new/unconfigured agents are safe by default. */
    private static String lookupToolMode(String configId) {
        if (!configId || configId == DEFAULT_CONFIG || sharedSessionService == null) return 'full'
        try {
            def ec = sharedSessionService.ecf.getExecutionContext()
            boolean wasDisabled = ec.artifactExecution.disableAuthz()
            try {
                def cfg = ec.entity.find('moqui.adk.AdkAgentConfig')
                        .condition('adkAgentConfigId', configId).one()
                // null toolMode = legacy row (pre-governance) → keep full tool access.
                return (cfg?.toolMode ?: 'full') as String
            } finally {
                if (!wasDisabled) ec.artifactExecution.enableAuthz()
            }
        } catch (Exception e) {
            logger.warn("lookupToolMode failed for ${configId}: ${e.message}")
            return 'readOnly'
        }
    }

    // ── Phase 4: multi-agent orchestration ──────────────────────────────────────

    /** Read a config's orchestration role: [role, type, loopMax]. null for rows that don't
     *  exist (DEFAULT/INTERACTIVE) or plain specialists. */
    private static Map lookupOrchestration(String configId) {
        if (!configId || configId == DEFAULT_CONFIG || sharedSessionService == null) return null
        try {
            def ec = sharedSessionService.ecf.getExecutionContext()
            boolean wasDisabled = ec.artifactExecution.disableAuthz()
            try {
                def cfg = ec.entity.find('moqui.adk.AdkAgentConfig')
                        .condition('adkAgentConfigId', configId).one()
                String role = cfg?.agentRole as String
                if (!role || role == 'specialist') return null
                return [role: role, type: (cfg.orchestrationType ?: 'router') as String,
                        loopMax: cfg.loopMaxIterations as Integer]
            } finally { if (!wasDisabled) ec.artifactExecution.enableAuthz() }
        } catch (Exception e) {
            logger.warn("lookupOrchestration failed for ${configId}: ${e.message}")
            return null
        }
    }

    /** Enabled team members of a coordinator, owner-scoped (cross-tenant members rejected),
     *  ordered by sequenceNum. Each entry: [memberConfigId, agentName, description, delegationMode]. */
    private static List<Map> loadTeamMembers(String coordinatorConfigId, String ownerPartyId) {
        List<Map> out = []
        try {
            def ec = sharedSessionService.ecf.getExecutionContext()
            boolean wasDisabled = ec.artifactExecution.disableAuthz()
            try {
                def rows = ec.entity.find('moqui.adk.AdkAgentTeamMember')
                        .condition('coordinatorConfigId', coordinatorConfigId)
                        .condition('enabled', 'Y').orderBy('sequenceNum').list()
                for (def r in rows) {
                    def mc = ec.entity.find('moqui.adk.AdkAgentConfig')
                            .condition('adkAgentConfigId', r.memberConfigId as String).one()
                    if (!mc) continue
                    // tenant guard: a member must belong to the coordinator's company
                    if (ownerPartyId && mc.ownerPartyId && (mc.ownerPartyId as String) != (ownerPartyId as String)) {
                        logger.warn("Skipping cross-tenant team member ${r.memberConfigId} (owner ${mc.ownerPartyId}) of coordinator ${coordinatorConfigId} (owner ${ownerPartyId})")
                        continue
                    }
                    out.add([memberConfigId: r.memberConfigId as String,
                             agentName: mc.agentName as String,
                             description: mc.description as String,
                             delegationMode: (r.delegationMode ?: 'tool') as String])
                }
            } finally { if (!wasDisabled) ec.artifactExecution.enableAuthz() }
        } catch (Exception e) {
            logger.warn("loadTeamMembers failed for ${coordinatorConfigId}: ${e.message}")
        }
        return out
    }

    /** Return a member agent's LlmAgent, building it on demand from its config row. Cycle-safe
     *  (returns null if the config is mid-build). */
    private static LlmAgent ensureAgentBuilt(String configId) {
        if (!configId) return null
        if (agentRegistry.containsKey(configId)) return agentRegistry[configId]
        if (sharedSessionService == null || buildingConfigs.contains(configId)) return agentRegistry[configId]
        try {
            def ec = sharedSessionService.ecf.getExecutionContext()
            boolean wasDisabled = ec.artifactExecution.disableAuthz()
            def cfg
            try {
                cfg = ec.entity.find('moqui.adk.AdkAgentConfig').condition('adkAgentConfigId', configId).one()
            } finally { if (!wasDisabled) ec.artifactExecution.enableAuthz() }
            if (!cfg) return null
            String provider = cfg.llmProvider ?: 'gemini'
            String key = (cfg.apiKey as String) ?: resolveTenantKey(cfg.ownerPartyId as String)
            initConfig(configId, cfg.ownerPartyId as String, cfg.agentName as String,
                    cfg.modelName as String, cfg.instruction as String, key, provider,
                    cfg.description as String)
        } catch (Exception e) {
            logger.warn("ensureAgentBuilt failed for ${configId}: ${e.message}")
        }
        return agentRegistry[configId]
    }

    /** Build a coordinator LlmAgent that delegates to its team members as AgentTools (router).
     *  sequential/parallel/loop orchestration is Phase 4b — for now it routes via AgentTool too. */
    /** The in-process FunctionTools every agent gets (read-only set, plus write tools when allowed). */
    private static List assembleFunctionTools(boolean allowWrites) {
        List allTools = new ArrayList()
        // lets the agent pull saved artifacts (PDFs/images) into context only when needed
        allTools.add(com.google.adk.tools.LoadArtifactsTool.INSTANCE)
        allTools.addAll(com.google.adk.tools.FunctionTool.create(HelloTimeAgent.class, 'getCurrentTime'))
        // Website-chat human handoff: safe (routes a conversation, no business-data write), so the
        // read-only Support agent can call it. Reads the active room from session state.
        allTools.addAll(com.google.adk.tools.FunctionTool.create(HandoffTool.class, 'requestHumanHandoff'))
        allTools.addAll(com.google.adk.tools.FunctionTool.create(EmailTool.class, 'readEmails'))
        allTools.addAll(com.google.adk.tools.FunctionTool.create(GithubTool.class, 'getLatestTestRun'))
        allTools.addAll(com.google.adk.tools.FunctionTool.create(GithubTool.class, 'getTestExceptions'))
        allTools.addAll(com.google.adk.tools.FunctionTool.create(GithubTool.class, 'getMainSha'))
        allTools.addAll(com.google.adk.tools.FunctionTool.create(GithubTool.class, 'getFileContent'))
        allTools.addAll(com.google.adk.tools.FunctionTool.create(SubstackTool.class, 'listSubstackPosts'))
        allTools.addAll(com.google.adk.tools.FunctionTool.create(SubstackTool.class, 'getSubstackPostComments'))
        allTools.addAll(com.google.adk.tools.FunctionTool.create(SubstackTool.class, 'getSubstackEngagements'))
        allTools.addAll(com.google.adk.tools.FunctionTool.create(SubstackTool.class, 'getSubscriberSyncStats'))
        if (allowWrites) {
            allTools.addAll(com.google.adk.tools.FunctionTool.create(EmailTool.class, 'sendEmail'))
            allTools.addAll(com.google.adk.tools.FunctionTool.create(GithubTool.class, 'createBranch'))
            allTools.addAll(com.google.adk.tools.FunctionTool.create(GithubTool.class, 'updateFileContent'))
            allTools.addAll(com.google.adk.tools.FunctionTool.create(GithubTool.class, 'createPullRequest'))
            allTools.addAll(com.google.adk.tools.FunctionTool.create(GithubTool.class, 'addComment'))
            allTools.addAll(com.google.adk.tools.FunctionTool.create(SubstackTool.class, 'postSubstackNote'))
            allTools.addAll(com.google.adk.tools.FunctionTool.create(SubstackTool.class, 'publishSubstackArticle'))
            allTools.addAll(com.google.adk.tools.FunctionTool.create(SubstackTool.class, 'addSubstackSubscriber'))
        }
        return allTools
    }

    /** Build a FRESH LlmAgent instance for a workflow sub-agent (Sequential/Parallel/Loop set a
     *  parent on their sub-agents, so we must not reuse the registry-shared instance). It reuses the
     *  member's already-built McpToolset (same adk_config_id/owner → governance preserved, no extra
     *  SSE connection). Not registered in the registry. */
    private static com.google.adk.agents.BaseAgent buildMemberInstance(String memberConfigId, def modelArg) {
        if (!memberConfigId) return null
        ensureAgentBuilt(memberConfigId)   // ensures the cached McpToolset + standalone runner exist
        def cfg
        try {
            def ec = sharedSessionService.ecf.getExecutionContext()
            boolean wasDisabled = ec.artifactExecution.disableAuthz()
            try { cfg = ec.entity.find('moqui.adk.AdkAgentConfig').condition('adkAgentConfigId', memberConfigId).one() }
            finally { if (!wasDisabled) ec.artifactExecution.enableAuthz() }
        } catch (Exception e) { logger.warn("buildMemberInstance(${memberConfigId}) load failed: ${e.message}"); return null }
        if (!cfg) return null
        boolean allowWrites = (cfg.toolMode ?: 'full') != 'readOnly'
        List tools = assembleFunctionTools(allowWrites)
        def ts = configMcpToolsets[memberConfigId]
        if (ts) tools.add(ts)
        return LlmAgent.builder()
                .name(sanitizeAgentName((cfg.agentName ?: memberConfigId) as String))
                .description((cfg.description ?: cfg.agentName ?: 'GrowERP agent') as String)
                .instruction(CONTEXT_PREAMBLE + ((cfg.instruction ?: '') as String))
                .model(modelArg)
                .tools(tools)
                .build()
    }

    private static LlmAgent buildOrchestrator(String configId, String ownerPartyId,
                                              String agentName, def modelArg, Map orch) {
        def members = loadTeamMembers(configId, ownerPartyId)
        if (!members) {
            logger.warn("Coordinator ${configId} has no enabled team members — leaving as a plain agent")
            return null
        }
        String type = orch.type ?: 'router'

        // ── Deterministic workflows: Sequential / Parallel / Loop run their sub-agents (no LLM
        //    picking). Sub-agents must be FRESH instances (they get a parent). ──
        if (type in ['sequential', 'parallel', 'loop']) {
            List<com.google.adk.agents.BaseAgent> subAgents = []
            buildingConfigs.add(configId)
            try {
                for (def m in members) {
                    if (m.memberConfigId == configId) continue
                    def inst = buildMemberInstance(m.memberConfigId as String, modelArg)
                    if (inst != null) subAgents.add(inst)
                }
            } finally { buildingConfigs.remove(configId) }
            if (subAgents.isEmpty()) {
                logger.warn("Workflow ${configId}: no member agents could be built — leaving as a plain agent")
                return null
            }
            String wfName = sanitizeAgentName(agentName ?: (type + '_' + configId))
            String wfDesc = "GrowERP ${type} workflow over ${subAgents.size()} specialist(s)"
            switch (type) {
                case 'sequential':
                    return com.google.adk.agents.SequentialAgent.builder()
                            .name(wfName).description(wfDesc).subAgents(subAgents).build()
                case 'parallel':
                    return com.google.adk.agents.ParallelAgent.builder()
                            .name(wfName).description(wfDesc).subAgents(subAgents).build()
                case 'loop':
                    return com.google.adk.agents.LoopAgent.builder()
                            .name(wfName).description(wfDesc)
                            .maxIterations((orch.loopMax ?: 3) as Integer)
                            .subAgents(subAgents).build()
            }
        }

        // ── Router (default): LLM picks a specialist, each wrapped as an AgentTool. ──
        buildingConfigs.add(configId)
        List memberTools = []
        List<String> roster = []
        try {
            for (def m in members) {
                if (m.memberConfigId == configId) continue   // no self-membership
                LlmAgent ma = ensureAgentBuilt(m.memberConfigId)
                if (ma == null) continue
                memberTools.add(com.google.adk.tools.AgentTool.create(ma))
                roster.add('- ' + ma.name() + (m.description ? (': ' + m.description) : ''))
            }
        } finally {
            buildingConfigs.remove(configId)
        }
        if (memberTools.isEmpty()) {
            logger.warn("Coordinator ${configId}: no member agents could be built — leaving as a plain agent")
            return null
        }
        // Give the coordinator its own Moqui MCP toolset too, so it can answer simple questions
        // and emit screen directives directly without always delegating.
        def own = configMcpToolsets[configId]
        if (own) memberTools.add(own)

        String coordInstr = CONTEXT_PREAMBLE + '''\
You are the COORDINATOR agent for this company. You lead a team of specialist agents, each
exposed to you as a tool you can call with a natural-language request:
''' + roster.join('\n') + '''

When a request matches a specialist, CALL that specialist's tool with the user's full request and
relay (or briefly summarise) its answer — never fabricate what a specialist would say. You may call
more than one specialist and combine their answers. For general questions you can answer directly or
use your own Moqui tools. Keep delegation minimal: pick the best-matching specialist, call it once.
'''
        return LlmAgent.builder()
                .name(agentName ?: ('coordinator_' + configId))
                .description('GrowERP coordinator delegating to specialist agents')
                .instruction(coordInstr)
                .model(modelArg)
                .tools(memberTools)
                .build()
    }

    /** Close every McpToolset (per-config, external, default). Idempotent: a re-close is a
     *  no-op. Shared by destroy() and the JVM shutdown hook. */
    static void closeAllToolsets() {
        // Close all per-config toolsets first — this signals the SSE clients to stop
        // retrying before the HTTP port goes away, suppressing ConnectException floods.
        configMcpToolsets.values().each { ts ->
            try { ts?.close() } catch (Exception e) {
                if (e.message?.contains('ConnectException') || e.cause instanceof java.net.ConnectException)
                    logger.warn("McpToolset closed during shutdown (expected): ${e.message}")
                else
                    logger.warn("Error closing per-config McpToolset: ${e.message}")
            }
        }
        configMcpToolsets.clear()
        configExternalToolsets.values().each { list ->
            list?.each { ts ->
                try { ts?.close() } catch (Exception e) {
                    logger.warn("Error closing external McpToolset: ${e.message}")
                }
            }
        }
        configExternalToolsets.clear()
        if (mcpToolset != null) {
            try {
                logger.info('Closing ADK McpToolset...')
                mcpToolset.close()
            } catch (Exception e) {
                logger.warn("McpToolset close during shutdown: ${e.message}")
            }
            mcpToolset = null
        }
    }

    static void destroy() {
        shuttingDown = true
        closeAllToolsets()
        registry.clear()
        agentRegistry.clear()
        tenantRegistry.clear()
        sessionOwn.clear()
        turnCounts.clear()
        providerRegistry.clear()
        sharedSessionService = null
        mcpApiKey = null
    }
}
