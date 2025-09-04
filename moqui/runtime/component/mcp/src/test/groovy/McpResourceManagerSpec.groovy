package com.mcp

import spock.lang.Specification
import spock.lang.Shared
import org.moqui.context.ExecutionContext
import org.moqui.Moqui

/**
 * Test specification for MCP Resource Manager
 */
class McpResourceManagerSpec extends Specification {
    
    @Shared ExecutionContext ec
    @Shared McpResourceManager resourceManager
    
    def setupSpec() {
        ec = Moqui.getExecutionContext()
        resourceManager = new McpResourceManager(ec)
    }
    
    def cleanupSpec() {
        ec?.destroy()
    }
    
    def "should list available resources"() {
        when:
        def result = resourceManager.listResources([:])
        
        then:
        result.resources != null
        result.resources.size() > 0
        result.resources.any { it.uri.contains("entities/company") }
        result.resources.any { it.uri.contains("system/status") }
    }
    
    def "should read company entity resource"() {
        when:
        def result = resourceManager.readResource([uri: "growerp://entities/Party"])
        
        then:
        result.contents != null
        result.contents.size() > 0
        result.contents[0].uri == "growerp://entities/Party"
        result.contents[0].mimeType == "application/json"
        result.contents[0].text.contains("entityName")
    }
    
    def "should read system status resource"() {
        when:
        def result = resourceManager.readResource([uri: "growerp://system/health"])
        
        then:
        result.contents[0].text.contains("status")
        result.contents[0].text.contains("healthy")
    }
    
    def "should handle invalid resource URIs"() {
        when:
        resourceManager.readResource([uri: "invalid://resource"])
        
        then:
        thrown(IllegalArgumentException)
    }
    
    def "should validate resource structure"() {
        when:
        def result = resourceManager.listResources([:])
        
        then:
        result.resources.each { resource ->
            assert resource.uri != null
            assert resource.name != null
            assert resource.description != null
            assert resource.mimeType != null
        }
    }
}
