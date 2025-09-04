# MCP Endpoint Fix Summary

## Problem
Gemini CLI and other MCP clients were getting HTTP 400 errors when trying to connect to the GrowERP MCP server:
```
MCP error -32603: Failed to call tool: HTTP 400: {
  "errorCode" : 400,
  "errors" : "Field cannot be empty(for field Request of service Mcp Services Handle Mcp Request"
}
```

## Root Cause
The original MCP service implementation required JSON-RPC requests to be wrapped in a `request` field due to Moqui service parameter requirements:

```json
{
  "request": {
    "jsonrpc": "2.0",
    "method": "tools/list",
    "params": {},
    "id": 2
  }
}
```

However, standard MCP clients expect to send raw JSON-RPC requests:

```json
{
  "jsonrpc": "2.0",
  "method": "tools/list", 
  "params": {},
  "id": 2
}
```

## Solution
Created a new flexible service and endpoint that supports both formats:

### New Service: `McpServices.handle#McpRequestFlexible`
- Automatically detects whether the request is wrapped or raw JSON-RPC
- Handles both formats transparently
- Returns standard JSON-RPC responses

### New Endpoint: `/rest/s1/mcp/protocol`
- **Recommended for all MCP clients**
- Supports standard JSON-RPC format
- Compatible with Gemini CLI, Claude Desktop, and other MCP clients

### Legacy Endpoint: `/rest/s1/mcp/mcp`
- Still available for backward compatibility
- Requires the wrapped format with `request` field

## Usage

### For MCP Clients (Recommended)
Use the new protocol endpoint with standard JSON-RPC:
```bash
curl -X POST http://localhost:8080/rest/s1/mcp/protocol \
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

### Response Format
Standard JSON-RPC response:
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "text": "System is operational"
  }
}
```

## Files Modified
1. `service/McpServices.xml` - Added flexible service
2. `service/mcp.rest.xml` - Added new protocol endpoint
3. `docs/quick-start.md` - Updated documentation with new endpoint

## Testing
All MCP protocol methods tested and working:
- ✅ `initialize`
- ✅ `tools/list`
- ✅ `tools/call`
- ✅ `resources/list`
- ✅ `resources/read`

The Gemini CLI should now work correctly with the GrowERP MCP server using the `/rest/s1/mcp/protocol` endpoint.
