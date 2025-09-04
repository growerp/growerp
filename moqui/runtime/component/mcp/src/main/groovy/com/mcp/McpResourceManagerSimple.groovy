package com.mcp

import org.moqui.context.ExecutionContext
import groovy.json.JsonBuilder

/**
 * Simplified MCP Resource Manager that compiles without type issues
 */
class McpResourceManagerSimple {
    private ExecutionContext ec
    
    McpResourceManagerSimple(ExecutionContext ec) {
        this.ec = ec
    }
    
    /**
     * List all available resources
     */
    Map listResources() {
        def resources = []
        
        resources << [
            uri: "growerp://entities/company",
            name: "Company Entities",
            description: "Company and organization data",
            mimeType: "application/json"
        ]
        
        resources << [
            uri: "growerp://entities/user",
            name: "User Entities", 
            description: "User account and profile data",
            mimeType: "application/json"
        ]
        
        resources << [
            uri: "growerp://system/status",
            name: "System Status",
            description: "Current system health and status",
            mimeType: "application/json"
        ]
        
        return [resources: resources]
    }
    
    /**
     * Read a specific resource by URI
     */
    Map readResource(String uri) {
        try {
            if (uri == "growerp://system/status") {
                return getSystemStatus()
            } else if (uri.startsWith("growerp://entities/")) {
                return getEntityInfo(uri)
            } else {
                return [error: "Unknown resource: ${uri}"]
            }
        } catch (Exception e) {
            ec.logger.error("Error reading resource", e)
            return [error: "Failed to read resource: ${e.message}"]
        }
    }
    
    /**
     * Get system status
     */
    private Map getSystemStatus() {
        def statusData = [
            status: "operational",
            timestamp: System.currentTimeMillis(),
            services: [
                database: "connected",
                mcp: "running"
            ]
        ]
        
        return [
            contents: [[
                uri: "growerp://system/status",
                mimeType: "application/json",
                text: new JsonBuilder(statusData).toPrettyString()
            ]]
        ]
    }
    
    /**
     * Get entity information
     */
    private Map getEntityInfo(String uri) {
        def entityData = [
            entityName: "Generic Entity",
            description: "Entity information",
            fields: [
                id: [type: "String", description: "Identifier"],
                name: [type: "String", description: "Name"]
            ]
        ]
        
        return [
            contents: [[
                uri: uri,
                mimeType: "application/json",
                text: new JsonBuilder(entityData).toPrettyString()
            ]]
        ]
    }
}
