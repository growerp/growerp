package com.mcp

import groovy.json.JsonBuilder
import groovy.json.JsonSlurper
import groovy.transform.CompileStatic
import org.moqui.context.ExecutionContext
import org.slf4j.Logger
import org.slf4j.LoggerFactory

import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.CompletableFuture
import java.net.ServerSocket
import java.net.Socket
import java.io.*
import java.nio.charset.StandardCharsets

/**
 * Main MCP Server implementation that handles WebSocket/HTTP connections
 * and delegates to the MCP protocol handler
 */
// @CompileStatic // Temporarily disabled for testing
class McpServerImpl {
    private static final Logger logger = LoggerFactory.getLogger(McpServerImpl.class)
    
    private final ExecutionContext ec
    private final Map<String, Object> config
    private ServerSocket serverSocket
    private volatile boolean running = false
    private Thread serverThread
    private final McpProtocolHandler protocolHandler
    
    McpServerImpl(ExecutionContext ec, Map<String, Object> config) {
        this.ec = ec
        this.config = config
        this.protocolHandler = new McpProtocolHandler(ec)
    }
    
    void start() throws IOException {
        Integer port = (Integer) config.get("port")
        serverSocket = new ServerSocket(port)
        running = true
        
        serverThread = new Thread({
            while (running && !serverSocket.isClosed()) {
                try {
                    Socket clientSocket = serverSocket.accept()
                    handleClientConnection(clientSocket)
                } catch (IOException e) {
                    if (running) {
                        logger.error("Error accepting client connection", e)
                    }
                }
            }
        } as Runnable)
        
        serverThread.name = "MCP-Server-${config.id}"
        serverThread.start()
        
        logger.info("MCP Server started on port ${port}")
    }
    
    void stop() {
        running = false
        try {
            if (serverSocket && !serverSocket.isClosed()) {
                serverSocket.close()
            }
            if (serverThread && serverThread.alive) {
                serverThread.interrupt()
                serverThread.join(5000)
            }
        } catch (Exception e) {
            logger.error("Error stopping MCP server", e)
        }
    }
    
    private void handleClientConnection(Socket clientSocket) {
        Thread.start {
            try {
                BufferedReader reader = new BufferedReader(
                    new InputStreamReader(clientSocket.getInputStream(), StandardCharsets.UTF_8)
                )
                PrintWriter writer = new PrintWriter(
                    new OutputStreamWriter(clientSocket.getOutputStream(), StandardCharsets.UTF_8), 
                    true
                )
                
                // Handle HTTP upgrade to WebSocket or direct JSON-RPC over HTTP
                String firstLine = reader.readLine()
                if (firstLine?.startsWith("GET")) {
                    handleHttpRequest(reader, writer, firstLine)
                } else {
                    handleJsonRpcRequest(reader, writer, firstLine)
                }
                
            } catch (Exception e) {
                logger.error("Error handling client connection", e)
            } finally {
                try {
                    clientSocket.close()
                } catch (IOException e) {
                    // Ignore
                }
            }
        }
    }
    
    private void handleHttpRequest(BufferedReader reader, PrintWriter writer, String requestLine) {
        // Simple HTTP server for CORS and WebSocket upgrade
        Map<String, String> headers = [:]
        String line
        while ((line = reader.readLine()) != null && !line.isEmpty()) {
            String[] parts = line.split(": ", 2)
            if (parts.length == 2) {
                headers[parts[0].toLowerCase()] = parts[1]
            }
        }
        
        if (headers["upgrade"]?.toLowerCase() == "websocket") {
            handleWebSocketUpgrade(reader, writer, headers)
        } else {
            // Send CORS headers for regular HTTP requests
            writer.println("HTTP/1.1 200 OK")
            writer.println("Access-Control-Allow-Origin: *")
            writer.println("Access-Control-Allow-Methods: POST, GET, OPTIONS")
            writer.println("Access-Control-Allow-Headers: Content-Type")
            writer.println("Content-Type: application/json")
            writer.println()
            
            JsonBuilder response = new JsonBuilder([
                name: "growerp-mcp-server",
                version: "1.0.0",
                description: "Model Context Protocol Server for GrowERP/Moqui",
                capabilities: protocolHandler.getCapabilities()
            ])
            writer.println(response.toString())
        }
    }
    
    private void handleWebSocketUpgrade(BufferedReader reader, PrintWriter writer, Map<String, String> headers) {
        // Basic WebSocket handshake - for production use a proper WebSocket library
        String key = headers["sec-websocket-key"]
        if (key) {
            String accept = generateWebSocketAccept(key)
            writer.println("HTTP/1.1 101 Switching Protocols")
            writer.println("Upgrade: websocket")
            writer.println("Connection: Upgrade")
            writer.println("Sec-WebSocket-Accept: ${accept}")
            writer.println()
            
            // Handle WebSocket frames (simplified implementation)
            handleWebSocketCommunication(reader, writer)
        }
    }
    
    private void handleJsonRpcRequest(BufferedReader reader, PrintWriter writer, String firstLine) {
        try {
            // For stdin/stdout communication (typical MCP usage)
            JsonSlurper jsonSlurper = new JsonSlurper()
            
            if (firstLine) {
                Object request = jsonSlurper.parseText(firstLine)
                Map<String, Object> response = processJsonRpcRequest(request as Map)
                
                JsonBuilder responseJson = new JsonBuilder(response)
                writer.println(responseJson.toString())
            }
            
            // Continue reading for additional requests
            String line
            while ((line = reader.readLine()) != null) {
                Object request = jsonSlurper.parseText(line)
                Map<String, Object> response = processJsonRpcRequest(request as Map)
                
                JsonBuilder responseJson = new JsonBuilder(response)
                writer.println(responseJson.toString())
            }
            
        } catch (Exception e) {
            logger.error("Error processing JSON-RPC request", e)
            
            JsonBuilder errorResponse = new JsonBuilder([
                jsonrpc: "2.0",
                error: [
                    code: -32603,
                    message: "Internal error: ${e.message}"
                ],
                id: null
            ])
            writer.println(errorResponse.toString())
        }
    }
    
    private void handleWebSocketCommunication(BufferedReader reader, PrintWriter writer) {
        // Simplified WebSocket frame handling - decode text frames and process as JSON-RPC
        try {
            // This is a basic implementation - for production use a proper WebSocket library
            while (running) {
                // Read WebSocket frame (simplified)
                String message = readWebSocketFrame(reader)
                if (message) {
                    JsonSlurper jsonSlurper = new JsonSlurper()
                    Object request = jsonSlurper.parseText(message)
                    Map<String, Object> response = processJsonRpcRequest(request as Map)
                    
                    // Send response as WebSocket frame
                    JsonBuilder responseJson = new JsonBuilder(response)
                    sendWebSocketFrame(writer, responseJson.toString())
                }
            }
        } catch (Exception e) {
            logger.error("Error in WebSocket communication", e)
        }
    }
    
    private Map<String, Object> processJsonRpcRequest(Map<String, Object> request) {
        String method = request.method as String
        Map<String, Object> params = (request.params as Map) ?: [:]
        Object id = request.id
        
        try {
            Map<String, Object> result = protocolHandler.handleRequest(method, params)
            
            return [
                jsonrpc: "2.0",
                result: result,
                id: id
            ]
            
        } catch (Exception e) {
            logger.error("Error processing MCP request: ${method}", e)
            
            return [
                jsonrpc: "2.0",
                error: [
                    code: -32603,
                    message: "Internal error: ${e.message}"
                ],
                id: id
            ]
        }
    }
    
    // Simplified WebSocket frame reading - replace with proper implementation
    private String readWebSocketFrame(BufferedReader reader) {
        // This is a very basic implementation for demonstration
        // In production, use a proper WebSocket library like Jetty WebSocket
        return reader.readLine()
    }
    
    // Simplified WebSocket frame sending - replace with proper implementation  
    private void sendWebSocketFrame(PrintWriter writer, String message) {
        // This is a very basic implementation for demonstration
        // In production, use a proper WebSocket library like Jetty WebSocket
        writer.println(message)
    }
    
    private String generateWebSocketAccept(String key) {
        // Basic WebSocket accept key generation
        String magicString = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
        String combined = key + magicString
        
        try {
            java.security.MessageDigest digest = java.security.MessageDigest.getInstance("SHA-1")
            byte[] hash = digest.digest(combined.getBytes(StandardCharsets.UTF_8))
            return Base64.getEncoder().encodeToString(hash)
        } catch (Exception e) {
            logger.error("Error generating WebSocket accept key", e)
            return ""
        }
    }
}
