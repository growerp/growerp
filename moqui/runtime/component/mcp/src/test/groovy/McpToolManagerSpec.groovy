package com.mcp

import spock.lang.Specification
import spock.lang.Shared
import org.moqui.context.ExecutionContext
import org.moqui.Moqui

/**
 * Test specification for MCP Tool Manager
 */
class McpToolManagerSpec extends Specification {
    
    @Shared ExecutionContext ec
    @Shared McpToolManager toolManager
    
    def setupSpec() {
        // Initialize Moqui framework for testing
        ec = Moqui.getExecutionContext()
        toolManager = new McpToolManager(ec)
    }
    
    def cleanupSpec() {
        ec?.destroy()
    }
    
    def "should list available tools"() {
        when:
        def result = toolManager.listTools([:])
        
        then:
        result.tools != null
        result.tools.size() > 0
        result.tools.any { it.name == "create_company" }
        result.tools.any { it.name == "get_companies" }
        result.tools.any { it.name == "ping_system" }
    }
    
    def "should validate tool schemas"() {
        when:
        def result = toolManager.listTools([:])
        
        then:
        result.tools.each { tool ->
            assert tool.name != null
            assert tool.description != null
            assert tool.inputSchema != null
            assert tool.inputSchema.type == "object"
            assert tool.inputSchema.properties != null
        }
    }
    
    def "should execute ping system tool"() {
        when:
        def result = toolManager.callTool([name: "ping_system", arguments: [:]])
        
        then:
        result.isError == false
        result.content != null
        result.content.size() > 0
        result.content[0].type == "text"
        result.content[0].text.contains("System Status")
    }
    
    def "should handle invalid tool names"() {
        when:
        def result = toolManager.callTool([name: "invalid_tool", arguments: [:]])
        
        then:
        result.isError == true
        result.content[0].text.contains("Unknown tool")
    }
    
    def "should execute get companies tool"() {
        when:
        def result = toolManager.callTool([
            name: "get_companies", 
            arguments: [limit: 5]
        ])
        
        then:
        result.isError == false
        result.content[0].text.contains("Found")
        result.content[0].text.contains("companies")
    }
}
