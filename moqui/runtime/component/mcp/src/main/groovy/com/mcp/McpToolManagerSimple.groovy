package com.mcp

import org.moqui.context.ExecutionContext
import groovy.json.JsonBuilder

/**
 * Simplified MCP Tool Manager 
 */
class McpToolManagerSimple {
    private ExecutionContext ec
    
    McpToolManagerSimple(ExecutionContext ec) {
        this.ec = ec
    }
    
    /**
     * List available tools
     */
    Map listTools() {
        def tools = []
        
        tools << [
            name: "ping_system",
            description: "Check system health",
            inputSchema: [
                type: "object",
                properties: [:],
                required: []
            ]
        ]
        
        tools << [
            name: "get_companies",
            description: "Get list of companies",
            inputSchema: [
                type: "object", 
                properties: [
                    limit: [type: "integer", description: "Maximum number of results"]
                ],
                required: []
            ]
        ]
        
        return [tools: tools]
    }
    
    /**
     * Execute a tool
     */
    Map executeTool(String name, Map arguments) {
        try {
            switch (name) {
                case "ping_system":
                    return [text: "System is operational"]
                case "get_companies":
                    return getCompanies(arguments)
                default:
                    return [text: "Unknown tool: ${name}"]
            }
        } catch (Exception e) {
            ec.logger.error("Error executing tool ${name}", e)
            return [text: "Error: ${e.message}"]
        }
    }
    
    /**
     * Get companies
     */
    private Map getCompanies(Map arguments) {
        def limit = arguments.limit ?: 10
        
        try {
            def companies = ec.entity.find("mantle.party.Party")
                .condition("partyTypeEnumId", "PtyOrganization") 
                .limit(limit as Integer)
                .list()
                
            def result = companies.collect { company ->
                [
                    partyId: company.partyId,
                    organizationName: company.organizationName ?: company.partyId
                ]
            }
            
            return [
                text: "Found ${result.size()} companies",
                data: result
            ]
        } catch (Exception e) {
            return [text: "Error retrieving companies: ${e.message}"]
        }
    }
}
