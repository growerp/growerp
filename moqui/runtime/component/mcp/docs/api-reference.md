# API Reference

Complete API documentation for the GrowERP MCP Server.

## Base URL

All API endpoints are available under the base URL:
```
http://localhost:8080/rest/s1/mcp/
```

## Endpoints Overview

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/health` | GET | Health check |
| `/tools` | GET | List available tools |
| `/resources` | GET | List available resources |
| `/mcp` | POST | MCP JSON-RPC protocol endpoint |

## Authentication

The MCP server inherits authentication from the GrowERP/Moqui framework. Currently, no additional authentication is required for basic endpoints, but this can be configured based on your security requirements.

## Health Check

### GET /health

Check the health and status of the MCP server.

**Response:**
```json
{
  "status": "healthy",
  "timestamp": 1693747200000,
  "version": "1.0.0"
}
```

**Response Fields:**
- `status` (string): Health status ("healthy" or "unhealthy")
- `timestamp` (number): Current server timestamp in milliseconds
- `version` (string): MCP server version

**Example:**
```bash
curl http://localhost:8080/rest/s1/mcp/health
```

## Tools Management

### GET /tools

List all available MCP tools that can be executed.

**Response:**
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

**Tool Schema:**
- `name` (string): Unique tool identifier
- `description` (string): Human-readable tool description
- `inputSchema` (object): JSON Schema defining the tool's input parameters

**Example:**
```bash
curl http://localhost:8080/rest/s1/mcp/tools
```

## Resources Management

### GET /resources

List all available MCP resources that can be read.

**Response:**
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

**Resource Schema:**
- `uri` (string): Unique resource identifier using growerp:// scheme
- `name` (string): Human-readable resource name
- `description` (string): Resource description
- `mimeType` (string): Content type of the resource

**Example:**
```bash
curl http://localhost:8080/rest/s1/mcp/resources
```

## MCP Protocol Endpoint

### POST /mcp

The main MCP protocol endpoint that handles JSON-RPC 2.0 requests according to the MCP specification.

**Request Format:**
```json
{
  "jsonrpc": "2.0",
  "method": "METHOD_NAME",
  "params": { ... },
  "id": "request_id"
}
```

**Response Format:**
```json
{
  "jsonrpc": "2.0",
  "id": "request_id",
  "result": { ... }
}
```

**Error Response Format:**
```json
{
  "jsonrpc": "2.0",
  "id": "request_id",
  "error": {
    "code": -32601,
    "message": "Method not found"
  }
}
```

## MCP Protocol Methods

### initialize

Initialize the MCP connection and exchange capabilities.

**Request:**
```json
{
  "jsonrpc": "2.0",
  "method": "initialize",
  "params": {
    "protocolVersion": "2024-11-05",
    "capabilities": {},
    "clientInfo": {
      "name": "client-name",
      "version": "1.0.0"
    }
  },
  "id": 1
}
```

**Response:**
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "protocolVersion": "2024-11-05",
    "capabilities": {
      "resources": {},
      "tools": {},
      "prompts": {},
      "logging": {}
    },
    "serverInfo": {
      "name": "GrowERP MCP Server",
      "version": "1.0.0"
    }
  }
}
```

### tools/list

List all available tools.

**Request:**
```json
{
  "jsonrpc": "2.0",
  "method": "tools/list",
  "id": 2
}
```

**Response:**
```json
{
  "jsonrpc": "2.0",
  "id": 2,
  "result": {
    "tools": [
      {
        "name": "ping_system",
        "description": "Check system health",
        "inputSchema": {
          "type": "object",
          "properties": {},
          "required": []
        }
      }
    ]
  }
}
```

### tools/call

Execute a specific tool with arguments.

**Request:**
```json
{
  "jsonrpc": "2.0",
  "method": "tools/call",
  "params": {
    "name": "get_companies",
    "arguments": {
      "limit": 5
    }
  },
  "id": 3
}
```

**Response:**
```json
{
  "jsonrpc": "2.0",
  "id": 3,
  "result": {
    "text": "Found 2 companies",
    "data": [
      {
        "partyId": "Company",
        "organizationName": "Demo Company"
      },
      {
        "partyId": "ZIZIWORK_ORG",
        "organizationName": "ZiZiWork"
      }
    ]
  }
}
```

### resources/list

List all available resources.

**Request:**
```json
{
  "jsonrpc": "2.0",
  "method": "resources/list",
  "id": 4
}
```

**Response:**
```json
{
  "jsonrpc": "2.0",
  "id": 4,
  "result": {
    "resources": [
      {
        "uri": "growerp://entities/company",
        "name": "Company Entities",
        "description": "Company and organization data",
        "mimeType": "application/json"
      }
    ]
  }
}
```

### resources/read

Read the contents of a specific resource.

**Request:**
```json
{
  "jsonrpc": "2.0",
  "method": "resources/read",
  "params": {
    "uri": "growerp://system/status"
  },
  "id": 5
}
```

**Response:**
```json
{
  "jsonrpc": "2.0",
  "id": 5,
  "result": {
    "contents": [
      {
        "uri": "growerp://system/status",
        "mimeType": "application/json",
        "text": "{\n  \"status\": \"operational\",\n  \"timestamp\": 1693747200000,\n  \"services\": {\n    \"database\": \"connected\",\n    \"mcp\": \"running\"\n  }\n}"
      }
    ]
  }
}
```

## Available Tools

### ping_system

Check system health and connectivity.

**Parameters:** None

**Response:**
```json
{
  "text": "System is operational"
}
```

**Example:**
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

### get_companies

Retrieve a list of companies from the GrowERP system.

**Parameters:**
- `limit` (integer, optional): Maximum number of companies to return (default: 10)

**Response:**
```json
{
  "text": "Found 2 companies",
  "data": [
    {
      "partyId": "Company",
      "organizationName": "Demo Company"
    },
    {
      "partyId": "CUSTOMER_001",
      "organizationName": "Customer Organization"
    }
  ]
}
```

**Example:**
```bash
curl -X POST http://localhost:8080/rest/s1/mcp/mcp \
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

## Available Resources

### growerp://entities/company

Company and organization entity information.

**Content:**
```json
{
  "entityName": "Company",
  "description": "Organization and company information",
  "fields": {
    "partyId": {
      "type": "String",
      "description": "Unique party identifier"
    },
    "organizationName": {
      "type": "String",
      "description": "Company name"
    },
    "currencyUomId": {
      "type": "String",
      "description": "Default currency"
    }
  }
}
```

### growerp://entities/user

User account and profile entity information.

**Content:**
```json
{
  "entityName": "User",
  "description": "User account and profile information",
  "fields": {
    "userId": {
      "type": "String",
      "description": "Unique user identifier"
    },
    "username": {
      "type": "String",
      "description": "Login username"
    },
    "userFullName": {
      "type": "String",
      "description": "Full display name"
    }
  }
}
```

### growerp://system/status

Current system status and health information.

**Content:**
```json
{
  "status": "operational",
  "timestamp": 1693747200000,
  "services": {
    "database": "connected",
    "mcp": "running"
  }
}
```

## Error Codes

The MCP server follows JSON-RPC 2.0 error code conventions:

| Code | Message | Description |
|------|---------|-------------|
| -32700 | Parse error | Invalid JSON was received |
| -32600 | Invalid Request | The JSON sent is not a valid Request object |
| -32601 | Method not found | The method does not exist / is not available |
| -32602 | Invalid params | Invalid method parameter(s) |
| -32603 | Internal error | Internal JSON-RPC error |

**Error Response Example:**
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "error": {
    "code": -32601,
    "message": "Method not found: unknown_method"
  }
}
```

## Rate Limiting

Currently, no rate limiting is implemented. This may be added in future versions based on usage patterns and requirements.

## Versioning

The API follows semantic versioning. The current version is `1.0.0`. Breaking changes will increment the major version number.

## Examples

### Complete Workflow Example

```bash
# 1. Check server health
curl http://localhost:8080/rest/s1/mcp/health

# 2. Initialize MCP connection
curl -X POST http://localhost:8080/rest/s1/mcp/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "initialize",
    "params": {
      "protocolVersion": "2024-11-05",
      "capabilities": {},
      "clientInfo": {"name": "test-client", "version": "1.0.0"}
    },
    "id": 1
  }'

# 3. List available tools
curl -X POST http://localhost:8080/rest/s1/mcp/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/list",
    "id": 2
  }'

# 4. Execute a tool
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

# 5. List available resources
curl -X POST http://localhost:8080/rest/s1/mcp/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "resources/list",
    "id": 4
  }'

# 6. Read a resource
curl -X POST http://localhost:8080/rest/s1/mcp/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "resources/read",
    "params": {"uri": "growerp://system/status"},
    "id": 5
  }'
```

## SDKs and Libraries

### Python

See the [Python client example](quick-start.md#python-client-example) in the Quick Start guide.

### JavaScript/Node.js

See the [JavaScript client example](quick-start.md#javascriptnodejs-example) in the Quick Start guide.

### Custom Integrations

The MCP server implements standard JSON-RPC 2.0 over HTTP, making it compatible with any HTTP client library in any programming language.

For more information about the Model Context Protocol specification, visit the [official MCP documentation](https://modelcontextprotocol.io/).
