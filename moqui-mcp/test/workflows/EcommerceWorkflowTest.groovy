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
package org.moqui.mcp.test.workflows

import groovy.json.JsonSlurper
import groovy.json.JsonOutput
import java.util.concurrent.atomic.AtomicInteger

/**
 * E-commerce Workflow Test for MCP
 * Tests complete product discovery to order placement workflow
 */
class EcommerceWorkflowTest {
    private String baseUrl
    private String username
    private String password
    private JsonSlurper jsonSlurper = new JsonSlurper()
    private String sessionId = null
    private AtomicInteger requestId = new AtomicInteger(1)
    
    // Test data
    def testProductId = null
    def testCustomerId = null
    def testOrderId = null
    
    EcommerceWorkflowTest(String baseUrl = "http://localhost:8080/mcp", 
                          String username = "john.sales", 
                          String password = "opencode") {
        this.baseUrl = baseUrl
        this.username = username
        this.password = password
    }
    
    /**
     * Initialize MCP session
     */
    boolean initialize() {
        println "🚀 Initializing MCP session for workflow test..."
        
        def response = sendJsonRpc("initialize", [
            protocolVersion: "2025-06-18",
            capabilities: [
                tools: [:],
                resources: [:]
            ],
            clientInfo: [
                name: "E-commerce Workflow Test",
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
        
        if (sessionId) {
            request.params.sessionId = sessionId
        }
        
        def jsonRequest = JsonOutput.toJson(request)
        
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
            
            return response
        } catch (Exception e) {
            println "❌ Request failed: ${e.message}"
            return null
        }
    }
    
    /**
     * Execute a tool
     */
    def executeTool(String toolName, Map arguments = [:]) {
        def response = sendJsonRpc("tools/call", [
            name: toolName,
            arguments: arguments
        ])
        return response?.result
    }
    
    /**
     * Step 1: Product Discovery
     */
    boolean testProductDiscovery() {
        println "\n🔍 Step 1: Product Discovery"
        println "==========================="
        
        try {
            // Get available tools
            def toolsResponse = sendJsonRpc("tools/list")
            def tools = toolsResponse?.result?.tools ?: []
            println "Found ${tools.size()} available tools"
            
            // Find product-related tools
            def productTools = tools.findAll { 
                it.name?.toLowerCase()?.contains("product") || 
                it.description?.toLowerCase()?.contains("product")
            }
            println "Found ${productTools.size()} product-related tools"
            
            // Try to create a test product using MCP test service
            def createProductResult = executeTool("org.moqui.mcp.McpTestServices.create#TestProduct", [
                productName: "MCP Test Product ${System.currentTimeMillis()}",
                description: "Product created via MCP workflow test",
                price: 29.99,
                category: "MCP Test"
            ])
            
            if (createProductResult && createProductResult.success) {
                testProductId = createProductResult.productId
                println "✅ Created test product: ${testProductId}"
                return true
            } else {
                println "❌ Failed to create test product"
                return false
            }
            
        } catch (Exception e) {
            println "❌ Product discovery failed: ${e.message}"
            return false
        }
    }
    
    /**
     * Step 2: Customer Management
     */
    boolean testCustomerManagement() {
        println "\n👥 Step 2: Customer Management"
        println "==============================="
        
        try {
            // Create a test customer using MCP test service
            def createCustomerResult = executeTool("org.moqui.mcp.McpTestServices.create#TestCustomer", [
                firstName: "MCP",
                lastName: "TestCustomer",
                email: "test-${System.currentTimeMillis()}@mcp.test",
                phoneNumber: "555-TEST-MCP"
            ])
            
            if (createCustomerResult && createCustomerResult.success) {
                testCustomerId = createCustomerResult.partyId
                println "✅ Created test customer: ${testCustomerId}"
                return true
            } else {
                println "❌ Failed to create test customer"
                return false
            }
            
        } catch (Exception e) {
            println "❌ Customer management failed: ${e.message}"
            return false
        }
    }
    
    /**
     * Step 3: Order Placement
     */
    boolean testOrderPlacement() {
        println "\n🛒 Step 3: Order Placement"
        println "=========================="
        
        if (!testProductId || !testCustomerId) {
            println "❌ Missing test data: productId=${testProductId}, customerId=${testCustomerId}"
            return false
        }
        
        try {
            // Create a test order using MCP test service
            def createOrderResult = executeTool("org.moqui.mcp.McpTestServices.create#TestOrder", [
                customerId: testCustomerId,
                productId: testProductId,
                quantity: 2,
                price: 29.99
            ])
            
            if (createOrderResult && createOrderResult.success) {
                testOrderId = createOrderResult.orderId
                println "✅ Created test order: ${testOrderId}"
                return true
            } else {
                println "❌ Failed to create test order"
                return false
            }
            
        } catch (Exception e) {
            println "❌ Order placement failed: ${e.message}"
            return false
        }
    }
    
    /**
     * Step 4: Screen-based Workflow
     */
    boolean testScreenBasedWorkflow() {
        println "\n🖥️ Step 4: Screen-based Workflow"
        println "================================="
        
        try {
            // Get available tools
            def toolsResponse = sendJsonRpc("tools/list")
            def tools = toolsResponse?.result?.tools ?: []
            
            // Find catalog screens
            def catalogScreens = tools.findAll { 
                it.name?.toLowerCase()?.contains("catalog") 
            }
            
            if (catalogScreens) {
                println "Found ${catalogScreens.size()} catalog screens"
                
                // Try to execute the first catalog screen
                def catalogResult = executeTool(catalogScreens[0].name)
                if (catalogResult) {
                    println "✅ Successfully executed catalog screen: ${catalogScreens[0].name}"
                    return true
                } else {
                    println "❌ Failed to execute catalog screen"
                    return false
                }
            } else {
                println "⚠️ No catalog screens found, skipping screen test"
                return true // Not a failure, just not available
            }
            
        } catch (Exception e) {
            println "❌ Screen-based workflow failed: ${e.message}"
            return false
        }
    }
    
    /**
     * Step 5: Complete E-commerce Workflow
     */
    boolean testCompleteWorkflow() {
        println "\n🔄 Step 5: Complete E-commerce Workflow"
        println "========================================"
        
        try {
            // Run the complete e-commerce workflow service
            def workflowResult = executeTool("org.moqui.mcp.McpTestServices.run#EcommerceWorkflow", [
                productName: "Complete Workflow Product ${System.currentTimeMillis()}",
                customerFirstName: "Workflow",
                customerLastName: "Test",
                customerEmail: "workflow-${System.currentTimeMillis()}@mcp.test",
                quantity: 1,
                price: 49.99
            ])
            
            if (workflowResult && workflowResult.success) {
                println "✅ Complete workflow executed successfully"
                println "   Workflow ID: ${workflowResult.workflowId}"
                println "   Product ID: ${workflowResult.productId}"
                println "   Customer ID: ${workflowResult.customerId}"
                println "   Order ID: ${workflowResult.orderId}"
                
                // Print workflow steps
                workflowResult.steps?.each { step ->
                    println "   ${step.success ? '✅' : '❌'} ${step.step}: ${step.message}"
                }
                
                return true
            } else {
                println "❌ Complete workflow failed"
                return false
            }
            
        } catch (Exception e) {
            println "❌ Complete workflow failed: ${e.message}"
            return false
        }
    }
    
    /**
     * Step 6: Cleanup Test Data
     */
    boolean testCleanup() {
        println "\n🧹 Step 6: Cleanup Test Data"
        println "============================"
        
        try {
            // Cleanup test data using MCP test service
            def cleanupResult = executeTool("org.moqui.mcp.McpTestServices.cleanup#TestData", [
                olderThanHours: 0 // Cleanup immediately
            ])
            
            if (cleanupResult && cleanupResult.success) {
                println "✅ Test data cleanup completed"
                println "   Deleted orders: ${cleanupResult.deletedOrders}"
                println "   Deleted products: ${cleanupResult.deletedProducts}"
                println "   Deleted customers: ${cleanupResult.deletedCustomers}"
                return true
            } else {
                println "❌ Test data cleanup failed"
                return false
            }
            
        } catch (Exception e) {
            println "❌ Cleanup failed: ${e.message}"
            return false
        }
    }
    
    /**
     * Run complete e-commerce workflow test
     */
    void runCompleteTest() {
        println "🧪 E-commerce Workflow Test for MCP"
        println "=================================="
        
        def startTime = System.currentTimeMillis()
        def results = [:]
        
        // Initialize session
        if (!initialize()) {
            println "❌ Failed to initialize MCP session"
            return
        }
        
        // Run all test steps
        results.productDiscovery = testProductDiscovery()
        results.customerManagement = testCustomerManagement()
        results.orderPlacement = testOrderPlacement()
        results.screenBasedWorkflow = testScreenBasedWorkflow()
        results.completeWorkflow = testCompleteWorkflow()
        results.cleanup = testCleanup()
        
        // Generate report
        def endTime = System.currentTimeMillis()
        def duration = endTime - startTime
        
        println "\n" + "="*60
        println "📋 E-COMMERCE WORKFLOW TEST REPORT"
        println "="*60
        println "Duration: ${duration}ms"
        println ""
        
        def totalSteps = results.size()
        def successfulSteps = results.count { it.value }
        
        results.each { stepName, success ->
            println "${success ? '✅' : '❌'} ${stepName}"
        }
        
        println ""
        println "Overall Result: ${successfulSteps}/${totalSteps} steps passed"
        println "Success Rate: ${(successfulSteps/totalSteps * 100).round()}%"
        
        if (successfulSteps == totalSteps) {
            println "🎉 ALL TESTS PASSED! MCP e-commerce workflow is working correctly."
        } else {
            println "⚠️ Some tests failed. Check the output above for details."
        }
        
        println "="*60
    }
    
    /**
     * Main method for standalone execution
     */
    static void main(String[] args) {
        def test = new EcommerceWorkflowTest()
        test.runCompleteTest()
    }
}