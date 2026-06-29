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

import java.util.Properties
import java.io.FileInputStream
import java.io.File

/**
 * MCP Test Suite - Main test runner
 * Runs all MCP tests in a deterministic way
 */
class McpTestSuite {
    private Properties config
    private McpJavaClient client
    
    McpTestSuite() {
        loadConfiguration()
        this.client = new McpJavaClient(
            config.getProperty("test.mcp.url", "http://localhost:8080/mcp"),
            config.getProperty("test.user", "john.sales"),
            config.getProperty("test.password", "opencode")
        )
    }
    
    /**
     * Load test configuration
     */
    void loadConfiguration() {
        config = new Properties()
        
        try {
            def configFile = new File("test/resources/test-config.properties")
            if (configFile.exists()) {
                config.load(new FileInputStream(configFile))
                println "📋 Loaded configuration from test-config.properties"
            } else {
                println "⚠️ Configuration file not found, using defaults"
                setDefaultConfiguration()
            }
        } catch (Exception e) {
            println "⚠️ Error loading configuration: ${e.message}"
            setDefaultConfiguration()
        }
    }
    
    /**
     * Set default configuration values
     */
    void setDefaultConfiguration() {
        config.setProperty("test.user", "john.sales")
        config.setProperty("test.password", "opencode")
        config.setProperty("test.mcp.url", "http://localhost:8080/mcp")
        config.setProperty("test.customer.firstName", "John")
        config.setProperty("test.customer.lastName", "Doe")
        config.setProperty("test.product.color", "blue")
        config.setProperty("test.product.category", "PopCommerce")
    }
    
    /**
     * Run all tests
     */
    boolean runAllTests() {
        println "🧪 MCP TEST SUITE"
        println "=================="
        println "Configuration:"
        println "  URL: ${config.getProperty("test.mcp.url")}"
        println "  User: ${config.getProperty("test.user")}"
        println "  Customer: ${config.getProperty("test.customer.firstName")} ${config.getProperty("test.customer.lastName")}"
        println "  Product Color: ${config.getProperty("test.product.color")}"
        println ""
        
        def startTime = System.currentTimeMillis()
        def results = [:]
        
        try {
            // Initialize client
            if (!client.initialize()) {
                println "❌ Failed to initialize MCP client"
                return false
            }
            
            // Run screen infrastructure tests
            println "\n" + "="*50
            println "SCREEN INFRASTRUCTURE TESTS"
            println "="*50
            
            def infraTest = new ScreenInfrastructureTest(client)
            results.infrastructure = infraTest.runAllTests()
            
            // Run catalog screen tests
            println "\n" + "="*50
            println "CATALOG SCREEN TESTS"
            println "="*50
            
            def catalogTest = new CatalogScreenTest(client)
            results.catalog = catalogTest.runAllTests()
            
            // Run PopCommerce workflow tests
            println "\n" + "="*50
            println "POPCOMMERCE WORKFLOW TESTS"
            println "="*50
            
            def workflowTest = new PopCommerceOrderTest(client)
            results.workflow = workflowTest.runCompleteTest()
            
            // Generate combined report
            def endTime = System.currentTimeMillis()
            def duration = endTime - startTime
            
            generateCombinedReport(results, duration)
            
            return results.infrastructure && results.catalog && results.workflow
            
        } finally {
            client.close()
        }
    }
    
    /**
     * Generate combined test report
     */
    void generateCombinedReport(Map results, long duration) {
        println "\n" + "="*60
        println "📋 MCP TEST SUITE REPORT"
        println "="*60
        println "Duration: ${duration}ms (${Math.round(duration/1000)}s)"
        println ""
        
        def totalTests = results.size()
        def passedTests = results.count { it.value }
        
        results.each { testName, result ->
            println "${result ? '✅' : '❌'} ${testName.toUpperCase()}: ${result ? 'PASSED' : 'FAILED'}"
        }
        
        println ""
        println "Overall Result: ${passedTests}/${totalTests} test suites passed"
        println "Success Rate: ${Math.round(passedTests/totalTests * 100)}%"
        
        if (passedTests == totalTests) {
            println "\n🎉 ALL TESTS PASSED! MCP screen infrastructure is working correctly."
        } else {
            println "\n⚠️ Some tests failed. Check the output above for details."
        }
        
        println "\n" + "="*60
    }
    
    /**
     * Run individual test suites
     */
    boolean runInfrastructureTests() {
        try {
            if (!client.initialize()) {
                println "❌ Failed to initialize MCP client"
                return false
            }
            
            def test = new ScreenInfrastructureTest(client)
            return test.runAllTests()
            
        } finally {
            client.close()
        }
    }
    
    boolean runWorkflowTests() {
        try {
            if (!client.initialize()) {
                println "❌ Failed to initialize MCP client"
                return false
            }
            
            def test = new PopCommerceOrderTest(client)
            return test.runCompleteTest()
            
        } finally {
            client.close()
        }
    }
    
    /**
     * Main method with command line arguments
     */
    static void main(String[] args) {
        def suite = new McpTestSuite()
        
        if (args.length == 0) {
            // Run all tests
            def success = suite.runAllTests()
            System.exit(success ? 0 : 1)
            
        } else {
            // Run specific test suite
            def testType = args[0].toLowerCase()
            def success = false
            
            switch (testType) {
                case "infrastructure":
                case "infra":
                    success = suite.runInfrastructureTests()
                    break
                    
                case "workflow":
                case "popcommerce":
                    success = suite.runWorkflowTests()
                    break
                    
                case "help":
                case "-h":
                case "--help":
                    printUsage()
                    return
                    
                default:
                    println "❌ Unknown test type: ${testType}"
                    printUsage()
                    System.exit(1)
            }
            
            System.exit(success ? 0 : 1)
        }
    }
    
    /**
     * Print usage information
     */
    static void printUsage() {
        println "Usage: java McpTestSuite [test_type]"
        println ""
        println "Test types:"
        println "  infrastructure, infra  - Run screen infrastructure tests only"
        println "  workflow, popcommerce - Run PopCommerce workflow tests only"
        println "  (no argument)          - Run all tests"
        println ""
        println "Examples:"
        println "  java McpTestSuite"
        println "  java McpTestSuite infrastructure"
        println "  java McpTestSuite workflow"
    }
}