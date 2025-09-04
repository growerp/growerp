#!/usr/bin/env groovy

/**
 * GrowERP MCP Server - Groovy Stdio Bridge (Simple Version)
 * This script provides a standard MCP protocol interface over stdio
 * that communicates with the GrowERP Moqui HTTP REST endpoints.
 * 
 * Uses basic Java HTTP capabilities to avoid dependency issues.
 */

import groovy.json.JsonBuilder
import groovy.json.JsonSlurper
import java.net.http.HttpClient
import java.net.http.HttpRequest
import java.net.http.HttpResponse
import java.net.URI
import java.time.Duration

class GrowERPMCPServer {
    
    String baseUrl = System.getenv("MCP_BASE_URL") ?: "http://localhost:8080/rest/s1/mcp"
    HttpClient httpClient
    JsonSlurper jsonSlurper = new JsonSlurper()
    
    GrowERPMCPServer() {
        this.httpClient = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(10))
            .build()
    }
    
    void writeResponse(Map response) {
        def json = new JsonBuilder(response).toString()
        println json
        System.out.flush()
    }
    
    void writeError(def requestId, int code, String message) {
        if (requestId == null) return
        
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
                    tools: [
                        listChanged: false
                    ],
                    resources: [
                        subscribe: false,
                        listChanged: false
                    ],
                    prompts: [
                        listChanged: false
                    ]
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
            HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create("${baseUrl}/tools"))
                .timeout(Duration.ofSeconds(10))
                .GET()
                .build()
            
            HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString())
            
            if (response.statusCode() == 200) {
                def data = jsonSlurper.parseText(response.body())
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
                throw new Exception("HTTP ${response.statusCode()}: ${response.body()}")
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
            
            def payloadJson = new JsonBuilder(payload).toString()
            
            HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create("${baseUrl}/mcp"))
                .timeout(Duration.ofSeconds(30))
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(payloadJson))
                .build()
            
            HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString())
            
            if (response.statusCode() == 200) {
                def data = jsonSlurper.parseText(response.body())
                
                // Convert response to MCP format
                def result = [
                    content: [
                        [
                            type: "text",
                            text: data.result?.text ?: data.toString()
                        ]
                    ]
                ]
                
                return [
                    jsonrpc: "2.0",
                    id: requestId,
                    result: result
                ]
            } else {
                throw new Exception("HTTP ${response.statusCode()}: ${response.body()}")
            }
        } catch (Exception e) {
            writeError(requestId, -32603, "Failed to call tool: ${e.message}")
            return null
        }
    }
    
    Map handleResourcesList(def requestId, Map params) {
        try {
            HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create("${baseUrl}/resources"))
                .timeout(Duration.ofSeconds(10))
                .GET()
                .build()
            
            HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString())
            
            if (response.statusCode() == 200) {
                def data = jsonSlurper.parseText(response.body())
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
            HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create("${baseUrl}/health"))
                .timeout(Duration.ofSeconds(10))
                .GET()
                .build()
            
            HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString())
            
            if (response.statusCode() == 200) {
                def data = jsonSlurper.parseText(response.body())
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
            def bufferedReader = new BufferedReader(new InputStreamReader(System.in))
            String line
            
            while ((line = bufferedReader.readLine()) != null) {
                line = line.trim()
                if (!line) continue
                
                try {
                    def request = jsonSlurper.parseText(line)
                    handleRequest(request)
                } catch (Exception e) {
                    writeError(null, -32700, "Parse error: ${e.message}")
                }
            }
        } catch (Exception e) {
            writeError(null, -32603, "Server error: ${e.message}")
        }
    }
}

// Main execution
def server = new GrowERPMCPServer()
server.run()
