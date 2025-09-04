package com.mcp

import org.moqui.context.ExecutionContext
import groovy.json.JsonBuilder

/**
 * Simplified MCP Protocol Handler
 */
class McpProtocolHandlerSimple {
    private ExecutionContext ec
    private McpResourceManagerSimple resourceManager
    private McpToolManagerSimple toolManager
    
    McpProtocolHandlerSimple(ExecutionContext ec) {
        this.ec = ec
        this.resourceManager = new McpResourceManagerSimple(ec)
        this.toolManager = new McpToolManagerSimple(ec)
    }
    
    /**
     * Handle MCP request
     */
    Map handleRequest(Map request) {
        def method = request.method
        def params = request.params ?: [:]
        def id = request.id
        
        ec.logger.info("MCP Request: method=${method}, params=${params}, id=${id}")
        
        try {
            Map result
            switch (method) {
                case "initialize":
                    result = handleInitialize(params)
                    break
                case "resources/list":
                    result = resourceManager.listResources()
                    break
                case "resources/read":
                    result = resourceManager.readResource(params.uri as String)
                    break
                case "tools/list":
                    result = toolManager.listTools()
                    break
                case "tools/call":
                    result = toolManager.executeTool(params.name as String, params.arguments as Map ?: [:])
                    break
                case "prompts/list":
                    result = handlePromptsList()
                    break
                default:
                    result = [error: [code: -32601, message: "Method not found: ${method}"]]
            }
            
            return [
                jsonrpc: "2.0",
                id: id,
                result: result
            ]
        } catch (Exception e) {
            ec.logger.error("Error handling MCP request", e)
            return [
                jsonrpc: "2.0",
                id: id,
                error: [
                    code: -32603,
                    message: "Internal error: ${e.message}"
                ]
            ]
        }
    }
    
    /**
     * Handle initialization
     */
    private Map handleInitialize(Map params) {
        return [
            protocolVersion: "2024-11-05",
            capabilities: [
                resources: [:],
                tools: [:],
                prompts: [:],
                logging: [:]
            ],
            serverInfo: [
                name: "GrowERP MCP Server",
                version: "1.0.0"
            ]
        ]
    }
    
    /**
     * Handle prompts list
     */
    private Map handlePromptsList() {
        return [
            prompts: []
        ]
    }
}
