# GrowERP MCP Server

A Model Context Protocol (MCP) server implementation for the GrowERP/Moqui backend, providing AI agents and development tools with structured access to ERP data and business operations.

## Overview

The GrowERP MCP Server exposes GrowERP's business capabilities through the Model Context Protocol, enabling AI agents to:

- Access and manipulate business entities (companies, users, products, orders)
- Execute business operations (create orders, generate invoices, process payments)
- Query data and generate reports
- Understand business processes and workflows
- Get contextual help and guidance

## Features

### 🔗 **MCP Protocol Compliance**
- Full implementation of MCP specification (2024-11-05)
- Resources, Tools, Prompts, and Logging capabilities
- JSON-RPC 2.0 communication protocol
- WebSocket and HTTP transport support

### 🏢 **Business Entity Access**
- **Companies**: Create, update, and query organization data
- **Users**: Manage user accounts and authentication
- **Products**: Catalog management and product operations
- **Financial Documents**: Orders, invoices, payments
- **Opportunities**: Sales pipeline and CRM data
- **Assets**: Inventory and asset management

### 🛠️ **Business Tools**
- Entity CRUD operations (Create, Read, Update, Delete)
- Financial workflows (order-to-cash, procure-to-pay)
- Reporting and analytics
- System administration and health checks

### 📊 **Rich Resources**
- Entity schemas and sample data
- Service documentation and APIs
- System status and configuration
- Business process guides

### 💡 **Intelligent Prompts**
- Context-aware guidance for business operations
- Workflow optimization suggestions
- Data analysis and insights
- Development and debugging help

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   AI Agent      │    │   MCP Server     │    │   GrowERP       │
│                 │    │                  │    │                 │
│ ┌─────────────┐ │    │ ┌──────────────┐ │    │ ┌─────────────┐ │
│ │ MCP Client  │◄├────┤►│ Protocol     │ │    │ │ Moqui       │ │
│ └─────────────┘ │    │ │ Handler      │ │    │ │ Services    │ │
│                 │    │ └──────────────┘ │    │ └─────────────┘ │
│                 │    │ ┌──────────────┐ │    │ ┌─────────────┐ │
│                 │    │ │ Resource     │◄├────┤►│ Entity      │ │
│                 │    │ │ Manager      │ │    │ │ Engine      │ │
│                 │    │ └──────────────┘ │    │ └─────────────┘ │
│                 │    │ ┌──────────────┐ │    │ ┌─────────────┐ │
│                 │    │ │ Tool         │◄├────┤►│ Business    │ │
│                 │    │ │ Manager      │ │    │ │ Logic       │ │
│                 │    │ └──────────────┘ │    │ └─────────────┘ │
│                 │    │ ┌──────────────┐ │    │                 │
│                 │    │ │ Prompt       │ │    │                 │
│                 │    │ │ Manager      │ │    │                 │
│                 │    │ └──────────────┘ │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

## Installation

### Prerequisites

- Java 11+ 
- Moqui Framework 3.0+
- GrowERP 1.9+
- Gradle 8.5+

### Setup

1. **Clone/Copy the MCP Server Component**
   ```bash
   cd $MOQUI_HOME/runtime/component
   # Copy growerp-mcp-server directory to this location
   ```

2. **Build the Component**
   ```bash
   cd growerp-mcp-server
   gradle build
   ```

3. **Start Moqui with MCP Server**
   ```bash
   cd $MOQUI_HOME
   gradle cleanAll load run
   ```

4. **Verify Installation**
   ```bash
   curl http://localhost:8080/mcp/health
   ```

## Configuration

### Environment Variables
```bash
# MCP Server Configuration
MCP_SERVER_PORT=3000
MCP_SERVER_DEBUG=false
MCP_ALLOWED_ORIGINS=*

# Security
SECURITY_API_KEY_REQUIRED=false
SECURITY_SESSION_TIMEOUT=86400000

# Performance
PERFORMANCE_CACHING_ENABLED=true
PERFORMANCE_POOL_SIZE=10
```

### Moqui Configuration
Add to your `MoquiConf.xml`:
```xml
<moqui-conf>
    <webapp-list>
        <webapp name="mcp" location="component://growerp-mcp-server/screen/mcp" 
                mount-point="/mcp"/>
    </webapp-list>
    
    <component-list>
        <component name="growerp-mcp-server" location="component/growerp-mcp-server"/>
    </component-list>
</moqui-conf>
```

## Usage

### Starting the MCP Server

#### Via REST API
```bash
# Start server
curl -X POST http://localhost:8080/mcp/server \
  -H "Content-Type: application/json" \
  -d '{"action": "start", "port": 3000, "debug": false}'

# Check server status
curl http://localhost:8080/mcp/server \
  -H "Content-Type: application/json" \
  -d '{"action": "list"}'
```

#### Via Moqui Service
```groovy
def result = ec.service.sync().name("growerp.mcp.start#McpServer")
    .parameters([port: 3000, debug: false]).call()
```

### Connecting AI Agents

#### Python Example
```python
import asyncio
from mcp import ClientSession, StdioServerTransport

async def main():
    # Connect to MCP server via stdio transport
    transport = StdioServerTransport()
    
    async with ClientSession(transport) as session:
        # Initialize connection
        await session.initialize()
        
        # List available tools
        tools = await session.list_tools()
        print(f"Available tools: {[tool.name for tool in tools]}")
        
        # Call a tool
        result = await session.call_tool("get_companies", {"limit": 5})
        print(f"Companies: {result.content}")
        
        # Read a resource
        resource = await session.read_resource("growerp://entities/company")
        print(f"Company schema: {resource.contents}")

asyncio.run(main())
```

#### Direct HTTP/JSON-RPC
```bash
# List available tools
curl -X POST http://localhost:8080/mcp/protocol \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/list",
    "id": 1
  }'

# Call a tool
curl -X POST http://localhost:8080/mcp/protocol \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/call",
    "params": {
      "name": "get_companies",
      "arguments": {"limit": 5}
    },
    "id": 2
  }'
```

## Available Tools

### Entity Management
- `create_company` - Create new companies
- `create_user` - Create user accounts  
- `create_product` - Add products to catalog
- `update_company` - Update company information
- `update_user` - Update user accounts

### Business Operations
- `create_sales_order` - Create sales orders
- `create_purchase_order` - Create purchase orders
- `create_invoice` - Generate invoices
- `approve_document` - Approve financial documents

### Data Queries
- `get_companies` - Retrieve company data
- `get_users` - Retrieve user accounts
- `get_products` - Query product catalog
- `get_orders` - Retrieve order information
- `get_financial_summary` - Financial reporting

### System Operations
- `ping_system` - Health check
- `get_entity_info` - Entity schema information
- `get_service_info` - Service documentation

## Available Resources

### Entity Resources
- `growerp://entities/company` - Company data and schemas
- `growerp://entities/user` - User account information
- `growerp://entities/product` - Product catalog data
- `growerp://entities/findoc` - Financial documents
- `growerp://entities/opportunity` - Sales opportunities
- `growerp://entities/asset` - Asset management data

### Service Resources
- `growerp://services/party` - Party management services
- `growerp://services/catalog` - Catalog services
- `growerp://services/order` - Order management
- `growerp://services/accounting` - Financial services

### System Resources
- `growerp://system/status` - System health status
- `growerp://system/info` - Version and system information
- `growerp://system/entities` - All entity definitions
- `growerp://system/services` - All service definitions

## Available Prompts

### Entity Operations
- `create_entity_guide` - Step-by-step entity creation
- `entity_validation` - Data validation assistance
- `entity_relationship_guide` - Understanding relationships

### Business Processes
- `business_process_guide` - Business workflow guidance
- `workflow_optimization` - Process improvement suggestions
- `financial_analysis` - Financial insights and analysis

### Analytics
- `data_analysis` - Data analysis guidance
- `performance_metrics` - KPI and metrics help
- `trend_analysis` - Trend identification

### Development
- `service_development` - Moqui service development
- `entity_design` - Entity modeling guidance
- `debugging_guide` - Troubleshooting help

## API Reference

### REST Endpoints

#### Server Management
- `POST /mcp/server` - Start/stop/list MCP servers
- `GET /mcp/health` - Health check

#### MCP Protocol
- `POST /mcp/protocol` - JSON-RPC 2.0 MCP communication
- `GET /mcp/ws` - WebSocket endpoint for real-time communication

### Service Interface

#### Start MCP Server
```xml
<service verb="start" noun="McpServer">
    <in-parameters>
        <parameter name="port" type="Integer" default="3000"/>
        <parameter name="debug" type="Boolean" default="false"/>
    </in-parameters>
    <out-parameters>
        <parameter name="serverId" type="String"/>
        <parameter name="status" type="String"/>
    </out-parameters>
</service>
```

#### Handle MCP Request
```xml
<service verb="handle" noun="McpRequest">
    <in-parameters>
        <parameter name="method" type="String" required="true"/>
        <parameter name="params" type="Map"/>
    </in-parameters>
    <out-parameters>
        <parameter name="response" type="Map"/>
    </out-parameters>
</service>
```

## Security

### Authentication
- Optional API key authentication
- Session-based security integration
- Moqui authorization framework integration

### Access Control
- Tool-level permission checking
- Resource access validation
- Rate limiting support

### Data Protection
- Input validation and sanitization
- SQL injection prevention
- XSS protection for web endpoints

## Development

### Adding Custom Tools

1. **Implement Tool Logic**
   ```groovy
   private Map<String, Object> executeCustomTool(Map<String, Object> arguments) {
       // Tool implementation
       return [text: "Result", data: result]
   }
   ```

2. **Register Tool**
   ```groovy
   // Add to getEntityCrudTools() or similar method
   [
       name: "custom_tool",
       description: "Custom business operation",
       inputSchema: [
           type: "object",
           properties: [
               param1: [type: "string", description: "Parameter 1"]
           ],
           required: ["param1"]
       ]
   ]
   ```

3. **Handle Tool Calls**
   ```groovy
   // Add to executeTool() switch statement
   case "custom_tool":
       return executeCustomTool(arguments)
   ```

### Adding Custom Resources

1. **Define Resource**
   ```groovy
   // Add to getEntityResources() or similar
   [
       uri: "growerp://custom/resource",
       name: "Custom Resource",
       description: "Custom business data",
       mimeType: "application/json"
   ]
   ```

2. **Implement Reader**
   ```groovy
   private Map<String, Object> readCustomResource(List<String> subPath) {
       // Resource reading logic
       return [contents: [[uri: uri, mimeType: "application/json", text: data]]]
   }
   ```

### Testing

```bash
# Run unit tests
gradle test

# Run integration tests
gradle integrationTest

# Test MCP protocol compliance
gradle mcpTest
```

## Troubleshooting

### Common Issues

1. **Server Won't Start**
   - Check Moqui is running
   - Verify component is properly installed
   - Check logs for startup errors

2. **Connection Refused**
   - Verify MCP server is started
   - Check firewall settings
   - Confirm port availability

3. **Authentication Errors**
   - Check API key configuration
   - Verify user permissions
   - Review security settings

4. **Tool Execution Failures**
   - Validate input parameters
   - Check business rule compliance
   - Review entity relationships

### Logs

```bash
# Enable MCP debug logging
echo "logging.mcp.level=DEBUG" >> gradle.properties

# View MCP server logs
tail -f runtime/log/moqui.log | grep MCP

# Check specific component logs
grep "growerp.mcp" runtime/log/moqui.log
```

## Performance

### Optimization Tips

1. **Caching**
   - Enable entity caching
   - Use service result caching
   - Implement resource caching

2. **Connection Pooling**
   - Configure database pools
   - Optimize thread pools
   - Tune WebSocket connections

3. **Query Optimization**
   - Use entity find conditions
   - Implement proper indexing
   - Limit result sets

## Contributing

1. Fork the repository
2. Create a feature branch
3. Implement changes with tests
4. Submit a pull request

### Development Setup

```bash
# Clone repository
git clone https://github.com/growerp/growerp.git

# Navigate to MCP server
cd growerp/moqui/runtime/component/growerp-mcp-server

# Build and test
gradle build test

# Run with debug logging
gradle run --debug-jvm
```

## License

This project is licensed under the CC0 1.0 Universal License - see the LICENSE.md file for details.

## Support

- **Documentation**: https://www.growerp.com/docs
- **Community**: https://github.com/growerp/growerp/discussions
- **Issues**: https://github.com/growerp/growerp/issues
- **Email**: support@growerp.com

---

*GrowERP MCP Server - Bringing AI to Business Operations*
