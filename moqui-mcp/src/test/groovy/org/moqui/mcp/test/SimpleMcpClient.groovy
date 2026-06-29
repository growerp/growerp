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
package org.moqui.mcp.test

import groovy.json.JsonBuilder
import groovy.json.JsonSlurper
import java.net.http.HttpClient
import java.net.http.HttpRequest
import java.net.http.HttpResponse
import java.net.URI
import java.time.Duration
import java.util.concurrent.ConcurrentHashMap

/**
 * Simple MCP client for testing MCP server functionality
 * Makes JSON-RPC requests to the MCP server endpoint
 */
class SimpleMcpClient {
    private String baseUrl
    private String sessionId
    private HttpClient httpClient
    private JsonSlurper jsonSlurper
    private Map<String, Object> sessionData = new ConcurrentHashMap<>()

    SimpleMcpClient(String baseUrl = "http://localhost:8080/mcp") {
        this.baseUrl = baseUrl
        this.httpClient = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(30))
            .build()
        this.jsonSlurper = new JsonSlurper()
    }

    /**
     * Initialize MCP session with Basic authentication
     */
    boolean initializeSession(String username = "john.sales", String password = "moqui") {
        try {
            // Store credentials for Basic auth
            sessionData.put("username", username)
            sessionData.put("password", password)
            
            // Initialize MCP session
            def params = [
                protocolVersion: "2025-06-18",
                capabilities: [tools: [:], resources: [:]],
                clientInfo: [name: "SimpleMcpClient", version: "1.0.0"]
            ]
            
            def result = makeJsonRpcRequest("initialize", params)
            
            if (result && result.result && result.result.sessionId) {
                this.sessionId = result.result.sessionId
                sessionData.put("initialized", true)
                sessionData.put("sessionId", sessionId)
                println "Session initialized: ${sessionId}"
                return true
            }
            
            return false
        } catch (Exception e) {
            println "Error initializing session: ${e.message}"
            return false
        }
    }
    
    /**
     * Make JSON-RPC request to MCP server
     */
    private Map makeJsonRpcRequest(String method, Map params = null) {
        try {
            def requestBody = [
                jsonrpc: "2.0",
                id: System.currentTimeMillis(),
                method: method
            ]
            
            if (params != null) {
                requestBody.params = params
            }
            
            def requestBuilder = HttpRequest.newBuilder()
                .uri(URI.create(baseUrl))
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(new JsonBuilder(requestBody).toString()))
            
            // Add Basic authentication
            if (sessionData.containsKey("username") && sessionData.containsKey("password")) {
                def auth = "${sessionData.username}:${sessionData.password}"
                def encodedAuth = java.util.Base64.getEncoder().encodeToString(auth.bytes)
                requestBuilder.header("Authorization", "Basic ${encodedAuth}")
            }
            
            // Add session header for non-initialize requests
            if (method != "initialize" && sessionId) {
                requestBuilder.header("Mcp-Session-Id", sessionId)
            }
            
            def request = requestBuilder.build()
            def response = httpClient.send(request, HttpResponse.BodyHandlers.ofString())
            
            if (response.statusCode() == 200) {
                return jsonSlurper.parseText(response.body())
            } else {
                return [error: [message: "HTTP ${response.statusCode()}: ${response.body()}"]]
            }
        } catch (Exception e) {
            println "Error making JSON-RPC request: ${e.message}"
            return [error: [message: e.message]]
        }
    }

    /**
     * Ping MCP server
     */
    boolean ping() {
        try {
            def result = makeJsonRpcRequest("tools/call", [
                name: "McpServices.mcp#Ping",
                arguments: [:]
            ])
            
            return result && !result.error
        } catch (Exception e) {
            println "Error pinging server: ${e.message}"
            return false
        }
    }

    /**
     * List available tools
     */
    List<Map> listTools() {
        try {
            def result = makeJsonRpcRequest("tools/list", [sessionId: sessionId])
            
            if (result && result.result && result.result.tools) {
                return result.result.tools
            }
            return []
        } catch (Exception e) {
            println "Error listing tools: ${e.message}"
            return []
        }
    }

    /**
     * Call any tool
     */
    Map callTool(String toolName, Map arguments = [:]) {
        try {
            def result = makeJsonRpcRequest("tools/call", [
                name: toolName,
                arguments: arguments
            ])
            
            return result ?: [error: [message: "No response from server"]]
        } catch (Exception e) {
            println "Error calling tool ${toolName}: ${e.message}"
            return [error: [message: e.message]]
        }
    }

    /**
     * Call a screen tool
     */
    Map callScreen(String screenPath, Map parameters = [:]) {
        try {
            // Determine the correct tool name based on the screen path
            String toolName = getScreenToolName(screenPath)
            
            // Don't override render mode - let the MCP service handle it
            def args = parameters
            
            def result = makeJsonRpcRequest("tools/call", [
                name: toolName,
                arguments: args
            ])
            
            return result ?: [error: [message: "No response from server"]]
        } catch (Exception e) {
            println "Error calling screen ${screenPath}: ${e.message}"
            return [error: [message: e.message]]
        }
    }
    
    /**
     * Get the correct tool name for a given screen path
     */
    private String getScreenToolName(String screenPath) {
        // If it already looks like a tool name, return it
        if (screenPath.startsWith("screen_")) {
            return screenPath
        }
        
        // Clean Encoding: strip component:// and .xml, replace / with _
        def cleanPath = screenPath
        if (cleanPath.startsWith("component://")) cleanPath = cleanPath.substring(12)
        if (cleanPath.endsWith(".xml")) cleanPath = cleanPath.substring(0, cleanPath.length() - 4)
        
        return "screen_" + cleanPath.replace('/', '_')
    }

    /**
     * Search for products in PopCommerce catalog
     */
    List<Map> searchProducts(String color = "blue", String category = "PopCommerce") {
        def result = callScreen("PopCommerce/Catalog/Product", [
            color: color,
            category: category
        ])
        
        if (result.error) {
            println "Error searching products: ${result.error.message}"
            return []
        }
        
        // Extract products from the screen response
        def content = result.result?.content
        if (content && content instanceof List && content.size() > 0) {
            // Look for products in the content
            for (item in content) {
                if (item.type == "resource" && item.resource && item.resource.products) {
                    return item.resource.products
                }
            }
        }
        
        return []
    }

    /**
     * Find customer by name
     */
    Map findCustomer(String firstName = "John", String lastName = "Doe") {
        def result = callScreen("PopCommerce/Customer/FindCustomer", [
            firstName: firstName,
            lastName: lastName
        ])
        
        if (result.error) {
            println "Error finding customer: ${result.error.message}"
            return [:]
        }
        
        // Extract customer from the screen response
        def content = result.result?.content
        if (content && content instanceof List && content.size() > 0) {
            // Look for customer in the content
            for (item in content) {
                if (item.type == "resource" && item.resource && item.resource.customer) {
                    return item.resource.customer
                }
            }
        }
        
        return [:]
    }

    /**
     * Create an order
     */
    Map createOrder(String customerId, String productId, Map orderDetails = [:]) {
        def parameters = [
            customerId: customerId,
            productId: productId
        ] + orderDetails
        
        def result = callScreen("PopCommerce/Order/CreateOrder", parameters)
        
        if (result.error) {
            println "Error creating order: ${result.error.message}"
            return [:]
        }
        
        // Extract order from the screen response
        def content = result.result?.content
        if (content && content instanceof List && content.size() > 0) {
            // Look for order in the content
            for (item in content) {
                if (item.type == "resource" && item.resource && item.resource.order) {
                    return item.resource.order
                }
            }
        }
        
        return [:]
    }

    /**
     * Get session data
     */
    Map getSessionData() {
        return new HashMap(sessionData)
    }

    /**
     * Close the session
     */
    void closeSession() {
        try {
            if (sessionId) {
                makeJsonRpcRequest("close", [:])
            }
        } catch (Exception e) {
            println "Error closing session: ${e.message}"
        } finally {
            sessionData.clear()
            sessionId = null
        }
    }
}
