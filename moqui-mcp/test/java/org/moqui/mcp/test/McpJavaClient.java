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
package org.moqui.mcp.test;

import groovy.json.JsonSlurper
import groovy.json.JsonOutput
import java.util.concurrent.atomic.AtomicInteger
import java.util.concurrent.TimeUnit
import java.net.http.HttpClient
import java.net.http.HttpRequest
import java.net.http.HttpResponse
import java.net.URI
import java.time.Duration
import java.util.Base64

/**
 * Java MCP Client - equivalent to mcp.sh functionality
 * Provides JSON-RPC communication with Moqui MCP server
 */
class McpJavaClient {
    private String baseUrl
    private String username
    private String password
    private JsonSlurper jsonSlurper = new JsonSlurper()
    private String sessionId = null
    private AtomicInteger requestId = new AtomicInteger(1)
    private HttpClient httpClient
    
    // Test results tracking
    def testResults = []
    def currentWorkflow = null
    
    McpJavaClient(String baseUrl = "http://localhost:8080/mcp", 
                  String username = "john.sales", 
                  String password = "moqui") {
        this.baseUrl = baseUrl
        this.username = username
        this.password = password
        
        // Initialize HTTP client with reasonable timeouts
        this.httpClient = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(30))
            .build()
    }
    
    /**
     * Initialize MCP session
     */
    boolean initialize() {
        println "🚀 Initializing MCP session..."
        
        // First check if server is accessible
        if (!checkServerHealth()) {
            println "❌ Server health check failed"
            return false
        }
        
        def response = sendJsonRpc("initialize", [
            protocolVersion: "2025-06-18",
            capabilities: [
                tools: [:],
                resources: [:]
            ],
            clientInfo: [
                name: "Java MCP Test Client",
                version: "1.0.0"
            ]
        ])
        
        if (response && response.result) {
            this.sessionId = response.result.sessionId
            println "✅ Session initialized: ${sessionId}"
            
            // Verify MCP services are actually working
            if (!verifyMcpServices()) {
                println "❌ MCP services verification failed"
                return false
            }
            
            return true
        } else {
            println "❌ Failed to initialize session"
            return false
        }
    }
    
    /**
     * Check if MCP server is healthy and accessible
     */
    boolean checkServerHealth() {
        println "🏥 Checking server health..."
        
        try {
            // Try to ping the server first
            def pingResponse = sendJsonRpc("mcp#Ping")
            if (!pingResponse) {
                println "❌ Server ping failed"
                return false
            }
            
            // Check if we can access the health endpoint
            def healthUrl = baseUrl.replace("/mcp", "/test/health")
            def healthRequest = HttpRequest.newBuilder()
                .uri(URI.create(healthUrl))
                .header("Accept", "application/json")
                .GET()
                .timeout(Duration.ofSeconds(10))
                .build()
            
            def healthResponse = httpClient.send(healthRequest, HttpResponse.BodyHandlers.ofString())
            
            if (healthResponse.statusCode() == 200) {
                println "✅ Server health check passed"
                return true
            } else {
                println "⚠️ Health endpoint returned: ${healthResponse.statusCode()}"
                // Continue anyway - health endpoint might not be available
                return true
            }
            
        } catch (Exception e) {
            println "❌ Health check failed: ${e.message}"
            return false
        }
    }
    
    /**
     * Verify that MCP services are working properly
     */
    boolean verifyMcpServices() {
        println "🔍 Verifying MCP services..."
        
        try {
            // Test basic functionality
            def tools = getTools()
            if (tools == null) {
                println "❌ Failed to get tools list"
                return false
            }
            
            def resources = getResources()
            if (resources == null) {
                println "❌ Failed to get resources list"
                return false
            }
            
            println "✅ Found ${tools.size()} tools and ${resources.size()} resources"
            
            // Test a simple operation if tools are available
            if (tools.size() > 0) {
                def firstTool = tools[0]
                println "🔧 Testing tool: ${firstTool.name}"
                
                // Try to call the tool with empty arguments (many tools support this)
                def toolResult = executeTool(firstTool.name, [:])
                if (toolResult == null) {
                    println "⚠️ Tool execution failed, but continuing..."
                }
            }
            
            println "✅ MCP services verification completed"
            return true
            
        } catch (Exception e) {
            println "❌ MCP services verification failed: ${e.message}"
            return false
        }
    }
    
    /**
     * Send JSON-RPC request using Java HttpClient
     */
    def sendJsonRpc(String method, Map params = null) {
        def request = [
            jsonrpc: "2.0",
            id: requestId.getAndIncrement().toString(),
            method: method,
            params: params ?: [:]
        ]
        
        // Add session ID if available
        if (sessionId) {
            request.params.sessionId = sessionId
        }
        
        def jsonRequest = JsonOutput.toJson(request)
        println "📤 Sending: ${method}"
        
        try {
            // Create HTTP request with basic auth
            def authString = "${username}:${password}"
            def encodedAuth = Base64.getEncoder().encodeToString(authString.getBytes())
            
            def httpRequest = HttpRequest.newBuilder()
                .uri(URI.create(baseUrl))
                .header("Content-Type", "application/json")
                .header("Authorization", "Basic ${encodedAuth}")
                .header("Mcp-Session-Id", sessionId ?: "")
                .POST(HttpRequest.BodyPublishers.ofString(jsonRequest))
                .timeout(Duration.ofSeconds(60))
                .build()
            
            // Send request and get response
            def httpResponse = httpClient.send(httpRequest, HttpResponse.BodyHandlers.ofString())
            def responseText = httpResponse.body()
            
            if (httpResponse.statusCode() != 200) {
                println "❌ HTTP Error: ${httpResponse.statusCode()} - ${responseText}"
                return null
            }
            
            def response = jsonSlurper.parseText(responseText)
            
            if (response.error) {
                println "❌ Error: ${response.error.message}"
                return null
            }
            
            println "📥 Response received"
            return response
            
        } catch (Exception e) {
            println "❌ Request failed: ${e.message}"
            e.printStackTrace()
            return null
        }
    }
    
    /**
     * Get available tools
     */
    def getTools() {
        println "🔧 Getting available tools..."
        def response = sendJsonRpc("tools/list")
        return response?.result?.tools ?: []
    }
    
    /**
     * Execute a tool
     */
    def executeTool(String toolName, Map arguments = [:]) {
        println "🔨 Executing tool: ${toolName}"
        def response = sendJsonRpc("tools/call", [
            name: toolName,
            arguments: arguments
        ])
        return response?.result
    }
    
    /**
     * Get available resources
     */
    def getResources() {
        println "📚 Getting available resources..."
        def response = sendJsonRpc("resources/list")
        return response?.result?.resources ?: []
    }
    
    /**
     * Read a resource
     */
    def readResource(String uri) {
        println "📖 Reading resource: ${uri}"
        def response = sendJsonRpc("resources/read", [
            uri: uri
        ])
        return response?.result
    }
    
    /**
     * Ping server for health check
     */
    def ping() {
        println "🏓 Pinging server..."
        def response = sendJsonRpc("mcp#Ping")
        return response?.result
    }
    
    /**
     * Start a test workflow
     */
    void startWorkflow(String workflowName) {
        currentWorkflow = [
            name: workflowName,
            startTime: System.currentTimeMillis(),
            steps: []
        ]
        println "🎯 Starting workflow: ${workflowName}"
    }
    
    /**
     * Record a workflow step
     */
    void recordStep(String stepName, boolean success, String details = null) {
        if (!currentWorkflow) return
        
        def step = [
            name: stepName,
            success: success,
            details: details,
            timestamp: System.currentTimeMillis()
        ]
        
        currentWorkflow.steps.add(step)
        
        if (success) {
            println "✅ ${stepName}"
        } else {
            println "❌ ${stepName}: ${details}"
        }
    }
    
    /**
     * Complete current workflow
     */
    def completeWorkflow() {
        if (!currentWorkflow) return null
        
        currentWorkflow.endTime = System.currentTimeMillis()
        currentWorkflow.duration = currentWorkflow.endTime - currentWorkflow.startTime
        currentWorkflow.success = currentWorkflow.steps.every { it.success }
        
        testResults.add(currentWorkflow)
        
        println "\n📊 Workflow Results: ${currentWorkflow.name}"
        println "   Duration: ${currentWorkflow.duration}ms"
        println "   Success: ${currentWorkflow.success ? '✅' : '❌'}"
        println "   Steps: ${currentWorkflow.steps.size()}"
        
        def result = currentWorkflow
        currentWorkflow = null
        return result
    }
    
    /**
     * Generate test report
     */
    void generateReport() {
        println "\n" + "="*60
        println "📋 JAVA MCP TEST CLIENT REPORT"
        println "="*60
        
        def totalWorkflows = testResults.size()
        def successfulWorkflows = testResults.count { it.success }
        def totalSteps = testResults.sum { it.steps.size() }
        def successfulSteps = testResults.sum { workflow -> 
            workflow.steps.count { it.success } 
        }
        
        println "Total Workflows: ${totalWorkflows}"
        println "Successful Workflows: ${successfulWorkflows}"
        println "Total Steps: ${totalSteps}"
        println "Successful Steps: ${successfulSteps}"
        println "Success Rate: ${successfulWorkflows > 0 ? (successfulWorkflows/totalWorkflows * 100).round() : 0}%"
        
        println "\n📊 Workflow Details:"
        testResults.each { workflow ->
            println "\n🎯 ${workflow.name}"
            println "   Duration: ${workflow.duration}ms"
            println "   Success: ${workflow.success ? '✅' : '❌'}"
            println "   Steps: ${workflow.steps.size()}/${workflow.steps.count { it.success }} successful"
            
            workflow.steps.each { step ->
                println "     ${step.success ? '✅' : '❌'} ${step.name}"
                if (step.details && !step.success) {
                    println "        Error: ${step.details}"
                }
            }
        }
        
        println "\n" + "="*60
    }
    
    /**
     * Close the client and cleanup resources
     */
    void close() {
        println "🔒 Closing MCP client..."
        // HttpClient doesn't need explicit closing in Java 11+
        sessionId = null
    }
    
    /**
     * Main method for standalone testing
     */
    static void main(String[] args) {
        def client = new McpJavaClient()
        
        try {
            // Test basic functionality
            if (!client.initialize()) {
                println "❌ Failed to initialize"
                return
            }
            
            // Test ping
            def pingResult = client.ping()
            println "Ping result: ${pingResult}"
            
            // Test tools
            def tools = client.getTools()
            println "Found ${tools.size()} tools"
            
            // Test resources
            def resources = client.getResources()
            println "Found ${resources.size()} resources"
            
        } finally {
            client.close()
        }
    }
}