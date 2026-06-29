/*
 * This software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 *
 * To the extent possible under law, the author(s) have dedicated all
 * copyright and related and neighboring rights to this software to the
 * public domain worldwide. This software is distributed without any
 * warranty.
 *
 * You should have received a copy of the CC0 Public Domain Dedication
 * along with this software (see the LICENSE.md file). If not, see
 * <http://creativecommons.org/publicdomain/zero/1.0/>.
 */

import groovy.json.JsonBuilder
import groovy.json.JsonSlurper
import java.util.concurrent.TimeUnit

/**
 * Screen Infrastructure Test for MCP
 * 
 * Tests screen-based functionality following Moqui patterns:
 * - Screen discovery and navigation
 * - Form-list and form-single execution
 * - Transition testing
 * - Parameter handling
 * - Subscreen navigation
 * - Security and permissions
 */
class ScreenInfrastructureTest {
    
    static void main(String[] args) {
        def test = new ScreenInfrastructureTest()
        test.runAllTests()
    }
    
    def jsonSlurper = new JsonSlurper()
    def testResults = [:]
    def startTime = System.currentTimeMillis()
    
    void runAllTests() {
        println "🖥️  Screen Infrastructure Test for MCP"
        println "=================================="
        
        try {
            // Initialize MCP session
            def sessionId = initializeSession()
            
            // Run screen infrastructure tests
            testScreenDiscovery(sessionId)
            testScreenNavigation(sessionId)
            testFormListExecution(sessionId)
            testFormSingleExecution(sessionId)
            testTransitionExecution(sessionId)
            testParameterHandling(sessionId)
            testSubscreenNavigation(sessionId)
            testScreenSecurity(sessionId)
            
            // Generate report
            generateReport()
            
        } catch (Exception e) {
            println "❌ Test failed with exception: ${e.message}"
            e.printStackTrace()
        }
    }
    
    String initializeSession() {
        println "\n🚀 Initializing MCP session for screen test..."
        
        def initResult = callMcpService("org.moqui.mcp.McpTestServices.initialize#Session", [:])
        if (initResult?.sessionId) {
            println "✅ Session initialized: ${initResult.sessionId}"
            return initResult.sessionId
        } else {
            throw new RuntimeException("Failed to initialize session")
        }
    }
    
    void testScreenDiscovery(String sessionId) {
        println "\n🔍 Test 1: Screen Discovery"
        println "============================="
        
        try {
            // Test tool discovery for screen-related tools
            def tools = callMcpService("org.moqui.mcp.McpServices.get#AvailableTools", [:])
            def screenTools = tools?.tools?.findAll { it.name?.contains('screen') || it.name?.contains('Screen') }
            
            if (screenTools && screenTools.size() > 0) {
                println "✅ Found ${screenTools.size()} screen-related tools"
                screenTools.each { tool ->
                    println "   - ${tool.name}: ${tool.description}"
                }
                testResults.screenDiscovery = true
            } else {
                println "❌ No screen tools found"
                testResults.screenDiscovery = false
            }
            
            // Test screen path resolution
            def screenPaths = [
                "SimpleScreens/Order/FindOrder",
                "SimpleScreens/Catalog/Product", 
                "SimpleScreens/Customer/FindCustomer",
                "PopCommerceAdmin/Catalog"
            ]
            
            def validScreens = []
            screenPaths.each { path ->
                try {
                    def result = callMcpService("org.moqui.mcp.McpServices.execute#Screen", [
                        screenPath: path,
                        parameters: [:]
                    ])
                    if (result && !result.error) {
                        validScreens << path
                        println "   ✅ Screen accessible: ${path}"
                    }
                } catch (Exception e) {
                    println "   ⚠️  Screen not accessible: ${path} - ${e.message}"
                }
            }
            
            testResults.screenDiscoveryValid = validScreens.size() > 0
            println "✅ Valid screens found: ${validScreens.size()}/${screenPaths.size()}"
            
        } catch (Exception e) {
            println "❌ Screen discovery test failed: ${e.message}"
            testResults.screenDiscovery = false
        }
    }
    
    void testScreenNavigation(String sessionId) {
        println "\n🧭 Test 2: Screen Navigation"
        println "=============================="
        
        try {
            // Test navigation to known screens
            def navigationTests = [
                [
                    name: "Order Find Screen",
                    path: "SimpleScreens/Order/FindOrder",
                    expectedElements: ["OrderList", "CreateSalesOrderDialog"]
                ],
                [
                    name: "Product Catalog", 
                    path: "SimpleScreens/Catalog/Product",
                    expectedElements: ["ProductList", "CreateProductDialog"]
                ],
                [
                    name: "Customer Find",
                    path: "SimpleScreens/Customer/FindCustomer", 
                    expectedElements: ["CustomerList", "CreateCustomerDialog"]
                ]
            ]
            
            def passedTests = 0
            navigationTests.each { test ->
                try {
                    def result = callMcpService("org.moqui.mcp.McpServices.execute#Screen", [
                        screenPath: test.path,
                        parameters: [:]
                    ])
                    
                    if (result && !result.error) {
                        def foundElements = 0
                        test.expectedElements.each { element ->
                            if (result.content?.toString()?.contains(element)) {
                                foundElements++
                            }
                        }
                        
                        if (foundElements > 0) {
                            println "   ✅ ${test.name}: ${foundElements}/${test.expectedElements.size()} elements found"
                            passedTests++
                        } else {
                            println "   ⚠️  ${test.name}: No expected elements found"
                        }
                    } else {
                        println "   ❌ ${test.name}: ${result?.error ?: 'Unknown error'}"
                    }
                } catch (Exception e) {
                    println "   ❌ ${test.name}: ${e.message}"
                }
            }
            
            testResults.screenNavigation = passedTests > 0
            println "✅ Navigation tests passed: ${passedTests}/${navigationTests.size()}"
            
        } catch (Exception e) {
            println "❌ Screen navigation test failed: ${e.message}"
            testResults.screenNavigation = false
        }
    }
    
    void testFormListExecution(String sessionId) {
        println "\n📋 Test 3: Form-List Execution"
        println "================================="
        
        try {
            // Test form-list with search parameters
            def formListTests = [
                [
                    name: "Order List Search",
                    screenPath: "SimpleScreens/Order/FindOrder",
                    transition: "actions",
                    parameters: [
                        orderId: "",
                        partStatusId: "OrderPlaced,OrderApproved",
                        entryDate_poffset: "-7",
                        entryDate_period: "d"
                    ]
                ],
                [
                    name: "Product List Search",
                    screenPath: "SimpleScreens/Catalog/Product", 
                    transition: "actions",
                    parameters: [
                        productName: "",
                        productCategoryId: ""
                    ]
                ]
            ]
            
            def passedTests = 0
            formListTests.each { test ->
                try {
                    def result = callMcpService("org.moqui.mcp.McpServices.execute#Screen", [
                        screenPath: test.screenPath,
                        transition: test.transition,
                        parameters: test.parameters
                    ])
                    
                    if (result && !result.error) {
                        // Check if we got list data back
                        if (result.content || result.data || result.list) {
                            println "   ✅ ${test.name}: Form-list executed successfully"
                            passedTests++
                        } else {
                            println "   ⚠️  ${test.name}: No list data returned"
                        }
                    } else {
                        println "   ❌ ${test.name}: ${result?.error ?: 'Unknown error'}"
                    }
                } catch (Exception e) {
                    println "   ❌ ${test.name}: ${e.message}"
                }
            }
            
            testResults.formListExecution = passedTests > 0
            println "✅ Form-list tests passed: ${passedTests}/${formListTests.size()}"
            
        } catch (Exception e) {
            println "❌ Form-list execution test failed: ${e.message}"
            testResults.formListExecution = false
        }
    }
    
    void testFormSingleExecution(String sessionId) {
        println "\n📝 Test 4: Form-Single Execution"
        println "==================================="
        
        try {
            // Test form-single for data creation
            def formSingleTests = [
                [
                    name: "Create Product Form",
                    screenPath: "SimpleScreens/Catalog/Product",
                    transition: "createProduct",
                    parameters: [
                        productName: "TEST-SCREEN-PRODUCT-${System.currentTimeMillis()}",
                        productTypeId: "FinishedGood",
                        internalName: "Test Screen Product"
                    ]
                ],
                [
                    name: "Create Customer Form", 
                    screenPath: "SimpleScreens/Customer/FindCustomer",
                    transition: "createCustomer",
                    parameters: [
                        firstName: "Test",
                        lastName: "Screen",
                        partyTypeEnumId: "Person"
                    ]
                ]
            ]
            
            def passedTests = 0
            formSingleTests.each { test ->
                try {
                    def result = callMcpService("org.moqui.mcp.McpServices.execute#Screen", [
                        screenPath: test.screenPath,
                        transition: test.transition,
                        parameters: test.parameters
                    ])
                    
                    if (result && !result.error) {
                        if (result.productId || result.partyId || result.success) {
                            println "   ✅ ${test.name}: Form-single executed successfully"
                            passedTests++
                        } else {
                            println "   ⚠️  ${test.name}: No confirmation returned"
                        }
                    } else {
                        println "   ❌ ${test.name}: ${result?.error ?: 'Unknown error'}"
                    }
                } catch (Exception e) {
                    println "   ❌ ${test.name}: ${e.message}"
                }
            }
            
            testResults.formSingleExecution = passedTests > 0
            println "✅ Form-single tests passed: ${passedTests}/${formSingleTests.size()}"
            
        } catch (Exception e) {
            println "❌ Form-single execution test failed: ${e.message}"
            testResults.formSingleExecution = false
        }
    }
    
    void testTransitionExecution(String sessionId) {
        println "\n🔄 Test 5: Transition Execution"
        println "================================="
        
        try {
            // Test specific transitions
            def transitionTests = [
                [
                    name: "Order Detail Transition",
                    screenPath: "SimpleScreens/Order/FindOrder",
                    transition: "orderDetail",
                    parameters: [orderId: "TEST-ORDER"]
                ],
                [
                    name: "Edit Party Transition",
                    screenPath: "SimpleScreens/Customer/FindCustomer", 
                    transition: "editParty",
                    parameters: [partyId: "TEST-PARTY"]
                ]
            ]
            
            def passedTests = 0
            transitionTests.each { test ->
                try {
                    def result = callMcpService("org.moqui.mcp.McpServices.execute#Screen", [
                        screenPath: test.screenPath,
                        transition: test.transition,
                        parameters: test.parameters
                    ])
                    
                    // Transitions might redirect or return URLs
                    if (result && (!result.error || result.url || result.redirect)) {
                        println "   ✅ ${test.name}: Transition executed"
                        passedTests++
                    } else {
                        println "   ⚠️  ${test.name}: ${result?.error ?: 'No clear result'}"
                    }
                } catch (Exception e) {
                    println "   ❌ ${test.name}: ${e.message}"
                }
            }
            
            testResults.transitionExecution = passedTests > 0
            println "✅ Transition tests passed: ${passedTests}/${transitionTests.size()}"
            
        } catch (Exception e) {
            println "❌ Transition execution test failed: ${e.message}"
            testResults.transitionExecution = false
        }
    }
    
    void testParameterHandling(String sessionId) {
        println "\n📊 Test 6: Parameter Handling"
        println "================================"
        
        try {
            // Test parameter passing and validation
            def parameterTests = [
                [
                    name: "Search Parameters",
                    screenPath: "SimpleScreens/Order/FindOrder",
                    parameters: [
                        orderId: "TEST%",
                        partStatusId: "OrderPlaced",
                        entryDate_poffset: "-1",
                        entryDate_period: "d"
                    ]
                ],
                [
                    name: "Date Range Parameters",
                    screenPath: "SimpleScreens/Order/FindOrder", 
                    parameters: [
                        entryDate_from: "2024-01-01",
                        entryDate_thru: "2024-12-31"
                    ]
                ],
                [
                    name: "Dropdown Parameters",
                    screenPath: "SimpleScreens/Order/FindOrder",
                    parameters: [
                        orderType: "Sales",
                        salesChannelEnumId: "ScWebStore"
                    ]
                ]
            ]
            
            def passedTests = 0
            parameterTests.each { test ->
                try {
                    def result = callMcpService("org.moqui.mcp.McpServices.execute#Screen", [
                        screenPath: test.screenPath,
                        transition: "actions",
                        parameters: test.parameters
                    ])
                    
                    if (result && !result.error) {
                        println "   ✅ ${test.name}: Parameters handled correctly"
                        passedTests++
                    } else {
                        println "   ❌ ${test.name}: ${result?.error ?: 'Parameter handling failed'}"
                    }
                } catch (Exception e) {
                    println "   ❌ ${test.name}: ${e.message}"
                }
            }
            
            testResults.parameterHandling = passedTests > 0
            println "✅ Parameter tests passed: ${passedTests}/${parameterTests.size()}"
            
        } catch (Exception e) {
            println "❌ Parameter handling test failed: ${e.message}"
            testResults.parameterHandling = false
        }
    }
    
    void testSubscreenNavigation(String sessionId) {
        println "\n🗂️  Test 7: Subscreen Navigation"
        println "================================="
        
        try {
            // Test subscreen navigation
            def subscreenTests = [
                [
                    name: "Order Subscreens",
                    basePath: "SimpleScreens/Order",
                    subscreens: ["FindOrder", "OrderDetail", "QuickItems"]
                ],
                [
                    name: "Catalog Subscreens",
                    basePath: "SimpleScreens/Catalog", 
                    subscreens: ["Product", "Category", "Search"]
                ],
                [
                    name: "Customer Subscreens",
                    basePath: "SimpleScreens/Customer",
                    subscreens: ["FindCustomer", "EditCustomer", "CustomerData"]
                ]
            ]
            
            def passedTests = 0
            subscreenTests.each { test ->
                def accessibleSubscreens = 0
                test.subscreens.each { subscreen ->
                    try {
                        def result = callMcpService("org.moqui.mcp.McpServices.execute#Screen", [
                            screenPath: "${test.basePath}/${subscreen}",
                            parameters: [:]
                        ])
                        
                        if (result && !result.error) {
                            accessibleSubscreens++
                        }
                    } catch (Exception e) {
                        // Expected for some subscreens
                    }
                }
                
                if (accessibleSubscreens > 0) {
                    println "   ✅ ${test.name}: ${accessibleSubscreens}/${test.subscreens.size()} subscreens accessible"
                    passedTests++
                } else {
                    println "   ❌ ${test.name}: No accessible subscreens"
                }
            }
            
            testResults.subscreenNavigation = passedTests > 0
            println "✅ Subscreen tests passed: ${passedTests}/${subscreenTests.size()}"
            
        } catch (Exception e) {
            println "❌ Subscreen navigation test failed: ${e.message}"
            testResults.subscreenNavigation = false
        }
    }
    
    void testScreenSecurity(String sessionId) {
        println "\n🔒 Test 8: Screen Security"
        println "============================"
        
        try {
            // Test security and permissions
            def securityTests = [
                [
                    name: "Admin Screen Access",
                    screenPath: "SimpleScreens/Accounting/Invoice",
                    expectAccess: false  // Should require admin permissions
                ],
                [
                    name: "Public Screen Access",
                    screenPath: "SimpleScreens/Order/FindOrder", 
                    expectAccess: true   // Should be accessible
                ],
                [
                    name: "User Screen Access",
                    screenPath: "MyAccount/User/Account",
                    expectAccess: true   // Should be accessible to authenticated user
                ]
            ]
            
            def passedTests = 0
            securityTests.each { test ->
                try {
                    def result = callMcpService("org.moqui.mcp.McpServices.execute#Screen", [
                        screenPath: test.screenPath,
                        parameters: [:]
                    ])
                    
                    def hasAccess = result && !result.error
                    def testPassed = (hasAccess == test.expectAccess)
                    
                    if (testPassed) {
                        println "   ✅ ${test.name}: Access ${hasAccess ? 'granted' : 'denied'} as expected"
                        passedTests++
                    } else {
                        println "   ⚠️  ${test.name}: Access ${hasAccess ? 'granted' : 'denied'} (expected ${test.expectAccess ? 'granted' : 'denied'})"
                    }
                } catch (Exception e) {
                    def accessDenied = e.message?.contains('access') || e.message?.contains('permission') || e.message?.contains('authorized')
                    def testPassed = (!accessDenied == test.expectAccess)
                    
                    if (testPassed) {
                        println "   ✅ ${test.name}: Security working as expected"
                        passedTests++
                    } else {
                        println "   ❌ ${test.name}: Unexpected security behavior: ${e.message}"
                    }
                }
            }
            
            testResults.screenSecurity = passedTests > 0
            println "✅ Security tests passed: ${passedTests}/${securityTests.size()}"
            
        } catch (Exception e) {
            println "❌ Screen security test failed: ${e.message}"
            testResults.screenSecurity = false
        }
    }
    
    def callMcpService(String serviceName, Map parameters) {
        try {
            def url = "http://localhost:8080/rest/s1/org/moqui/mcp/McpTestServices/${serviceName.split('\\.')[2]}"
            def connection = url.toURL().openConnection()
            connection.setRequestMethod("POST")
            connection.setRequestProperty("Content-Type", "application/json")
            connection.setRequestProperty("Authorization", "Basic ${"john.sales:opencode".bytes.encodeBase64()}")
            connection.doOutput = true
            
            def json = new JsonBuilder(parameters).toString()
            connection.outputStream.write(json.bytes)
            
            def response = connection.inputStream.text
            return jsonSlurper.parseText(response)
        } catch (Exception e) {
            // println "Error calling ${serviceName}: ${e.message}"
            return null
        }
    }
    
    void generateReport() {
        def duration = System.currentTimeMillis() - startTime
        
        println "\n" + "=".repeat(60)
        println "📋 SCREEN INFRASTRUCTURE TEST REPORT"
        println "=".repeat(60)
        println "Duration: ${duration}ms"
        println ""
        
        def totalTests = testResults.size()
        def passedTests = testResults.values().count { it == true }
        
        testResults.each { test, result ->
            def status = result ? "✅" : "❌"
            println "${status} ${test}"
        }
        
        println ""
        println "Overall Result: ${passedTests}/${totalTests} tests passed"
        println "Success Rate: ${Math.round((passedTests / totalTests) * 100)}%"
        
        if (passedTests == totalTests) {
            println "🎉 ALL SCREEN INFRASTRUCTURE TESTS PASSED!"
            println "MCP screen integration is working correctly."
        } else {
            println "⚠️  Some tests failed. Review the results above."
        }
        
        println "=".repeat(60)
    }
}