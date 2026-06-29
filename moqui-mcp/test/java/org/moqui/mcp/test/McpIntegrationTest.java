/*
 * This software is in the public domain under CC0 1.0 Universal plus a 
 * Grant of Patent License.
 * 
 * To the extent possible under law, author(s) have dedicated all
 * copyright and related and neighboring rights to this software to the
 * public domain worldwide. This software is distributed without any
 * warranty.
 * 
 * You should have received a copy of the CC0 Public Domain Dedication
 * along with this software (see the LICENSE.md file). If not, see
 * <http://creativecommons.org/publicdomain/zero/1.0/>.
 */
package org.moqui.mcp.test;

import org.junit.jupiter.api.*;
import org.moqui.context.ExecutionContext;
import org.moqui.context.ExecutionContextFactory;
import org.moqui.entity.EntityValue;
import org.moqui.Moqui;

import static org.junit.jupiter.api.Assertions.*;

/**
 * MCP Integration Tests - Tests MCP services with running Moqui instance
 */
public class McpIntegrationTest {
    
    private static ExecutionContextFactory ecf;
    private ExecutionContext ec;
    
    @BeforeAll
    static void initMoqui() {
        System.out.println("🚀 Initializing Moqui for MCP tests...");
        try {
            ecf = Moqui.getExecutionContextFactory();
            assertNotNull(ecf, "ExecutionContextFactory should not be null");
            System.out.println("✅ Moqui initialized successfully");
        } catch (Exception e) {
            fail("Failed to initialize Moqui: " + e.getMessage());
        }
    }
    
    @AfterAll
    static void destroyMoqui() {
        if (ecf != null) {
            System.out.println("🔒 Destroying Moqui...");
            ecf.destroy();
        }
    }
    
    @BeforeEach
    void setUp() {
        ec = ecf.getExecutionContext();
        assertNotNull(ec, "ExecutionContext should not be null");
    }
    
    @AfterEach
    void tearDown() {
        if (ec != null) {
            ec.destroy();
        }
    }
    
    @Test
    @DisplayName("Test MCP Services Initialization")
    void testMcpServicesInitialization() {
        System.out.println("🔍 Testing MCP Services Initialization...");
        
        try {
            // Check if MCP services are available
            boolean mcpServiceAvailable = ec.getService().isServiceDefined("org.moqui.mcp.McpServices.initialize#McpSession");
            assertTrue(mcpServiceAvailable, "MCP initialize service should be available");
            
            // Check if MCP entities exist
            long mcpSessionCount = ec.getEntity().findCount("org.moqui.mcp.entity.McpSession");
            System.out.println("📊 Found " + mcpSessionCount + " MCP sessions");
            
            // Check if MCP tools service is available
            boolean toolsServiceAvailable = ec.getService().isServiceDefined("org.moqui.mcp.McpServices.list#McpTools");
            assertTrue(toolsServiceAvailable, "MCP tools service should be available");
            
            // Check if MCP resources service is available
            boolean resourcesServiceAvailable = ec.getService().isServiceDefined("org.moqui.mcp.McpServices.list#McpResources");
            assertTrue(resourcesServiceAvailable, "MCP resources service should be available");
            
            System.out.println("✅ MCP services are properly initialized");
            
        } catch (Exception e) {
            fail("MCP services initialization failed: " + e.getMessage());
        }
    }
    
    @Test
    @DisplayName("Test MCP Session Creation")
    void testMcpSessionCreation() {
        System.out.println("🔍 Testing MCP Session Creation...");
        
        try {
            // Create a new MCP session
            EntityValue session = ec.getService().sync().name("org.moqui.mcp.McpServices.initialize#McpSession")
                .parameters("protocolVersion", "2025-06-18")
                .parameters("clientInfo", [name: "Test Client", version: "1.0.0"])
                .call();
            
            assertNotNull(session, "MCP session should be created");
            assertNotNull(session.get("sessionId"), "Session ID should not be null");
            
            String sessionId = session.getString("sessionId");
            System.out.println("✅ Created MCP session: " + sessionId);
            
            // Verify session exists in database
            EntityValue foundSession = ec.getEntity().find("org.moqui.mcp.entity.McpSession")
                .condition("sessionId", sessionId)
                .one();
            
            assertNotNull(foundSession, "Session should be found in database");
            assertEquals(sessionId, foundSession.getString("sessionId"));
            
            System.out.println("✅ Session verified in database");
            
        } catch (Exception e) {
            fail("MCP session creation failed: " + e.getMessage());
        }
    }
    
    @Test
    @DisplayName("Test MCP Tools List")
    void testMcpToolsList() {
        System.out.println("🔍 Testing MCP Tools List...");
        
        try {
            // First create a session
            EntityValue session = ec.getService().sync().name("org.moqui.mcp.McpServices.initialize#McpSession")
                .parameters("protocolVersion", "2025-06-18")
                .parameters("clientInfo", [name: "Test Client", version: "1.0.0"])
                .call();
            
            String sessionId = session.getString("sessionId");
            
            // List tools
            EntityValue toolsResult = ec.getService().sync().name("org.moqui.mcp.McpServices.list#McpTools")
                .parameters("sessionId", sessionId)
                .call();
            
            assertNotNull(toolsResult, "Tools result should not be null");
            
            Object tools = toolsResult.get("tools");
            assertNotNull(tools, "Tools list should not be null");
            
            System.out.println("✅ Retrieved MCP tools successfully");
            
        } catch (Exception e) {
            fail("MCP tools list failed: " + e.getMessage());
        }
    }
    
    @Test
    @DisplayName("Test MCP Resources List")
    void testMcpResourcesList() {
        System.out.println("🔍 Testing MCP Resources List...");
        
        try {
            // First create a session
            EntityValue session = ec.getService().sync().name("org.moqui.mcp.McpServices.initialize#McpSession")
                .parameters("protocolVersion", "2025-06-18")
                .parameters("clientInfo", [name: "Test Client", version: "1.0.0"])
                .call();
            
            String sessionId = session.getString("sessionId");
            
            // List resources
            EntityValue resourcesResult = ec.getService().sync().name("org.moqui.mcp.McpServices.list#McpResources")
                .parameters("sessionId", sessionId)
                .call();
            
            assertNotNull(resourcesResult, "Resources result should not be null");
            
            Object resources = resourcesResult.get("resources");
            assertNotNull(resources, "Resources list should not be null");
            
            System.out.println("✅ Retrieved MCP resources successfully");
            
        } catch (Exception e) {
            fail("MCP resources list failed: " + e.getMessage());
        }
    }
    
    @Test
    @DisplayName("Test MCP Ping")
    void testMcpPing() {
        System.out.println("🔍 Testing MCP Ping...");
        
        try {
            // Ping the MCP service
            EntityValue pingResult = ec.getService().sync().name("org.moqui.mcp.McpServices.ping#Mcp")
                .call();
            
            assertNotNull(pingResult, "Ping result should not be null");
            
            Object pong = pingResult.get("pong");
            assertNotNull(pong, "Pong should not be null");
            
            System.out.println("✅ MCP ping successful: " + pong);
            
        } catch (Exception e) {
            fail("MCP ping failed: " + e.getMessage());
        }
    }
    
    @Test
    @DisplayName("Test MCP Health Check")
    void testMcpHealthCheck() {
        System.out.println("🔍 Testing MCP Health Check...");
        
        try {
            // Check MCP health
            EntityValue healthResult = ec.getService().sync().name("org.moqui.mcp.McpServices.health#Mcp")
                .call();
            
            assertNotNull(healthResult, "Health result should not be null");
            
            Object status = healthResult.get("status");
            assertNotNull(status, "Health status should not be null");
            
            System.out.println("✅ MCP health check successful: " + status);
            
        } catch (Exception e) {
            fail("MCP health check failed: " + e.getMessage());
        }
    }
}