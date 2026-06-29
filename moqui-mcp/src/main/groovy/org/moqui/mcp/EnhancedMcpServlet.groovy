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
package org.moqui.mcp

import groovy.json.JsonSlurper
import groovy.json.JsonOutput
import org.moqui.impl.context.ExecutionContextFactoryImpl
import org.moqui.context.ArtifactAuthorizationException
import org.moqui.context.ArtifactTarpitException
import org.moqui.impl.context.ExecutionContextImpl
import org.moqui.entity.EntityValue
import org.moqui.mcp.adapter.McpSessionAdapter
import org.moqui.mcp.adapter.McpSession
import org.moqui.mcp.adapter.McpToolAdapter
import org.moqui.mcp.adapter.MoquiNotificationMcpBridge
import org.moqui.mcp.transport.SseTransport
import org.slf4j.Logger
import org.slf4j.LoggerFactory

import jakarta.servlet.ServletConfig
import jakarta.servlet.ServletException
import jakarta.servlet.http.HttpServlet
import jakarta.servlet.http.HttpServletRequest
import jakarta.servlet.http.HttpServletResponse

/**
 * Enhanced MCP Servlet with adapter-based architecture.
 * Uses adapters for session management, tool dispatch, and notifications.
 * This servlet acts as an orchestrator, delegating to specialized adapters.
 */
class EnhancedMcpServlet extends HttpServlet {
    protected final static Logger logger = LoggerFactory.getLogger(EnhancedMcpServlet.class)

    private volatile boolean shuttingDown = false
    private final java.util.concurrent.atomic.AtomicInteger activeSseCount =
            new java.util.concurrent.atomic.AtomicInteger(0)

    private JsonSlurper jsonSlurper = new JsonSlurper()

    // Adapter instances
    private McpSessionAdapter sessionAdapter
    private McpToolAdapter toolAdapter
    private SseTransport transport
    private MoquiNotificationMcpBridge notificationBridge

    // Visit cache to reduce database access and prevent lock contention
    private final Map<String, EntityValue> visitCache = new java.util.concurrent.ConcurrentHashMap<>()

    // ADK agent identity captured from the SSE-connect request headers, keyed by MCP
    // sessionId. Tool calls dispatch on a detached worker thread with no HttpServletRequest,
    // so the governance gate / searchKnowledge resolve the calling agent + tenant by
    // sessionId from here instead of from request headers. (static: shared with McpServices.xml)
    static final Map<String, Map<String, String>> adkSessionHeaders =
            new java.util.concurrent.ConcurrentHashMap<>()

    /** Headers captured for an MCP sessionId, e.g. [configId:.., owner:..]; null if none. */
    static Map<String, String> getAdkHeaders(String sessionId) {
        sessionId ? adkSessionHeaders.get(sessionId) : null
    }

    // Throttled session activity tracking
    private final Map<String, Long> lastActivityUpdate = new java.util.concurrent.ConcurrentHashMap<>()
    private static final long ACTIVITY_UPDATE_INTERVAL_MS = 30000 // 30 seconds

    // Configuration parameters
    private String sseEndpoint = "/sse"
    private String messageEndpoint = "/message"
    private int keepAliveIntervalSeconds = 30
    private int maxConnections = 100

    @Override
    void init(ServletConfig config) throws ServletException {
        super.init(config)

        // Initialize adapters
        sessionAdapter = new McpSessionAdapter()
        toolAdapter = new McpToolAdapter()
        transport = new SseTransport(sessionAdapter)

        // Initialize notification bridge
        notificationBridge = new MoquiNotificationMcpBridge()

        // Read configuration from servlet init parameters
        sseEndpoint = config.getInitParameter("sseEndpoint") ?: sseEndpoint
        messageEndpoint = config.getInitParameter("messageEndpoint") ?: messageEndpoint
        keepAliveIntervalSeconds = config.getInitParameter("keepAliveIntervalSeconds")?.toInteger() ?: keepAliveIntervalSeconds
        maxConnections = config.getInitParameter("maxConnections")?.toInteger() ?: maxConnections

        String webappName = config.getInitParameter("moqui-name") ?:
            config.getServletContext().getInitParameter("moqui-name")

        // Register servlet instance in context for service access
        config.getServletContext().setAttribute("enhancedMcpServlet", this)

        // Get ECF and register notification bridge
        ExecutionContextFactoryImpl ecfi =
            (ExecutionContextFactoryImpl) config.getServletContext().getAttribute("executionContextFactory")
        if (ecfi) {
            notificationBridge.init(ecfi)
            notificationBridge.setTransport(transport)
            ecfi.registerNotificationMessageListener(notificationBridge)
            logger.info("Registered MoquiNotificationMcpBridge with ECF")
        }

        logger.info("EnhancedMcpServlet initialized with adapter architecture for webapp ${webappName}")
        logger.info("SSE endpoint: ${sseEndpoint}, Message endpoint: ${messageEndpoint}")
        logger.info("Keep-alive interval: ${keepAliveIntervalSeconds}s, Max connections: ${maxConnections}")

        // Pre-warm the growerp service name cache in background so the first moqui_search_services
        // call doesn't incur the getKnownServiceNames() filesystem scan delay.
        if (ecfi) {
            final ExecutionContextFactoryImpl ecfiRef = ecfi
            Thread.start {
                try {
                    Thread.sleep(12000) // wait for Moqui to finish startup
                    def warmEc = ecfiRef.getEci()
                    try {
                        org.moqui.mcp.adapter.McpToolAdapter.getCachedGroWerpServiceNames(warmEc)
                    } finally {
                        warmEc.destroy()
                    }
                    // Pre-compile McpServices Groovy scripts so the Groovy global-transform scan
                    // completes before McpToolset.getTools() is triggered by the first user message.
                    // Without this, the very first Groovy compilation in the JVM may fail with
                    // "IO Exception attempting to load global transforms" for groovy-5.0.3.jar,
                    // causing McpToolset to exhaust its 3 retries and stop retrying permanently.
                    try {
                        def preEc = ecfiRef.getEci()
                        try {
                            preEc.artifactExecution.disableAuthz()
                            preEc.service.sync().name('McpServices.mcp#Initialize')
                                .parameters([protocolVersion: '2024-11-05', sessionId: 'prewarm-compile']).call()
                        } catch (Exception ignored) { /* expected; compilation side-effect already happened */ }
                        finally { preEc.destroy() }
                    } catch (Exception e) {
                        logger.warn("McpServices prewarm failed: ${e.message}")
                    }
                } catch (Exception e) {
                    logger.warn("Service name cache pre-warm failed: ${e.message}")
                }
            }
        }
    }

    @Override
    void service(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        ExecutionContextFactoryImpl ecfi =
            (ExecutionContextFactoryImpl) getServletContext().getAttribute("executionContextFactory")
        String webappName = getInitParameter("moqui-name") ?:
            getServletContext().getInitParameter("moqui-name")

        if (ecfi == null || webappName == null) {
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                "System is initializing, try again soon.")
            return
        }

        // Handle CORS
        if (handleCors(request, response)) return

        long startTime = System.currentTimeMillis()

        if (logger.traceEnabled) {
            logger.trace("Start Enhanced MCP request to [${request.getPathInfo()}] at time [${startTime}] in session [${request.session.id}] thread [${Thread.currentThread().id}:${Thread.currentThread().name}]")
        }

        ExecutionContextImpl ec = ecfi.activeContext.get()
        if (ec == null) {
            logger.warn("No ExecutionContext found from MoquiAuthFilter, creating new one")
            ec = ecfi.getEci()
        }

        try {
            // Read request body early before any other processing can consume it
            String requestBody = null
            if ("POST".equals(request.getMethod())) {
                try {
                    logger.debug("Early reading request body, content length: ${request.getContentLength()}")
                    BufferedReader reader = request.getReader()
                    StringBuilder body = new StringBuilder()
                    String line
                    int lineCount = 0
                    while ((line = reader.readLine()) != null) {
                        body.append(line)
                        lineCount++
                    }
                    requestBody = body.toString()
                    logger.debug("Early read ${lineCount} lines, request body length: ${requestBody.length()}")
                } catch (Exception e) {
                    logger.error("Failed to read request body early: ${e.message}")
                }
            }

            // Initialize web facade early to set up session and visit context
            try {
                ec.initWebFacade(webappName, request, response)
            } catch (Exception e) {
                logger.debug("Web facade initialization (non-screen path): ${e.message}")
            }

            // Per the MCP specification, 'initialize' and 'ping' are public handshake methods
            // that must be reachable without prior authentication.  All other methods still
            // require a valid authenticated session.
            if (!ec.user?.userId) {
                // Peek at the JSON-RPC method from the already-read body
                String rpcMethod = null
                if (requestBody) {
                    try {
                        def peeked = jsonSlurper.parseText(requestBody)
                        rpcMethod = peeked?.method?.toString()
                    } catch (Exception ignored) { }
                }

                // MCP-standard public (unauthenticated) methods
                boolean isPublicMethod = rpcMethod in ["initialize", "ping", "notifications/initialized"]

                if (!isPublicMethod) {
                    logger.warn("Enhanced MCP - no authenticated user after MoquiAuthFilter (method: ${rpcMethod})")
                    response.setStatus(HttpServletResponse.SC_UNAUTHORIZED)
                    response.setContentType("application/json")
                    response.writer.write(JsonOutput.toJson([
                        jsonrpc: "2.0",
                        error: [code: -32003, message: "Authentication required. Use Basic auth with valid Moqui credentials."],
                        id: null
                    ]))
                    return
                }

                logger.debug("Allowing unauthenticated MCP public method: ${rpcMethod}")
            }

            // Get Visit created by web facade (may be null for stateless API-key auth)
            def visit = ec.user.getVisit()
            if (!visit) {
                logger.debug("No Visit for request (stateless API-key auth) — proceeding without visit")
            }

            // Route based on request method and path
            String requestURI = request.getRequestURI()
            String method = request.getMethod()
            logger.debug("Enhanced MCP Request: ${method} ${requestURI} - Content-Length: ${request.getContentLength()}")

            if ("GET".equals(method) && requestURI.endsWith("/sse")) {
                handleSseConnection(request, response, ec, webappName)
            } else if ("POST".equals(method) && requestURI.endsWith("/message")) {
                handleMessage(request, response, ec, requestBody)
            } else if ("POST".equals(method) && (requestURI.equals("/mcp") || requestURI.endsWith("/mcp"))) {
                handleJsonRpc(request, response, ec, webappName, requestBody, visit)
            } else if ("GET".equals(method) && (requestURI.equals("/mcp") || requestURI.endsWith("/mcp"))) {
                handleSseConnection(request, response, ec, webappName)
            } else {
                // Fallback to JSON-RPC handling
                handleJsonRpc(request, response, ec, webappName, requestBody, visit)
            }

        } catch (ArtifactAuthorizationException e) {
            logger.warn("Enhanced MCP Access Forbidden (no authz): " + e.message)
            response.setStatus(HttpServletResponse.SC_FORBIDDEN)
            response.setContentType("application/json")
            def msg = e.message?.toString() ?: "Access forbidden"
            response.writer.write("{\"jsonrpc\":\"2.0\",\"error\":{\"code\":-32001,\"message\":\"Access Forbidden: ${msg.replace("\"", "\\\"")}\"},\"id\":null}")
        } catch (ArtifactTarpitException e) {
            logger.warn("Enhanced MCP Too Many Requests (tarpit): " + e.message)
            response.setStatus(429)
            if (e.getRetryAfterSeconds()) {
                response.addIntHeader("Retry-After", e.getRetryAfterSeconds())
            }
            response.setContentType("application/json")
            response.writer.write(JsonOutput.toJson([
                jsonrpc: "2.0",
                error: [code: -32002, message: "Too Many Requests: " + e.message],
                id: null
            ]))
        } catch (Throwable t) {
            logger.error("Error in Enhanced MCP request", t)
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR)
            response.setContentType("application/json")
            def errorMsg = t.message?.toString() ?: "Unknown error"
            response.writer.write("{\"jsonrpc\":\"2.0\",\"error\":{\"code\":-32603,\"message\":\"Internal error: ${errorMsg.replace("\"", "\\\"")}\"},\"id\":null}")
        }
    }

    private void handleSseConnection(HttpServletRequest request, HttpServletResponse response, ExecutionContextImpl ec, String webappName)
            throws IOException {

        logger.debug("Handling Enhanced SSE connection from ${request.remoteAddr}")

        // Check for existing session ID
        String sessionId = request.getHeader("Mcp-Session-Id")
        def visit = null
        String userId = ec.user.userId?.toString()

        // If we have a session ID, validate it
        if (sessionId) {
            def session = sessionAdapter.getSession(sessionId)
            if (session) {
                // Verify user has access
                if (session.userId != userId) {
                    logger.warn("Session userId ${session.userId} doesn't match current user ${userId} - access denied")
                    response.sendError(HttpServletResponse.SC_FORBIDDEN, "Access denied for session: " + sessionId)
                    return
                }
                visit = getCachedVisit(ec, sessionId)
            } else {
                logger.warn("Session not found: ${sessionId}")
                response.sendError(HttpServletResponse.SC_NOT_FOUND, "Session not found: " + sessionId)
                return
            }
        }

        // Create new Visit/session if needed
        if (!visit) {
            try {
                // initWebFacade was already called in service(); call again only if needed
                if (!ec.web) {
                    ec.initWebFacade(webappName, request, response)
                }
                visit = ec.user.getVisit()

                if (visit) {
                    // Session-cookie based auth: use Visit ID as session key
                    sessionId = visit.visitId?.toString()
                    sessionAdapter.createSession(sessionId, ec.user.userId?.toString())
                    logger.info("Created new session ${sessionId} for user ${ec.user.username}")
                } else {
                    // Stateless API-key auth: no Visit is created. Use a unique UUID per connection so
                    // concurrent SSE connections from the same user (e.g. McpToolset reconnects) don't
                    // overwrite each other's SSE writers and lose in-flight tool call responses.
                    if (!ec.user?.userId) {
                        logger.warn("SSE connection attempted without authenticated user")
                        response.sendError(HttpServletResponse.SC_UNAUTHORIZED, "Authentication required")
                        return
                    }
                    sessionId = java.util.UUID.randomUUID().toString()
                    sessionAdapter.createSession(sessionId, ec.user.userId?.toString())
                    logger.info("API-key auth: created new session ${sessionId} for user ${ec.user.username}")
                }

            } catch (Exception e) {
                logger.error("Failed to create SSE session: ${e.message}", e)
                response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Failed to create session")
                return
            }
        }

        // NOTE: deliberately NOT calling request.startAsync() here. This handler streams the SSE
        // response synchronously, blocking this request thread in the keep-alive loop below for the
        // life of the connection (thread-per-SSE). Once startAsync() is called Jetty switches the
        // output to async mode, where blocking writes/flushes from a thread that never returns to
        // the container get aggregated instead of pushed to the socket — so the `endpoint` event is
        // never delivered and legacy HTTP+SSE clients (google-adk McpToolset) time out after 300s.
        // The periodic ping (every 5s) keeps the connection from hitting Jetty's idle timeout.

        // Set SSE headers
        response.setContentType("text/event-stream")
        response.setCharacterEncoding("UTF-8")
        response.setHeader("Cache-Control", "no-cache")
        response.setHeader("Connection", "keep-alive")
        response.setHeader("Access-Control-Allow-Origin", "*")
        response.setHeader("X-Accel-Buffering", "no")
        response.setHeader("Mcp-Session-Id", sessionId)

        // Capture the calling ADK agent's identity (config + tenant owner) from the SSE
        // request headers — the only point we still have the HttpServletRequest. Tool calls
        // resolve it back by sessionId (see getAdkHeaders / McpServices.xml).
        try {
            String adkCid   = request.getHeader("adk_config_id")
            String adkOwner = request.getHeader("adk_owner_party_id")
            if (adkCid || adkOwner) {
                adkSessionHeaders.put(sessionId, [configId: adkCid, owner: adkOwner])
                logger.info("Captured ADK headers for session ${sessionId}: configId=${adkCid}, owner=${adkOwner}")
            }
        } catch (Exception e) {
            logger.warn("Could not capture ADK headers for session ${sessionId}: ${e.message}")
        }

        // Register SSE writer with transport
        transport.registerSseWriter(sessionId, response.writer)

        activeSseCount.incrementAndGet()
        try {
            // Send endpoint event for backwards compatibility
            if (!request.getHeader("Mcp-Session-Id")) {
                // Determine relative URL for the message endpoint
                String relativeEndpoint = "/mcp/message?sessionId=" + URLEncoder.encode(sessionId, "UTF-8")
                transport.sendSseEventWithId(response.writer, "endpoint", relativeEndpoint, 0)
            }

            // Deliver any queued notifications
            transport.deliverQueuedNotifications(sessionId)

            // Commit the response to the network so the SSE stream actually starts. PrintWriter.flush()
            // alone only flushes into Jetty's output buffer; without flushBuffer() the endpoint event is
            // never sent to the socket, so a legacy HTTP+SSE client (google-adk McpToolset) waits for the
            // endpoint event forever and times out (300s) instead of POSTing initialize/tools/list.
            response.flushBuffer()

            // Keep connection alive with periodic pings.
            // NOTE: response.isCommitted() is TRUE once headers are flushed, so we must NOT
            // use !isCommitted() as the loop condition — that would exit immediately.
            // Instead we loop until the writer signals an error (client disconnected).
            int pingCount = 0
            boolean connectionAlive = true
            while (connectionAlive && !shuttingDown && pingCount < 360) {  // max ~30 minutes (360 × 5s)
                // Sleep 5000ms in increments of 100ms to allow fast shutdown response
                for (int i = 0; i < 50 && !shuttingDown && transport.isSessionActive(sessionId); i++) {
                    Thread.sleep(100)
                }
                if (shuttingDown || !transport.isSessionActive(sessionId)) {
                    connectionAlive = false
                    break
                }

                if (!transport.sendPing(sessionId)) {
                    logger.debug("Ping failed for session ${sessionId}, ending SSE loop")
                    connectionAlive = false
                } else {
                    pingCount++

                    // Update session activity throttled (every 30s)
                    if (pingCount % 6 == 0) {
                        updateSessionActivityThrottled(sessionId)
                    }
                }
            }
            logger.debug("SSE keep-alive loop ended for session ${sessionId} after ${pingCount} pings")

        } catch (InterruptedException e) {
            logger.info("SSE connection interrupted for session ${sessionId}")
            Thread.currentThread().interrupt()
        } catch (Exception e) {
            logger.warn("Enhanced SSE connection error: ${e.message}", e)
        } finally {
            transport.unregisterSseWriter(sessionId)
            adkSessionHeaders.remove(sessionId)
            // Invalidate HTTP session before completing to prevent Jetty session passivation race on shutdown
            try { request.getSession(false)?.invalidate() } catch (Exception ignored) {}
            if (request.isAsyncStarted()) {
                try {
                    request.getAsyncContext().complete()
                } catch (Exception e) {
                    logger.debug("Error completing async context: ${e.message}")
                }
            }
            activeSseCount.decrementAndGet()
        }
    }

    private void handleMessage(HttpServletRequest request, HttpServletResponse response, ExecutionContextImpl ec, String requestBody)
            throws IOException {

        String sessionId = request.getHeader("Mcp-Session-Id") ?: request.getParameter("sessionId")
        def session = sessionAdapter.getSession(sessionId)

        if (!session) {
            response.sendError(HttpServletResponse.SC_NOT_FOUND, "Session not found: " + sessionId)
            return
        }

        // Verify user has access
        if (session.userId != ec.user.userId?.toString()) {
            response.setStatus(HttpServletResponse.SC_FORBIDDEN)
            response.setContentType("application/json")
            response.writer.write(JsonOutput.toJson([
                error: "Access denied for session: " + sessionId
            ]))
            return
        }

        try {
            if (!requestBody || !requestBody.trim()) {
                response.setStatus(HttpServletResponse.SC_BAD_REQUEST)
                response.setContentType("application/json")
                response.writer.write(JsonOutput.toJson([
                    jsonrpc: "2.0",
                    error: [code: -32602, message: "Empty request body"],
                    id: null
                ]))
                return
            }

            // Parse JSON-RPC message
            def rpcRequest
            try {
                rpcRequest = jsonSlurper.parseText(requestBody)
            } catch (Exception e) {
                response.setStatus(HttpServletResponse.SC_BAD_REQUEST)
                response.setContentType("application/json")
                response.writer.write(JsonOutput.toJson([
                    jsonrpc: "2.0",
                    error: [code: -32700, message: "Invalid JSON: " + e.message],
                    id: null
                ]))
                return
            }

            // Validate JSON-RPC 2.0 structure
            if (!rpcRequest?.jsonrpc || rpcRequest.jsonrpc != "2.0" || !rpcRequest?.method) {
                response.setStatus(HttpServletResponse.SC_BAD_REQUEST)
                response.setContentType("application/json")
                response.writer.write(JsonOutput.toJson([
                    jsonrpc: "2.0",
                    error: [code: -32600, message: "Invalid JSON-RPC 2.0 request"],
                    id: rpcRequest?.id ?: null
                ]))
                return
            }
            
            // Handle notifications (messages without an id)
            if (!rpcRequest.containsKey('id')) {
                response.setStatus(HttpServletResponse.SC_ACCEPTED)
                response.writer.flush()
                String notifUsername = ec.user.username
                Thread.start {
                    def asyncEc = ec.factory.getExecutionContext()
                    try {
                        try {
                            if (notifUsername) {
                                asyncEc.user.internalLoginUser(notifUsername)
                            }
                            if (rpcRequest.method == 'notifications/initialized') {
                                logger.info("Session ${sessionId} initialized")
                                sessionAdapter.setSessionState(sessionId, McpSession.STATE_INITIALIZED)
                            } else {
                                processMcpMethod(rpcRequest.method, rpcRequest.params, asyncEc, sessionId, null)
                            }
                        } catch (Exception e) {
                            logger.error("Error processing notification for session ${sessionId}: ${e.message}", e)
                        }
                    } finally {
                        asyncEc.destroy()
                    }
                }
                return
            }

            // Return 202 Accepted immediately to prevent timeout
            response.setStatus(HttpServletResponse.SC_ACCEPTED)
            response.setContentType("application/json")
            response.setCharacterEncoding("UTF-8")
            response.writer.flush()
            
            // Capture username to restore in async thread
            String currentUsername = ec.user.username
            
            // Offload processing
            Thread.start {
                // Initialize a new ExecutionContext for the background thread
                def asyncEc = ec.factory.getExecutionContext()
                try {
                    try {
                        if (currentUsername) {
                            asyncEc.user.internalLoginUser(currentUsername)
                        }
                        def result = processMcpMethod(rpcRequest.method, rpcRequest.params, asyncEc, sessionId, null)
                        
                        if (result != null) {
                            def actualResult = result?.result ?: result
                            // Forward response to SSE client
                            def mcpMessage = [
                                jsonrpc: "2.0",
                                id: rpcRequest.id,
                                result: actualResult
                            ]
                            // Call sendToSession to send to SSE clients
                            sendToSession(sessionId, mcpMessage)
                        }
                    } catch (Exception e) {
                        logger.error("Error processing message for session ${sessionId}: ${e.message}", e)
                        if (rpcRequest.id != null) {
                            def errorMsg = [
                                jsonrpc: "2.0",
                                error: [code: -32603, message: "Internal error: " + e.message],
                                id: rpcRequest.id
                            ]
                            sendToSession(sessionId, errorMsg)
                        }
                    }
                } finally {
                    asyncEc.destroy()
                }
            }
        } catch (Exception e) {
            logger.error("Error reading JSON-RPC request for session ${sessionId}: ${e.message}", e)
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR)
            response.setContentType("application/json")
            response.writer.write(JsonOutput.toJson([
                jsonrpc: "2.0",
                error: [code: -32603, message: "Internal error: " + e.message],
                id: null
            ]))
        }
    }

    private void handleJsonRpc(HttpServletRequest request, HttpServletResponse response, ExecutionContextImpl ec, String webappName, String requestBody, def visit)
            throws IOException {

        String method = request.getMethod()
        String acceptHeader = request.getHeader("Accept")

        // Validate Accept header per MCP spec
        if (!acceptHeader || !(acceptHeader.contains("application/json") || acceptHeader.contains("text/event-stream"))) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST)
            response.setContentType("application/json")
            response.writer.write(JsonOutput.toJson([
                jsonrpc: "2.0",
                error: [code: -32600, message: "Accept header must include application/json or text/event-stream"],
                id: null
            ]))
            return
        }

        if (!"POST".equals(method)) {
            response.setStatus(HttpServletResponse.SC_METHOD_NOT_ALLOWED)
            response.setContentType("application/json")
            response.writer.write(JsonOutput.toJson([
                jsonrpc: "2.0",
                error: [code: -32601, message: "Method Not Allowed. Use POST for JSON-RPC."],
                id: null
            ]))
            return
        }

        if (!requestBody) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST)
            response.setContentType("application/json")
            response.writer.write(JsonOutput.toJson([
                jsonrpc: "2.0",
                error: [code: -32602, message: "Empty request body"],
                id: null
            ]))
            return
        }

        def rpcRequest
        try {
            rpcRequest = jsonSlurper.parseText(requestBody)
        } catch (Exception e) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST)
            response.setContentType("application/json")
            response.writer.write(JsonOutput.toJson([
                jsonrpc: "2.0",
                error: [code: -32700, message: "Invalid JSON: " + e.message],
                id: null
            ]))
            return
        }

        // Validate JSON-RPC 2.0 structure
        if (!rpcRequest?.jsonrpc || rpcRequest.jsonrpc != "2.0" || !rpcRequest?.method) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST)
            response.setContentType("application/json")
            response.writer.write(JsonOutput.toJson([
                jsonrpc: "2.0",
                error: [code: -32600, message: "Invalid JSON-RPC 2.0 request"],
                id: null
            ]))
            return
        }

        // Validate MCP protocol version
        String protocolVersion = request.getHeader("MCP-Protocol-Version")
        def supportedVersions = ["2025-06-18", "2025-11-25", "2024-11-05", "2024-10-07", "2023-06-05"]
        if (protocolVersion && !supportedVersions.contains(protocolVersion)) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST)
            response.setContentType("application/json")
            response.writer.write(JsonOutput.toJson([
                jsonrpc: "2.0",
                error: [code: -32600, message: "Unsupported MCP protocol version: ${protocolVersion}. Supported: ${supportedVersions.join(', ')}"],
                id: null
            ]))
            return
        }

        // Get session ID from header
        String sessionId = request.getHeader("Mcp-Session-Id")

        // For initialize, use visit ID as session ID (or stable userId-based ID for stateless auth)
        if (!sessionId && ("initialize".equals(rpcRequest.method) || "notifications/initialized".equals(rpcRequest.method))) {
            sessionId = visit?.visitId?.toString() ?: "apikey-${ec.user.userId}"
        }

        // Validate session ID for non-initialize requests
        if (!sessionId && rpcRequest.method != "initialize" && rpcRequest.method != "notifications/initialized") {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST)
            response.setContentType("application/json")
            response.writer.write(JsonOutput.toJson([
                jsonrpc: "2.0",
                error: [code: -32600, message: "Mcp-Session-Id header required for non-initialize requests"],
                id: rpcRequest.id
            ]))
            return
        }

        // For existing sessions, validate ownership
        if (sessionId && rpcRequest.method != "initialize") {
            def session = sessionAdapter.getSession(sessionId)
            if (!session) {
                // Try loading from database
                def existingVisit = getCachedVisit(ec, sessionId)
                if (!existingVisit) {
                    response.setStatus(HttpServletResponse.SC_NOT_FOUND)
                    response.setContentType("application/json")
                    response.writer.write(JsonOutput.toJson([
                        jsonrpc: "2.0",
                        error: [code: -32600, message: "Session not found: ${sessionId}"],
                        id: rpcRequest.id
                    ]))
                    return
                }

                // Verify ownership
                if (existingVisit.userId?.toString() != ec.user.userId?.toString()) {
                    response.setStatus(HttpServletResponse.SC_FORBIDDEN)
                    response.setContentType("application/json")
                    response.writer.write(JsonOutput.toJson([
                        jsonrpc: "2.0",
                        error: [code: -32600, message: "Access denied for session: ${sessionId}"],
                        id: rpcRequest.id
                    ]))
                    return
                }

                // Create session in adapter if not exists
                if (!sessionAdapter.hasSession(sessionId)) {
                    sessionAdapter.createSession(sessionId, ec.user.userId?.toString())
                }
            } else if (session.userId != ec.user.userId?.toString()) {
                response.setStatus(HttpServletResponse.SC_FORBIDDEN)
                response.setContentType("application/json")
                response.writer.write(JsonOutput.toJson([
                    jsonrpc: "2.0",
                    error: [code: -32600, message: "Access denied for session: ${sessionId}"],
                    id: rpcRequest.id
                ]))
                return
            }
        }

        // Check if this is a notification (no id)
        boolean isNotification = !rpcRequest.containsKey('id')

        if (isNotification) {
            if ("notifications/initialized".equals(rpcRequest.method)) {
                if (sessionId) {
                    sessionAdapter.setSessionState(sessionId, McpSession.STATE_INITIALIZED)
                    logger.debug("Session ${sessionId} transitioned to INITIALIZED state")
                }

                if (sessionId) {
                    response.setHeader("Mcp-Session-Id", sessionId)
                }
                response.setContentType("text/event-stream")
                response.setStatus(HttpServletResponse.SC_ACCEPTED)
                response.flushBuffer()
                return
            }

            // Other notifications receive 204 No Content
            if (sessionId) {
                response.setHeader("Mcp-Session-Id", sessionId)
            }
            response.setStatus(HttpServletResponse.SC_NO_CONTENT)
            response.flushBuffer()
            return
        }

        // Process MCP method
        def result = processMcpMethod(rpcRequest.method, rpcRequest.params, ec, sessionId, visit)

        // Update session activity
        if (sessionId && !"ping".equals(rpcRequest.method) && !"tools/list".equals(rpcRequest.method)) {
            updateSessionActivityThrottled(sessionId)
        }

        // Set session header
        String responseSessionId = null
        if (rpcRequest.method == "initialize" && sessionId) {
            responseSessionId = sessionId
        } else if (result?.sessionId) {
            responseSessionId = result.sessionId?.toString()
        } else if (sessionId) {
            responseSessionId = sessionId
        }

        if (responseSessionId) {
            response.setHeader("Mcp-Session-Id", responseSessionId)
        }

        // Build response
        def actualResult = result?.result ?: result
        def rpcResponse = [
            jsonrpc: "2.0",
            id: rpcRequest.id,
            result: actualResult
        ]

        response.setContentType("application/json")
        response.setCharacterEncoding("UTF-8")
        response.writer.write(JsonOutput.toJson(rpcResponse))
    }

    private Map<String, Object> processMcpMethod(String method, Map params, ExecutionContextImpl ec, String sessionId, def visit) {
        logger.info("Processing MCP method: ${method} with sessionId: ${sessionId}")

        try {
            if (params == null) params = [:]
            params.sessionId = visit?.visitId ?: sessionId

            // Check session state for methods that require initialization
            def session = sessionId ? sessionAdapter.getSession(sessionId) : null
            if (!["initialize", "ping"].contains(method)) {
                if (!session || session.state != McpSession.STATE_INITIALIZED) {
                    logger.warn("Method ${method} called but session ${sessionId} not initialized")
                    return [error: "Session not initialized. Call initialize first, then send notifications/initialized."]
                }
            }

            switch (method) {
                case "initialize":
                    // Guard: refuse to create an anonymous session (userId=null would produce
                    // the shared "apikey-null" session key that all unauthenticated clients share).
                    if (!ec.user.userId) {
                        logger.warn("MCP initialize rejected: no authenticated user. Provide Basic auth credentials.")
                        return [error: "Authentication required. Provide Basic auth credentials (e.g. Authorization: Basic <base64(user:password)>)."]
                    }
                    if (visit && visit.visitId) {
                        params.sessionId = visit.visitId
                    } else if (!params.sessionId) {
                        // Stateless API-key auth: generate a stable session ID from userId
                        params.sessionId = "apikey-${ec.user.userId}"
                    }
                    // Create session in adapter with actual authenticated userId
                    if (!sessionAdapter.hasSession(params.sessionId?.toString())) {
                        sessionAdapter.createSession(params.sessionId?.toString(), ec.user.userId?.toString())
                    }
                    sessionAdapter.setSessionState(params.sessionId?.toString(), McpSession.STATE_INITIALIZING)
                    params.actualUserId = ec.user.userId
                    def serviceResult = callMcpService("mcp#Initialize", params, ec)
                    if (serviceResult && !serviceResult.error) {
                        serviceResult.sessionId = params.sessionId
                        sessionAdapter.setSessionState(params.sessionId?.toString(), McpSession.STATE_INITIALIZED)
                    }
                    return serviceResult

                case "ping":
                    return [pong: System.currentTimeMillis(), sessionId: visit?.visitId, user: ec.user.username]

                case "tools/list":
                    if (sessionId) params.sessionId = sessionId
                    return callMcpService("list#Tools", params, ec)

                case "tools/call":
                    if (sessionId) params.sessionId = sessionId
                    return callMcpService("mcp#ToolsCall", params, ec)

                case "resources/list":
                    return callMcpService("mcp#ResourcesList", params, ec)

                case "resources/read":
                    return callMcpService("mcp#ResourcesRead", params, ec)

                case "resources/templates/list":
                    return callMcpService("mcp#ResourcesTemplatesList", params, ec)

                case "resources/subscribe":
                    return callMcpService("mcp#ResourcesSubscribe", params, ec)

                case "resources/unsubscribe":
                    return callMcpService("mcp#ResourcesUnsubscribe", params, ec)

                case "prompts/list":
                    return callMcpService("mcp#PromptsList", params, ec)

                case "prompts/get":
                    return callMcpService("mcp#PromptsGet", params, ec)

                case "roots/list":
                    return callMcpService("mcp#RootsList", params, ec)

                case "sampling/createMessage":
                    return callMcpService("mcp#SamplingCreateMessage", params, ec)

                case "elicitation/create":
                    return callMcpService("mcp#ElicitationCreate", params, ec)

                case "notifications/tools/list_changed":
                case "notifications/resources/list_changed":
                case "notifications/prompts/list_changed":
                case "notifications/roots/list_changed":
                case "logging/setLevel":
                    logger.debug("Notification ${method} for sessionId: ${sessionId}")
                    return null

                case "notifications/send":
                    def notificationMethod = params?.method
                    def notificationParams = params?.params
                    if (!notificationMethod) {
                        throw new IllegalArgumentException("method is required for sending notification")
                    }
                    if (sessionId) {
                        def notification = [
                            jsonrpc: "2.0",
                            method: notificationMethod,
                            params: notificationParams
                        ]
                        transport.sendNotification(sessionId, notification)
                    }
                    return [sent: true, sessionId: sessionId, method: notificationMethod]

                case "notifications/subscribe":
                    def subscriptionMethod = params?.method
                    if (!sessionId || !subscriptionMethod) {
                        throw new IllegalArgumentException("sessionId and method are required for subscription")
                    }
                    session?.subscriptions?.add(subscriptionMethod)
                    return [subscribed: true, sessionId: sessionId, method: subscriptionMethod]

                case "notifications/unsubscribe":
                    def subscriptionMethod = params?.method
                    if (!sessionId || !subscriptionMethod) {
                        throw new IllegalArgumentException("sessionId and method are required for unsubscription")
                    }
                    session?.subscriptions?.remove(subscriptionMethod)
                    return [unsubscribed: true, sessionId: sessionId, method: subscriptionMethod]

                case "notifications/progress":
                    def progressToken = params?.progressToken
                    def progressValue = params?.progress
                    def total = params?.total
                    logger.debug("Progress notification: ${progressToken}, ${progressValue}/${total}")
                    return null

                case "notifications/resources/updated":
                    logger.debug("Resource updated: ${params?.uri}")
                    return null

                case "notifications/message":
                    def level = params?.level ?: "info"
                    def message = params?.message
                    logger.debug("Message notification: level=${level}, message=${message}")
                    return null

                default:
                    throw new IllegalArgumentException("Method not found: ${method}")
            }
        } catch (Exception e) {
            logger.error("Error processing MCP method ${method}: ${e.message}", e)
            throw e
        }
    }

    private Map<String, Object> callMcpService(String serviceName, Map params, ExecutionContextImpl ec) {
        logger.debug("Calling MCP service: ${serviceName}")

        try {
            ec.artifactExecution.disableAuthz()
            def result = ec.service.sync().name("McpServices.${serviceName}")
                .parameters(params ?: [:])
                .call()

            if (result == null) {
                return [error: "Service returned null result"]
            }

            if (result?.containsKey('result')) {
                return result.result
            }
            return result

        } catch (Exception e) {
            logger.error("Error calling MCP service ${serviceName}", e)
            return [error: e.message]
        } finally {
            ec.artifactExecution.enableAuthz()
        }
    }

    private EntityValue getCachedVisit(ExecutionContextImpl ec, String sessionId) {
        if (!sessionId) return null

        EntityValue cachedVisit = visitCache.get(sessionId)
        if (cachedVisit != null) {
            return cachedVisit
        }

        try {
            ec.artifactExecution.disableAuthz()
            EntityValue visit = ec.entity.find("moqui.server.Visit")
                .condition("visitId", sessionId)
                .one()
            if (visit != null) {
                visitCache.put(sessionId, visit)
            }
            return visit
        } finally {
            ec.artifactExecution.enableAuthz()
        }
    }

    private void updateSessionActivityThrottled(String sessionId) {
        if (!sessionId) return

        long now = System.currentTimeMillis()
        Long lastUpdate = lastActivityUpdate.get(sessionId)

        if (lastUpdate == null || (now - lastUpdate) > ACTIVITY_UPDATE_INTERVAL_MS) {
            Object sessionLock = sessionAdapter.getSessionLock(sessionId)
            synchronized (sessionLock) {
                lastUpdate = lastActivityUpdate.get(sessionId)
                if (lastUpdate == null || (now - lastUpdate) > ACTIVITY_UPDATE_INTERVAL_MS) {
                    sessionAdapter.touchSession(sessionId)
                    lastActivityUpdate.put(sessionId, now)
                    logger.debug("Updated activity for session ${sessionId}")
                }
            }
        }
    }

    private static boolean handleCors(HttpServletRequest request, HttpServletResponse response) {
        String originHeader = request.getHeader("Origin")
        if (originHeader) {
            response.setHeader("Access-Control-Allow-Origin", originHeader)
            response.setHeader("Access-Control-Allow-Credentials", "true")
        }

        String methodHeader = request.getHeader("Access-Control-Request-Method")
        if (methodHeader) {
            response.setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
            response.setHeader("Access-Control-Allow-Headers", "Content-Type, Authorization, Mcp-Session-Id, MCP-Protocol-Version, Accept")
            response.setHeader("Access-Control-Max-Age", "3600")
            return true
        }
        return false
    }

    /**
     * Queue a notification for delivery to a session
     */
    void queueNotification(String sessionId, Map notification) {
        if (!sessionId || !notification) return
        transport.sendNotification(sessionId, notification)
    }

    /**
     * Send to a specific session
     */
    void sendToSession(String sessionId, Map message) {
        transport.sendMessage(sessionId, message)
    }

    /**
     * Get session statistics
     */
    Map getSessionStatistics() {
        def stats = transport.getStatistics()
        return stats + [
            maxConnections: maxConnections,
            endpoints: [
                sse: sseEndpoint,
                message: messageEndpoint
            ],
            keepAliveInterval: keepAliveIntervalSeconds
        ]
    }

    /**
     * Get the notification bridge for external access
     */
    MoquiNotificationMcpBridge getNotificationBridge() {
        return notificationBridge
    }

    /**
     * Get the transport for external access
     */
    SseTransport getTransport() {
        return transport
    }

    @Override
    void destroy() {
        logger.info("Destroying EnhancedMcpServlet")
        shuttingDown = true

        // Close all sessions
        for (String sessionId in sessionAdapter.getAllSessionIds()) {
            transport.closeSession(sessionId)
        }

        // Wait for SSE threads to complete asyncContext.complete() before Moqui tears down the DB pool
        long deadline = System.currentTimeMillis() + 3000
        while (activeSseCount.get() > 0 && System.currentTimeMillis() < deadline) {
            try { Thread.sleep(50) } catch (InterruptedException ignored) {}
        }
        if (activeSseCount.get() > 0) {
            logger.warn("${activeSseCount.get()} SSE thread(s) still active after shutdown wait")
        }

        // Clean up notification bridge
        if (notificationBridge) {
            notificationBridge.destroy()
        }

        super.destroy()
    }
}
