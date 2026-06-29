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
package org.moqui.mcp.adapter

import org.moqui.context.ExecutionContext
import org.slf4j.Logger
import org.slf4j.LoggerFactory

/**
 * Adapter that maps MCP tool calls to Moqui services.
 * Provides a clean translation layer between MCP protocol and Moqui service framework.
 */
class McpToolAdapter {
    protected final static Logger logger = LoggerFactory.getLogger(McpToolAdapter.class)

    // MCP tool name → Moqui service name mapping
    private static final Map<String, String> TOOL_SERVICE_MAP = [
        'moqui_browse_screens': 'McpServices.mcp#BrowseScreens',
        'moqui_search_screens': 'McpServices.mcp#SearchScreens',
        'moqui_get_screen_details': 'McpServices.mcp#GetScreenDetails',
        'moqui_get_help': 'McpServices.mcp#GetHelp'
    ]

    // MCP method → Moqui service name mapping for JSON-RPC methods
    private static final Map<String, String> METHOD_SERVICE_MAP = [
        'initialize': 'McpServices.mcp#Initialize',
        'ping': 'McpServices.mcp#Ping',
        'tools/list': 'McpServices.list#Tools',
        'tools/call': 'McpServices.mcp#ToolsCall',
        'resources/list': 'McpServices.mcp#ResourcesList',
        'resources/read': 'McpServices.mcp#ResourcesRead',
        'resources/templates/list': 'McpServices.mcp#ResourcesTemplatesList',
        'resources/subscribe': 'McpServices.mcp#ResourcesSubscribe',
        'resources/unsubscribe': 'McpServices.mcp#ResourcesUnsubscribe',
        'prompts/list': 'McpServices.mcp#PromptsList',
        'prompts/get': 'McpServices.mcp#PromptsGet',
        'roots/list': 'McpServices.mcp#RootsList',
        'sampling/createMessage': 'McpServices.mcp#SamplingCreateMessage',
        'elicitation/create': 'McpServices.mcp#ElicitationCreate'
    ]

    // Tool descriptions for MCP tool definitions
    private static final Map<String, String> TOOL_DESCRIPTIONS = [
        'moqui_browse_screens': 'Browse Moqui screen hierarchy and render screen content',
        'moqui_search_screens': 'Search for screens by name to find their paths',
        'moqui_get_screen_details': 'Get screen field details including dropdown options',
        'moqui_get_help': 'Fetch extended documentation for a screen or service'
    ]

    private static final Map<String, Map> TOOL_SCHEMAS = [:]

    // Static cache: computed once per JVM, avoids repeated filesystem scans in getKnownServiceNames()
    private static volatile List<String> cachedGroWerpServiceNames = null
    private static final Object cacheInitLock = new Object()

    static List<String> getCachedGroWerpServiceNames(ExecutionContext ec) {
        if (cachedGroWerpServiceNames != null) return cachedGroWerpServiceNames
        synchronized(cacheInitLock) {
            if (cachedGroWerpServiceNames != null) return cachedGroWerpServiceNames
            logger.info("McpToolAdapter: building growerp service name cache...")
            long t = System.currentTimeMillis()
            cachedGroWerpServiceNames = ec.service.getKnownServiceNames()
                .findAll { it && it.startsWith("growerp.") }
                .sort() as List<String>
            logger.info("McpToolAdapter: cached ${cachedGroWerpServiceNames.size()} growerp service names in ${System.currentTimeMillis() - t}ms")
            return cachedGroWerpServiceNames
        }
    }

    static void clearServiceNameCache() {
        cachedGroWerpServiceNames = null
        logger.info("McpToolAdapter: cleared growerp service name cache")
    }

    static void registerTool(String name, String serviceName, String description, Map schema) {
        TOOL_SERVICE_MAP.put(name, serviceName)
        if (description) TOOL_DESCRIPTIONS.put(name, description)
        if (schema) TOOL_SCHEMAS.put(name, schema)
        logger.info("McpToolAdapter: registered plugin tool '${name}' -> ${serviceName}")
    }

    /**
     * Call an MCP tool, translating to the appropriate Moqui service
     * @param ec The execution context
     * @param toolName The MCP tool name
     * @param arguments The tool arguments
     * @return The result map or error map
     */
    Map callTool(ExecutionContext ec, String toolName, Map arguments) {
        String serviceName = TOOL_SERVICE_MAP.get(toolName)
        if (!serviceName) {
            logger.warn("Unknown tool: ${toolName}")
            return [error: [code: -32601, message: "Unknown tool: ${toolName}"]]
        }

        logger.debug("Calling tool ${toolName} -> service ${serviceName} with args: ${arguments}")

        try {
            // NOTE: Authorization is NOT disabled here.
            // Tools run with the current user's permissions (or the impersonated user's permissions).
            def result = ec.service.sync()
                .name(serviceName)
                .parameters(arguments ?: [:])
                .call()

            logger.debug("Tool ${toolName} completed successfully")

            // Extract result from service response if wrapped
            if (result?.containsKey('result')) {
                return result.result
            }
            return result ?: [:]

        } catch (org.moqui.context.ArtifactAuthorizationException e) {
            logger.warn("Security rejection for tool ${toolName} (user: ${ec.user.username}): ${e.message}")
            return [
                error: [
                    code: -32001,
                    message: "Permission Denied: You do not have access to ${e.artifactName}",
                    data: [
                        artifact: e.artifactName, 
                        action: e.authzActionEnumId,
                        message: e.message
                    ]
                ]
            ]
        } catch (Exception e) {
            logger.error("Error calling tool ${toolName}: ${e.message}", e)
            return [error: [code: -32000, message: e.message]]
        }
    }

    /**
     * Call an MCP method, translating to the appropriate Moqui service
     * @param ec The execution context
     * @param method The MCP method name
     * @param params The method parameters
     * @return The result map or error map
     */
    Map callMethod(ExecutionContext ec, String method, Map params) {
        String serviceName = METHOD_SERVICE_MAP.get(method)
        if (!serviceName) {
            logger.warn("Unknown method: ${method}")
            return [error: [code: -32601, message: "Method not found: ${method}"]]
        }

        logger.debug("Calling method ${method} -> service ${serviceName}")

        try {
            // Standard RBAC applies
            def result = ec.service.sync()
                .name(serviceName)
                .parameters(params ?: [:])
                .call()

            logger.debug("Method ${method} completed successfully")

            // Extract result from service response if wrapped
            if (result?.containsKey('result')) {
                return result.result
            }
            return result ?: [:]

        } catch (org.moqui.context.ArtifactAuthorizationException e) {
             logger.warn("Security rejection for method ${method}: ${e.message}")
             return [error: [code: -32001, message: "Permission Denied: ${e.message}"]]
        } catch (Exception e) {
            logger.error("Error calling method ${method}: ${e.message}", e)
            return [error: [code: -32603, message: "Internal error: ${e.message}"]]
        }
    }

    /**
     * Check if a tool name is valid
     * @param toolName The tool name to check
     * @return true if the tool is known
     */
    boolean isValidTool(String toolName) {
        return TOOL_SERVICE_MAP.containsKey(toolName)
    }

    /**
     * Check if a method name is valid (has a service mapping)
     * @param method The method name to check
     * @return true if the method has a service mapping
     */
    boolean isValidMethod(String method) {
        return METHOD_SERVICE_MAP.containsKey(method)
    }

    /**
     * Get the service name for a given tool
     * @param toolName The tool name
     * @return The service name or null if not found
     */
    String getServiceForTool(String toolName) {
        return TOOL_SERVICE_MAP.get(toolName)
    }

    /**
     * Get the service name for a given method
     * @param method The method name
     * @return The service name or null if not found
     */
    String getServiceForMethod(String method) {
        return METHOD_SERVICE_MAP.get(method)
    }

    /**
     * Get the list of available tools with their definitions
     * @return List of tool definition maps
     */
    static List<Map> listTools() {
        return TOOL_SERVICE_MAP.keySet().collect { toolName ->
            Map toolDef = [
                name: toolName,
                description: TOOL_DESCRIPTIONS.get(toolName) ?: "MCP tool: ${toolName}"
            ]
            toolDef.inputSchema = TOOL_SCHEMAS.get(toolName) ?: [type: "object", properties: [:]]
            return toolDef
        }
    }

    /**
     * Get tool description
     * @param toolName The tool name
     * @return The tool description or null if not found
     */
    String getToolDescription(String toolName) {
        return TOOL_DESCRIPTIONS.get(toolName)
    }

    /**
     * Get all supported tool names
     * @return Set of tool names
     */
    Set<String> getToolNames() {
        return TOOL_SERVICE_MAP.keySet()
    }

    /**
     * Get all supported method names
     * @return Set of method names
     */
    Set<String> getMethodNames() {
        return METHOD_SERVICE_MAP.keySet()
    }
}
