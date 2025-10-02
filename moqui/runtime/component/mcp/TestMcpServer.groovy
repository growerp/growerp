#!/usr/bin/env groovy

/**
 * GrowERP MCP Server Test Script (Groovy Version)
 * 
 * This script tests all available MCP server endpoints using test data
 * 
 * Usage: groovy TestMcpServer.groovy [BASE_URL]
 * Default BASE_URL: http://localhost:8080
 */

import groovy.json.JsonOutput
import groovy.json.JsonSlurper
import java.net.HttpURLConnection

class McpServerTester {
    // Configuration
    String baseUrl
    String mcpBase
    String classificationId = "AppSupport"
    String apiKey
    
    // Test counters
    int totalTests = 0
    int passedTests = 0
    int failedTests = 0
    
    // Email counter for unique emails
    int emailCounter = 0
    
    // Created IDs
    String createdCompanyId
    String createdUserId
    String createdProductId
    String createdCategoryId
    String createdOrderId
    
    JsonSlurper jsonSlurper = new JsonSlurper()
    
    McpServerTester(String baseUrl = "http://localhost:8080") {
        this.baseUrl = baseUrl
        this.mcpBase = "${baseUrl}/rest/s1/mcp"
    }
    
    // Helper methods
    void printHeader(String text) {
        println "\n========================================"
        println text
        println "========================================"
    }
    
    void printTest(String text) {
        println "\nTEST: ${text}"
        totalTests++
    }
    
    void printSuccess(String text) {
        println "✓ PASS: ${text}"
        passedTests++
    }
    
    void printFailure(String text, Object response = null) {
        println "✗ FAIL: ${text}"
        if (response) {
            println "Response: ${JsonOutput.prettyPrint(JsonOutput.toJson(response))}"
        }
        failedTests++
    }
    
    void printInfo(String text) {
        println "ℹ INFO: ${text}"
    }
    
    String getUniqueEmail(String template) {
        emailCounter++
        if (emailCounter > 999) emailCounter = 1
        String formatted = String.format("%03d", emailCounter)
        return template.replaceAll(/XXX|xxx/, formatted)
    }
    
    Map httpPost(String path, Map data, Map headers = [:]) {
        try {
            def url = new URL("${mcpBase}/${path}")
            HttpURLConnection connection = (HttpURLConnection) url.openConnection()
            connection.setRequestMethod("POST")
            connection.setDoOutput(true)
            connection.setRequestProperty("Content-Type", "application/json")
            
            if (apiKey) {
                connection.setRequestProperty("api_key", apiKey)
            }
            
            headers.each { key, value ->
                connection.setRequestProperty(key as String, value as String)
            }
            
            // Write request body
            def jsonBody = JsonOutput.toJson(data)
            connection.outputStream.withWriter('UTF-8') { writer ->
                writer.write(jsonBody)
            }
            
            // Read response
            def responseCode = connection.responseCode
            def responseBody
            
            if (responseCode >= 200 && responseCode < 300) {
                responseBody = connection.inputStream.text
            } else {
                responseBody = connection.errorStream?.text ?: ""
            }
            
            def responseData = responseBody ? jsonSlurper.parseText(responseBody) : [:]
            
            return [
                success: (responseCode >= 200 && responseCode < 300),
                status: responseCode,
                data: responseData
            ]
        } catch (Exception e) {
            return [success: false, error: e.message]
        }
    }
    
    Map httpGet(String path, Map headers = [:]) {
        try {
            def url = new URL("${mcpBase}/${path}")
            HttpURLConnection connection = (HttpURLConnection) url.openConnection()
            connection.setRequestMethod("GET")
            
            if (apiKey) {
                connection.setRequestProperty("api_key", apiKey)
            }
            
            headers.each { key, value ->
                connection.setRequestProperty(key as String, value as String)
            }
            
            def responseCode = connection.responseCode
            def responseBody
            
            if (responseCode >= 200 && responseCode < 300) {
                responseBody = connection.inputStream.text
            } else {
                responseBody = connection.errorStream?.text ?: ""
            }
            
            def responseData = responseBody ? jsonSlurper.parseText(responseBody) : [:]
            
            return [
                success: (responseCode >= 200 && responseCode < 300),
                status: responseCode,
                data: responseData
            ]
        } catch (Exception e) {
            return [success: false, error: e.message]
        }
    }
    
    // Test data
    Map getCompanyDataTemplate() {
        return [
            name: "Test Main Company",
            role: "Company",
            currency: [currencyId: "EUR", description: "Euro"],
            email: "testXXX@example.com",
            telephoneNr: "555555555555",
            address: [
                address1: "mountain Ally 223",
                address2: "suite 23",
                postalCode: "90210",
                city: "Los Angeles",
                province: "California",
                country: "United States"
            ]
        ]
    }
    
    Map getUserDataTemplate() {
        return [
            firstName: "John",
            lastName: "Doe",
            email: "testXXX@example.com",
            loginName: "testuserXXX",
            role: "Customer"
        ]
    }
    
    Map getProductData() {
        return [
            productName: "Test Product 1 - Shippable",
            price: 23.99,
            listPrice: 27.99,
            description: "This is a test product",
            productTypeId: "ProductTypeShippableGood",
            useWarehouse: true,
            assetClassId: "AsClsInventoryFin"
        ]
    }
    
    Map getCustomerDataTemplate() {
        return [
            name: "Test Customer Company 1",
            role: "Customer",
            email: "customerXXX@example.org",
            telephoneNr: "111111111111"
        ]
    }
    
    // Authentication
    boolean authenticate() {
        printHeader("AUTHENTICATION")
        printTest("Login and get API key")
        
        def response = httpPost('auth/login', [
            username: "test@example.com",
            password: "qqqqqq9!",
            classificationId: classificationId
        ])
        
        if (response.success && response.data?.loginResponse?.result?.apiKey) {
            apiKey = response.data.loginResponse.result.apiKey
            printSuccess("Authentication successful. API Key obtained.")
            printInfo("API Key: ${apiKey.take(20)}...")
            return true
        } else {
            printFailure("Authentication failed", response)
            return false
        }
    }
    
    // Test methods
    void testHealthCheck() {
        printHeader("HEALTH CHECK TESTS")
        printTest("GET /health")
        
        def response = httpGet('health')
        
        if (response.success && response.data?.status) {
            printSuccess("Health check endpoint working")
            printInfo("Status: ${response.data.status}")
        } else {
            printFailure("Health check failed", response)
        }
    }
    
    void testCreateCompany() {
        printHeader("COMPANY MANAGEMENT - CREATE")
        printTest("Create new company")
        
        def companyData = getCompanyDataTemplate()
        companyData.email = getUniqueEmail(companyData.email as String)
        
        def response = httpPost('protocol', [
            jsonrpc: "2.0",
            method: "tools/call",
            params: [
                name: "create_company",
                arguments: [
                    company: companyData
                ]
            ],
            id: 21
        ])
        
        if (response.success && response.data?.result && !response.data.result.isError) {
            // Extract partyId from text content: "Successfully created company 'Name' with partyId: 100169"
            def textContent = response.data.result.content?.find { it.type == 'text' }?.text
            if (textContent) {
                def matcher = (textContent =~ /partyId:\s*(\w+)/)
                if (matcher.find()) {
                    createdCompanyId = matcher.group(1)
                }
            }
            printSuccess("Create company successful")
            printInfo("Company ID: ${createdCompanyId}")
            printInfo("Email used: ${companyData.email}")
        } else {
            printFailure("Create company failed", response)
        }
    }
    
    void testCreateProduct() {
        printHeader("PRODUCT MANAGEMENT - CREATE")
        printTest("Create new product")
        
        def response = httpPost('protocol', [
            jsonrpc: "2.0",
            method: "tools/call",
            params: [
                name: "create_product",
                arguments: [
                    product: getProductData()
                ]
            ],
            id: 41
        ])
        
        if (response.success && response.data?.result && !response.data.result.isError) {
            // Extract productId from text content: "Successfully created product 'Name' with productId: 100169"
            def textContent = response.data.result.content?.find { it.type == 'text' }?.text
            if (textContent) {
                def matcher = (textContent =~ /productId:\s*(\w+)/)
                if (matcher.find()) {
                    createdProductId = matcher.group(1)
                }
            }
            printSuccess("Create product successful")
            printInfo("Product ID: ${createdProductId}")
        } else {
            printFailure("Create product failed", response)
        }
    }
    
    void testCreateSalesOrder() {
        printHeader("ORDER MANAGEMENT - CREATE SALES ORDER")
        
        // Ensure we have company and product IDs
        if (!createdCompanyId) {
            printInfo("No company ID available - creating a customer company first")
            def customerData = getCustomerDataTemplate()
            customerData.email = getUniqueEmail(customerData.email as String)
            
            def customerResponse = httpPost('protocol', [
                jsonrpc: "2.0",
                method: "tools/call",
                params: [
                    name: "create_company",
                    arguments: [
                        company: customerData
                    ]
                ],
                id: 50
            ])
            
            if (customerResponse.success && customerResponse.data?.result && !customerResponse.data.result.isError) {
                // Extract partyId from text content
                def textContent = customerResponse.data.result.content?.find { it.type == 'text' }?.text
                if (textContent) {
                    def matcher = (textContent =~ /partyId:\s*(\w+)/)
                    if (matcher.find()) {
                        createdCompanyId = matcher.group(1)
                    }
                }
                printInfo("Customer company created: ${createdCompanyId}")
            } else {
                printFailure("Failed to create customer company", customerResponse)
                return
            }
        }
        
        if (!createdProductId) {
            printInfo("No product ID available - creating a product first")
            
            def productResponse = httpPost('protocol', [
                jsonrpc: "2.0",
                method: "tools/call",
                params: [
                    name: "create_product",
                    arguments: [
                        product: getProductData()
                    ]
                ],
                id: 50
            ])
            
            if (productResponse.success && productResponse.data?.result && !productResponse.data.result.isError) {
                // Extract productId from text content
                def textContent = productResponse.data.result.content?.find { it.type == 'text' }?.text
                if (textContent) {
                    def matcher = (textContent =~ /productId:\s*(\w+)/)
                    if (matcher.find()) {
                        createdProductId = matcher.group(1)
                    }
                }
                printInfo("Product created: ${createdProductId}")
            } else {
                printFailure("Failed to create product", productResponse)
                return
            }
        }
        
        printTest("Create sales order using company ID: ${createdCompanyId} and product ID: ${createdProductId}")
        
        def response = httpPost('protocol', [
            jsonrpc: "2.0",
            method: "tools/call",
            params: [
                name: "create_sales_order",
                arguments: [
                    finDoc: [
                        docType: "order",
                        sales: true,
                        otherCompany: [
                            partyId: createdCompanyId
                        ],
                        items: [
                            [
                                productId: createdProductId,
                                quantity: 2,
                                price: 23.99
                            ]
                        ]
                    ]
                ]
            ],
            id: 51
        ])
        
        if (response.success && response.data?.result && !response.data.result.isError) {
            // Extract orderId from text content: "Successfully created sales order with orderId: 100169"
            def textContent = response.data.result.content?.find { it.type == 'text' }?.text
            if (textContent) {
                def matcher = (textContent =~ /orderId:\s*(\w+)/)
                if (matcher.find()) {
                    createdOrderId = matcher.group(1)
                }
            }
            printSuccess("Create sales order successful")
            printInfo("Order ID: ${createdOrderId}")
            printInfo("Customer: ${createdCompanyId}")
            printInfo("Product: ${createdProductId}")
        } else {
            printFailure("Create sales order failed", response)
        }
    }
    
    void testGetBalanceSummary() {
        printHeader("FINANCIAL MANAGEMENT - BALANCE SUMMARY")
        printTest("Get balance summary for period 2024-Q1")
        
        def response = httpPost('protocol', [
            jsonrpc: "2.0",
            method: "tools/call",
            params: [
                name: "get_balance_summary",
                arguments: [
                    periodName: "2024-Q1"
                ]
            ],
            id: 60
        ])
        
        if (response.success && response.data?.result) {
            printSuccess("Get balance summary successful")
        } else {
            printFailure("Get balance summary failed", response)
        }
    }
    
    void printSummary() {
        printHeader("TEST SUMMARY")
        println "Total Tests: ${totalTests}"
        println "Passed: ${passedTests}"
        println "Failed: ${failedTests}"
        
        if (failedTests == 0) {
            println "\n🎉 All tests passed!"
        } else {
            println "\n❌ Some tests failed"
        }
    }
    
    void runAllTests() {
        printHeader("GROWERP MCP SERVER TEST SUITE")
        printInfo("Base URL: ${baseUrl}")
        printInfo("MCP Endpoint: ${mcpBase}")
        printInfo("Classification ID: ${classificationId}")
        
        // Authenticate first
        if (!authenticate()) {
            println "Authentication failed - aborting tests"
            System.exit(1)
        }
        
        // Run tests in order
        testHealthCheck()
        testCreateCompany()
        testCreateProduct()
        testCreateSalesOrder()
        testGetBalanceSummary()
        
        // Print summary
        printSummary()
        
        System.exit(failedTests > 0 ? 1 : 0)
    }
}

// Main execution
def baseUrl = args.length > 0 ? args[0] : "http://localhost:8080"
def tester = new McpServerTester(baseUrl)
tester.runAllTests()
