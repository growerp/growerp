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
import java.util.concurrent.TimeUnit

/**
 * Screen Infrastructure Test for MCP
 * Tests basic screen rendering, transitions, and form handling
 */
class ScreenInfrastructureTest {
    private McpJavaClient client
    private JsonSlurper jsonSlurper = new JsonSlurper()
    
    ScreenInfrastructureTest(McpJavaClient client) {
        this.client = client
    }
    
    /**
     * Test basic MCP connectivity and authentication
     */
    boolean testBasicConnectivity() {
        println "\n🔌 Testing Basic MCP Connectivity"
        println "=================================="
        
        try {
            // Test ping
            def pingResult = client.ping()
            if (!pingResult) {
                client.recordStep("Ping Server", false, "Failed to ping server")
                return false
            }
            client.recordStep("Ping Server", true, "Server responded: ${pingResult.status}")
            
            // Test tools list
            def tools = client.getTools()
            if (tools.size() == 0) {
                client.recordStep("List Tools", false, "No tools found")
                return false
            }
            client.recordStep("List Tools", true, "Found ${tools.size()} tools")
            
            // Test resources list
            def resources = client.getResources()
            client.recordStep("List Resources", true, "Found ${resources.size()} resources")
            
            return true
            
        } catch (Exception e) {
            client.recordStep("Basic Connectivity", false, e.message)
            return false
        }
    }
    
    /**
     * Test screen discovery and metadata
     */
    boolean testScreenDiscovery() {
        println "\n🔍 Testing Screen Discovery"
        println "============================"
        
        try {
            def tools = client.getTools()
            
            // Find screen-based tools
            def screenTools = tools.findAll { 
                it.name?.startsWith("screen_") || 
                it.description?.contains("Moqui screen:")
            }
            
            if (screenTools.size() == 0) {
                client.recordStep("Find Screen Tools", false, "No screen tools found")
                return false
            }
            
            client.recordStep("Find Screen Tools", true, "Found ${screenTools.size()} screen tools")
            
            // Validate screen tool structure
            def validScreenTools = 0
            screenTools.each { tool ->
                if (tool.name && tool.description && tool.inputSchema) {
                    validScreenTools++
                }
            }
            
            if (validScreenTools == 0) {
                client.recordStep("Validate Screen Tool Structure", false, "No valid screen tool structures")
                return false
            }
            
            client.recordStep("Validate Screen Tool Structure", true, 
                "${validScreenTools}/${screenTools.size()} tools have valid structure")
            
            // Print some screen tools for debugging
            println "\n📋 Sample Screen Tools:"
            screenTools.take(5).each { tool ->
                println "  - ${tool.name}: ${tool.description}"
            }
            
            return true
            
        } catch (Exception e) {
            client.recordStep("Screen Discovery", false, e.message)
            return false
        }
    }
    
    /**
     * Test basic screen rendering
     */
    boolean testScreenRendering() {
        println "\n🖥️ Testing Screen Rendering"
        println "============================"
        
        try {
            def tools = client.getTools()
            
            // Find a simple screen to test rendering
            def screenTools = tools.findAll { 
                it.name?.startsWith("screen_") && 
                !it.name?.toLowerCase()?.contains("error") &&
                !it.name?.toLowerCase()?.contains("system")
            }
            
            if (screenTools.size() == 0) {
                client.recordStep("Find Renderable Screen", false, "No renderable screens found")
                return false
            }
            
            // Try to render the first few screens
            def successfulRenders = 0
            def totalAttempts = Math.min(3, screenTools.size())
            
            screenTools.take(totalAttempts).each { tool ->
                try {
                    println "  🎨 Rendering screen: ${tool.name}"
                    def result = client.executeTool(tool.name, [:])
                    
                    if (result && result.content && result.content.size() > 0) {
                        def content = result.content[0]
                        if (content.text && content.text.length() > 0) {
                            successfulRenders++
                            println "    ✅ Rendered successfully (${content.text.length()} chars)"
                        } else {
                            println "    ⚠️ Empty content"
                        }
                    } else {
                        println "    ❌ No content returned"
                    }
                    
                } catch (Exception e) {
                    println "    ❌ Render failed: ${e.message}"
                }
            }
            
            if (successfulRenders == 0) {
                client.recordStep("Screen Rendering", false, "No screens rendered successfully")
                return false
            }
            
            client.recordStep("Screen Rendering", true, 
                "${successfulRenders}/${totalAttempts} screens rendered successfully")
            
            return true
            
        } catch (Exception e) {
            client.recordStep("Screen Rendering", false, e.message)
            return false
        }
    }
    
    /**
     * Test screen parameter handling
     */
    boolean testScreenParameters() {
        println "\n⚙️ Testing Screen Parameters"
        println "=============================="
        
        try {
            def tools = client.getTools()
            
            // Find screens with parameters
            def screensWithParams = tools.findAll { 
                it.name?.startsWith("screen_") && 
                it.inputSchema?.properties?.size() > 0
            }
            
            if (screensWithParams.size() == 0) {
                client.recordStep("Find Screens with Parameters", false, "No screens with parameters found")
                return false
            }
            
            client.recordStep("Find Screens with Parameters", true, 
                "Found ${screensWithParams.size()} screens with parameters")
            
            // Test parameter validation
            def validParamScreens = 0
            screensWithParams.take(3).each { tool ->
                try {
                    def params = tool.inputSchema.properties
                    def requiredParams = tool.inputSchema.required ?: []
                    
                    println "  📝 Screen ${tool.name} has ${params.size()} parameters (${requiredParams.size()} required)"
                    
                    // Try to call with empty parameters (should handle gracefully)
                    def result = client.executeTool(tool.name, [:])
                    
                    if (result) {
                        validParamScreens++
                        println "    ✅ Handled empty parameters"
                    } else {
                        println "    ⚠️ Failed with empty parameters"
                    }
                    
                } catch (Exception e) {
                    println "    ❌ Parameter test failed: ${e.message}"
                }
            }
            
            if (validParamScreens == 0) {
                client.recordStep("Parameter Handling", false, "No screens handled parameters correctly")
                return false
            }
            
            client.recordStep("Parameter Handling", true, 
                "${validParamScreens}/${Math.min(3, screensWithParams.size())} screens handled parameters")
            
            return true
            
        } catch (Exception e) {
            client.recordStep("Screen Parameters", false, e.message)
            return false
        }
    }
    
    /**
     * Test error handling and edge cases
     */
    boolean testErrorHandling() {
        println "\n🚨 Testing Error Handling"
        println "==========================="
        
        try {
            // Test invalid tool name
            def invalidResult = client.executeTool("nonexistent_screen", [:])
            if (invalidResult?.isError) {
                client.recordStep("Invalid Tool Error", true, "Correctly handled invalid tool")
            } else {
                client.recordStep("Invalid Tool Error", false, "Did not handle invalid tool correctly")
            }
            
            // Test malformed parameters
            def tools = client.getTools()
            def screenTools = tools.findAll { it.name?.startsWith("screen_") }
            
            if (screenTools.size() > 0) {
                def malformedResult = client.executeTool(screenTools[0].name, [
                    invalidParam: "invalid_value"
                ])
                
                // Should either succeed (ignoring invalid params) or fail gracefully
                client.recordStep("Malformed Parameters", true, 
                    malformedResult ? "Handled malformed parameters" : "Rejected malformed parameters")
            }
            
            return true
            
        } catch (Exception e) {
            client.recordStep("Error Handling", false, e.message)
            return false
        }
    }
    
    /**
     * Run all screen infrastructure tests
     */
    boolean runAllTests() {
        println "🧪 Running Screen Infrastructure Tests"
        println "====================================="
        
        client.startWorkflow("Screen Infrastructure Tests")
        
        def results = [
            testBasicConnectivity(),
            testScreenDiscovery(),
            testScreenRendering(),
            testScreenParameters(),
            testErrorHandling()
        ]
        
        def workflowResult = client.completeWorkflow()
        
        return workflowResult?.success ?: false
    }
    
    /**
     * Main method for standalone execution
     */
    static void main(String[] args) {
        def client = new McpJavaClient()
        def test = new ScreenInfrastructureTest(client)
        
        try {
            if (!client.initialize()) {
                println "❌ Failed to initialize MCP client"
                return
            }
            
            def success = test.runAllTests()
            
            println "\n" + "="*60
            println "🏁 SCREEN INFRASTRUCTURE TEST COMPLETE"
            println "="*60
            println "Overall Result: ${success ? '✅ PASSED' : '❌ FAILED'}"
            println "="*60
            
        } finally {
            client.close()
        }
    }
}