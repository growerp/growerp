# Architecture Guide

Deep dive into the GrowERP MCP Server architecture, design patterns, and implementation details.

## Overview

The GrowERP MCP Server is designed as a bridge between AI agents and the GrowERP business management system. It follows the Model Context Protocol (MCP) specification to provide standardized access to business data and operations through a JSON-RPC 2.0 interface.

## Architecture Principles

### 1. **Separation of Concerns**
- **Protocol Layer**: Handles MCP JSON-RPC communication
- **Business Logic Layer**: Implements GrowERP-specific operations
- **Data Access Layer**: Interfaces with Moqui entity engine
- **Service Layer**: Exposes functionality through Moqui services

### 2. **Modularity**
- **Component-Based**: Built as a standalone Moqui component
- **Pluggable Tools**: New tools can be easily added
- **Resource Management**: Flexible resource discovery and access
- **Configuration-Driven**: Behavior controlled through configuration files

### 3. **Integration**
- **Moqui Native**: Built on top of Moqui framework patterns
- **GrowERP Compatible**: Seamlessly integrates with existing GrowERP data
- **REST API**: Standard HTTP/REST interface for broad compatibility
- **Security Inherited**: Leverages Moqui's security framework

## Component Architecture

```
┌─────────────────────────────────────────┐
│              MCP Client                 │
│          (AI Agent/Tool)                │
└─────────────┬───────────────────────────┘
              │ HTTP/JSON-RPC 2.0
              ▼
┌─────────────────────────────────────────┐
│         REST API Layer                  │
│   (McpServer.xml screens)               │
└─────────────┬───────────────────────────┘
              │ Service Calls
              ▼
┌─────────────────────────────────────────┐
│        Service Layer                    │
│   (McpServerServices.xml)               │
└─────────────┬───────────────────────────┘
              │ Groovy Implementations
              ▼
┌─────────────────────────────────────────┐
│        Protocol Handler                 │
│   (McpProtocolHandlerSimple.groovy)    │
└─────────────┬───────────────────────────┘
              │
    ┌─────────┼─────────┐
    ▼         ▼         ▼
┌──────┐ ┌──────┐ ┌──────────┐
│ Tool │ │Resource││   Core   │
│Mgr   │ │  Mgr   ││  Server  │
└──────┘ └──────┘ └──────────┘
    │         │         │
    └─────────┼─────────┘
              ▼
┌─────────────────────────────────────────┐
│          Moqui Framework                │
│    (Entity Engine, Services, etc.)     │
└─────────────────────────────────────────┘
```

## Core Components

### 1. McpServerSimple

**Purpose**: Main server orchestrator and entry point.

**Responsibilities**:
- Initialize MCP server components
- Coordinate protocol handling
- Manage server lifecycle
- Handle high-level MCP operations

**Key Methods**:
```groovy
class McpServerSimple {
    def initialize(Map params)     // Initialize with client capabilities
    def handleRequest(Map request) // Process incoming MCP requests
    def shutdown()                 // Clean shutdown
}
```

**Integration Points**:
- Delegates to `McpProtocolHandlerSimple` for protocol processing
- Uses `McpToolManagerSimple` for tool operations
- Uses `McpResourceManagerSimple` for resource operations

### 2. McpProtocolHandlerSimple

**Purpose**: Implements MCP JSON-RPC 2.0 protocol handling.

**Responsibilities**:
- Parse and validate JSON-RPC requests
- Route requests to appropriate handlers
- Format responses according to MCP specification
- Handle protocol errors and edge cases

**Key Methods**:
```groovy
class McpProtocolHandlerSimple {
    def processRequest(Map request)      // Main request processor
    def handleInitialize(Map params)     // Handle initialize method
    def handleToolsList()               // Handle tools/list method
    def handleToolsCall(Map params)     // Handle tools/call method
    def handleResourcesList()           // Handle resources/list method
    def handleResourcesRead(Map params) // Handle resources/read method
}
```

**Protocol Methods Supported**:
- `initialize`: Client-server capability negotiation
- `tools/list`: Enumerate available tools
- `tools/call`: Execute specific tools
- `resources/list`: Enumerate available resources
- `resources/read`: Read resource contents

### 3. McpToolManagerSimple

**Purpose**: Manages and executes MCP tools.

**Responsibilities**:
- Register and discover available tools
- Validate tool parameters
- Execute tool logic
- Format tool results

**Tool Registry**:
```groovy
class McpToolManagerSimple {
    def getAvailableTools()           // List all registered tools
    def executeTool(String name, Map args) // Execute specific tool
    def validateToolArgs(String name, Map args) // Validate arguments
}
```

**Built-in Tools**:
- `ping_system`: System health check
- `get_companies`: Retrieve company list from GrowERP

**Tool Schema Format**:
```groovy
[
    name: "tool_name",
    description: "Tool description",
    inputSchema: [
        type: "object",
        properties: [...],
        required: [...]
    ]
]
```

### 4. McpResourceManagerSimple

**Purpose**: Manages MCP resources for data access.

**Responsibilities**:
- Register and discover available resources
- Control resource access permissions
- Format resource content
- Handle resource URIs

**Resource Types**:
```groovy
class McpResourceManagerSimple {
    def getAvailableResources()     // List all available resources
    def readResource(String uri)    // Read resource content
    def validateResourceAccess(String uri) // Check access permissions
}
```

**Resource URI Scheme**:
- `growerp://entities/{entityName}`: Entity definitions
- `growerp://system/{component}`: System information
- `growerp://data/{dataSet}`: Business data sets

## Data Flow

### 1. Request Processing Flow

```
MCP Client Request
       ↓
REST Endpoint (McpServer.xml)
       ↓
Moqui Service (McpServerServices.xml)
       ↓
McpServerSimple.handleRequest()
       ↓
McpProtocolHandlerSimple.processRequest()
       ↓
┌──────────────────┬──────────────────┐
│                  │                  │
▼                  ▼                  ▼
ToolManager    ResourceManager    Direct Response
       ↓              ↓                  ↓
Tool Execution  Resource Read    Protocol Response
       ↓              ↓                  ↓
└──────────────────┬──────────────────┘
                   ▼
           Formatted JSON-RPC Response
                   ↓
              MCP Client
```

### 2. Error Handling Flow

```
Error Occurs
     ↓
Exception Caught
     ↓
Error Type Classification
     ↓
┌─────────┬─────────┬─────────┐
│         │         │         │
▼         ▼         ▼         ▼
Parse   Invalid  Method   Internal
Error   Request  Not Found  Error
│         │         │         │
└─────────┼─────────┼─────────┘
          ▼
   JSON-RPC Error Response
          ▼
      MCP Client
```

## Design Patterns

### 1. **Manager Pattern**
Each major concern (tools, resources, protocol) is handled by a dedicated manager class with a consistent interface:

```groovy
interface Manager {
    def initialize(Map config)
    def handleOperation(Map params)
    def cleanup()
}
```

### 2. **Service Facade Pattern**
Moqui services act as facades that delegate to Groovy implementations:

```xml
<service name="mcpHandleRequest">
    <in-parameters>
        <parameter name="request" type="String"/>
    </in-parameters>
    <out-parameters>
        <parameter name="response" type="String"/>
    </out-parameters>
    <actions>
        <!-- Delegate to Groovy implementation -->
    </actions>
</service>
```

### 3. **Strategy Pattern**
Different resource types and tools use strategy pattern for extensibility:

```groovy
interface ToolStrategy {
    def execute(Map args)
    def getSchema()
}

interface ResourceStrategy {
    def read(String uri)
    def getMetadata()
}
```

## Configuration

### 1. Component Configuration

**Location**: `component.xml`
```xml
<moqui-component name="growerp-mcp-server" version="1.0.0">
    <depends-on name="growerp"/>
    <!-- Component dependencies and metadata -->
</moqui-component>
```

### 2. Service Configuration

**Location**: `service/McpServerServices.xml`
```xml
<services>
    <service name="mcpHandleRequest">
        <!-- Service definitions -->
    </service>
</services>
```

### 3. Screen Configuration

**Location**: `screen/McpServer.xml`
```xml
<screen>
    <transition name="mcp">
        <!-- REST endpoint definitions -->
    </transition>
</screen>
```

## Security Architecture

### 1. **Authentication**
- Inherits from Moqui framework authentication
- Can be configured for different security levels
- Supports token-based authentication

### 2. **Authorization**
- Role-based access control through Moqui
- Resource-level permissions
- Tool execution permissions

### 3. **Data Privacy**
- Configurable data masking
- Audit logging for sensitive operations
- Compliance with data protection regulations

## Performance Considerations

### 1. **Caching Strategy**
- Tool and resource metadata cached at startup
- Dynamic content cached based on TTL
- Cache invalidation on data changes

### 2. **Connection Pooling**
- Database connections managed by Moqui
- HTTP client connection reuse
- Resource cleanup on component shutdown

### 3. **Async Operations**
- Long-running tools can be executed asynchronously
- Progress tracking for extended operations
- Timeout handling for client connections

## Extension Points

### 1. **Adding New Tools**

```groovy
// 1. Create tool implementation
class MyCustomTool implements ToolStrategy {
    def execute(Map args) {
        // Tool logic
    }
    
    def getSchema() {
        return [
            name: "my_tool",
            description: "Custom tool",
            inputSchema: [...]
        ]
    }
}

// 2. Register with ToolManager
toolManager.registerTool(new MyCustomTool())
```

### 2. **Adding New Resources**

```groovy
// 1. Create resource implementation
class MyCustomResource implements ResourceStrategy {
    def read(String uri) {
        // Resource reading logic
    }
    
    def getMetadata() {
        return [
            uri: "growerp://custom/my_resource",
            name: "My Resource",
            description: "Custom resource",
            mimeType: "application/json"
        ]
    }
}

// 2. Register with ResourceManager
resourceManager.registerResource(new MyCustomResource())
```

### 3. **Custom Protocol Extensions**

```groovy
// Extend protocol handler for custom methods
class CustomProtocolHandler extends McpProtocolHandlerSimple {
    def handleCustomMethod(Map params) {
        // Custom protocol logic
    }
}
```

## Monitoring and Observability

### 1. **Health Checks**
- System health endpoint
- Component status monitoring
- Dependency health verification

### 2. **Metrics**
- Request/response metrics
- Tool execution metrics
- Resource access metrics
- Error rate monitoring

### 3. **Logging**
- Structured logging with correlation IDs
- Request/response logging
- Error and exception logging
- Performance metrics logging

## Deployment Architecture

### 1. **Development Environment**
```
Developer Machine
├── Moqui Framework
├── GrowERP Components
└── MCP Server Component
    ├── Groovy Classes
    ├── Service Definitions
    └── REST Endpoints
```

### 2. **Production Environment**
```
Production Server
├── Load Balancer
├── Moqui Application Server
│   ├── GrowERP Core
│   └── MCP Server Component
├── Database Server
└── Monitoring/Logging
```

## Future Architecture Considerations

### 1. **Scalability**
- Horizontal scaling through multiple Moqui instances
- Database connection pooling optimization
- Caching layer improvements

### 2. **Reliability**
- Circuit breaker patterns for external dependencies
- Graceful degradation for partial failures
- Retry logic with exponential backoff

### 3. **Security Enhancements**
- OAuth 2.0 integration
- API key management
- Rate limiting implementation
- Request signing and verification

## Troubleshooting Common Issues

### 1. **Component Not Loading**
- Check `component.xml` syntax
- Verify dependency chain
- Review Moqui logs for initialization errors

### 2. **Service Errors**
- Validate service definition syntax
- Check Groovy class compilation
- Verify parameter mappings

### 3. **Protocol Issues**
- Validate JSON-RPC request format
- Check method name spelling
- Verify parameter schema compliance

This architecture guide provides the foundation for understanding, extending, and maintaining the GrowERP MCP Server. For specific implementation details, refer to the source code and other documentation files.
