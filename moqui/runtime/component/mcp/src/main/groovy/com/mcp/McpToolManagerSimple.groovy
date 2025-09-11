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
        } catch (IllegalStateException e) {
            // Authentication error - return error response that can be converted to JSON-RPC error
            if (e.message?.contains("Authentication required")) {
                return [
                    _error: true,
                    _authRequired: true, 
                    _errorCode: -32002,
                    text: e.message
                ]
            }
            return [text: "Error: ${e.message}"]
        } catch (Exception e) {
            ec.logger.error("Error executing tool ${name}", e)
            return [text: "Error: ${e.message}"]
        }
    }
    
    /**
     * Get companies
     */
    private Map getCompanies(Map arguments) {
        // Simple authentication check - always fail for testing
        ec.logger.info("Testing authentication check in get_companies")
        throw new IllegalStateException("Authentication required: API key required for get_companies")
    }
}
