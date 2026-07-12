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
     * Check if a method name is valid (has a service mapping)
     * @param method The method name to check
     * @return true if the method has a service mapping
     */
    boolean isValidMethod(String method) {
        return METHOD_SERVICE_MAP.containsKey(method)
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
     * Get all supported method names
     * @return Set of method names
     */
    Set<String> getMethodNames() {
        return METHOD_SERVICE_MAP.keySet()
    }
}
