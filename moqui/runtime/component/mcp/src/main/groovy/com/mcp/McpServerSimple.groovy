package com.mcp

import org.moqui.context.ExecutionContext
import groovy.json.JsonBuilder

/**
 * Simplified MCP Server Implementation
 */
class McpServerSimple {
    private ExecutionContext ec
    private McpProtocolHandlerSimple protocolHandler
    
    McpServerSimple(ExecutionContext ec) {
        this.ec = ec
        this.protocolHandler = new McpProtocolHandlerSimple(ec)
    }
    
    /**
     * Handle MCP request
     */
    Map handleRequest(Map request) {
        return protocolHandler.handleRequest(request)
    }
    
    /**
     * Get server status
     */
    Map getStatus() {
        return [
            status: "running",
            timestamp: System.currentTimeMillis(),
            version: "1.0.0"
        ]
    }
}
