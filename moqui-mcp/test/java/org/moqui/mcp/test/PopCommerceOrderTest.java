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
import java.util.regex.Pattern

/**
 * PopCommerce Order Workflow Test
 * Tests complete workflow: Product lookup → Order placement for John Doe
 */
class PopCommerceOrderTest {
    private McpJavaClient client
    private JsonSlurper jsonSlurper = new JsonSlurper()
    
    // Test data
    def testCustomerId = null
    def testProductId = null
    def testOrderId = null
    
    PopCommerceOrderTest(McpJavaClient client) {
        this.client = client
    }
    
    /**
     * Step 1: Find and access PopCommerce catalog
     */
    boolean testPopCommerceCatalogAccess() {
        println "\n🛍️ Testing PopCommerce Catalog Access"
        println "===================================="
        
        try {
            def tools = client.getTools()
            
            // Find PopCommerce catalog screens
            def catalogScreens = tools.findAll { 
                (it.name?.toLowerCase()?.contains("catalog") || 
                 it.name?.toLowerCase()?.contains("product")) &&
                (it.description?.toLowerCase()?.contains("popcommerce") ||
                 it.name?.toLowerCase()?.contains("popcommerce"))
            }
            
            if (catalogScreens.size() == 0) {
                // Try broader search for any catalog/product screens
                catalogScreens = tools.findAll { 
                    it.name?.toLowerCase()?.contains("catalog") || 
                    it.name?.toLowerCase()?.contains("product")
                }
            }
            
            if (catalogScreens.size() == 0) {
                client.recordStep("Find Catalog Screens", false, "No catalog screens found")
                return false
            }
            
            client.recordStep("Find Catalog Screens", true, "Found ${catalogScreens.size()} catalog screens")
            
            // Try to render catalog screen
            def catalogScreen = catalogScreens[0]
            println "  📱 Testing catalog screen: ${catalogScreen.name}"
            
            def catalogResult = client.executeTool(catalogScreen.name, [:])
            
            if (!catalogResult || !catalogResult.content) {
                client.recordStep("Render Catalog Screen", false, "Failed to render catalog screen")
                return false
            }
            
            def content = catalogResult.content[0]
            if (!content.text || content.text.length() == 0) {
                client.recordStep("Render Catalog Screen", false, "Catalog screen returned empty content")
                return false
            }
            
            client.recordStep("Render Catalog Screen", true, 
                "Catalog rendered successfully (${content.text.length()} chars)")
            
            // Look for product listings in content
            def hasProducts = content.text.toLowerCase().contains("product") ||
                           content.text.toLowerCase().contains("item") ||
                           content.text.contains("<table") ||
                           content.text.contains("productList")
            
            if (hasProducts) {
                client.recordStep("Catalog Contains Products", true, "Catalog appears to contain product listings")
            } else {
                client.recordStep("Catalog Contains Products", false, "Catalog doesn't appear to have products")
            }
            
            return true
            
        } catch (Exception e) {
            client.recordStep("Catalog Access", false, e.message)
            return false
        }
    }
    
    /**
     * Step 2: Search for blue products
     */
    boolean testBlueProductSearch() {
        println "\n🔵 Testing Blue Product Search"
        println "================================"
        
        try {
            def tools = client.getTools()
            
            // Find catalog or search screens
            def searchScreens = tools.findAll { 
                it.name?.toLowerCase()?.contains("catalog") ||
                it.name?.toLowerCase()?.contains("product") ||
                it.name?.toLowerCase()?.contains("search")
            }
            
            if (searchScreens.size() == 0) {
                client.recordStep("Find Search Screens", false, "No search screens found")
                return false
            }
            
            client.recordStep("Find Search Screens", true, "Found ${searchScreens.size()} search screens")
            
            // Try different search approaches
            def foundBlueProduct = false
            
            searchScreens.each { screen ->
                try {
                    println "  🔍 Searching with screen: ${screen.name}"
                    
                    // Try with search parameters
                    def searchParams = [:]
                    
                    // Common search parameter names
                    def paramNames = ["search", "query", "productName", "name", "description", "color"]
                    paramNames.each { paramName ->
                        if (screen.inputSchema?.properties?.containsKey(paramName)) {
                            searchParams[paramName] = "blue"
                        }
                    }
                    
                    def searchResult = client.executeTool(screen.name, searchParams)
                    
                    if (searchResult && searchResult.content) {
                        def content = searchResult.content[0].text
                        
                        // Check if we found blue products
                        if (content.toLowerCase().contains("blue") ||
                            Pattern.compile(?i)\bblue\b).matcher(content).find()) {
                            
                            println "    ✅ Found blue products!"
                            foundBlueProduct = true
                            
                            // Try to extract a product ID
                            def productIdMatch = content =~ /product[_-]?id["\s]*[:=]["\s]*([A-Z0-9-_]+)/i
                            if (productIdMatch.find()) {
                                testProductId = productIdMatch[0][1]
                                println "    📋 Extracted product ID: ${testProductId}"
                            }
                            
                            return true // Stop searching
                        }
                    }
                    
                } catch (Exception e) {
                    println "    ❌ Search failed: ${e.message}"
                }
            }
            
            if (!foundBlueProduct) {
                // Try without search params - just get all products and look for blue ones
                def catalogScreens = tools.findAll { 
                    it.name?.toLowerCase()?.contains("catalog") ||
                    it.name?.toLowerCase()?.contains("product")
                }
                
                catalogScreens.each { screen ->
                    try {
                        def result = client.executeTool(screen.name, [:])
                        if (result && result.content) {
                            def content = result.content[0].text
                            if (content.toLowerCase().contains("blue")) {
                                foundBlueProduct = true
                                println "    ✅ Found blue products in catalog"
                                return true
                            }
                        }
                    } catch (Exception e) {
                        println "    ❌ Catalog check failed: ${e.message}"
                    }
                }
            }
            
            if (foundBlueProduct) {
                client.recordStep("Find Blue Products", true, "Successfully found blue products")
            } else {
                client.recordStep("Find Blue Products", false, "No blue products found")
            }
            
            return foundBlueProduct
            
        } catch (Exception e) {
            client.recordStep("Blue Product Search", false, e.message)
            return false
        }
    }
    
    /**
     * Step 3: Find or create John Doe customer
     */
    boolean testJohnDoeCustomer() {
        println "\n👤 Testing John Doe Customer"
        println "=============================="
        
        try {
            def tools = client.getTools()
            
            // Look for customer screens
            def customerScreens = tools.findAll { 
                it.name?.toLowerCase()?.contains("customer") ||
                it.name?.toLowerCase()?.contains("party")
            }
            
            if (customerScreens.size() == 0) {
                client.recordStep("Find Customer Screens", false, "No customer screens found")
                return false
            }
            
            client.recordStep("Find Customer Screens", true, "Found ${customerScreens.size()} customer screens")
            
            // Try to find John Doe
            def foundJohnDoe = false
            
            customerScreens.each { screen ->
                try {
                    println "  👥 Searching for John Doe with screen: ${screen.name}"
                    
                    // Try search parameters
                    def searchParams = [:]
                    def paramNames = ["search", "query", "firstName", "lastName", "name"]
                    
                    paramNames.each { paramName ->
                        if (screen.inputSchema?.properties?.containsKey(paramName)) {
                            if (paramName.contains("first")) {
                                searchParams[paramName] = "John"
                            } else if (paramName.contains("last")) {
                                searchParams[paramName] = "Doe"
                            } else {
                                searchParams[paramName] = "John Doe"
                            }
                        }
                    }
                    
                    def searchResult = client.executeTool(screen.name, searchParams)
                    
                    if (searchResult && searchResult.content) {
                        def content = searchResult.content[0].text
                        
                        // Check if we found John Doe
                        if (content.toLowerCase().contains("john") && 
                            content.toLowerCase().contains("doe")) {
                            
                            println "    ✅ Found John Doe!"
                            foundJohnDoe = true
                            
                            // Try to extract customer ID
                            def customerIdMatch = content =~ /party[_-]?id["\s]*[:=]["\s]*([A-Z0-9-_]+)/i
                            if (customerIdMatch.find()) {
                                testCustomerId = customerIdMatch[0][1]
                                println "    📋 Extracted customer ID: ${testCustomerId}"
                            }
                            
                            return true
                        }
                    }
                    
                } catch (Exception e) {
                    println "    ❌ Customer search failed: ${e.message}"
                }
            }
            
            if (foundJohnDoe) {
                client.recordStep("Find John Doe", true, "Successfully found John Doe customer")
            } else {
                client.recordStep("Find John Doe", false, "John Doe customer not found")
            }
            
            return foundJohnDoe
            
        } catch (Exception e) {
            client.recordStep("John Doe Customer", false, e.message)
            return false
        }
    }
    
    /**
     * Step 4: Create order for John Doe
     */
    boolean testOrderCreation() {
        println "\n🛒 Testing Order Creation"
        println "=========================="
        
        if (!testCustomerId) {
            client.recordStep("Order Creation", false, "No customer ID available")
            return false
        }
        
        try {
            def tools = client.getTools()
            
            // Find order screens
            def orderScreens = tools.findAll { 
                it.name?.toLowerCase()?.contains("order") &&
                !it.name?.toLowerCase()?.contains("find") &&
                !it.name?.toLowerCase()?.contains("list")
            }
            
            if (orderScreens.size() == 0) {
                client.recordStep("Find Order Screens", false, "No order creation screens found")
                return false
            }
            
            client.recordStep("Find Order Screens", true, "Found ${orderScreens.size()} order screens")
            
            // Try to create order
            def orderCreated = false
            
            orderScreens.each { screen ->
                try {
                    println "  📝 Creating order with screen: ${screen.name}"
                    
                    def orderParams = [:]
                    
                    // Add customer ID if parameter exists
                    def paramNames = ["customerId", "partyId", "customer", "customerPartyId"]
                    paramNames.each { paramName ->
                        if (screen.inputSchema?.properties?.containsKey(paramName)) {
                            orderParams[paramName] = testCustomerId
                        }
                    }
                    
                    // Add product ID if we have one
                    if (testProductId) {
                        def productParamNames = ["productId", "product", "itemId"]
                        productParamNames.each { paramName ->
                            if (screen.inputSchema?.properties?.containsKey(paramName)) {
                                orderParams[paramName] = testProductId
                            }
                        }
                    }
                    
                    // Add quantity
                    if (screen.inputSchema?.properties?.containsKey("quantity")) {
                        orderParams.quantity = "1"
                    }
                    
                    def orderResult = client.executeTool(screen.name, orderParams)
                    
                    if (orderResult && orderResult.content) {
                        def content = orderResult.content[0].text
                        
                        // Check if order was created
                        if (content.toLowerCase().contains("order") &&
                            (content.toLowerCase().contains("created") ||
                             content.toLowerCase().contains("success") ||
                             content.contains("orderId"))) {
                            
                            println "    ✅ Order created successfully!"
                            orderCreated = true
                            
                            // Try to extract order ID
                            def orderIdMatch = content =~ /order[_-]?id["\s]*[:=]["\s]*([A-Z0-9-_]+)/i
                            if (orderIdMatch.find()) {
                                testOrderId = orderIdMatch[0][1]
                                println "    📋 Extracted order ID: ${testOrderId}"
                            }
                            
                            return true
                        }
                    }
                    
                } catch (Exception e) {
                    println "    ❌ Order creation failed: ${e.message}"
                }
            }
            
            if (orderCreated) {
                client.recordStep("Create Order", true, "Successfully created order for John Doe")
            } else {
                client.recordStep("Create Order", false, "Failed to create order")
            }
            
            return orderCreated
            
        } catch (Exception e) {
            client.recordStep("Order Creation", false, e.message)
            return false
        }
    }
    
    /**
     * Step 5: Validate complete workflow
     */
    boolean testWorkflowValidation() {
        println "\n✅ Testing Workflow Validation"
        println "==============================="
        
        try {
            def allStepsComplete = testCustomerId && testOrderId
            
            if (allStepsComplete) {
                client.recordStep("Workflow Validation", true, 
                    "Complete workflow successful - Customer: ${testCustomerId}, Order: ${testOrderId}")
            } else {
                client.recordStep("Workflow Validation", false, 
                    "Incomplete workflow - Customer: ${testCustomerId}, Order: ${testOrderId}")
            }
            
            return allStepsComplete
            
        } catch (Exception e) {
            client.recordStep("Workflow Validation", false, e.message)
            return false
        }
    }
    
    /**
     * Run complete PopCommerce order workflow test
     */
    boolean runCompleteTest() {
        println "🛍️ Running PopCommerce Order Workflow Test"
        println "========================================"
        
        client.startWorkflow("PopCommerce Order Workflow")
        
        def results = [
            testPopCommerceCatalogAccess(),
            testBlueProductSearch(),
            testJohnDoeCustomer(),
            testOrderCreation(),
            testWorkflowValidation()
        ]
        
        def workflowResult = client.completeWorkflow()
        
        // Print summary
        println "\n📊 Workflow Summary:"
        println "  Customer ID: ${testCustomerId ?: 'Not found'}"
        println "  Product ID: ${testProductId ?: 'Not found'}"
        println "  Order ID: ${testOrderId ?: 'Not created'}"
        
        return workflowResult?.success ?: false
    }
    
    /**
     * Main method for standalone execution
     */
    static void main(String[] args) {
        def client = new McpJavaClient()
        def test = new PopCommerceOrderTest(client)
        
        try {
            if (!client.initialize()) {
                println "❌ Failed to initialize MCP client"
                return
            }
            
            def success = test.runCompleteTest()
            
            println "\n" + "="*60
            println "🏁 POPCOMMERCE ORDER WORKFLOW TEST COMPLETE"
            println "="*60
            println "Overall Result: ${success ? '✅ PASSED' : '❌ FAILED'}"
            println "="*60
            
        } finally {
            client.close()
        }
    }
}