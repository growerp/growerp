#!/usr/bin/env groovy

@Grab('org.apache.httpcomponents:httpclient:4.5.13')
@Grab('com.fasterxml.jackson.core:jackson-databind:2.15.2')

import groovy.json.JsonBuilder
import groovy.json.JsonSlurper
import groovy.transform.Field

import org.apache.http.client.methods.HttpGet
import org.apache.http.client.methods.HttpPost
import org.apache.http.entity.StringEntity
import org.apache.http.impl.client.HttpClients
import org.apache.http.util.EntityUtils
import org.apache.http.client.HttpClient

/**
 * GrowERP MCP Server - Groovy Stdio Bridge
 * This script provides a standard MCP protocol interface over stdio
 * that communicates with the GrowERP Moqui HTTP REST endpoints.
 */
class GrowERPMCPServer {
    
    @Field String baseUrl = "http://localhost:8080/rest/s1/mcp"
    @Field HttpClient httpClient = HttpClients.createDefault()
    @Field JsonSlurper jsonSlurper = new JsonSlurper()
    
    void writeResponse(Map response) {
        println new JsonBuilder(response).toString()
        System.out.flush()
    }
    
    void writeError(def requestId, int code, String message) {
        def errorResponse = [
            jsonrpc: "2.0",
            id: requestId,
            error: [
                code: code,
                message: message
            ]
        ]
        writeResponse(errorResponse)
    }
    
    Map handleInitialize(def requestId, Map params) {
        return [
            jsonrpc: "2.0",
            id: requestId,
            result: [
                protocolVersion: "2024-11-05",
                capabilities: [
                    tools: [:],
                    resources: [:],
                    prompts: [:]
                ],
                serverInfo: [
                    name: "growerp-mcp-server",
                    version: "1.0.0"
                ]
            ]
        ]
    }
    
    Map handleToolsList(def requestId, Map params) {
        try {
            HttpGet request = new HttpGet("${baseUrl}/tools")
            def response = httpClient.execute(request)
            
            if (response.statusLine.statusCode == 200) {
                def responseBody = EntityUtils.toString(response.entity)
                def data = jsonSlurper.parseText(responseBody)
                def tools = data.tools ?: []
                
                // Convert to MCP format
                def mcpTools = tools.collect { tool ->
                    [
                        name: tool.name,
                        description: tool.description,
                        inputSchema: tool.inputSchema
                    ]
                }
                
                return [
                    jsonrpc: "2.0",
                    id: requestId,
                    result: [
                        tools: mcpTools
                    ]
                ]
            } else {
                throw new Exception("HTTP ${response.statusLine.statusCode}: ${EntityUtils.toString(response.entity)}")
            }
        } catch (Exception e) {
            writeError(requestId, -32603, "Failed to list tools: ${e.message}")
            return null
        }
    }
    
    Map handleToolsCall(def requestId, Map params) {
        try {
            def toolName = params.name
            def arguments = params.arguments ?: [:]
            
            // Create request payload
            def payload = [
                name: toolName,
                arguments: arguments
            ]
            
            HttpPost request = new HttpPost("${baseUrl}/execute")
            request.setHeader("Content-Type", "application/json")
            request.setEntity(new StringEntity(new JsonBuilder(payload).toString()))
            
            def response = httpClient.execute(request)
            
            if (response.statusLine.statusCode == 200) {
                def responseBody = EntityUtils.toString(response.entity)
                def data = jsonSlurper.parseText(responseBody)
                
                // Convert response to MCP format
                def result = [
                    content: [
                        [
                            type: "text",
                            text: data.text ?: data.toString()
                        ]
                    ]
                ]
                
                return [
                    jsonrpc: "2.0",
                    id: requestId,
                    result: result
                ]
            } else {
                throw new Exception("HTTP ${response.statusLine.statusCode}: ${EntityUtils.toString(response.entity)}")
            }
        } catch (Exception e) {
            writeError(requestId, -32603, "Failed to call tool: ${e.message}")
            return null
        }
    }
    
    Map handleResourcesList(def requestId, Map params) {
        try {
            HttpGet request = new HttpGet("${baseUrl}/resources")
            def response = httpClient.execute(request)
            
            if (response.statusLine.statusCode == 200) {
                def responseBody = EntityUtils.toString(response.entity)
                def data = jsonSlurper.parseText(responseBody)
                return [
                    jsonrpc: "2.0",
                    id: requestId,
                    result: [
                        resources: data.resources ?: []
                    ]
                ]
            } else {
                return [
                    jsonrpc: "2.0",
                    id: requestId,
                    result: [
                        resources: []
                    ]
                ]
            }
        } catch (Exception e) {
            writeError(requestId, -32603, "Failed to list resources: ${e.message}")
            return null
        }
    }
    
    Map handlePing(def requestId, Map params) {
        try {
            HttpGet request = new HttpGet("${baseUrl}/health")
            def response = httpClient.execute(request)
            
            if (response.statusLine.statusCode == 200) {
                def responseBody = EntityUtils.toString(response.entity)
                def data = jsonSlurper.parseText(responseBody)
                return [
                    jsonrpc: "2.0",
                    id: requestId,
                    result: [
                        status: data.status ?: "ok",
                        timestamp: data.timestamp,
                        server: "growerp-mcp-server"
                    ]
                ]
            } else {
                return [
                    jsonrpc: "2.0",
                    id: requestId,
                    result: [
                        status: "ok",
                        server: "growerp-mcp-server"
                    ]
                ]
            }
        } catch (Exception e) {
            writeError(requestId, -32603, "Failed to ping: ${e.message}")
            return null
        }
    }
    
    void handleRequest(Map request) {
        try {
            def method = request.method
            def params = request.params ?: [:]
            def requestId = request.id
            
            Map response = null
            
            switch (method) {
                case "initialize":
                    response = handleInitialize(requestId, params)
                    break
                case "tools/list":
                    response = handleToolsList(requestId, params)
                    break
                case "tools/call":
                    response = handleToolsCall(requestId, params)
                    break
                case "resources/list":
                    response = handleResourcesList(requestId, params)
                    break
                case "ping":
                    response = handlePing(requestId, params)
                    break
                default:
                    writeError(requestId, -32601, "Method not found: ${method}")
                    return
            }
            
            if (response) {
                writeResponse(response)
            }
            
        } catch (Exception e) {
            def requestId = (request instanceof Map) ? request.id : null
            writeError(requestId, -32603, "Internal error: ${e.message}")
        }
    }
    
    void run() {
        try {
            System.in.eachLine { line ->
                line = line.trim()
                if (!line) return
                
                try {
                    def request = jsonSlurper.parseText(line)
                    handleRequest(request)
                } catch (Exception e) {
                    writeError(null, -32700, "Parse error: ${e.message}")
                }
            }
        } catch (Exception e) {
            writeError(null, -32603, "Server error: ${e.message}")
        } finally {
            httpClient.close()
        }
    }
}

// Main execution
def server = new GrowERPMCPServer()
server.run()
