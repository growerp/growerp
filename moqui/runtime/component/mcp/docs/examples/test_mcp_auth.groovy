#!/usr/bin/env groovy

// Test MCP Authorization implementation
// This script tests the API key authentication with user test@example.com/qqqqqq9!
// Updated to use Java 11+ HttpClient instead of deprecated HTTP Builder

import groovy.json.JsonBuilder
import groovy.json.JsonSlurper
import java.net.http.HttpClient
import java.net.http.HttpRequest
import java.net.http.HttpResponse
import java.net.URI
import java.time.Duration

class McpAuthTest {
    def baseUrl = "http://localhost:8080"
    def httpClient
    def jsonSlurper
    def apiKey = null
    
    def setup() {
        httpClient = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(10))
            .build()
        jsonSlurper = new JsonSlurper()
    }
    
    def makeRequest(String method, String path, Map headers = [:], String body = null) {
        def requestBuilder = HttpRequest.newBuilder()
            .uri(URI.create("${baseUrl}/${path}"))
            .timeout(Duration.ofSeconds(30))
        
        // Add headers
        headers.each { key, value ->
            requestBuilder.header(key, value.toString())
        }
        
        // Set method and body
        if (method == "GET") {
            requestBuilder.GET()
        } else if (method == "POST") {
            requestBuilder.header("Content-Type", "application/json")
            requestBuilder.POST(HttpRequest.BodyPublishers.ofString(body ?: ""))
        }
        
        try {
            def request = requestBuilder.build()
            def response = httpClient.send(request, HttpResponse.BodyHandlers.ofString())
            
            def result = [
                status: response.statusCode(),
                body: response.body(),
                data: null
            ]
            
            // Try to parse JSON response
            try {
                if (response.body() && !response.body().trim().isEmpty()) {
                    result.data = jsonSlurper.parseText(response.body())
                }
            } catch (Exception e) {
                // Not JSON, keep body as string
                // This is normal for some responses
            }
            
            return result
        } catch (Exception e) {
            return [
                status: -1,
                body: "Error: ${e.message}",
                data: null,
                error: e
            ]
        }
    }
    
    def loginAndGetApiKey() {
        println "=== Step 1: Login with test credentials ==="
        
        def loginData = [
            username: "test@example.com",
            password: "qqqqqq9!",
            classificationId: "AppSupport"
        ]
        
        def loginJson = new JsonBuilder(loginData).toString()
        
        def response = makeRequest("POST", "rest/s1/growerp/100/Login", [:], loginJson)
        
        if (response.status == 200 && response.data) {
            apiKey = response.data?.authenticate?.apiKey
            println "✓ Login successful!"
            println "  User ID: ${response.data?.authenticate?.user?.userId}"
            println "  Company: ${response.data?.authenticate?.company?.name}"
            println "  API Key: ${apiKey ? apiKey[0..15] + "..." : "NOT FOUND"}"
            return apiKey != null
        } else {
            println "✗ Login failed with status: ${response.status}"
            if (response.body) {
                println "  Response: ${response.body}"
            }
            return false
        }
    }
    
    def testMcpAuthenticate() {
        println "\n=== Step 2: Test MCP Authentication Service ==="
        
        if (!apiKey) {
            println "✗ No API key available for testing"
            return false
        }
        
        def response = makeRequest("GET", "rest/s1/growerp/100/Authenticate?classificationId=AppSupport", 
            [api_key: apiKey])
        
        if (response.status == 200 && response.data) {
            println "✓ Authentication service works!"
            println "  Owner Party ID: ${response.data?.authenticate?.ownerPartyId}"
            println "  Classification: ${response.data?.authenticate?.classificationId}"
            return true
        } else {
            println "✗ Authentication failed with status: ${response.status}"
            if (response.body) {
                println "  Response: ${response.body}"
            }
            return false
        }
    }
    
    def testMcpEndpointsWithoutAuth() {
        println "\n=== Step 3: Test MCP endpoints without authentication (should fail) ==="
        
        def response = makeRequest("GET", "rest/s1/mcp/health")
        
        if (response.status >= 400) {
            println "✓ MCP endpoints properly reject unauthenticated requests (${response.status})"
            return true
        } else {
            println "✗ MCP endpoints allowed unauthenticated access (${response.status})"
            return false
        }
    }
    
    def testMcpEndpointsWithAuth() {
        println "\n=== Step 4: Test MCP endpoints with authentication (should work) ==="
        
        if (!apiKey) {
            println "✗ No API key available for testing"
            return false
        }
        
        def endpoints = ["health", "tools", "resources", "prompts"]
        def allPassed = true
        
        endpoints.each { endpoint ->
            def response = makeRequest("GET", "rest/s1/mcp/${endpoint}", [api_key: apiKey])
            
            if (response.status == 200) {
                println "✓ ${endpoint} endpoint works with authentication"
            } else {
                println "✗ ${endpoint} endpoint failed: ${response.status}"
                if (response.body && response.body.length() > 0) {
                    def truncatedResponse = response.body.length() > 200 ? 
                        response.body[0..200] + "..." : response.body
                    println "  Response: ${truncatedResponse}"
                }
                allPassed = false
            }
        }
        
        return allPassed
    }
    
    def testMcpProtocol() {
        println "\n=== Step 5: Test MCP Protocol endpoint ==="
        
        if (!apiKey) {
            println "✗ No API key available for testing"
            return false
        }
        
        def mcpRequest = [
            jsonrpc: "2.0",
            method: "tools/list",
            id: 1
        ]
        
        def requestJson = new JsonBuilder(mcpRequest).toString()
        def response = makeRequest("POST", "rest/s1/mcp/protocol", [api_key: apiKey], requestJson)
        
        if (response.status == 200 && response.data) {
            println "✓ MCP Protocol endpoint works!"
            def responseJson = new JsonBuilder(response.data).toPrettyString()
            def truncatedResponse = responseJson.length() > 200 ? 
                responseJson[0..200] + "..." : responseJson
            println "  Response: ${truncatedResponse}"
            return true
        } else {
            println "✗ MCP Protocol failed: ${response.status}"
            if (response.body) {
                println "  Response: ${response.body}"
            }
            return false
        }
    }
    
    def runAllTests() {
        println "GrowERP MCP Authorization Test"
        println "=============================="
        
        setup()
        
        def testResults = [
            loginAndGetApiKey(),
            testMcpAuthenticate(),
            testMcpEndpointsWithoutAuth(),
            testMcpEndpointsWithAuth(),
            testMcpProtocol()
        ]
        
        def passed = testResults.count { it == true }
        def total = testResults.size()
        
        println "\n=== Test Results ==="
        println "Passed: ${passed}/${total}"
        
        if (passed == total) {
            println "🎉 All tests passed! MCP authorization is working correctly."
            System.exit(0)
        } else {
            println "❌ Some tests failed. Check the output above for details."
            System.exit(1)
        }
    }
}

// Run the tests
new McpAuthTest().runAllTests()
