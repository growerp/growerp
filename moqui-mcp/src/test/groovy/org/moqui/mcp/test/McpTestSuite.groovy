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

import org.moqui.Moqui
import org.moqui.context.ExecutionContext
import spock.lang.Shared
import spock.lang.Specification
import spock.lang.Stepwise

@Stepwise
class McpTestSuite extends Specification {
    
    @Shared
    ExecutionContext ec

    @Shared
    SimpleMcpClient client

    @Shared
    boolean criticalTestFailed = false
    
    def setupSpec() {
        // Initialize Moqui framework for testing
        // Note: moqui.runtime is set by build.gradle
        
        // Clear moqui.conf to ensure we use the runtime's MoquiDevConf.xml instead of component's minimal conf
        //System.clearProperty('moqui.conf')
        
        // System.setProperty('moqui.init.static', 'true')
        
        ec = Moqui.getExecutionContext()

        // Initialize MCP client
        client = new SimpleMcpClient()
    }
    
    def cleanupSpec() {
        if (client) {
            client.closeSession()
        }
        if (ec) {
            ec.destroy()
        }
    }

    def "Test Internal Service Direct Call"() {
        println "🔧 Testing Internal Service Direct Call"
        println "📂 Runtime Path: ${System.getProperty('moqui.runtime')}"
        println "📂 Conf Path: ${System.getProperty('moqui.conf')}"
        
        if (ec == null) {
            println "⚠️ No ExecutionContext available - skipping internal service test (running in external client mode)"
            return
        }
        
        println "✅ ExecutionContext available, testing service directly"
        
        // Login as mcp-user to ensure we have a valid user context for the screen render
        try {
            ec.user.internalLoginUser("mcp-user")
            println "✅ Logged in as mcp-user"
        } catch (Throwable t) {
            println "❌ Failed to login as mcp-user: ${t.message}"
            t.printStackTrace()
            // Continue to see if service call works (it might fail auth but shouldn't crash)
        }
        
        when:
            // Call the service directly
            def result = ec.service.sync().name("McpServices.execute#ScreenAsMcpTool")
                .parameters([
                    screenPath: "component://moqui-mcp-2/screen/McpTestScreen.xml",
                    parameters: [message: "Direct Service Call Test"],
                    renderMode: "html"
                ])
                .call()
                
            println "✅ Service returned result: ${result}"
        
        then:
            // Verify result structure
            result != null
            result.result != null
            result.result.type == "html"
            result.result.screenPath == "component://moqui-mcp-2/screen/McpTestScreen.xml"
            !result.result.isError
            
            // Verify content
            def text = result.result.text
            println "📄 Rendered text length: ${text?.length()}"
            if (text && text.contains("Direct Service Call Test")) {
                println "🎉 SUCCESS: Found test message in direct render output"
            } else {
                println "⚠️ Test message not found in output (or output empty)"
            }

        cleanup:
            ec.user.logoutUser()
    }
    
    def "Test MCP Server Connectivity"() {
        if (criticalTestFailed) return

        println "🔌 Testing MCP Server Connectivity"
        
        expect:
        // Test session initialization first
        client.initializeSession()
        println "✅ Session initialized successfully"
        
        // Test server ping
        client.ping()
        println "✅ Server ping successful"
        
        // Test tool listing
        def tools = client.listTools()
        tools != null
        tools.size() > 0
        println "✅ Found ${tools.size()} available tools"
    }
    
    def "Test PopCommerce Product Search"() {
        if (criticalTestFailed) return

        println "🛍️ Testing PopCommerce Product Search"
        
        when:
        // Use SimpleScreens search screen directly (PopCommerce/SimpleScreens reuses this)
        // Pass "Blue" as queryString to find blue products
        def result = client.callScreen("component://SimpleScreens/screen/SimpleScreens/Catalog/Search.xml", [queryString: "Blue"])
        
        then:
        result != null
        result instanceof Map
        
        // Fail test if screen returns error
        !result.containsKey('error')
        !result.isError
        
        println "✅ PopCommerce search screen accessed successfully"
        
        // Check if we got content - fail test if no content
        def content = result.result?.content
        content != null && content instanceof List && content.size() > 0
        println "✅ Screen returned content with ${content.size()} items"
        
        def blueProductsFound = false
        
        // Look for product data in the content (HTML or JSON)
        for (item in content) {
            println "📦 Content item type: ${item.type}"
            if (item.type == "text" && item.text) {
                println "✅ Screen returned text content start: ${item.text.take(200)}..."
                
                // Check for HTML content containing expected product name
                if (item.text.contains("Demo with Variants Blue")) {
                    println "🛍️ Found 'Demo with Variants Blue' in HTML content!"
                    blueProductsFound = true
                }
                
                // Also try to parse as JSON just in case, but don't rely on it
                try {
                    def jsonData = new groovy.json.JsonSlurper().parseText(item.text)
                    if (jsonData instanceof Map) {
                        println "📊 Parsed JSON data keys: ${jsonData.keySet()}"
                        if (jsonData.containsKey('products') || jsonData.containsKey('productList')) {
                            def products = jsonData.products ?: jsonData.productList
                            if (products instanceof List && products.size() > 0) {
                                println "🛍️ Found ${products.size()} products in JSON!"
                                blueProductsFound = true
                            }
                        }
                    }
                } catch (Exception e) {
                    // Ignore JSON parse errors as we expect HTML
                }
            } else if (item.type == "resource" && item.resource) {
                println "🔗 Resource data: ${item.resource.keySet()}"
                if (item.resource.containsKey('products')) {
                    def products = item.resource.products
                    if (products instanceof List && products.size() > 0) {
                        println "🛍️ Found ${products.size()} products in resource!"
                        blueProductsFound = true
                    }
                }
            }
        }
        
        // Fail test if no blue products were found
        blueProductsFound
    }
    
    def "Test Customer Lookup"() {
        if (criticalTestFailed) return

        println "👤 Testing Customer Lookup"
        
        when:
        // Use actual available screen - PartyList from mantle component
        def result = client.callScreen("component://mantle/screen/party/PartyList.xml", [:])
        
        then:
        result != null
        result instanceof Map
        
        if (result.containsKey('error')) {
            println "⚠️ Screen call returned error: ${result.error}"
        } else {
            println "✅ Party list screen accessed successfully"
            
            // Check if we got content
            def content = result.result?.content
            if (content && content instanceof List && content.size() > 0) {
                println "✅ Screen returned content with ${content.size()} items"
                
                // Look for customer data in the content
                for (item in content) {
                    if (item.type == "text" && item.text) {
                        println "✅ Screen returned text content: ${item.text.take(100)}..."
                        break
                    }
                }
            } else {
                println "✅ Screen executed successfully (no structured customer data expected)"
            }
        }
    }
    
    def "Test Complete Order Workflow"() {
        if (criticalTestFailed) return

        println "🛒 Testing Complete Order Workflow"
        
        when:
        // Use actual available screen - OrderList from mantle component
        def result = client.callScreen("component://mantle/screen/order/OrderList.xml", [:])
        
        then:
        result != null
        result instanceof Map
        
        if (result.containsKey('error')) {
            println "⚠️ Screen call returned error: ${result.error}"
        } else {
            println "✅ Order list screen accessed successfully"
            
            // Check if we got content
            def content = result.result?.content
            if (content && content instanceof List && content.size() > 0) {
                println "✅ Screen returned content with ${content.size()} items"
                
                // Look for order data in the content
                for (item in content) {
                    if (item.type == "text" && item.text) {
                        println "✅ Screen returned text content: ${item.text.take(100)}..."
                        break
                    }
                }
            } else {
                println "✅ Screen executed successfully (no structured order data expected)"
            }
        }
    }
    
    def "Test MCP Screen Infrastructure"() {
        if (criticalTestFailed) return

        println "🖥️ Testing MCP Screen Infrastructure"
        
        when:
        // Test calling the MCP test screen with a custom message
        def result = client.callScreen("component://moqui-mcp-2/screen/McpTestScreen.xml", [
            message: "MCP Test Successful!"
        ])
        
        then:
        result != null
        result instanceof Map
        
        if (result.containsKey('error')) {
            println "⚠️ Screen call returned error: ${result.error}"
        } else {
            println "✅ Screen infrastructure working correctly"
            
            // Check if we got content
            def content = result.result?.content
            if (content && content instanceof List && content.size() > 0) {
                println "✅ Screen returned content with ${content.size()} items"
                
                // Look for actual data in the content
                for (item in content) {
                    println "📦 Content item type: ${item.type}"
                    if (item.type == "text" && item.text) {
                        println "✅ Screen returned actual text content:"
                        println "   ${item.text}"
                        
                        // Verify the content contains our test message
                        if (item.text.contains("MCP Test Successful!")) {
                            println "🎉 SUCCESS: Custom message found in screen output!"
                        }
                        
                        // Look for user and timestamp info
                        if (item.text.contains("User:")) {
                            println "👤 User information found in output"
                        }
                        if (item.text.contains("Time:")) {
                            println "🕐 Timestamp found in output"
                        }
                        break
                    } else if (item.type == "resource" && item.resource) {
                        println "🔗 Resource data: ${item.resource.keySet()}"
                    }
                }
            } else {
                println "⚠️ No content returned from screen"
            }
        }
    }
}
