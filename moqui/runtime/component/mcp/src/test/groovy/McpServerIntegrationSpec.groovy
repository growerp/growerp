package com.mcp

import spock.lang.Specification
import spock.lang.Shared
import org.moqui.context.ExecutionContext
import org.moqui.Moqui
import groovy.json.JsonSlurper
import groovy.json.JsonBuilder

import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

/**
 * Integration test specification for complete MCP Server workflow
 */
class McpServerIntegrationSpec extends Specification {
    
    @Shared ExecutionContext ec
    @Shared McpServerImpl mcpServer
    @Shared Map<String, Object> serverConfig
    @Shared JsonSlurper jsonSlurper = new JsonSlurper()
    @Shared int testPort = 18081
    
    def setupSpec() {
        // Initialize Moqui framework for testing
        ec = Moqui.getExecutionContext()
        
        // Configure server for integration testing
        serverConfig = [
            id: "integration-test-server",
            port: testPort,
            host: "localhost"
        ]
        
        mcpServer = new McpServerImpl(ec, serverConfig)
        mcpServer.start()
        Thread.sleep(200) // Give server time to start
    }
    
    def cleanupSpec() {
        mcpServer?.stop()
        ec?.destroy()
    }
    
    def "should complete full MCP initialization workflow"() {
        when: "Client connects and sends initialize request"
        Socket socket = new Socket("localhost", testPort)
        PrintWriter writer = new PrintWriter(socket.getOutputStream(), true)
        BufferedReader reader = new BufferedReader(new InputStreamReader(socket.getInputStream()))
        
        Map initRequest = [
            jsonrpc: "2.0",
            method: "initialize",
            params: [
                protocolVersion: "2024-11-05",
                clientInfo: [
                    name: "integration-test-client",
                    version: "1.0.0"
                ]
            ],
            id: 1
        ]
        
        writer.println(new JsonBuilder(initRequest).toString())
        String response = reader.readLine()
        
        then: "Server responds with valid initialization"
        response != null
        Map responseObj = jsonSlurper.parseText(response) as Map
        responseObj.jsonrpc == "2.0"
        responseObj.id == 1
        responseObj.result.protocolVersion == "2024-11-05"
        responseObj.result.serverInfo.name == "growerp-mcp-server"
        responseObj.result.capabilities != null
        
        when: "Client requests available resources"
        Map resourcesRequest = [
            jsonrpc: "2.0",
            method: "resources/list",
            params: [:],
            id: 2
        ]
        
        writer.println(new JsonBuilder(resourcesRequest).toString())
        String resourcesResponse = reader.readLine()
        
        then: "Server returns resource list"
        resourcesResponse != null
        Map resourcesObj = jsonSlurper.parseText(resourcesResponse) as Map
        resourcesObj.jsonrpc == "2.0"
        resourcesObj.id == 2
        resourcesObj.result.resources != null
        resourcesObj.result.resources.size() > 0
        
        when: "Client requests available tools"
        Map toolsRequest = [
            jsonrpc: "2.0",
            method: "tools/list",
            params: [:],
            id: 3
        ]
        
        writer.println(new JsonBuilder(toolsRequest).toString())
        String toolsResponse = reader.readLine()
        
        then: "Server returns tool list"
        toolsResponse != null
        Map toolsObj = jsonSlurper.parseText(toolsResponse) as Map
        toolsObj.jsonrpc == "2.0"
        toolsObj.id == 3
        toolsObj.result.tools != null
        toolsObj.result.tools.size() > 0
        
        when: "Client executes a tool"
        Map toolCallRequest = [
            jsonrpc: "2.0",
            method: "tools/call",
            params: [
                name: "ping_system",
                arguments: [:]
            ],
            id: 4
        ]
        
        writer.println(new JsonBuilder(toolCallRequest).toString())
        String toolCallResponse = reader.readLine()
        
        then: "Server executes tool and returns result"
        toolCallResponse != null
        Map toolCallObj = jsonSlurper.parseText(toolCallResponse) as Map
        toolCallObj.jsonrpc == "2.0"
        toolCallObj.id == 4
        toolCallObj.result.isError == false
        toolCallObj.result.content != null
        
        when: "Client reads a resource"
        Map readResourceRequest = [
            jsonrpc: "2.0",
            method: "resources/read",
            params: [
                uri: "growerp://system/health"
            ],
            id: 5
        ]
        
        writer.println(new JsonBuilder(readResourceRequest).toString())
        String readResourceResponse = reader.readLine()
        
        then: "Server returns resource content"
        readResourceResponse != null
        Map readResourceObj = jsonSlurper.parseText(readResourceResponse) as Map
        readResourceObj.jsonrpc == "2.0"
        readResourceObj.id == 5
        readResourceObj.result.contents != null
        readResourceObj.result.contents.size() > 0
        
        cleanup:
        socket.close()
    }
    
    def "should handle multiple simultaneous client sessions"() {
        given:
        int numClients = 3
        CountDownLatch latch = new CountDownLatch(numClients)
        List<Boolean> results = Collections.synchronizedList([])
        
        when:
        for (int clientId = 0; clientId < numClients; clientId++) {
            final int id = clientId
            Thread.start {
                try {
                    Socket socket = new Socket("localhost", testPort)
                    PrintWriter writer = new PrintWriter(socket.getOutputStream(), true)
                    BufferedReader reader = new BufferedReader(new InputStreamReader(socket.getInputStream()))
                    
                    // Each client performs initialization and a few operations
                    Map initRequest = [
                        jsonrpc: "2.0",
                        method: "initialize",
                        params: [
                            protocolVersion: "2024-11-05",
                            clientInfo: [name: "client-${id}"]
                        ],
                        id: id * 10 + 1
                    ]
                    
                    writer.println(new JsonBuilder(initRequest).toString())
                    String initResponse = reader.readLine()
                    Map initObj = jsonSlurper.parseText(initResponse) as Map
                    
                    // Ping request
                    Map pingRequest = [
                        jsonrpc: "2.0",
                        method: "ping",
                        params: [:],
                        id: id * 10 + 2
                    ]
                    
                    writer.println(new JsonBuilder(pingRequest).toString())
                    String pingResponse = reader.readLine()
                    Map pingObj = jsonSlurper.parseText(pingResponse) as Map
                    
                    // List resources request
                    Map resourcesRequest = [
                        jsonrpc: "2.0",
                        method: "resources/list",
                        params: [:],
                        id: id * 10 + 3
                    ]
                    
                    writer.println(new JsonBuilder(resourcesRequest).toString())
                    String resourcesResponse = reader.readLine()
                    Map resourcesObj = jsonSlurper.parseText(resourcesResponse) as Map
                    
                    socket.close()
                    
                    // Verify all responses are correct
                    boolean success = initObj.result?.serverInfo?.name == "growerp-mcp-server" &&
                                    pingObj.result?.status == "ok" &&
                                    resourcesObj.result?.resources != null
                    
                    results.add(success)
                    
                } catch (Exception e) {
                    results.add(false)
                } finally {
                    latch.countDown()
                }
            }
        }
        
        boolean completed = latch.await(15, TimeUnit.SECONDS)
        
        then:
        completed
        results.size() == numClients
        results.every { it == true }
    }
    
    def "should maintain session state correctly"() {
        when: "Client connects and performs sequence of operations"
        Socket socket = new Socket("localhost", testPort)
        PrintWriter writer = new PrintWriter(socket.getOutputStream(), true)
        BufferedReader reader = new BufferedReader(new InputStreamReader(socket.getInputStream()))
        
        // Initialize
        Map initRequest = [
            jsonrpc: "2.0",
            method: "initialize",
            params: [protocolVersion: "2024-11-05"],
            id: 1
        ]
        writer.println(new JsonBuilder(initRequest).toString())
        reader.readLine() // consume response
        
        // Set log level
        Map logRequest = [
            jsonrpc: "2.0",
            method: "logging/setLevel",
            params: [level: "DEBUG"],
            id: 2
        ]
        writer.println(new JsonBuilder(logRequest).toString())
        String logResponse = reader.readLine()
        
        // Ping after log level change
        Map pingRequest = [
            jsonrpc: "2.0",
            method: "ping",
            params: [:],
            id: 3
        ]
        writer.println(new JsonBuilder(pingRequest).toString())
        String pingResponse = reader.readLine()
        
        socket.close()
        
        then: "All operations succeed in sequence"
        logResponse != null
        Map logObj = jsonSlurper.parseText(logResponse) as Map
        logObj.jsonrpc == "2.0"
        logObj.id == 2
        
        pingResponse != null
        Map pingObj = jsonSlurper.parseText(pingResponse) as Map
        pingObj.jsonrpc == "2.0"
        pingObj.id == 3
        pingObj.result.status == "ok"
    }
    
    def "should handle error scenarios gracefully"() {
        when: "Client sends malformed requests"
        Socket socket = new Socket("localhost", testPort)
        PrintWriter writer = new PrintWriter(socket.getOutputStream(), true)
        BufferedReader reader = new BufferedReader(new InputStreamReader(socket.getInputStream()))
        
        // Send invalid JSON
        writer.println("{ invalid json")
        String errorResponse1 = reader.readLine()
        
        // Send request with unknown method
        Map unknownRequest = [
            jsonrpc: "2.0",
            method: "unknown/method",
            params: [:],
            id: 1
        ]
        writer.println(new JsonBuilder(unknownRequest).toString())
        String errorResponse2 = reader.readLine()
        
        // Send tool call with invalid tool name
        Map invalidToolRequest = [
            jsonrpc: "2.0",
            method: "tools/call",
            params: [name: "nonexistent_tool", arguments: [:]],
            id: 2
        ]
        writer.println(new JsonBuilder(invalidToolRequest).toString())
        String errorResponse3 = reader.readLine()
        
        socket.close()
        
        then: "Server responds with appropriate errors"
        errorResponse1 != null
        Map errorObj1 = jsonSlurper.parseText(errorResponse1) as Map
        errorObj1.error.code == -32603
        
        errorResponse2 != null
        Map errorObj2 = jsonSlurper.parseText(errorResponse2) as Map
        errorObj2.error.message.contains("Unknown method")
        
        errorResponse3 != null
        Map errorObj3 = jsonSlurper.parseText(errorResponse3) as Map
        errorObj3.result.isError == true
    }
    
    def "should support HTTP-based MCP communication"() {
        when: "Client makes HTTP GET request"
        Socket socket = new Socket("localhost", testPort)
        PrintWriter writer = new PrintWriter(socket.getOutputStream(), true)
        BufferedReader reader = new BufferedReader(new InputStreamReader(socket.getInputStream()))
        
        writer.println("GET /mcp HTTP/1.1")
        writer.println("Host: localhost:${testPort}")
        writer.println("Content-Type: application/json")
        writer.println()
        
        // Read HTTP response
        List<String> headers = []
        String line
        while ((line = reader.readLine()) != null && !line.isEmpty()) {
            headers.add(line)
        }
        
        StringBuilder body = new StringBuilder()
        while (reader.ready() && (line = reader.readLine()) != null) {
            body.append(line)
        }
        
        socket.close()
        
        then: "Server responds with HTTP response including server info"
        headers[0] == "HTTP/1.1 200 OK"
        headers.any { it.contains("Access-Control-Allow-Origin") }
        headers.any { it.contains("Content-Type: application/json") }
        
        body.length() > 0
        Map serverInfo = jsonSlurper.parseText(body.toString()) as Map
        serverInfo.name == "growerp-mcp-server"
        serverInfo.capabilities != null
    }
}
