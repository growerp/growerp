#!/usr/bin/env groovy

/**
 * Advanced Groovy MCP Integration Examples
 * Demonstrates advanced patterns for integrating GrowERP MCP server with AI applications
 */

@Grab('org.apache.httpcomponents:httpclient:4.5.13')
@Grab('com.fasterxml.jackson.core:jackson-databind:2.15.2')

import org.apache.http.client.methods.HttpPost
import org.apache.http.entity.StringEntity
import org.apache.http.impl.client.HttpClients
import org.apache.http.util.EntityUtils
import com.fasterxml.jackson.databind.ObjectMapper
import groovy.transform.CompileStatic
import java.util.concurrent.CompletableFuture
import java.util.concurrent.Executors

/**
 * Enhanced MCP Client with Groovy-specific features
 */
class AdvancedMCPClient {
    private String mcpUrl
    private def httpClient
    private ObjectMapper objectMapper
    private def executor = Executors.newFixedThreadPool(5)
    
    AdvancedMCPClient(String mcpUrl = "http://localhost:8081") {
        this.mcpUrl = mcpUrl
        this.httpClient = HttpClients.createDefault()
        this.objectMapper = new ObjectMapper()
    }
    
    /**
     * Async MCP request using CompletableFuture
     */
    CompletableFuture<Map> makeRequestAsync(String method, Map params = [:]) {
        return CompletableFuture.supplyAsync({
            makeRequest(method, params)
        }, executor)
    }
    
    /**
     * Synchronous MCP request
     */
    Map makeRequest(String method, Map params = [:]) {
        def requestData = [
            jsonrpc: "2.0",
            method: method,
            params: params,
            id: System.currentTimeMillis()
        ]
        
        try {
            HttpPost httpPost = new HttpPost(mcpUrl)
            httpPost.setHeader("Content-Type", "application/json")
            
            String jsonRequest = objectMapper.writeValueAsString(requestData)
            httpPost.setEntity(new StringEntity(jsonRequest))
            
            def response = httpClient.execute(httpPost)
            String responseBody = EntityUtils.toString(response.getEntity())
            
            return objectMapper.readValue(responseBody, Map.class)
            
        } catch (Exception e) {
            return [error: "Request failed: ${e.message}"]
        }
    }
    
    /**
     * Groovy builder-style tool execution
     */
    def tools(Closure closure) {
        def builder = new ToolBuilder(this)
        closure.delegate = builder
        closure.resolveStrategy = Closure.DELEGATE_FIRST
        closure.call()
        return builder.results
    }
    
    void close() {
        try {
            httpClient.close()
            executor.shutdown()
        } catch (Exception e) {
            // Ignore
        }
    }
}

/**
 * Groovy DSL Builder for MCP tool operations
 */
class ToolBuilder {
    private AdvancedMCPClient client
    def results = [:]
    
    ToolBuilder(AdvancedMCPClient client) {
        this.client = client
    }
    
    def ping() {
        results.ping = client.makeRequest("tools/call", [name: "ping_system"])
    }
    
    def companies(Map args = [:]) {
        results.companies = client.makeRequest("tools/call", [
            name: "get_companies", 
            arguments: args
        ])
    }
    
    def users(Map args = [:]) {
        results.users = client.makeRequest("tools/call", [
            name: "get_users", 
            arguments: args
        ])
    }
    
    def custom(String toolName, Map args = [:]) {
        results[toolName] = client.makeRequest("tools/call", [
            name: toolName,
            arguments: args
        ])
    }
}

/**
 * AI Integration DSL for creating prompts
 */
class AIPromptBuilder {
    private StringBuilder prompt = new StringBuilder()
    private Map context = [:]
    
    AIPromptBuilder withSystemContext(String context) {
        prompt.append("System Context: ").append(context).append("\n\n")
        return this
    }
    
    AIPromptBuilder withBusinessData(Map data) {
        this.context.putAll(data)
        prompt.append("Business Data:\n")
        data.each { key, value ->
            prompt.append("- ${key}: ${value}\n")
        }
        prompt.append("\n")
        return this
    }
    
    AIPromptBuilder withQuery(String query) {
        prompt.append("User Query: ").append(query).append("\n\n")
        return this
    }
    
    AIPromptBuilder withInstructions(String instructions) {
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
 * Groovy trait for MCP-enabled AI operations
 */
trait MCPEnabled {
    abstract AdvancedMCPClient getMcpClient()
    
    def withBusinessContext(Closure operation) {
        def data = mcpClient.tools {
            ping()
            companies(limit: 5)
            users(limit: 3)
        }
        
        operation.call(data.results)
    }
    
    String createContextualPrompt(String userQuery) {
        def promptBuilder = new AIPromptBuilder()
        
        withBusinessContext { businessData ->
            promptBuilder
                .withSystemContext("GrowERP Business Management System")
                .withBusinessData(businessData)
                .withQuery(userQuery)
                .withInstructions("Provide a comprehensive response based on the business context above.")
        }
        
        return promptBuilder.build()
    }
}

/**
 * Example AI Assistant with MCP integration
 */
class BusinessAIAssistant implements MCPEnabled {
    private AdvancedMCPClient mcpClient
    
    BusinessAIAssistant(String mcpUrl = "http://localhost:8081") {
        this.mcpClient = new AdvancedMCPClient(mcpUrl)
        this.mcpClient.makeRequest("initialize", [
            protocolVersion: "2024-11-05",
            clientInfo: [name: "business-ai-assistant", version: "1.0.0"]
        ])
    }
    
    @Override
    AdvancedMCPClient getMcpClient() {
        return mcpClient
    }
    
    /**
     * Process a business query with full context
     */
    Map processQuery(String query) {
        println "🤖 Processing query: ${query}"
        
        // Get business context
        def contextData = [:]
        withBusinessContext { data ->
            contextData = data
        }
        
        // Create AI prompt
        String prompt = createContextualPrompt(query)
        
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
        // In real implementation, send prompt to AI service
        def insights = []
        
        // Analyze system health
        if (context.ping?.result?.content) {
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
    
    void close() {
        mcpClient.close()
    }
}

/**
 * Demonstrate advanced Groovy patterns with MCP
 */
void demonstrateAdvancedPatterns() {
    println "========================================="
    println "Advanced Groovy MCP Integration Patterns"
    println "========================================="
    
    AdvancedMCPClient client = new AdvancedMCPClient()
    
    try {
        // Initialize
        client.makeRequest("initialize", [
            protocolVersion: "2024-11-05",
            clientInfo: [name: "advanced-groovy-client"]
        ])
        
        // Pattern 1: Groovy DSL for tool operations
        println "\n1. Groovy DSL Pattern:"
        println "----------------------"
        
        def results = client.tools {
            ping()
            companies(limit: 2)
            users(limit: 1)
        }
        
        println "✓ DSL executed successfully"
        println "Results: ${results.results.keySet()}"
        
        // Pattern 2: Async operations with CompletableFuture
        println "\n2. Async Operations Pattern:"
        println "----------------------------"
        
        def futures = [
            client.makeRequestAsync("tools/call", [name: "ping_system"]),
            client.makeRequestAsync("tools/call", [name: "get_companies", arguments: [limit: 1]]),
            client.makeRequestAsync("tools/list", [:])
        ]
        
        def asyncResults = futures.collect { it.get() }
        println "✓ Async operations completed: ${asyncResults.size()} results"
        
        // Pattern 3: AI Prompt Builder
        println "\n3. AI Prompt Builder Pattern:"
        println "-----------------------------"
        
        def prompt = new AIPromptBuilder()
            .withSystemContext("Business Management System")
            .withBusinessData([companies: 5, users: 12, status: "healthy"])
            .withQuery("What's the current business status?")
            .withInstructions("Provide actionable insights")
            .build()
        
        println "✓ AI Prompt created:"
        println prompt.take(200) + "..."
        
    } finally {
        client.close()
    }
}

/**
 * Demonstrate full AI assistant integration
 */
void demonstrateAIAssistant() {
    println "\n========================================="
    println "Business AI Assistant Demo"
    println "========================================="
    
    BusinessAIAssistant assistant = new BusinessAIAssistant()
    
    try {
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
        
    } finally {
        assistant.close()
    }
}

/**
 * Main execution
 */
void main() {
    println "Advanced Groovy MCP Integration Examples"
    println "=" * 45
    
    try {
        demonstrateAdvancedPatterns()
        demonstrateAIAssistant()
        
        println "\n" + "=" * 45
        println "Integration Patterns Demonstrated:"
        println "=" * 45
        println "✓ Groovy DSL for MCP operations"
        println "✓ Async/concurrent request handling"
        println "✓ Builder pattern for AI prompts"
        println "✓ Trait-based MCP integration"
        println "✓ Full AI assistant implementation"
        println "\nThese patterns can be extended for:"
        println "• Custom business logic DSLs"
        println "• Multi-tenant MCP operations"
        println "• Advanced AI workflow automation"
        println "• Real-time business intelligence"
        
    } catch (Exception e) {
        println "❌ Error during demonstration: ${e.message}"
        println "Make sure the MCP server is running: ./deploy_mcp_server.sh"
    }
}

// Run if executed directly
if (this.class.name == 'advanced_mcp_examples') {
    main()
}
