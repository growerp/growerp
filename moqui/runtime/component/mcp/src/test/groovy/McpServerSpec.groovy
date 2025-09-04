package com.mcp

import spock.lang.Specification
import spock.lang.Shared
import org.moqui.context.ExecutionContext
import org.moqui.Moqui
import groovy.json.JsonSlurper
import groovy.json.JsonBuilder

import java.util.concurrent.TimeUnit
import java.util.concurrent.CountDownLatch

/**
 * Test specification for MCP Server Implementation
 */
class McpServerSpec extends Specification {
    
    @Shared ExecutionContext ec
    @Shared McpServerImpl mcpServer
    @Shared Map<String, Object> serverConfig
    @Shared JsonSlurper jsonSlurper = new JsonSlurper()
    
    def setupSpec() {
        // Initialize Moqui framework for testing
        ec = Moqui.getExecutionContext()
        
        // Configure server for testing
        serverConfig = [
            id: "test-server",
            port: 18080, // Use different port for testing
            host: "localhost"
        ]
        
        mcpServer = new McpServerImpl(ec, serverConfig)
    }
    
    def cleanupSpec() {
        mcpServer?.stop()
        ec?.destroy()
    }
    
    def "should initialize server with correct configuration"() {
        expect:
        mcpServer != null
        mcpServer.config == serverConfig
        mcpServer.protocolHandler != null
    }
    
    def "should start and stop server successfully"() {
        when:
        mcpServer.start()
        
        then:
        noExceptionThrown()
        
        when:
        // Give server time to start
        Thread.sleep(100)
        
        then:
        // Try to connect to verify server is running
        Socket testSocket = null
        try {
            testSocket = new Socket("localhost", 18080)
            testSocket.isConnected()
        } finally {
            testSocket?.close()
        }
        
        when:
        mcpServer.stop()
        
        then:
        noExceptionThrown()
    }
    
    def "should handle JSON-RPC requests correctly"() {
        given:
        mcpServer.start()
        Thread.sleep(100) // Wait for server to start
        
        when:
        Socket socket = new Socket("localhost", 18080)
        PrintWriter writer = new PrintWriter(socket.getOutputStream(), true)
        BufferedReader reader = new BufferedReader(new InputStreamReader(socket.getInputStream()))
        
        // Send initialize request
        Map initRequest = [
            jsonrpc: "2.0",
            method: "initialize",
            params: [
                protocolVersion: "2024-11-05",
                clientInfo: [
                    name: "test-client",
                    version: "1.0.0"
                ]
            ],
            id: 1
        ]
        
        writer.println(new JsonBuilder(initRequest).toString())
        
        String response = reader.readLine()
        socket.close()
        
        then:
        response != null
        
        Map responseObj = jsonSlurper.parseText(response) as Map
        responseObj.jsonrpc == "2.0"
        responseObj.id == 1
        responseObj.result != null
        responseObj.result.protocolVersion == "2024-11-05"
        responseObj.result.serverInfo.name == "growerp-mcp-server"
        
        cleanup:
        mcpServer.stop()
    }
    
    def "should handle ping requests"() {
        given:
        mcpServer.start()
        Thread.sleep(100)
        
        when:
        Socket socket = new Socket("localhost", 18080)
        PrintWriter writer = new PrintWriter(socket.getOutputStream(), true)
        BufferedReader reader = new BufferedReader(new InputStreamReader(socket.getInputStream()))
        
        Map pingRequest = [
            jsonrpc: "2.0",
            method: "ping",
            params: [:],
            id: 2
        ]
        
        writer.println(new JsonBuilder(pingRequest).toString())
        String response = reader.readLine()
        socket.close()
        
        then:
        response != null
        
        Map responseObj = jsonSlurper.parseText(response) as Map
        responseObj.jsonrpc == "2.0"
        responseObj.id == 2
        responseObj.result.status == "ok"
        responseObj.result.timestamp != null
        responseObj.result.server == "growerp-mcp-server"
        
        cleanup:
        mcpServer.stop()
    }
    
    def "should handle HTTP requests with CORS headers"() {
        given:
        mcpServer.start()
        Thread.sleep(100)
        
        when:
        Socket socket = new Socket("localhost", 18080)
        PrintWriter writer = new PrintWriter(socket.getOutputStream(), true)
        BufferedReader reader = new BufferedReader(new InputStreamReader(socket.getInputStream()))
        
        // Send HTTP GET request
        writer.println("GET / HTTP/1.1")
        writer.println("Host: localhost:18080")
        writer.println("Content-Type: application/json")
        writer.println()
        
        // Read HTTP response
        List<String> responseLines = []
        String line
        while ((line = reader.readLine()) != null) {
            responseLines.add(line)
            if (line.isEmpty()) break // End of headers
        }
        
        // Read response body
        StringBuilder body = new StringBuilder()
        while (reader.ready() && (line = reader.readLine()) != null) {
            body.append(line)
        }
        socket.close()
        
        then:
        responseLines[0] == "HTTP/1.1 200 OK"
        responseLines.any { it.contains("Access-Control-Allow-Origin: *") }
        responseLines.any { it.contains("Access-Control-Allow-Methods") }
        responseLines.any { it.contains("Content-Type: application/json") }
        
        body.length() > 0
        Map bodyObj = jsonSlurper.parseText(body.toString()) as Map
        bodyObj.name == "growerp-mcp-server"
        bodyObj.version == "1.0.0"
        bodyObj.capabilities != null
        
        cleanup:
        mcpServer.stop()
    }
    
    def "should handle invalid JSON-RPC requests gracefully"() {
        given:
        mcpServer.start()
        Thread.sleep(100)
        
        when:
        Socket socket = new Socket("localhost", 18080)
        PrintWriter writer = new PrintWriter(socket.getOutputStream(), true)
        BufferedReader reader = new BufferedReader(new InputStreamReader(socket.getInputStream()))
        
        // Send invalid JSON
        writer.println("invalid json")
        
        String response = reader.readLine()
        socket.close()
        
        then:
        response != null
        
        Map responseObj = jsonSlurper.parseText(response) as Map
        responseObj.jsonrpc == "2.0"
        responseObj.error != null
        responseObj.error.code == -32603
        responseObj.error.message.contains("Internal error")
        
        cleanup:
        mcpServer.stop()
    }
    
    def "should handle unknown methods"() {
        given:
        mcpServer.start()
        Thread.sleep(100)
        
        when:
        Socket socket = new Socket("localhost", 18080)
        PrintWriter writer = new PrintWriter(socket.getOutputStream(), true)
        BufferedReader reader = new BufferedReader(new InputStreamReader(socket.getInputStream()))
        
        Map unknownRequest = [
            jsonrpc: "2.0",
            method: "unknown_method",
            params: [:],
            id: 3
        ]
        
        writer.println(new JsonBuilder(unknownRequest).toString())
        String response = reader.readLine()
        socket.close()
        
        then:
        response != null
        
        Map responseObj = jsonSlurper.parseText(response) as Map
        responseObj.jsonrpc == "2.0"
        responseObj.id == 3
        responseObj.error != null
        responseObj.error.message.contains("Unknown method")
        
        cleanup:
        mcpServer.stop()
    }
    
    def "should generate valid WebSocket accept key"() {
        given:
        String testKey = "dGhlIHNhbXBsZSBub25jZQ=="
        
        when:
        String acceptKey = mcpServer.generateWebSocketAccept(testKey)
        
        then:
        acceptKey == "s3pPLMBiTxaQ9kYGzzhZRbK+xOo="
    }
    
    def "should handle multiple concurrent connections"() {
        given:
        mcpServer.start()
        Thread.sleep(100)
        
        int numConnections = 5
        CountDownLatch latch = new CountDownLatch(numConnections)
        List<Boolean> results = Collections.synchronizedList([])
        
        when:
        for (int i = 0; i < numConnections; i++) {
            Thread.start {
                try {
                    Socket socket = new Socket("localhost", 18080)
                    PrintWriter writer = new PrintWriter(socket.getOutputStream(), true)
                    BufferedReader reader = new BufferedReader(new InputStreamReader(socket.getInputStream()))
                    
                    Map pingRequest = [
                        jsonrpc: "2.0",
                        method: "ping",
                        params: [:],
                        id: i
                    ]
                    
                    writer.println(new JsonBuilder(pingRequest).toString())
                    String response = reader.readLine()
                    socket.close()
                    
                    Map responseObj = jsonSlurper.parseText(response) as Map
                    results.add(responseObj.result?.status == "ok")
                    
                } catch (Exception e) {
                    results.add(false)
                } finally {
                    latch.countDown()
                }
            }
        }
        
        boolean completed = latch.await(10, TimeUnit.SECONDS)
        
        then:
        completed
        results.size() == numConnections
        results.every { it == true }
        
        cleanup:
        mcpServer.stop()
    }
    
    def "should handle WebSocket upgrade request"() {
        given:
        mcpServer.start()
        Thread.sleep(100)
        
        when:
        Socket socket = new Socket("localhost", 18080)
        PrintWriter writer = new PrintWriter(socket.getOutputStream(), true)
        BufferedReader reader = new BufferedReader(new InputStreamReader(socket.getInputStream()))
        
        // Send WebSocket upgrade request
        writer.println("GET / HTTP/1.1")
        writer.println("Host: localhost:18080")
        writer.println("Upgrade: websocket")
        writer.println("Connection: Upgrade")
        writer.println("Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==")
        writer.println("Sec-WebSocket-Version: 13")
        writer.println()
        
        // Read response headers
        List<String> responseLines = []
        String line
        while ((line = reader.readLine()) != null) {
            responseLines.add(line)
            if (line.isEmpty()) break
        }
        socket.close()
        
        then:
        responseLines[0] == "HTTP/1.1 101 Switching Protocols"
        responseLines.any { it.contains("Upgrade: websocket") }
        responseLines.any { it.contains("Connection: Upgrade") }
        responseLines.any { it.contains("Sec-WebSocket-Accept:") }
        
        cleanup:
        mcpServer.stop()
    }
}
