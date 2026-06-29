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

import groovy.json.JsonSlurper
import groovy.json.JsonOutput
import java.util.concurrent.atomic.AtomicInteger
import java.util.concurrent.atomic.AtomicReference
import java.util.concurrent.TimeUnit

/**
 * Comprehensive MCP Test Client for testing workflows
 * Supports both JSON-RPC and SSE communication
 */
class McpTestClient {
    private String baseUrl
    private String username
    private String password
    private JsonSlurper jsonSlurper = new JsonSlurper()
    private String sessionId = null
    private AtomicInteger requestId = new AtomicInteger(1)
    
    // Test results tracking
    def testResults = []
    def currentWorkflow = null
    
    McpTestClient(String baseUrl = "http://localhost:8080/mcp", 
                  String username = "mcp-user", 
                  String password = "moqui") {
        this.baseUrl = baseUrl
        this.username = username
        this.password = password
    }
    
    /**
     * Initialize MCP session
     */
    boolean initialize() {
        println "🚀 Initializing MCP session..."
        
        def response = sendJsonRpc("initialize", [
            protocolVersion: "2025-06-18",
            capabilities: [
                tools: [:],
                resources: [:]
            ],
            clientInfo: [
                name: "MCP Test Client",
                version: "1.0.0"
            ]
        ])
        
        if (response && response.result) {
            this.sessionId = response.result.sessionId
            println "✅ Session initialized: ${sessionId}"
            return true
        } else {
            println "❌ Failed to initialize session"
            return false
        }
    }
    
    /**
     * Send JSON-RPC request
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
            def process = ["curl", "-s", "-u", "${username}:${password}", 
                          "-H", "Content-Type: application/json",
                          "-H", "Mcp-Session-Id: ${sessionId ?: ''}",
                          "-d", jsonRequest, baseUrl].execute()
            
            def responseText = process.text
            def response = jsonSlurper.parseText(responseText)
            
            if (response.error) {
                println "❌ Error: ${response.error.message}"
                return null
            }
            
            println "📥 Response received"
            return response
        } catch (Exception e) {
            println "❌ Request failed: ${e.message}"
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
     * Test product discovery workflow
     */
    def testProductDiscoveryWorkflow() {
        startWorkflow("Product Discovery")
        
        try {
            // Step 1: Get available tools
            def tools = getTools()
            recordStep("Get Tools", tools.size() > 0, "Found ${tools.size()} tools")
            
            // Step 2: Find product-related screens
            def productScreens = tools.findAll { 
                it.name?.contains("Product") || it.description?.toLowerCase()?.contains("product") 
            }
            recordStep("Find Product Screens", productScreens.size() > 0, 
                      "Found ${productScreens.size()} product screens")
            
            // Step 3: Execute ProductList screen
            def productListScreen = tools.find { it.name?.contains("ProductList") }
            if (productListScreen) {
                def result = executeTool(productListScreen.name)
                recordStep("Execute ProductList", result != null, 
                          "Screen executed successfully")
            } else {
                recordStep("Find ProductList Screen", false, "ProductList screen not found")
            }
            
            // Step 4: Try to find products using entity resources
            def resources = getResources()
            def productEntities = resources.findAll { 
                it.uri?.contains("Product") || it.name?.toLowerCase()?.contains("product") 
            }
            recordStep("Find Product Entities", productEntities.size() > 0, 
                      "Found ${productEntities.size()} product entities")
            
            // Step 5: Query for products
            if (productEntities) {
                def productResource = productEntities.find { it.uri?.contains("Product") }
                if (productResource) {
                    def products = readResource(productResource.uri + "?limit=10")
                    recordStep("Query Products", products != null, 
                              "Retrieved product data")
                }
            }
            
        } catch (Exception e) {
            recordStep("Workflow Error", false, e.message)
        }
        
        return completeWorkflow()
    }
    
    /**
     * Test order placement workflow
     */
    def testOrderPlacementWorkflow() {
        startWorkflow("Order Placement")
        
        try {
            // Step 1: Get available tools
            def tools = getTools()
            recordStep("Get Tools", tools.size() > 0, "Found ${tools.size()} tools")
            
            // Step 2: Find order-related screens
            def orderScreens = tools.findAll { 
                it.name?.contains("Order") || it.description?.toLowerCase()?.contains("order") 
            }
            recordStep("Find Order Screens", orderScreens.size() > 0, 
                      "Found ${orderScreens.size()} order screens")
            
            // Step 3: Execute OrderList screen
            def orderListScreen = tools.find { it.name?.contains("OrderList") }
            if (orderListScreen) {
                def result = executeTool(orderListScreen.name)
                recordStep("Execute OrderList", result != null, 
                          "Order list screen executed successfully")
            } else {
                recordStep("Find OrderList Screen", false, "OrderList screen not found")
            }
            
            // Step 4: Try to access order creation
            def orderCreateScreen = tools.find { 
                it.name?.toLowerCase()?.contains("order") && 
                (it.name?.toLowerCase()?.contains("create") || it.name?.toLowerCase()?.contains("new"))
            }
            if (orderCreateScreen) {
                def result = executeTool(orderCreateScreen.name)
                recordStep("Access Order Creation", result != null, 
                          "Order creation screen accessed")
            } else {
                recordStep("Find Order Creation", false, "Order creation screen not found")
            }
            
            // Step 5: Check customer/party access
            def partyScreens = tools.findAll { 
                it.name?.contains("Party") || it.name?.contains("Customer") 
            }
            recordStep("Find Customer Screens", partyScreens.size() > 0, 
                      "Found ${partyScreens.size()} customer screens")
            
        } catch (Exception e) {
            recordStep("Workflow Error", false, e.message)
        }
        
        return completeWorkflow()
    }
    
    /**
     * Test complete e-commerce workflow
     */
    def testEcommerceWorkflow() {
        startWorkflow("E-commerce Full Workflow")
        
        try {
            // Step 1: Product Discovery
            def productResult = testProductDiscoveryWorkflow()
            recordStep("Product Discovery", productResult?.success, 
                      "Product discovery completed")
            
            // Step 2: Customer Management
            def tools = getTools()
            def customerScreens = tools.findAll { 
                it.name?.contains("Party") || it.name?.contains("Customer") 
            }
            recordStep("Customer Access", customerScreens.size() > 0, 
                      "Found ${customerScreens.size()} customer screens")
            
            // Step 3: Order Management
            def orderResult = testOrderPlacementWorkflow()
            recordStep("Order Management", orderResult?.success, 
                      "Order management completed")
            
            // Step 4: Catalog Management
            def catalogScreens = tools.findAll { 
                it.name?.toLowerCase()?.contains("catalog") 
            }
            recordStep("Catalog Access", catalogScreens.size() > 0, 
                      "Found ${catalogScreens.size()} catalog screens")
            
            if (catalogScreens) {
                def catalogResult = executeTool(catalogScreens[0].name)
                recordStep("Catalog Execution", catalogResult != null, 
                          "Catalog screen executed")
            }
            
        } catch (Exception e) {
            recordStep("Workflow Error", false, e.message)
        }
        
        return completeWorkflow()
    }
    
    /**
     * Generate test report
     */
    void generateReport() {
        println "\n" + "="*60
        println "📋 MCP TEST CLIENT REPORT"
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
     * Run all test workflows
     */
    void runAllTests() {
        println "🧪 Starting MCP Test Suite..."
        
        if (!initialize()) {
            println "❌ Failed to initialize MCP session"
            return
        }
        
        // Run individual workflows
        testProductDiscoveryWorkflow()
        testOrderPlacementWorkflow()
        testEcommerceWorkflow()
        
        // Generate report
        generateReport()
    }
    
    /**
     * Main method for standalone execution
     */
    static void main(String[] args) {
        def client = new McpTestClient()
        client.runAllTests()
    }
}