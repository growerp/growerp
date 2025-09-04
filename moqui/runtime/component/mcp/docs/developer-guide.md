# Developer Guide

Comprehensive guide for developers working with and extending the GrowERP MCP Server.

## Overview

This guide covers everything developers need to know to understand, modify, and extend the GrowERP MCP Server. It includes code examples, best practices, testing strategies, and deployment guidelines.

## Getting Started

### Prerequisites

- **Java 11+**: Required for Moqui framework
- **Groovy**: Familiarity with Groovy syntax and concepts
- **Moqui Framework**: Understanding of Moqui services, screens, and entities
- **JSON-RPC 2.0**: Knowledge of the JSON-RPC protocol
- **Model Context Protocol**: Understanding of MCP specification

### Development Environment Setup

1. **Clone and Setup GrowERP**:
```bash
cd /path/to/growerp
./gradlew build
java -jar moqui.war load types=seed,seed-initial,install no-run-es
```

2. **Verify MCP Server Component**:
```bash
# Check component is loaded
java -jar moqui.war
# Look for "growerp-mcp-server" in component listing
```

3. **Test MCP Server**:
```bash
# Start Moqui
java -jar moqui.war no-run-es

# Test health endpoint
curl http://localhost:8080/rest/s1/mcp/health
```

### Development Workflow

1. **Make Changes**: Edit Groovy classes or configuration files
2. **Restart Moqui**: Changes require server restart
3. **Test Changes**: Use curl or MCP client to test
4. **Debug Issues**: Check logs in `runtime/log/`

## Code Structure

### Directory Layout

```
growerp-mcp-server/
├── component.xml              # Component definition
├── build.gradle              # Build configuration
├── docs/                     # Documentation
├── src/main/groovy/          # Groovy source code
│   └── org/growerpmc/
│       ├── McpServerSimple.groovy
│       ├── McpProtocolHandlerSimple.groovy
│       ├── McpToolManagerSimple.groovy
│       └── McpResourceManagerSimple.groovy
├── service/                  # Service definitions
│   └── McpServerServices.xml
└── screen/                   # Screen/endpoint definitions
    └── McpServer.xml
```

### Key Files

| File | Purpose | Description |
|------|---------|-------------|
| `component.xml` | Component definition | Defines the component, dependencies, and configuration |
| `build.gradle` | Build script | Groovy compilation and dependency management |
| `McpServerSimple.groovy` | Main server | Primary MCP server orchestrator |
| `McpProtocolHandlerSimple.groovy` | Protocol handler | JSON-RPC 2.0 protocol implementation |
| `McpToolManagerSimple.groovy` | Tool manager | Tool registration and execution |
| `McpResourceManagerSimple.groovy` | Resource manager | Resource discovery and access |
| `McpServerServices.xml` | Service definitions | Moqui service interfaces |
| `McpServer.xml` | REST endpoints | HTTP endpoint definitions |

## Core Classes Deep Dive

### McpServerSimple.groovy

The main server orchestrator that coordinates all MCP operations.

```groovy
package org.growerp.mcp

class McpServerSimple {
    
    // Dependencies
    def ec  // ExecutionContext
    def protocolHandler
    def toolManager
    def resourceManager
    
    // Server state
    private boolean initialized = false
    private Map serverCapabilities = [:]
    private Map clientInfo = [:]
    
    /**
     * Initialize the MCP server with client capabilities
     */
    def initialize(Map params) {
        if (initialized) {
            throw new IllegalStateException("Server already initialized")
        }
        
        // Validate protocol version
        def protocolVersion = params.protocolVersion
        if (!isProtocolVersionSupported(protocolVersion)) {
            throw new IllegalArgumentException("Unsupported protocol version: $protocolVersion")
        }
        
        // Store client info
        clientInfo = params.clientInfo ?: [:]
        
        // Initialize components
        protocolHandler = new McpProtocolHandlerSimple()
        toolManager = new McpToolManagerSimple()
        resourceManager = new McpResourceManagerSimple()
        
        // Set up server capabilities
        serverCapabilities = [
            resources: [:],
            tools: [:],
            prompts: [:],
            logging: [:]
        ]
        
        initialized = true
        
        return [
            protocolVersion: protocolVersion,
            capabilities: serverCapabilities,
            serverInfo: [
                name: "GrowERP MCP Server",
                version: "1.0.0"
            ]
        ]
    }
    
    /**
     * Handle incoming MCP requests
     */
    def handleRequest(Map request) {
        if (!initialized) {
            throw new IllegalStateException("Server not initialized")
        }
        
        try {
            return protocolHandler.processRequest(request)
        } catch (Exception e) {
            ec.logger.error("Error handling MCP request", e)
            return createErrorResponse(request.id, -32603, "Internal error")
        }
    }
    
    /**
     * Create JSON-RPC error response
     */
    private def createErrorResponse(def requestId, int code, String message) {
        return [
            jsonrpc: "2.0",
            id: requestId,
            error: [
                code: code,
                message: message
            ]
        ]
    }
    
    /**
     * Check if protocol version is supported
     */
    private boolean isProtocolVersionSupported(String version) {
        def supportedVersions = ["2024-11-05"]
        return supportedVersions.contains(version)
    }
    
    /**
     * Graceful shutdown
     */
    def shutdown() {
        if (initialized) {
            // Cleanup resources
            protocolHandler?.cleanup()
            toolManager?.cleanup()
            resourceManager?.cleanup()
            
            initialized = false
        }
    }
}
```

### McpProtocolHandlerSimple.groovy

Handles JSON-RPC 2.0 protocol parsing and routing.

```groovy
package org.growerp.mcp

import groovy.json.JsonSlurper
import groovy.json.JsonBuilder

class McpProtocolHandlerSimple {
    
    def ec  // ExecutionContext
    def toolManager
    def resourceManager
    
    // JSON parser/builder
    private jsonSlurper = new JsonSlurper()
    
    /**
     * Process incoming JSON-RPC request
     */
    def processRequest(Map request) {
        // Validate basic JSON-RPC structure
        if (!isValidJsonRpcRequest(request)) {
            return createErrorResponse(request.id, -32600, "Invalid Request")
        }
        
        def method = request.method
        def params = request.params ?: [:]
        def id = request.id
        
        try {
            def result = routeRequest(method, params)
            return createSuccessResponse(id, result)
        } catch (MethodNotFoundException e) {
            return createErrorResponse(id, -32601, "Method not found: $method")
        } catch (InvalidParamsException e) {
            return createErrorResponse(id, -32602, "Invalid params: ${e.message}")
        } catch (Exception e) {
            ec.logger.error("Error processing method $method", e)
            return createErrorResponse(id, -32603, "Internal error")
        }
    }
    
    /**
     * Route request to appropriate handler
     */
    private def routeRequest(String method, Map params) {
        switch (method) {
            case "initialize":
                return handleInitialize(params)
            case "tools/list":
                return handleToolsList()
            case "tools/call":
                return handleToolsCall(params)
            case "resources/list":
                return handleResourcesList()
            case "resources/read":
                return handleResourcesRead(params)
            default:
                throw new MethodNotFoundException("Method not found: $method")
        }
    }
    
    /**
     * Handle initialize method
     */
    def handleInitialize(Map params) {
        // Delegate to main server
        return ec.getProperty("mcpServer").initialize(params)
    }
    
    /**
     * Handle tools/list method
     */
    def handleToolsList() {
        def tools = toolManager.getAvailableTools()
        return [tools: tools]
    }
    
    /**
     * Handle tools/call method
     */
    def handleToolsCall(Map params) {
        def toolName = params.name
        def arguments = params.arguments ?: [:]
        
        if (!toolName) {
            throw new InvalidParamsException("Tool name is required")
        }
        
        return toolManager.executeTool(toolName, arguments)
    }
    
    /**
     * Handle resources/list method
     */
    def handleResourcesList() {
        def resources = resourceManager.getAvailableResources()
        return [resources: resources]
    }
    
    /**
     * Handle resources/read method
     */
    def handleResourcesRead(Map params) {
        def uri = params.uri
        
        if (!uri) {
            throw new InvalidParamsException("Resource URI is required")
        }
        
        def content = resourceManager.readResource(uri)
        return [
            contents: [[
                uri: uri,
                mimeType: "application/json",
                text: content
            ]]
        ]
    }
    
    /**
     * Validate JSON-RPC request structure
     */
    private boolean isValidJsonRpcRequest(Map request) {
        return request.jsonrpc == "2.0" && 
               request.method != null && 
               request.id != null
    }
    
    /**
     * Create success response
     */
    private def createSuccessResponse(def id, def result) {
        return [
            jsonrpc: "2.0",
            id: id,
            result: result
        ]
    }
    
    /**
     * Create error response
     */
    private def createErrorResponse(def id, int code, String message) {
        return [
            jsonrpc: "2.0",
            id: id,
            error: [
                code: code,
                message: message
            ]
        ]
    }
    
    def cleanup() {
        // Cleanup resources if needed
    }
}

// Custom exceptions
class MethodNotFoundException extends RuntimeException {
    MethodNotFoundException(String message) { super(message) }
}

class InvalidParamsException extends RuntimeException {
    InvalidParamsException(String message) { super(message) }
}
```

### McpToolManagerSimple.groovy

Manages tool registration and execution.

```groovy
package org.growerp.mcp

class McpToolManagerSimple {
    
    def ec  // ExecutionContext
    
    // Tool registry
    private Map<String, Map> toolRegistry = [:]
    
    /**
     * Initialize tool manager and register built-in tools
     */
    def initialize() {
        registerBuiltInTools()
    }
    
    /**
     * Register built-in tools
     */
    private def registerBuiltInTools() {
        // System ping tool
        registerTool("ping_system", [
            description: "Check system health",
            inputSchema: [
                type: "object",
                properties: [:],
                required: []
            ],
            executor: this.&executePingSystem
        ])
        
        // Company listing tool
        registerTool("get_companies", [
            description: "Get list of companies",
            inputSchema: [
                type: "object",
                properties: [
                    limit: [
                        type: "integer",
                        description: "Maximum number of results",
                        default: 10
                    ]
                ],
                required: []
            ],
            executor: this.&executeGetCompanies
        ])
    }
    
    /**
     * Register a new tool
     */
    def registerTool(String name, Map toolDefinition) {
        if (!name || !toolDefinition) {
            throw new IllegalArgumentException("Tool name and definition are required")
        }
        
        if (!toolDefinition.description || !toolDefinition.inputSchema) {
            throw new IllegalArgumentException("Tool must have description and inputSchema")
        }
        
        toolRegistry[name] = toolDefinition
        ec.logger.info("Registered MCP tool: $name")
    }
    
    /**
     * Get list of available tools
     */
    def getAvailableTools() {
        return toolRegistry.collect { name, definition ->
            [
                name: name,
                description: definition.description,
                inputSchema: definition.inputSchema
            ]
        }
    }
    
    /**
     * Execute a specific tool
     */
    def executeTool(String name, Map arguments) {
        def toolDefinition = toolRegistry[name]
        if (!toolDefinition) {
            throw new IllegalArgumentException("Tool not found: $name")
        }
        
        // Validate arguments against schema
        validateArguments(name, arguments, toolDefinition.inputSchema)
        
        // Execute tool
        def executor = toolDefinition.executor
        if (executor instanceof Closure) {
            return executor.call(arguments)
        } else {
            throw new IllegalStateException("Invalid tool executor for: $name")
        }
    }
    
    /**
     * Validate tool arguments against schema
     */
    private def validateArguments(String toolName, Map arguments, Map schema) {
        // Basic validation - can be enhanced with JSON Schema validator
        def required = schema.required ?: []
        for (String requiredField : required) {
            if (!arguments.containsKey(requiredField)) {
                throw new IllegalArgumentException("Required parameter missing for tool $toolName: $requiredField")
            }
        }
    }
    
    /**
     * Built-in tool: ping_system
     */
    private def executePingSystem(Map arguments) {
        return [
            text: "System is operational",
            data: [
                timestamp: System.currentTimeMillis(),
                status: "healthy"
            ]
        ]
    }
    
    /**
     * Built-in tool: get_companies
     */
    private def executeGetCompanies(Map arguments) {
        def limit = arguments.limit ?: 10
        
        try {
            // Query companies using Moqui entity engine
            def companies = ec.entity.find("mantle.party.Organization")
                .selectField("partyId, organizationName")
                .limit(limit as Integer)
                .list()
            
            def companiesList = companies.collect { company ->
                [
                    partyId: company.partyId,
                    organizationName: company.organizationName
                ]
            }
            
            return [
                text: "Found ${companiesList.size()} companies",
                data: companiesList
            ]
        } catch (Exception e) {
            ec.logger.error("Error retrieving companies", e)
            throw new RuntimeException("Failed to retrieve companies: ${e.message}")
        }
    }
    
    def cleanup() {
        toolRegistry.clear()
    }
}
```

### McpResourceManagerSimple.groovy

Manages resource discovery and access.

```groovy
package org.growerp.mcp

import groovy.json.JsonBuilder

class McpResourceManagerSimple {
    
    def ec  // ExecutionContext
    
    // Resource registry
    private Map<String, Map> resourceRegistry = [:]
    
    /**
     * Initialize resource manager and register built-in resources
     */
    def initialize() {
        registerBuiltInResources()
    }
    
    /**
     * Register built-in resources
     */
    private def registerBuiltInResources() {
        // Company entity resource
        registerResource("growerp://entities/company", [
            name: "Company Entities",
            description: "Company and organization data",
            mimeType: "application/json",
            generator: this.&generateCompanyEntityResource
        ])
        
        // User entity resource
        registerResource("growerp://entities/user", [
            name: "User Entities",
            description: "User account and profile data",
            mimeType: "application/json",
            generator: this.&generateUserEntityResource
        ])
        
        // System status resource
        registerResource("growerp://system/status", [
            name: "System Status",
            description: "Current system health and status",
            mimeType: "application/json",
            generator: this.&generateSystemStatusResource
        ])
    }
    
    /**
     * Register a new resource
     */
    def registerResource(String uri, Map resourceDefinition) {
        if (!uri || !resourceDefinition) {
            throw new IllegalArgumentException("Resource URI and definition are required")
        }
        
        if (!resourceDefinition.name || !resourceDefinition.description) {
            throw new IllegalArgumentException("Resource must have name and description")
        }
        
        resourceRegistry[uri] = resourceDefinition
        ec.logger.info("Registered MCP resource: $uri")
    }
    
    /**
     * Get list of available resources
     */
    def getAvailableResources() {
        return resourceRegistry.collect { uri, definition ->
            [
                uri: uri,
                name: definition.name,
                description: definition.description,
                mimeType: definition.mimeType ?: "application/json"
            ]
        }
    }
    
    /**
     * Read resource content
     */
    def readResource(String uri) {
        def resourceDefinition = resourceRegistry[uri]
        if (!resourceDefinition) {
            throw new IllegalArgumentException("Resource not found: $uri")
        }
        
        // Generate resource content
        def generator = resourceDefinition.generator
        if (generator instanceof Closure) {
            def content = generator.call()
            
            // Convert to JSON string if not already
            if (content instanceof Map || content instanceof List) {
                return new JsonBuilder(content).toString()
            } else {
                return content.toString()
            }
        } else {
            throw new IllegalStateException("Invalid resource generator for: $uri")
        }
    }
    
    /**
     * Generate company entity resource
     */
    private def generateCompanyEntityResource() {
        return [
            entityName: "Company",
            description: "Organization and company information",
            fields: [
                partyId: [
                    type: "String",
                    description: "Unique party identifier"
                ],
                organizationName: [
                    type: "String",
                    description: "Company name"
                ],
                currencyUomId: [
                    type: "String",
                    description: "Default currency"
                ]
            ]
        ]
    }
    
    /**
     * Generate user entity resource
     */
    private def generateUserEntityResource() {
        return [
            entityName: "User",
            description: "User account and profile information",
            fields: [
                userId: [
                    type: "String",
                    description: "Unique user identifier"
                ],
                username: [
                    type: "String",
                    description: "Login username"
                ],
                userFullName: [
                    type: "String",
                    description: "Full display name"
                ]
            ]
        ]
    }
    
    /**
     * Generate system status resource
     */
    private def generateSystemStatusResource() {
        return [
            status: "operational",
            timestamp: System.currentTimeMillis(),
            services: [
                database: "connected",
                mcp: "running"
            ]
        ]
    }
    
    def cleanup() {
        resourceRegistry.clear()
    }
}
```

## Adding Custom Tools

### Step 1: Define Tool Schema

Create a tool definition with proper schema:

```groovy
def customToolDefinition = [
    description: "Retrieve customer orders",
    inputSchema: [
        type: "object",
        properties: [
            customerId: [
                type: "string",
                description: "Customer ID to filter orders"
            ],
            status: [
                type: "string",
                description: "Order status filter",
                enum: ["pending", "processing", "shipped", "delivered"]
            ],
            limit: [
                type: "integer",
                description: "Maximum number of orders to return",
                default: 10,
                minimum: 1,
                maximum: 100
            ],
            startDate: [
                type: "string",
                format: "date",
                description: "Start date for order search (YYYY-MM-DD)"
            ]
        ],
        required: ["customerId"]
    ],
    executor: this.&executeGetCustomerOrders
]
```

### Step 2: Implement Tool Logic

```groovy
private def executeGetCustomerOrders(Map arguments) {
    def customerId = arguments.customerId
    def status = arguments.status
    def limit = arguments.limit ?: 10
    def startDate = arguments.startDate
    
    try {
        // Build query
        def orderQuery = ec.entity.find("mantle.order.OrderHeader")
            .condition("customerPartyId", customerId)
        
        if (status) {
            orderQuery.condition("statusId", status.toUpperCase())
        }
        
        if (startDate) {
            def parsedDate = Date.parse("yyyy-MM-dd", startDate)
            orderQuery.condition("orderDate", EntityCondition.GREATER_THAN_EQUAL_TO, parsedDate)
        }
        
        def orders = orderQuery
            .selectField("orderId, orderDate, grandTotal, statusId")
            .orderBy("-orderDate")
            .limit(limit as Integer)
            .list()
        
        def ordersList = orders.collect { order ->
            [
                orderId: order.orderId,
                orderDate: order.orderDate?.toString(),
                grandTotal: order.grandTotal,
                status: order.statusId
            ]
        }
        
        return [
            text: "Found ${ordersList.size()} orders for customer $customerId",
            data: ordersList
        ]
    } catch (Exception e) {
        ec.logger.error("Error retrieving customer orders", e)
        throw new RuntimeException("Failed to retrieve orders: ${e.message}")
    }
}
```

### Step 3: Register Tool

```groovy
// In McpToolManagerSimple.initialize()
registerTool("get_customer_orders", customToolDefinition)
```

## Adding Custom Resources

### Step 1: Define Resource

```groovy
def customResourceDefinition = [
    name: "Sales Reports",
    description: "Sales performance and analytics data",
    mimeType: "application/json",
    generator: this.&generateSalesReport
]
```

### Step 2: Implement Resource Generator

```groovy
private def generateSalesReport() {
    try {
        // Calculate sales metrics
        def totalSales = ec.entity.find("mantle.order.OrderHeader")
            .condition("statusId", "ORDER_COMPLETED")
            .selectField("grandTotal")
            .list()
            .sum { it.grandTotal ?: 0 }
        
        def orderCount = ec.entity.find("mantle.order.OrderHeader")
            .condition("statusId", "ORDER_COMPLETED")
            .count()
        
        def avgOrderValue = orderCount > 0 ? totalSales / orderCount : 0
        
        return [
            reportType: "sales_summary",
            generatedAt: new Date().toString(),
            metrics: [
                totalSales: totalSales,
                orderCount: orderCount,
                averageOrderValue: avgOrderValue
            ],
            period: "all_time"
        ]
    } catch (Exception e) {
        ec.logger.error("Error generating sales report", e)
        throw new RuntimeException("Failed to generate sales report: ${e.message}")
    }
}
```

### Step 3: Register Resource

```groovy
// In McpResourceManagerSimple.initialize()
registerResource("growerp://reports/sales", customResourceDefinition)
```

## Testing

### Unit Testing

Create unit tests for your tools and resources:

```groovy
// Test file: test/groovy/McpToolTests.groovy
import org.junit.Test
import static org.junit.Assert.*

class McpToolTests {
    
    @Test
    void testPingSystemTool() {
        def toolManager = new McpToolManagerSimple()
        toolManager.initialize()
        
        def result = toolManager.executeTool("ping_system", [:])
        
        assertNotNull(result)
        assertEquals("System is operational", result.text)
        assertNotNull(result.data.timestamp)
    }
    
    @Test
    void testGetCompaniesTool() {
        def toolManager = new McpToolManagerSimple()
        toolManager.initialize()
        
        def result = toolManager.executeTool("get_companies", [limit: 5])
        
        assertNotNull(result)
        assertTrue(result.text.contains("companies"))
        assertNotNull(result.data)
    }
    
    @Test
    void testInvalidTool() {
        def toolManager = new McpToolManagerSimple()
        toolManager.initialize()
        
        try {
            toolManager.executeTool("invalid_tool", [:])
            fail("Should have thrown exception")
        } catch (IllegalArgumentException e) {
            assertTrue(e.message.contains("Tool not found"))
        }
    }
}
```

### Integration Testing

Test the full MCP protocol flow:

```groovy
// Test file: test/groovy/McpIntegrationTests.groovy
import groovy.json.JsonSlurper
import groovy.json.JsonBuilder

class McpIntegrationTests {
    
    @Test
    void testMcpProtocolFlow() {
        def server = new McpServerSimple()
        
        // Test initialization
        def initRequest = [
            jsonrpc: "2.0",
            method: "initialize",
            params: [
                protocolVersion: "2024-11-05",
                capabilities: [:],
                clientInfo: [name: "test-client", version: "1.0.0"]
            ],
            id: 1
        ]
        
        def initResponse = server.handleRequest(initRequest)
        assertEquals("2.0", initResponse.jsonrpc)
        assertEquals(1, initResponse.id)
        assertNotNull(initResponse.result)
        
        // Test tools listing
        def toolsRequest = [
            jsonrpc: "2.0",
            method: "tools/list",
            id: 2
        ]
        
        def toolsResponse = server.handleRequest(toolsRequest)
        assertEquals(2, toolsResponse.id)
        assertNotNull(toolsResponse.result.tools)
        
        // Test tool execution
        def callRequest = [
            jsonrpc: "2.0",
            method: "tools/call",
            params: [
                name: "ping_system",
                arguments: [:]
            ],
            id: 3
        ]
        
        def callResponse = server.handleRequest(callRequest)
        assertEquals(3, callResponse.id)
        assertNotNull(callResponse.result)
    }
}
```

### Load Testing

Test MCP server performance:

```bash
# Using Apache Bench
ab -n 1000 -c 10 -H "Content-Type: application/json" \
   -p test_request.json \
   http://localhost:8080/rest/s1/mcp/mcp

# Using curl in a loop
for i in {1..100}; do
  curl -X POST http://localhost:8080/rest/s1/mcp/mcp \
    -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","method":"tools/list","id":'$i'}'
done
```

## Debugging

### Enable Debug Logging

Add debug configuration to `MoquiConf.xml`:

```xml
<Logger name="growerp.mcp" level="DEBUG" additivity="false">
    <AppenderRef ref="stdout"/>
</Logger>
```

### Common Debugging Techniques

1. **Add Logging Statements**:
```groovy
ec.logger.info("Processing MCP request: ${request.method}")
ec.logger.debug("Request parameters: ${request.params}")
```

2. **Use Groovy Console**:
```groovy
// Test code snippets in Groovy console
def toolManager = new McpToolManagerSimple()
toolManager.initialize()
println toolManager.getAvailableTools()
```

3. **Check Moqui Logs**:
```bash
tail -f runtime/log/moqui.log
```

4. **Use HTTP Debugging Tools**:
```bash
# Use httpie for formatted requests
http POST localhost:8080/rest/s1/mcp/mcp \
  jsonrpc=2.0 method=tools/list id:=1
```

## Performance Optimization

### Caching Strategies

1. **Tool Result Caching**:
```groovy
private Map toolCache = [:]

def executeTool(String name, Map arguments) {
    def cacheKey = "${name}_${arguments.hashCode()}"
    
    if (toolCache.containsKey(cacheKey)) {
        return toolCache[cacheKey]
    }
    
    def result = actuallyExecuteTool(name, arguments)
    toolCache[cacheKey] = result
    
    return result
}
```

2. **Resource Caching**:
```groovy
private Map resourceCache = [:]
private Map cacheTimestamps = [:]

def readResource(String uri) {
    def now = System.currentTimeMillis()
    def cached = resourceCache[uri]
    def timestamp = cacheTimestamps[uri] ?: 0
    
    // Cache for 5 minutes
    if (cached && (now - timestamp) < 300000) {
        return cached
    }
    
    def content = actuallyReadResource(uri)
    resourceCache[uri] = content
    cacheTimestamps[uri] = now
    
    return content
}
```

### Connection Pooling

Configure efficient database connections:

```xml
<!-- In MoquiConf.xml -->
<datasource group-name="transactional" database-conf-name="mysql"
            schema-name="" startup-add-missing="true">
    <database-conf name="mysql" database-type="mysql"
                   host-name="localhost" database-name="moqui"
                   user="moqui" password="moqui">
        <pool minIdle="5" maxActive="50" maxWait="10000"/>
    </database-conf>
</datasource>
```

### Async Processing

Implement async processing for long-running operations:

```groovy
def executeToolAsync(String name, Map arguments) {
    def future = ec.service.async().name("executeToolBackground")
        .parameters([toolName: name, arguments: arguments])
        .call()
    
    return [
        taskId: future.toString(),
        status: "processing",
        message: "Tool execution started"
    ]
}
```

## Security Best Practices

### Input Validation

```groovy
def validateToolArguments(String toolName, Map arguments, Map schema) {
    // Validate required fields
    def required = schema.required ?: []
    for (String field : required) {
        if (!arguments.containsKey(field)) {
            throw new IllegalArgumentException("Missing required field: $field")
        }
    }
    
    // Validate field types and values
    def properties = schema.properties ?: [:]
    arguments.each { key, value ->
        def fieldSchema = properties[key]
        if (fieldSchema) {
            validateFieldValue(key, value, fieldSchema)
        }
    }
}

def validateFieldValue(String fieldName, def value, Map fieldSchema) {
    def type = fieldSchema.type
    
    switch (type) {
        case "string":
            if (!(value instanceof String)) {
                throw new IllegalArgumentException("Field $fieldName must be a string")
            }
            
            // Check length constraints
            if (fieldSchema.maxLength && value.length() > fieldSchema.maxLength) {
                throw new IllegalArgumentException("Field $fieldName exceeds maximum length")
            }
            
            // Check enum values
            if (fieldSchema.enum && !fieldSchema.enum.contains(value)) {
                throw new IllegalArgumentException("Field $fieldName has invalid value")
            }
            break
            
        case "integer":
            if (!(value instanceof Integer)) {
                throw new IllegalArgumentException("Field $fieldName must be an integer")
            }
            
            // Check range constraints
            if (fieldSchema.minimum && value < fieldSchema.minimum) {
                throw new IllegalArgumentException("Field $fieldName below minimum value")
            }
            if (fieldSchema.maximum && value > fieldSchema.maximum) {
                throw new IllegalArgumentException("Field $fieldName above maximum value")
            }
            break
    }
}
```

### Authentication Integration

```groovy
def authenticateRequest(Map request) {
    // Check if authentication is required
    if (!ec.factory.confFacade.getConfigProperty("mcp.security.auth.required", "false").toBoolean()) {
        return true
    }
    
    // Get authorization header
    def authHeader = ec.web.request.getHeader("Authorization")
    if (!authHeader) {
        throw new SecurityException("Authentication required")
    }
    
    // Validate token
    if (authHeader.startsWith("Bearer ")) {
        def token = authHeader.substring(7)
        return validateBearerToken(token)
    } else {
        throw new SecurityException("Invalid authentication method")
    }
}

def validateBearerToken(String token) {
    // Implement token validation logic
    // This could involve JWT validation, database lookup, etc.
    return true  // Simplified for example
}
```

### Data Sanitization

```groovy
def sanitizeOutput(def data) {
    if (data instanceof Map) {
        def sanitized = [:]
        data.each { key, value ->
            if (isSensitiveField(key)) {
                sanitized[key] = maskSensitiveData(value)
            } else {
                sanitized[key] = sanitizeOutput(value)
            }
        }
        return sanitized
    } else if (data instanceof List) {
        return data.collect { sanitizeOutput(it) }
    } else {
        return data
    }
}

def isSensitiveField(String fieldName) {
    def sensitiveFields = ["password", "ssn", "creditCard", "bankAccount"]
    return sensitiveFields.any { fieldName.toLowerCase().contains(it.toLowerCase()) }
}

def maskSensitiveData(def value) {
    if (value instanceof String && value.length() > 4) {
        return "****${value.substring(value.length() - 4)}"
    }
    return "****"
}
```

## Deployment

### Production Deployment

1. **Build Component**:
```bash
cd /path/to/growerp/moqui
./gradlew build
```

2. **Deploy to Production Server**:
```bash
# Copy component to production
scp -r runtime/component/growerp-mcp-server user@prod:/path/to/moqui/runtime/component/

# Restart Moqui on production
ssh user@prod "cd /path/to/moqui && java -jar moqui.war"
```

3. **Verify Deployment**:
```bash
# Test health endpoint
curl https://prod.example.com/rest/s1/mcp/health

# Test MCP protocol
curl -X POST https://prod.example.com/rest/s1/mcp/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/list","id":1}'
```

### Docker Deployment

Create a Dockerfile for containerized deployment:

```dockerfile
FROM openjdk:11-jre-slim

# Install required packages
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Copy Moqui application
COPY moqui/ /opt/moqui/
WORKDIR /opt/moqui

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:8080/rest/s1/mcp/health || exit 1

# Start Moqui
CMD ["java", "-jar", "moqui.war", "no-run-es"]
```

### Monitoring

Set up monitoring for the MCP server:

```groovy
// Add metrics collection
def collectMetrics() {
    return [
        requests_total: requestCounter.get(),
        requests_errors: errorCounter.get(),
        active_connections: activeConnections.get(),
        tool_executions: toolExecutions.collect { name, count ->
            [tool: name, executions: count.get()]
        }
    ]
}

// Expose metrics endpoint
def handleMetricsRequest() {
    def metrics = collectMetrics()
    return new JsonBuilder(metrics).toString()
}
```

This developer guide provides a comprehensive foundation for working with the GrowERP MCP Server. For additional support, refer to the other documentation files and the Moqui framework documentation.
