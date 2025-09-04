#!/usr/bin/env groovy

/**
 * GrowERP MCP Client Example (Groovy)
 * This script demonstrates how to connect to the GrowERP MCP server and use it with AI requests.
 */

@Grab('org.apache.httpcomponents:httpclient:4.5.13')
@Grab('com.fasterxml.jackson.core:jackson-databind:2.15.2')

import org.apache.http.client.methods.HttpPost
import org.apache.http.client.methods.HttpGet
import org.apache.http.entity.StringEntity
import org.apache.http.impl.client.HttpClients
import org.apache.http.util.EntityUtils
import com.fasterxml.jackson.databind.ObjectMapper
import com.fasterxml.jackson.databind.JsonNode
import java.util.concurrent.atomic.AtomicInteger

class GrowERPMCPClient {
    private String mcpUrl
    private def httpClient
    private ObjectMapper objectMapper
    private boolean initialized = false
    private AtomicInteger requestId = new AtomicInteger(1)
    
    GrowERPMCPClient(String mcpUrl = "http://localhost:8081") {
        this.mcpUrl = mcpUrl
        this.httpClient = HttpClients.createDefault()
        this.objectMapper = new ObjectMapper()
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
            HttpPost httpPost = new HttpPost(mcpUrl)
            httpPost.setHeader("Content-Type", "application/json")
            httpPost.setHeader("Accept", "application/json")
            
            String jsonRequest = objectMapper.writeValueAsString(requestData)
            httpPost.setEntity(new StringEntity(jsonRequest))
            
            def response = httpClient.execute(httpPost)
            String responseBody = EntityUtils.toString(response.getEntity())
            
            if (response.getStatusLine().getStatusCode() != 200) {
                return [error: "HTTP ${response.getStatusLine().getStatusCode()}: ${responseBody}"]
            }
            
            return objectMapper.readValue(responseBody, Map.class)
            
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
            HttpGet httpGet = new HttpGet(mcpUrl)
            def response = httpClient.execute(httpGet)
            return response.getStatusLine().getStatusCode() == 200
        } catch (Exception e) {
            return false
        }
    }
    
    /**
     * Close the HTTP client
     */
    void close() {
        try {
            httpClient.close()
        } catch (Exception e) {
            // Ignore close errors
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
    
    try {
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
        
    } finally {
        client.close()
    }
}

/**
 * Example of how to use MCP server data in AI interactions
 */
Map aiIntegrationExample() {
    println "\n========================================"
    println "AI Integration Example"
    println "========================================"
    
    GrowERPMCPClient client = new GrowERPMCPClient()
    
    try {
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
        println new ObjectMapper().writerWithDefaultPrettyPrinter().writeValueAsString(aiContext)
        
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
        
    } finally {
        client.close()
    }
}

/**
 * Groovy MCP Integration Utilities
 */
class MCPIntegrationUtils {
    
    /**
     * Create a formatted prompt for AI with MCP data
     */
    static String createAIPrompt(Map mcpData, String userQuery) {
        StringBuilder prompt = new StringBuilder()
        
        prompt.append("Context from GrowERP MCP Server:\n")
        prompt.append("="*40).append("\n")
        
        mcpData.each { key, value ->
            prompt.append("${key}: ${value}\n")
        }
        
        prompt.append("\n").append("="*40).append("\n")
        prompt.append("User Query: ${userQuery}\n")
        prompt.append("\nPlease provide a response based on the above context and query.")
        
        return prompt.toString()
    }
    
    /**
     * Extract key business metrics from MCP response
     */
    static Map extractBusinessMetrics(Map mcpResponse) {
        Map metrics = [:]
        
        if (mcpResponse.result?.content) {
            mcpResponse.result.content.each { content ->
                if (content.text) {
                    // Parse common business metrics from text
                    String text = content.text
                    
                    // Extract company count
                    def companyMatch = text =~ /(\d+)\s+compan(y|ies)/
                    if (companyMatch) {
                        metrics.company_count = companyMatch[0][1] as Integer
                    }
                    
                    // Extract user count
                    def userMatch = text =~ /(\d+)\s+users?/
                    if (userMatch) {
                        metrics.user_count = userMatch[0][1] as Integer
                    }
                    
                    // Extract status information
                    if (text.toLowerCase().contains("healthy") || text.toLowerCase().contains("ok")) {
                        metrics.system_status = "healthy"
                    } else if (text.toLowerCase().contains("error") || text.toLowerCase().contains("failed")) {
                        metrics.system_status = "error"
                    }
                }
            }
        }
        
        return metrics
    }
}

/**
 * Main function to run MCP tests and examples
 */
void main() {
    println "GrowERP MCP Client - AI Integration Example (Groovy)"
    println "=" * 55
    
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
    
    // Demonstrate utility functions
    println "\n" + "="*50
    println "Groovy Integration Utilities Demo:"
    println "="*50
    
    // Create AI prompt
    String examplePrompt = MCPIntegrationUtils.createAIPrompt(
        aiContext, 
        "What is the current status of my business?"
    )
    println "\nExample AI Prompt Creation:"
    println examplePrompt
    
    // Extract metrics
    Map metrics = MCPIntegrationUtils.extractBusinessMetrics(aiContext.system_status)
    println "\nExtracted Business Metrics:"
    println metrics
    
    println "\n" + "="*50
    println "Next Steps:"
    println "="*50
    println "1. Integrate this Groovy client with your AI framework"
    println "2. Use MCPIntegrationUtils for common data processing tasks"
    println "3. Create custom Groovy tools for specific business operations"
    println "4. Set up authentication for production use"
    println "\nFor more examples, see: DEPLOYMENT_GUIDE.md"
}

// Run the main function if script is executed directly
if (this.class.name == 'test_mcp_client') {
    main()
}
