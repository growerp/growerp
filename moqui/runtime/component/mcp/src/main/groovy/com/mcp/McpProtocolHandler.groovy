package com.mcp

import groovy.json.JsonBuilder
import groovy.json.JsonSlurper
import groovy.transform.CompileStatic
import org.moqui.context.ExecutionContext
import org.moqui.entity.EntityValue
import org.moqui.entity.EntityList
import org.moqui.entity.EntityFind
import org.slf4j.Logger
import org.slf4j.LoggerFactory

/**
 * MCP Protocol Handler - implements the Model Context Protocol specification
 * for GrowERP/Moqui backend integration
 */
// @CompileStatic // Temporarily disabled for testing
class McpProtocolHandler {
    private static final Logger logger = LoggerFactory.getLogger(McpProtocolHandler.class)
    
    private final ExecutionContext ec
    private final McpResourceManager resourceManager
    private final McpToolManager toolManager
    private final McpPromptManager promptManager
    
    McpProtocolHandler(ExecutionContext ec) {
        this.ec = ec
        this.resourceManager = new McpResourceManager(ec)
        this.toolManager = new McpToolManager(ec)
        this.promptManager = new McpPromptManager(ec)
    }
    
    Map<String, Object> getCapabilities() {
        return [
            resources: [:],
            tools: [:],
            prompts: [:],
            logging: [:]
        ]
    }
    
    Map<String, Object> handleRequest(String method, Map<String, Object> params) {
        logger.debug("Handling MCP request: ${method} with params: ${params}")
        
        switch (method) {
            case "initialize":
                return handleInitialize(params)
            case "resources/list":
                return resourceManager.listResources(params)
            case "resources/read":
                return resourceManager.readResource(params)
            case "tools/list":
                return toolManager.listTools(params)
            case "tools/call":
                return toolManager.callTool(params)
            case "prompts/list":
                return promptManager.listPrompts(params)
            case "prompts/get":
                return promptManager.getPrompt(params)
            case "logging/setLevel":
                return handleSetLogLevel(params)
            case "ping":
                return handlePing(params)
            default:
                throw new IllegalArgumentException("Unknown method: ${method}")
        }
    }
    
    private Map<String, Object> handleInitialize(Map<String, Object> params) {
        String protocolVersion = params.protocolVersion as String
        Map<String, Object> clientInfo = params.clientInfo as Map ?: [:]
        
        // Validate protocol version
        if (protocolVersion != "2024-11-05") {
            logger.warn("Unsupported protocol version: ${protocolVersion}")
        }
        
        return [
            protocolVersion: "2024-11-05",
            capabilities: getCapabilities(),
            serverInfo: [
                name: "growerp-mcp-server",
                version: "1.0.0",
                description: "Model Context Protocol Server for GrowERP/Moqui Backend",
                author: "GrowERP Team",
                homepage: "https://www.growerp.com"
            ]
        ]
    }
    
    private Map<String, Object> handleSetLogLevel(Map<String, Object> params) {
        String level = params.level as String
        logger.info("Setting log level to: ${level}")
        
        // Note: In a real implementation, you'd configure the logger level
        return [:]
    }
    
    private Map<String, Object> handlePing(Map<String, Object> params) {
        return [
            status: "ok",
            timestamp: new Date().time,
            server: "growerp-mcp-server",
            moquiVersion: ec.factory.moquiVersion
        ]
    }
}
