# Quick Start Guide

Get your GrowERP MCP Server up and running in minutes.

## Prerequisites

Before you begin, ensure you have:

- **Java 11 or later** installed
- **Moqui Framework 3.0+** installed and configured
- **GrowERP** components installed
- Basic familiarity with REST APIs and JSON

## Installation

The GrowERP MCP Server is already included as a component in your GrowERP installation. No additional installation steps are required.

### Verify Installation

1. **Check Component Structure**
   ```bash
   ls -la moqui/runtime/component/growerp-mcp-server/
   ```
   
   You should see:
   - `component.xml` - Component definition
   - `service/` - Moqui service definitions
   - `screen/` - REST API endpoints
   - `src/` - Groovy implementation classes

2. **Build the Component**
   ```bash
   cd moqui/runtime/component/growerp-mcp-server
   ../../../gradlew build
   ```

## Starting the Server

1. **Start Moqui** (if not already running)
   ```bash
   cd moqui
   java -jar moqui.war
   ```

2. **Verify MCP Server is Loaded**
   
   Look for this line in the Moqui startup logs:
   ```
   Component growerp-mcp-server version 1.0.0+0 initialized
   ```

3. **Test the Health Endpoint**
   ```bash
   curl http://localhost:8080/rest/s1/mcp/health
   ```
   
   Expected response:
   ```json
   {
     "status": "healthy",
     "timestamp": 1693747200000,
     "version": "1.0.0"
   }
   ```

## Basic Usage

### 1. Check Available Tools

```bash
curl http://localhost:8080/rest/s1/mcp/tools
```

Response:
```json
{
  "tools": [
    {
      "name": "ping_system",
      "description": "Check system health",
      "inputSchema": {
        "type": "object",
        "properties": {},
        "required": []
      }
    },
    {
      "name": "get_companies",
      "description": "Get list of companies",
      "inputSchema": {
        "type": "object",
        "properties": {
          "limit": {
            "type": "integer",
            "description": "Maximum number of results"
          }
        },
        "required": []
      }
    }
  ]
}
```

### 2. Execute a Tool

```bash
curl -X POST http://localhost:8080/rest/s1/mcp/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/call",
    "params": {
      "name": "ping_system",
      "arguments": {}
    },
    "id": 1
  }'
```

Response:
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "text": "System is operational"
  }
}
```

### 3. List Available Resources

```bash
curl http://localhost:8080/rest/s1/mcp/resources
```

Response:
```json
{
  "resources": [
    {
      "uri": "growerp://entities/company",
      "name": "Company Entities",
      "description": "Company and organization data",
      "mimeType": "application/json"
    },
    {
      "uri": "growerp://entities/user",
      "name": "User Entities",
      "description": "User account and profile data",
      "mimeType": "application/json"
    },
    {
      "uri": "growerp://system/status",
      "name": "System Status",
      "description": "Current system health and status",
      "mimeType": "application/json"
    }
  ]
}
```

### 4. Read a Resource

```bash
curl -X POST http://localhost:8080/rest/s1/mcp/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "resources/read",
    "params": {
      "uri": "growerp://system/status"
    },
    "id": 2
  }'
```

## MCP Protocol Communication

The MCP server supports the full MCP protocol through JSON-RPC 2.0. Here are the core methods:

### Initialize Connection

```bash
curl -X POST http://localhost:8080/rest/s1/mcp/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "initialize",
    "params": {
      "protocolVersion": "2024-11-05",
      "capabilities": {},
      "clientInfo": {
        "name": "test-client",
        "version": "1.0.0"
      }
    },
    "id": 1
  }'
```

### List Tools

```bash
curl -X POST http://localhost:8080/rest/s1/mcp/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/list",
    "id": 2
  }'
```

### Call a Tool

```bash
curl -X POST http://localhost:8080/rest/s1/mcp/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/call",
    "params": {
      "name": "get_companies",
      "arguments": {"limit": 3}
    },
    "id": 3
  }'
```

### List Resources

```bash
curl -X POST http://localhost:8080/rest/s1/mcp/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "resources/list",
    "id": 4
  }'
```

### Read a Resource

```bash
curl -X POST http://localhost:8080/rest/s1/mcp/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "resources/read",
    "params": {
      "uri": "growerp://entities/company"
    },
    "id": 5
  }'
```

## Integration with AI Tools

### Python Client Example

```python
import requests
import json

class GrowERPMCPClient:
    def __init__(self, base_url="http://localhost:8080"):
        self.base_url = base_url
        self.mcp_endpoint = f"{base_url}/rest/s1/mcp/mcp"
        
    def call_tool(self, tool_name, arguments=None):
        payload = {
            "jsonrpc": "2.0",
            "method": "tools/call",
            "params": {
                "name": tool_name,
                "arguments": arguments or {}
            },
            "id": 1
        }
        
        response = requests.post(self.mcp_endpoint, json=payload)
        return response.json()
    
    def get_companies(self, limit=10):
        return self.call_tool("get_companies", {"limit": limit})
    
    def ping_system(self):
        return self.call_tool("ping_system")

# Usage
client = GrowERPMCPClient()
print(client.ping_system())
print(client.get_companies(5))
```

### JavaScript/Node.js Example

```javascript
class GrowERPMCPClient {
    constructor(baseUrl = 'http://localhost:8080') {
        this.baseUrl = baseUrl;
        this.mcpEndpoint = `${baseUrl}/rest/s1/mcp/mcp`;
    }
    
    async callTool(toolName, arguments = {}) {
        const payload = {
            jsonrpc: "2.0",
            method: "tools/call",
            params: {
                name: toolName,
                arguments: arguments
            },
            id: 1
        };
        
        const response = await fetch(this.mcpEndpoint, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(payload)
        });
        
        return await response.json();
    }
    
    async getCompanies(limit = 10) {
        return await this.callTool('get_companies', { limit });
    }
    
    async pingSystem() {
        return await this.callTool('ping_system');
    }
}

// Usage
const client = new GrowERPMCPClient();
client.pingSystem().then(console.log);
client.getCompanies(5).then(console.log);
```

## Next Steps

Now that you have the MCP server running:

1. **Explore the API**: Check out the [API Reference](api-reference.md) for complete endpoint documentation
2. **Understand the Architecture**: Read the [Architecture Guide](architecture.md) to understand how components work together
3. **Customize**: Follow the [Developer Guide](developer-guide.md) to add custom tools and resources
4. **Configure**: Review the [Configuration Guide](configuration.md) for advanced settings
5. **Integrate**: Use the examples above to integrate with your AI tools and applications

## Troubleshooting

### Common Issues

**Server not responding**
- Verify Moqui is running: `curl http://localhost:8080/status`
- Check component is loaded in Moqui logs
- Ensure no firewall blocking port 8080

**404 errors on MCP endpoints**
- Verify the growerp component is properly loaded
- Check the REST endpoint paths in the logs
- Ensure you're using the correct URL format

**Tool execution errors**
- Check Moqui logs for detailed error messages
- Verify input parameters match the tool schema
- Ensure you have proper permissions for data access

For more detailed troubleshooting, see the [Troubleshooting Guide](troubleshooting.md).

## Support

- **Documentation**: Continue with the [API Reference](api-reference.md)
- **Issues**: [GitHub Issues](https://github.com/growerp/growerp/issues)
- **Community**: [GitHub Discussions](https://github.com/growerp/growerp/discussions)
