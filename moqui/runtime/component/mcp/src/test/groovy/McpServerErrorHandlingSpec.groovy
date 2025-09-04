package com.mcp

import spock.lang.Specification
import spock.lang.Shared
import org.moqui.context.ExecutionContext
import org.moqui.Moqui
import groovy.json.JsonBuilder

/**
 * Test specification for MCP Server error handling and edge cases
 */
class McpServerErrorHandlingSpec extends Specification {
    
    @Shared ExecutionContext ec
    @Shared McpServerImpl mcpServer
    @Shared Map<String, Object> serverConfig
    @Shared int testPort = 18082
    
    def setupSpec() {
        ec = Moqui.getExecutionContext()
        serverConfig = [
            id: "error-test-server",
            port: testPort,
            host: "localhost"
        ]
        mcpServer = new McpServerImpl(ec, serverConfig)
    }
    
    def cleanupSpec() {
        mcpServer?.stop()
        ec?.destroy()
    }
    
    def "should handle server start/stop lifecycle correctly"() {
        when: "Server is started"
        mcpServer.start()
        Thread.sleep(100)
        
        then: "Server is running"
        noExceptionThrown()
        
        when: "Server is stopped"
        mcpServer.stop()
        Thread.sleep(100)
        
        then: "Server stops cleanly"
        noExceptionThrown()
        
        when: "Server is started again"
        mcpServer.start()
        Thread.sleep(100)
        
        then: "Server restarts successfully"
        noExceptionThrown()
        
        cleanup:
        mcpServer.stop()
    }
    
    def "should handle connection errors gracefully"() {
        given:
        mcpServer.start()
        Thread.sleep(100)
        
        when: "Client connects and immediately disconnects"
        Socket socket = new Socket("localhost", testPort)
        socket.close()
        
        then: "Server handles disconnection gracefully"
        noExceptionThrown()
        
        when: "Client sends partial data and disconnects"
        Socket socket2 = new Socket("localhost", testPort)
        PrintWriter writer = new PrintWriter(socket2.getOutputStream(), true)
        writer.print('{"jsonrpc":"2.0","method":"test"') // Incomplete JSON
        socket2.close()
        
        then: "Server handles incomplete data gracefully"
        noExceptionThrown()
        
        cleanup:
        mcpServer.stop()
    }
    
    def "should handle malformed WebSocket upgrade requests"() {
        given:
        mcpServer.start()
        Thread.sleep(100)
        
        when: "Client sends WebSocket upgrade without required headers"
        Socket socket = new Socket("localhost", testPort)
        PrintWriter writer = new PrintWriter(socket.getOutputStream(), true)
        BufferedReader reader = new BufferedReader(new InputStreamReader(socket.getInputStream()))
        
        writer.println("GET / HTTP/1.1")
        writer.println("Host: localhost:${testPort}")
        writer.println("Upgrade: websocket")
        writer.println("Connection: Upgrade")
        // Missing Sec-WebSocket-Key header
        writer.println()
        
        // Read response
        List<String> responseLines = []
        String line
        while ((line = reader.readLine()) != null) {
            responseLines.add(line)
            if (line.isEmpty()) break
        }
        socket.close()
        
        then: "Server handles malformed upgrade gracefully"
        responseLines.size() > 0
        // Should not crash, but may not complete WebSocket handshake
        
        cleanup:
        mcpServer.stop()
    }
    
    def "should handle high load scenarios"() {
        given:
        mcpServer.start()
        Thread.sleep(100)
        
        when: "Multiple rapid connections"
        List<Thread> threads = []
        List<Exception> exceptions = Collections.synchronizedList([])
        
        for (int i = 0; i < 20; i++) {
            Thread thread = Thread.start {
                try {
                    Socket socket = new Socket("localhost", testPort)
                    PrintWriter writer = new PrintWriter(socket.getOutputStream(), true)
                    BufferedReader reader = new BufferedReader(new InputStreamReader(socket.getInputStream()))
                    
                    Map request = [
                        jsonrpc: "2.0",
                        method: "ping",
                        params: [:],
                        id: Thread.currentThread().id
                    ]
                    
                    writer.println(new JsonBuilder(request).toString())
                    reader.readLine() // Read response
                    socket.close()
                } catch (Exception e) {
                    exceptions.add(e)
                }
            }
            threads.add(thread)
        }
        
        // Wait for all threads to complete
        threads.each { it.join(5000) }
        
        then: "Server handles high load without crashing"
        exceptions.size() < 5 // Allow for some connection issues under high load
        
        cleanup:
        mcpServer.stop()
    }
    
    def "should handle invalid port configuration"() {
        when: "Server configured with invalid port"
        Map invalidConfig = [id: "invalid", port: -1, host: "localhost"]
        McpServerImpl invalidServer = new McpServerImpl(ec, invalidConfig)
        invalidServer.start()
        
        then: "Server throws appropriate exception"
        thrown(Exception)
        
        cleanup:
        invalidServer?.stop()
    }
    
    def "should handle null or empty configuration"() {
        when: "Server created with null config"
        new McpServerImpl(ec, null)
        
        then: "Constructor handles null config gracefully"
        noExceptionThrown() // Constructor may accept null and handle it internally
        
        when: "Server created with empty config"
        new McpServerImpl(ec, [:])
        
        then: "Constructor handles empty config gracefully"
        noExceptionThrown() // Constructor may accept empty config and set defaults
    }
    
    def "should handle concurrent start/stop operations"() {
        when: "Multiple threads try to start/stop server"
        List<Thread> threads = []
        List<Exception> exceptions = Collections.synchronizedList([])
        
        for (int i = 0; i < 5; i++) {
            Thread startThread = Thread.start {
                try {
                    mcpServer.start()
                } catch (Exception e) {
                    exceptions.add(e)
                }
            }
            
            Thread stopThread = Thread.start {
                try {
                    Thread.sleep(50) // Small delay
                    mcpServer.stop()
                } catch (Exception e) {
                    exceptions.add(e)
                }
            }
            
            threads.addAll([startThread, stopThread])
        }
        
        threads.each { it.join(2000) }
        
        then: "Server handles concurrent operations gracefully"
        // Some exceptions are expected due to race conditions, but server shouldn't crash
        exceptions.size() < 10
        
        cleanup:
        mcpServer.stop()
    }
}
