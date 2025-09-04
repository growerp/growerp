#!/usr/bin/env groovy

/**
 * GrowERP MCP Client Example (Groovy - No External Dependencies)
 * This script demonstrates how to connect to the GrowERP MCP server using only built-in Java/Groovy libraries.
 */

import java.net.http.HttpClient
import java.net.http.HttpRequest
import java.net.http.HttpResponse
import java.net.URI
import java.time.Duration
import groovy.json.JsonSlurper
import groovy.json.JsonBuilder
import java.util.concurrent.atomic.AtomicInteger

class GrowERPMCPClient {
    private String mcpUrl
    private HttpClient httpClient
    private JsonSlurper jsonSlurper
    private boolean initialized = false
    private AtomicInteger requestId = new AtomicInteger(1)
    
    GrowERPMCPClient(String mcpUrl = "http://localhost:8081") {
        this.mcpUrl = mcpUrl
        this.httpClient = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(10))
            .build()
        this.jsonSlurper = new JsonSlurper()
    }
    
    /**
     * Make a JSON-RPC request to the MCP server
     */
    Map makeRequest(String method, Map params = [:]) {
        def requestData = [
            jsonrpc: "2.0",
            method: method,
            params: params,
            id: requestId.getAndIncrement()
        ]
        
        try {
            def jsonRequest = new JsonBuilder(requestData).toString()
            
            HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(mcpUrl))
                .header("Content-Type", "application/json")
                .header("Accept", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(jsonRequest))
                .timeout(Duration.ofSeconds(30))
                .build()
            
            HttpResponse<String> response = httpClient.send(request, 
                HttpResponse.BodyHandlers.ofString())
            
            if (response.statusCode() != 200) {
                return [error: "HTTP ${response.statusCode()}: ${response.body()}"]
            }
            
            return jsonSlurper.parseText(response.body()) as Map
            
        } catch (Exception e) {
            return [error: "Request failed: ${e.message}"]
        }
    }
    
    /**
     * Initialize the MCP connection
     */
    Map initialize() {
        if (initialized) {
            return [status: "already_initialized"]
        }
        
        Map result = makeRequest("initialize", [
            protocolVersion: "2024-11-05",
            clientInfo: [
                name: "growerp-ai-client",
                version: "1.0.0"
            ]
        ])
        
        if (!result.containsKey("error")) {
            initialized = true
            println "✓ MCP client initialized successfully"
        }
        
        return result
    }
    
    /**
     * Ping the MCP server to check connectivity
     */
    Map ping() {
        return makeRequest("ping", [:])
    }
    
    /**
     * Get server capabilities
     */
    Map getCapabilities() {
        return makeRequest("initialize", [
            protocolVersion: "2024-11-05",
            clientInfo: [name: "capability-check"]
        ])
    }
    
    /**
     * Get available tools from the MCP server
     */
    Map listTools() {
        return makeRequest("tools/list", [:])
    }
    
    /**
     * Execute a tool via MCP
     */
    Map callTool(String name, Map arguments = [:]) {
        return makeRequest("tools/call", [
            name: name,
            arguments: arguments
        ])
    }
    
    /**
     * Get available resources
     */
    Map listResources() {
        return makeRequest("resources/list", [:])
    }
    
    /**
     * Read a specific resource
     */
    Map readResource(String uri) {
        return makeRequest("resources/read", [uri: uri])
    }
    
    /**
     * Get available prompts
     */
    Map listPrompts() {
        return makeRequest("prompts/list", [:])
    }
    
    /**
     * Check if server is reachable via HTTP GET
     */
    boolean isServerReachable() {
        try {
            HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(mcpUrl))
                .GET()
                .timeout(Duration.ofSeconds(5))
                .build()
            
            HttpResponse<String> response = httpClient.send(request, 
                HttpResponse.BodyHandlers.ofString())
            return response.statusCode() == 200
        } catch (Exception e) {
            return false
        }
    }
}

/**
 * Test basic MCP server connectivity and functionality
 */
boolean testMCPConnection() {
    println "========================================"
    println "Testing GrowERP MCP Server Connection"
    println "========================================"
    
    GrowERPMCPClient client = new GrowERPMCPClient()
    
    // Test 1: Server connectivity
    println "\n1. Testing server connectivity..."
    if (client.isServerReachable()) {
        println "✓ MCP server is responding"
    } else {
        println "✗ Cannot connect to MCP server"
        return false
    }
    
    // Test 2: Initialize MCP connection
    println "\n2. Initializing MCP connection..."
    Map initResult = client.initialize()
    if (initResult.containsKey("error")) {
        println "✗ Initialization failed: ${initResult.error}"
        return false
    }
    
    // Test 3: Ping server
    println "\n3. Testing ping..."
    Map pingResult = client.ping()
    if (!pingResult.containsKey("error") && 
        pingResult.result?.status == "ok") {
        println "✓ Ping successful"
    } else {
        println "⚠ Ping failed: ${pingResult}"
    }
    
    // Test 4: List available tools
    println "\n4. Listing available tools..."
    Map toolsResult = client.listTools()
    if (!toolsResult.containsKey("error")) {
        List tools = toolsResult.result?.tools ?: []
        println "✓ Found ${tools.size()} available tools:"
        tools.take(5).each { tool ->
            println "  - ${tool.name ?: 'Unknown'}: ${tool.description ?: 'No description'}"
        }
        if (tools.size() > 5) {
            println "  ... and ${tools.size() - 5} more tools"
        }
    } else {
        println "⚠ Failed to list tools: ${toolsResult.error}"
    }
    
    // Test 5: Execute a simple tool
    println "\n5. Testing tool execution..."
    Map pingToolResult = client.callTool("ping_system")
    if (!pingToolResult.containsKey("error")) {
        Map result = pingToolResult.result ?: [:]
        if (!result.isError) {
            println "✓ Tool execution successful"
        } else {
            println "⚠ Tool execution failed: ${result}"
        }
    } else {
        println "⚠ Tool call failed: ${pingToolResult.error}"
    }
    
    // Test 6: List resources
    println "\n6. Listing available resources..."
    Map resourcesResult = client.listResources()
    if (!resourcesResult.containsKey("error")) {
        List resources = resourcesResult.result?.resources ?: []
        println "✓ Found ${resources.size()} available resources:"
        resources.take(3).each { resource ->
            println "  - ${resource.name ?: 'Unknown'}: ${resource.uri ?: 'No URI'}"
        }
    } else {
        println "⚠ Failed to list resources: ${resourcesResult.error}"
    }
    
    println "\n========================================"
    println "✓ MCP Server Test Complete!"
    println "========================================"
    return true
}

/**
 * Example of how to use MCP server data in AI interactions
 */
Map aiIntegrationExample() {
    println "\n========================================"
    println "AI Integration Example"
    println "========================================"
    
    GrowERPMCPClient client = new GrowERPMCPClient()
    client.initialize()
    
    // Scenario: AI assistant needs business data
    println "\nScenario: AI assistant checking system health and business data"
    
    // Step 1: Check system health
    println "\n1. Checking system health..."
    Map healthResult = client.callTool("ping_system")
    
    if (!healthResult.containsKey("error")) {
        Map result = healthResult.result ?: [:]
        if (!result.isError) {
            println "✓ System is healthy"
            String systemInfo = result.content?.get(0)?.text ?: ""
            println "   ${systemInfo}"
        } else {
            println "⚠ System health check failed"
        }
    }
    
    // Step 2: Get business data
    println "\n2. Fetching company data..."
    Map companiesResult = client.callTool("get_companies", [limit: 3])
    
    if (!companiesResult.containsKey("error")) {
        Map result = companiesResult.result ?: [:]
        if (!result.isError) {
            println "✓ Retrieved company data"
            String companyInfo = result.content?.get(0)?.text ?: ""
            println "   ${companyInfo}"
        } else {
            println "⚠ Failed to get company data"
        }
    }
    
    // Step 3: Analyze data for AI
    println "\n3. Preparing data for AI analysis..."
    
    Map aiContext = [
        system_status: healthResult,
        business_data: companiesResult,
        timestamp: System.currentTimeMillis(),
        data_source: "GrowERP MCP Server"
    ]
    
    println "✓ Data prepared for AI analysis:"
    println new JsonBuilder(aiContext).toPrettyString()
    
    // Example AI prompt that could use this data
    String aiPrompt = """
Based on the following GrowERP system data:

System Status: ${healthResult}
Business Data: ${companiesResult}

Please provide:
1. A summary of the system health
2. Key insights about the business data
3. Any recommendations for action
"""
    
    println "\n" + "="*50
    println "Example AI Prompt:"
    println "="*50
    println aiPrompt
    println "="*50
    
    return aiContext
}

/**
 * Simple AI prompt builder using built-in Groovy features
 */
class SimpleAIPromptBuilder {
    private StringBuilder prompt = new StringBuilder()
    private Map context = [:]
    
    SimpleAIPromptBuilder withSystemContext(String context) {
        prompt.append("System Context: ").append(context).append("\n\n")
        return this
    }
    
    SimpleAIPromptBuilder withBusinessData(Map data) {
        this.context.putAll(data)
        prompt.append("Business Data:\n")
        data.each { key, value ->
            prompt.append("- ${key}: ${value}\n")
        }
        prompt.append("\n")
        return this
    }
    
    SimpleAIPromptBuilder withQuery(String query) {
        prompt.append("User Query: ").append(query).append("\n\n")
        return this
    }
    
    SimpleAIPromptBuilder withInstructions(String instructions) {
        prompt.append("Instructions: ").append(instructions).append("\n\n")
        return this
    }
    
    String build() {
        return prompt.toString()
    }
    
    Map getContext() {
        return context
    }
}

/**
 * Simple business AI assistant without external dependencies
 */
class SimpleBusinessAIAssistant {
    private GrowERPMCPClient mcpClient
    
    SimpleBusinessAIAssistant(String mcpUrl = "http://localhost:8081") {
        this.mcpClient = new GrowERPMCPClient(mcpUrl)
        this.mcpClient.initialize()
    }
    
    /**
     * Process a business query with full context
     */
    Map processQuery(String query) {
        println "🤖 Processing query: ${query}"
        
        // Get business context
        def contextData = [:]
        
        // Ping system
        def pingResult = mcpClient.callTool("ping_system")
        if (!pingResult.containsKey("error")) {
            contextData.system_health = pingResult
        }
        
        // Get companies
        def companiesResult = mcpClient.callTool("get_companies", [limit: 5])
        if (!companiesResult.containsKey("error")) {
            contextData.companies = companiesResult
        }
        
        // Get users
        def usersResult = mcpClient.callTool("get_users", [limit: 3])
        if (!usersResult.containsKey("error")) {
            contextData.users = usersResult
        }
        
        // Create AI prompt
        def promptBuilder = new SimpleAIPromptBuilder()
            .withSystemContext("GrowERP Business Management System")
            .withBusinessData(contextData)
            .withQuery(query)
            .withInstructions("Provide a comprehensive response based on the business context above.")
        
        String prompt = promptBuilder.build()
        
        // Simulate AI processing (in real use, send to OpenAI/Claude/etc.)
        def aiResponse = simulateAIResponse(prompt, contextData)
        
        return [
            query: query,
            context: contextData,
            prompt: prompt,
            aiResponse: aiResponse,
            timestamp: new Date()
        ]
    }
    
    /**
     * Simulate AI response (replace with actual AI API call)
     */
    private String simulateAIResponse(String prompt, Map context) {
        def insights = []
        
        // Analyze system health
        if (context.system_health?.result?.content) {
            insights << "System Status: Operational and responding normally"
        } else {
            insights << "System Status: May have connectivity issues"
        }
        
        // Analyze business data
        if (context.companies?.result?.content) {
            def companyText = context.companies.result.content[0]?.text ?: ""
            if (companyText.contains("companies")) {
                insights << "Business Analysis: Multiple companies are active in the system"
            }
        }
        
        if (context.users?.result?.content) {
            def userText = context.users.result.content[0]?.text ?: ""
            if (userText.contains("users")) {
                insights << "User Activity: System has active user base"
            }
        }
        
        return insights.join(". ") + ". Based on this data, the business operations appear to be functioning normally."
    }
}

/**
 * Demonstrate simple business AI integration
 */
void demonstrateSimpleAI() {
    println "\n========================================"
    println "Simple Business AI Assistant Demo"
    println "========================================"
    
    try {
        SimpleBusinessAIAssistant assistant = new SimpleBusinessAIAssistant()
        
        // Example queries
        def queries = [
            "What's the current status of my business?",
            "How many companies and users do I have?",
            "Is the system running normally?",
            "Give me a business overview"
        ]
        
        queries.each { query ->
            println "\n" + "-" * 40
            def result = assistant.processQuery(query)
            
            println "Query: ${result.query}"
            println "AI Response: ${result.aiResponse}"
            println "Context Keys: ${result.context.keySet()}"
        }
        
    } catch (Exception e) {
        println "❌ Error during AI demonstration: ${e.message}"
        println "Make sure the MCP server is running: ./deploy_mcp_server.sh"
    }
}

/**
 * Main function to run MCP tests and examples
 */
void main() {
    println "GrowERP MCP Client - AI Integration Example (Groovy - No Dependencies)"
    println "=" * 70
    
    // Test basic connectivity
    if (!testMCPConnection()) {
        println "\n⚠ MCP server tests failed. Please check:"
        println "  1. Is the MCP server running? (./deploy_mcp_server.sh)"
        println "  2. Is it accessible at http://localhost:8081?"
        println "  3. Check server logs for errors"
        return
    }
    
    // Show AI integration example
    Map aiContext = aiIntegrationExample()
    
    // Demonstrate simple AI assistant
    demonstrateSimpleAI()
    
    println "\n" + "="*50
    println "Next Steps:"
    println "="*50
    println "1. This client uses only built-in Java/Groovy libraries"
    println "2. Integrate with your AI framework (OpenAI, Anthropic, etc.)"
    println "3. Use the MCP data to enhance AI responses with real business data"
    println "4. Create custom tools for specific business operations"
    println "5. Set up authentication for production use"
    println "\nFor more examples, see: DEPLOYMENT_GUIDE.md"
}

// Run the main function if script is executed directly
if (this.class.name == 'test_mcp_client') {
    main()
}
