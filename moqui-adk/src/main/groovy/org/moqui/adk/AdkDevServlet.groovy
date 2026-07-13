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

import groovy.json.JsonOutput
import groovy.json.JsonSlurper
import jakarta.servlet.http.HttpServlet
import jakarta.servlet.http.HttpServletRequest
import jakarta.servlet.http.HttpServletResponse
import org.moqui.context.ExecutionContextFactory
import org.moqui.resource.ResourceReference
import org.slf4j.Logger
import org.slf4j.LoggerFactory

/**
 * Serves the ADK Angular DevUI at /adk/* together with the ADK REST API.
 *
 * Static SPA assets are loaded from component://moqui-adk/screen/adk-ui/
 * (populated at Gradle build time by the extractAdkBrowserAssets task).
 *
 * ADK REST endpoints implemented:
 *   GET  /list-apps
 *   POST /apps/{app}/users/{uid}/sessions
 *   GET  /apps/{app}/users/{uid}/sessions[/{sid}]
 *   DELETE /apps/{app}/users/{uid}/sessions/{sid}
 *   POST /run        — synchronous, returns event array
 *   POST /run_sse    — Server-Sent Events stream
 */
class AdkDevServlet extends HttpServlet {

    private static final Logger logger = LoggerFactory.getLogger(AdkDevServlet.class)

    static final String STATIC_ROOT = 'component://moqui-adk/screen/adk-ui'

    static final Map<String, String> MIME_TYPES = [
        '.html' : 'text/html; charset=utf-8',
        '.js'   : 'application/javascript',
        '.mjs'  : 'application/javascript',
        '.css'  : 'text/css',
        '.svg'  : 'image/svg+xml',
        '.json' : 'application/json',
        '.png'  : 'image/png',
        '.jpg'  : 'image/jpeg',
        '.ico'  : 'image/x-icon',
        '.woff' : 'font/woff',
        '.woff2': 'font/woff2',
        '.txt'  : 'text/plain',
    ].asImmutable()

    @Override
    protected void service(HttpServletRequest req, HttpServletResponse resp) {
        String pathInfo = req.pathInfo ?: '/'
        String method   = req.method

        addCorsHeaders(req, resp)
        if (method == 'OPTIONS') { resp.status = 204; return }

        resp.setHeader('Cache-Control', 'no-cache, no-store')

        // ── API routes ────────────────────────────────────────────────────────
        if (pathInfo == '/list-apps' || pathInfo == '/list-apps/') {
            AdkManager.lazyInit(ecf(req))
            handleListApps(resp)
            return
        }
        if (pathInfo.startsWith('/apps/')) {
            AdkManager.lazyInit(ecf(req))
            handleApps(pathInfo, method, req, resp)
            return
        }
        if (pathInfo == '/run' && method == 'POST') {
            AdkManager.lazyInit(ecf(req))
            handleRun(req, resp, false)
            return
        }
        if (pathInfo == '/run_sse' && method == 'POST') {
            AdkManager.lazyInit(ecf(req))
            handleRun(req, resp, true)
            return
        }
        if (pathInfo == '/configs' || pathInfo == '/configs/') {
            handleConfigs(pathInfo, method, req, resp)
            return
        }
        if (pathInfo.startsWith('/configs/')) {
            handleConfigs(pathInfo, method, req, resp)
            return
        }

        // ── Static SPA assets ─────────────────────────────────────────────────
        serveStatic(pathInfo, resp)
    }

    // ── API handlers ──────────────────────────────────────────────────────────

    private void handleListApps(HttpServletResponse resp) {
        json(resp, AdkManager.listAgents())
    }

    private void handleApps(String path, String method, HttpServletRequest req, HttpServletResponse resp) {
        // path: /apps/{app}/users/{userId}/sessions[/{sessionId}]
        String[] parts = path.split('/')
        if (parts.length < 6) { resp.sendError(400, 'Invalid path'); return }
        String userId    = parts[4]
        String sessionId = parts.length > 6 ? parts[6] : null

        switch (method) {
            case 'POST':
                // Read body FIRST (before buildContext → initWebFacade calls getReader);
                // the client may seed session state (e.g. screenCatalog) here.
                Map clientState = [:]
                try {
                    String rawBody = req.reader.text
                    if (rawBody) {
                        def parsed = new JsonSlurper().parseText(rawBody)
                        if (parsed instanceof Map && parsed.state instanceof Map) {
                            clientState = parsed.state as Map
                        }
                    }
                } catch (Exception ignored) {}
                Map<String, Object> initialState = buildContext(req, resp)
                initialState.putAll(clientState)
                try {
                    json(resp, AdkManager.createSession(userId, initialState))
                } catch (IllegalStateException e) {
                    // Expected when no LLM key is configured — return a clean 503 + JSON
                    // (the chat UI matches the message to prompt for System Setup) instead
                    // of letting it bubble to Jetty as a 500 with a stack trace.
                    logger.warn("ADK session not created: ${e.message}")
                    resp.status = 503
                    json(resp, [error: e.message])
                }
                break
            case 'GET':

                if (sessionId) {
                    def s = AdkManager.getSession(userId, sessionId)
                    if (!s) { resp.sendError(404); return }
                    json(resp, s)
                } else {
                    json(resp, AdkManager.listSessions(userId))
                }
                break
            case 'DELETE':
                if (sessionId) AdkManager.deleteSession(userId, sessionId)
                resp.status = 200
                break
            default:
                resp.sendError(405)
        }
    }

    private void handleRun(HttpServletRequest req, HttpServletResponse resp, boolean sse) {

        def body      = new JsonSlurper().parse(req.inputStream)
        String userId = (body.userId    ?: 'anonymous') as String
        String sid    = (body.sessionId ?: '') as String
        String text   = (body.newMessage?.parts?.find { it.text }?.text ?: '') as String

        if (!sid) sid = AdkManager.createSession(userId, buildContext(req, resp)).id as String

        if (sse) {
            resp.contentType = 'text/event-stream; charset=utf-8'
            resp.setHeader('X-Accel-Buffering', 'no')
            resp.setHeader('Connection', 'keep-alive')
            def writer = resp.writer
            AdkManager.runAgentSse(userId, sid, text,
                { Map event ->
                    writer.write("data: ${JsonOutput.toJson(event)}\n\n")
                    writer.flush()
                },
                { Throwable err ->
                    if (err) {
                        logger.error("ADK run_sse error (session=${sid}): ${err.message}", err)
                        writer.write("data: ${JsonOutput.toJson([error: err.message])}\n\n")
                    }
                    writer.write("data: [DONE]\n\n")
                    writer.flush()
                }
            )
        } else {
            json(resp, AdkManager.runAgent(userId, sid, text))
        }
    }

    // ── Agent config CRUD (/adk/configs) ─────────────────────────────────────

    private void handleConfigs(String path, String method, HttpServletRequest req, HttpServletResponse resp) {
        ExecutionContextFactory ecf = ecf(req)

        // Read POST body FIRST — initWebFacade internally calls getReader(),
        // and Jetty forbids mixing getReader() with getInputStream().
        String rawBody = (method == 'POST') ? req.reader.text : null

        // configId from path: /configs/{configId}
        String[] parts = path.split('/')
        String configId = parts.length > 2 ? parts[2] : null

        def ec = ecf.getExecutionContext()
        try {
            // Authenticate the caller from HTTP headers (api_key / moquiSessionToken).
            // Body is already consumed above so getReader() inside initWebFacade is safe.
            if (ec.getWebImpl() == null) {
                try {
                    ec.initWebFacade(req.servletContext.getInitParameter('moqui-name') ?: 'webroot', req, resp)
                } catch (Exception ignored) {}
            }

            // Resolve ownerPartyId for tenant-scoping
            String ownerPartyId = null
            if (ec.user?.userId) {
                try {
                    boolean wasDisabled = ec.artifactExecution.disableAuthz()
                    try {
                        def userAcct = ec.entity.find('moqui.security.UserAccount')
                            .condition('userId', ec.user.userId)
                            .selectField('partyId').one()
                        String userPartyId = userAcct?.partyId
                        if (userPartyId) {
                            def userParty = ec.entity.find('mantle.party.Party')
                                .condition('partyId', userPartyId)
                                .selectField('ownerPartyId').one()
                            ownerPartyId = userParty?.ownerPartyId ?: null
                        }
                    } finally { if (!wasDisabled) ec.artifactExecution.enableAuthz() }
                } catch (Exception ignored) {}
            }

            switch (method) {
                case 'GET':
                    boolean wasDisabled = ec.artifactExecution.disableAuthz()
                    try {
                        def find = ec.entity.find('moqui.adk.AdkAgentConfig')
                        if (ownerPartyId) find = find.condition('ownerPartyId', ownerPartyId)
                        def list = find.list().collect { cfg ->
                            [adkAgentConfigId   : cfg.adkAgentConfigId,
                             agentName          : cfg.agentName,
                             modelName          : cfg.modelName,
                             instruction        : cfg.instruction,
                             description        : cfg.description,
                             enabled            : cfg.enabled,
                             scheduleExpression : cfg.scheduleExpression,
                             scheduleEnabled    : cfg.scheduleEnabled,
                             schedulePrompt     : cfg.schedulePrompt,
                             scheduleChatRoomId : cfg.scheduleChatRoomId]
                        }
                        json(resp, list)
                    } finally { if (!wasDisabled) ec.artifactExecution.enableAuthz() }
                    break

                case 'POST':
                    def body = new JsonSlurper().parseText(rawBody ?: '{}') as Map
                    Map params = [
                        ownerPartyId      : ownerPartyId ?: body.ownerPartyId,
                        agentName         : body.agentName,
                        modelName         : body.modelName ?: 'gemini-2.5-flash-lite',
                        instruction       : body.instruction,
                        description       : body.description,
                        scheduleExpression: body.scheduleExpression,
                        scheduleEnabled   : body.scheduleEnabled ?: 'N',
                        schedulePrompt    : body.schedulePrompt,
                        scheduleChatRoomId: body.scheduleChatRoomId,
                    ]
                    if (body.apiKey) params.apiKey = body.apiKey
                    // Servlet already enforces AdkUsers/ADMIN access; skip redundant
                    // artifact-level authz check so the call runs as the authenticated user.
                    boolean wasDisabledPost = ec.artifactExecution.disableAuthz()
                    Map result
                    try {
                        result = ec.service.sync()
                            .name('AdkServices.update#AgentConfig')
                            .parameters(params).call()
                    } finally { if (!wasDisabledPost) ec.artifactExecution.enableAuthz() }
                    json(resp, [adkAgentConfigId: result.adkAgentConfigId])
                    break

                case 'DELETE':
                    if (!configId) { resp.sendError(400, 'configId required'); return }
                    boolean wasDisabled2 = ec.artifactExecution.disableAuthz()
                    try {
                        def cfg = ec.entity.find('moqui.adk.AdkAgentConfig')
                            .condition('adkAgentConfigId', configId).one()
                        if (!cfg) { resp.sendError(404); return }
                        cfg.delete()
                        resp.status = 200
                        json(resp, [deleted: configId])
                    } finally { if (!wasDisabled2) ec.artifactExecution.enableAuthz() }
                    break

                default:
                    resp.sendError(405)
            }
        } finally {
            ec.destroy()
        }
    }

    // ── Static file serving ───────────────────────────────────────────────────

    private void serveStatic(String path, HttpServletResponse resp) {
        if (path == '/' || path.isEmpty()) path = '/index.html'
        // SPA client-side routing: paths without a file extension → index.html
        if (!path.contains('.')) path = '/index.html'

        String ext      = path.contains('.') ? path.substring(path.lastIndexOf('.')) : ''
        resp.contentType = (MIME_TYPES[ext] ?: 'application/octet-stream')

        ExecutionContextFactory ecf =
            (ExecutionContextFactory) getServletContext().getAttribute('executionContextFactory')

        if (ecf == null) { resp.sendError(503, 'ExecutionContextFactory not available'); return }

        ResourceReference ref = ecf.resource.getLocationReference("${STATIC_ROOT}${path}")
        if (!ref || !ref.getExists()) {
            if (path != '/index.html') {
                serveStatic('/index.html', resp)  // SPA fallback
            } else {
                resp.sendError(404, "ADK DevUI assets not found. Run './gradlew build' first.")
            }
            return
        }

        InputStream stream = ref.openStream()
        try {
            resp.outputStream << stream
        } finally {
            stream?.close()
        }
    }

    // ── Utility ───────────────────────────────────────────────────────────────

    private ExecutionContextFactory ecf(HttpServletRequest req) {
        (ExecutionContextFactory) req.servletContext.getAttribute('executionContextFactory')
    }

    private static void addCorsHeaders(HttpServletRequest req, HttpServletResponse resp) {
        String origin = req.getHeader('Origin')
        if (origin) {
            resp.setHeader('Access-Control-Allow-Origin', origin)
            resp.setHeader('Access-Control-Allow-Credentials', 'true')
            resp.setHeader('Vary', 'Origin')
        } else {
            resp.setHeader('Access-Control-Allow-Origin', '*')
        }
        resp.setHeader('Access-Control-Allow-Methods', 'GET, POST, DELETE, OPTIONS')
        resp.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization, api_key, moquiSessionToken')
        resp.setHeader('Access-Control-Max-Age', '3600')
    }

    /**
     * Build a session-state map from the Moqui ExecutionContext so that the ADK
     * agent's instruction preamble can resolve {key} placeholders.
     *
     * Gathered fields: userId, username, userFullName, organizationName,
     * companyPseudoId, tenantId (ownerPartyId), timeZone, locale.
     */
    private Map<String, Object> buildContext(HttpServletRequest req, HttpServletResponse resp) {
        Map<String, Object> ctx = [
            userId          : 'anonymous',
            username        : 'anonymous',
            userFullName    : '',
            organizationName: '',
            companyPseudoId : '',
            tenantId        : 'DEFAULT',
            timeZone        : 'UTC',
            locale          : 'en_US',
            // Default for the {screenCatalog} instruction placeholder; the Flutter
            // client overrides this with the real catalog on session create.
            screenCatalog   : '[]',
            // {memory} — rolling per-(owner,user) summary; filled below when present.
            memory          : '',
        ]
        try {
            ExecutionContextFactory ecf = ecf(req)
            if (!ecf) return ctx
            def ec = ecf.getExecutionContext()
            try {
                // Initialize web facade to natively parse api_key/moquiSessionToken from headers.
                // Wrapped separately: initWebFacade may throw during visit/screen-URL stats tracking
                // for non-screen paths like /adk/apps/... — but api_key auth inside
                // initFromHttpRequest runs first and may have already succeeded.
                if (ec.getWebImpl() == null) {
                    try {
                        ec.initWebFacade(req.servletContext.getInitParameter("moqui-name") ?: "webroot", req, resp)
                    } catch (Exception ignored) {}
                }

                // Always read user after the initWebFacade attempt — auth may have succeeded
                // even if WebFacade setup partially failed (e.g. screen URL resolution error).
                if (ec.user?.userId) {
                    ctx.userId   = ec.user.userId   ?: 'anonymous'
                    ctx.username = ec.user.username ?: 'anonymous'
                    ctx.timeZone = ec.user.timeZone?.ID ?: 'UTC'
                    ctx.locale   = ec.user.locale?.toString() ?: 'en_US'
                }

                // Resolve full name, organization, company pseudoId, and ownerPartyId (GrowERP tenant)
                if (ec.user?.userId) {
                    try {
                        boolean wasDisabled = ec.artifactExecution.disableAuthz()
                        try {
                            // userFullName lives on UserAccount; UserFacade has no getter for it
                            def userAcct = ec.entity.find('moqui.security.UserAccount')
                                .condition('userId', ec.user.userId)
                                .selectField('userFullName').selectField('partyId')
                                .one()
                            ctx.userFullName = userAcct?.userFullName ?: ''

                            // ownerPartyId is GrowERP's tenant identifier — on mantle.party.Party
                            String userPartyId = userAcct?.partyId
                            if (userPartyId) {
                                def userParty = ec.entity.find('mantle.party.Party')
                                    .condition('partyId', userPartyId)
                                    .selectField('ownerPartyId')
                                    .one()
                                String ownerPartyId = userParty?.ownerPartyId
                                if (ownerPartyId) {
                                    ctx.tenantId = ownerPartyId

                                    // Load rolling memory summary for this (owner,user) → {memory}.
                                    def mem = ec.entity.find('moqui.adk.AdkMemory')
                                        .condition('ownerPartyId', ownerPartyId)
                                        .condition('userId', ec.user.userId)
                                        .one()
                                    if (mem?.summaryText) {
                                        ctx.memory = 'What you remember about this user/company from past ' +
                                            'conversations (use it for continuity; do not repeat it verbatim):\n' +
                                            mem.summaryText
                                    }

                                    // Main company = OrgInternal party for this owner
                                    def companyList = ec.entity.find('mantle.party.PartyDetailAndRole')
                                        .condition('ownerPartyId', ownerPartyId)
                                        .condition('partyTypeEnumId', 'PtyOrganization')
                                        .condition('roleTypeId', 'OrgInternal')
                                        .limit(1).list()
                                    String companyPartyId = companyList[0]?.partyId
                                    if (companyPartyId) {
                                        def org = ec.entity.find('mantle.party.Organization')
                                            .condition('partyId', companyPartyId).one()
                                        ctx.organizationName = org?.organizationName ?: ''

                                        def companyParty = ec.entity.find('mantle.party.Party')
                                            .condition('partyId', companyPartyId)
                                            .selectField('pseudoId').one()
                                        ctx.companyPseudoId = companyParty?.pseudoId ?: ''
                                    }
                                }
                            }
                        } finally {
                            if (!wasDisabled) ec.artifactExecution.enableAuthz()
                        }
                    } catch (Exception ignored) { /* best-effort */ }
                }
            } finally {
                ec.destroy()
            }
        } catch (Exception e) {
            // Context is best-effort; never block session creation
        }
        ctx
    }

    private static void json(HttpServletResponse resp, Object data) {
        resp.contentType = 'application/json; charset=utf-8'
        resp.writer.write(JsonOutput.toJson(data))
    }

    @Override
    void destroy() {
        AdkManager.destroy()
        super.destroy()
    }
}
