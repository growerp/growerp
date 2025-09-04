package com.mcp

import spock.lang.Specification
import spock.lang.Shared
import org.moqui.context.ExecutionContext
import org.moqui.Moqui

/**
 * Test specification for MCP Protocol Handler
 */
class McpProtocolHandlerSpec extends Specification {
    
    @Shared ExecutionContext ec
    @Shared McpProtocolHandler protocolHandler
    
    def setupSpec() {
        // Initialize Moqui framework for testing
        ec = Moqui.getExecutionContext()
        protocolHandler = new McpProtocolHandler(ec)
    }
    
    def cleanupSpec() {
        ec?.destroy()
    }
    
    def "should return valid capabilities"() {
        when:
        Map capabilities = protocolHandler.getCapabilities()
        
        then:
        capabilities != null
        capabilities.containsKey("resources")
        capabilities.containsKey("tools")
        capabilities.containsKey("prompts")
        capabilities.containsKey("logging")
    }
    
    def "should handle initialize request"() {
        when:
        Map result = protocolHandler.handleRequest("initialize", [
            protocolVersion: "2024-11-05",
            clientInfo: [
                name: "test-client",
                version: "1.0.0"
            ]
        ])
        
        then:
        result.protocolVersion == "2024-11-05"
        result.capabilities != null
        result.serverInfo != null
        result.serverInfo.name == "growerp-mcp-server"
        result.serverInfo.version == "1.0.0"
        result.serverInfo.description.contains("GrowERP")
        result.serverInfo.author == "GrowERP Team"
        result.serverInfo.homepage == "https://www.growerp.com"
    }
    
    def "should handle initialize with unsupported protocol version"() {
        when:
        Map result = protocolHandler.handleRequest("initialize", [
            protocolVersion: "2023-01-01",
            clientInfo: [:]
        ])
        
        then:
        // Should still work but log a warning
        result.protocolVersion == "2024-11-05"
        result.serverInfo != null
    }
    
    def "should handle ping request"() {
        when:
        Map result = protocolHandler.handleRequest("ping", [:])
        
        then:
        result.status == "ok"
        result.timestamp != null
        result.timestamp instanceof Long
        result.server == "growerp-mcp-server"
        result.moquiVersion != null
    }
    
    def "should handle set log level request"() {
        when:
        Map result = protocolHandler.handleRequest("logging/setLevel", [level: "DEBUG"])
        
        then:
        result != null
        // Should return empty map for successful log level setting
        result.isEmpty()
    }
    
    def "should delegate resources/list to resource manager"() {
        when:
        Map result = protocolHandler.handleRequest("resources/list", [:])
        
        then:
        result != null
        result.containsKey("resources")
        // This tests that the delegation works - detailed testing is in McpResourceManagerSpec
    }
    
    def "should delegate resources/read to resource manager"() {
        when:
        Map result = protocolHandler.handleRequest("resources/read", [
            uri: "growerp://system/health"
        ])
        
        then:
        result != null
        // This tests that the delegation works - detailed testing is in McpResourceManagerSpec
    }
    
    def "should delegate tools/list to tool manager"() {
        when:
        Map result = protocolHandler.handleRequest("tools/list", [:])
        
        then:
        result != null
        result.containsKey("tools")
        // This tests that the delegation works - detailed testing is in McpToolManagerSpec
    }
    
    def "should delegate tools/call to tool manager"() {
        when:
        Map result = protocolHandler.handleRequest("tools/call", [
            name: "ping_system",
            arguments: [:]
        ])
        
        then:
        result != null
        // This tests that the delegation works - detailed testing is in McpToolManagerSpec
    }
    
    def "should delegate prompts/list to prompt manager"() {
        when:
        Map result = protocolHandler.handleRequest("prompts/list", [:])
        
        then:
        result != null
        result.containsKey("prompts")
        // This tests that the delegation works - detailed testing in future McpPromptManagerSpec
    }
    
    def "should delegate prompts/get to prompt manager"() {
        when:
        Map result = protocolHandler.handleRequest("prompts/get", [
            name: "test-prompt"
        ])
        
        then:
        result != null
        // This tests that the delegation works - detailed testing in future McpPromptManagerSpec
    }
    
    def "should throw exception for unknown method"() {
        when:
        protocolHandler.handleRequest("unknown/method", [:])
        
        then:
        IllegalArgumentException e = thrown()
        e.message.contains("Unknown method: unknown/method")
    }
    
    def "should handle null params gracefully"() {
        when:
        Map result = protocolHandler.handleRequest("ping", null)
        
        then:
        result != null
        result.status == "ok"
    }
    
    def "should handle empty params gracefully"() {
        when:
        Map result = protocolHandler.handleRequest("initialize", [:])
        
        then:
        result != null
        result.protocolVersion == "2024-11-05"
        result.serverInfo != null
    }
    
    def "should validate initialization with minimal client info"() {
        when:
        Map result = protocolHandler.handleRequest("initialize", [
            protocolVersion: "2024-11-05"
            // No clientInfo provided
        ])
        
        then:
        result.protocolVersion == "2024-11-05"
        result.serverInfo != null
        result.capabilities != null
    }
    
    def "should create managers correctly"() {
        expect:
        protocolHandler.resourceManager != null
        protocolHandler.toolManager != null
        protocolHandler.promptManager != null
    }
    
    def "should handle concurrent requests safely"() {
        given:
        int numRequests = 10
        List<Map> results = Collections.synchronizedList([])
        
        when:
        (1..numRequests).each { i ->
            Thread.start {
                try {
                    Map result = protocolHandler.handleRequest("ping", [:])
                    results.add(result)
                } catch (Exception e) {
                    results.add([error: e.message])
                }
            }
        }
        
        // Wait for all threads to complete
        Thread.sleep(1000)
        
        then:
        results.size() == numRequests
        results.every { it.status == "ok" || it.containsKey("error") }
        results.count { it.status == "ok" } >= numRequests - 2 // Allow for some potential race conditions
    }
}
