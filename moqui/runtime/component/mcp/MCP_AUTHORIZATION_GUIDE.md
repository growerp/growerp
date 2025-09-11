# MCP Authorization Implementation Guide

This document describes the API key authorization implementation for the GrowERP MCP (Model Context Protocol) component.

## Overview

The MCP component now requires API key authentication for all endpoints. The implementation integrates with GrowERP's existing authentication system and requires users to have the `AppSupport` classification.

## Authentication Flow

1. **Frontend Login**: Client logs in with username/password (e.g., `test@example.com` / `qqqqqq9!`)
2. **API Key Generation**: Upon successful login, GrowERP returns an API key
3. **MCP Access**: Client includes API key in requests to MCP endpoints
4. **Authorization Check**: MCP validates the API key and checks `AppSupport` classification

## API Key Usage

### Header Format
```
api_key: <your_api_key_here>
```

### Test Credentials
- **Username**: `test@example.com`
- **Password**: `qqqqqq9!`
- **Classification**: `AppSupport`

## Protected Endpoints

All MCP REST endpoints now require authentication:

- `GET /rest/s1/mcp/health` - Health check
- `GET /rest/s1/mcp/tools` - List available tools  
- `GET /rest/s1/mcp/resources` - List available resources
- `GET /rest/s1/mcp/prompts` - List available prompts
- `POST /rest/s1/mcp/protocol` - MCP protocol endpoint
- `POST /rest/s1/mcp/mcp` - Legacy MCP endpoint

## Implementation Details

### Services Created

1. **`McpAuthServices.validate#McpApiKey`**
   - Validates API key against GrowERP authentication
   - Checks for `AppSupport` classification
   - Returns authentication status and user details

2. **`McpAuthServices.check#McpAuthorization`**
   - Comprehensive authorization check
   - Validates API key and checks permissions
   - Used by all MCP service operations

### Authorization Levels

- **Read Operations**: Requires valid API key with `AppSupport` classification
- **Execute Operations**: Requires valid API key + additional MCP execution permissions (if configured)

### Error Responses

**401 Unauthorized** - Invalid or missing API key
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "error": {
    "code": -32001,
    "message": "Authorization failed: API key required for MCP access"
  }
}
```

**403 Forbidden** - Valid API key but insufficient permissions
```json
{
  "jsonrpc": "2.0", 
  "id": 1,
  "error": {
    "code": -32001,
    "message": "Authorization failed: Execute permission required for MCP tool operations"
  }
}
```

## Testing

### Manual Testing

1. **Login to get API key**:
```bash
curl -X POST "http://localhost:8080/rest/s1/growerp/100/Login" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "test@example.com",
    "password": "qqqqqq9!",
    "classificationId": "AppSupport"
  }'
```

2. **Use API key for MCP requests**:
```bash
curl -X GET "http://localhost:8080/rest/s1/mcp/health" \
  -H "api_key: YOUR_API_KEY_HERE"
```

3. **Test MCP Protocol**:
```bash
curl -X POST "http://localhost:8080/rest/s1/mcp/protocol" \
  -H "Content-Type: application/json" \
  -H "api_key: YOUR_API_KEY_HERE" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/list",
    "id": 1
  }'
```

### Automated Testing

Run the provided test script:
```bash
cd /home/hans/growerp/moqui/runtime/component/mcp
groovy test_mcp_auth.groovy
```

## Configuration

### Security Settings

The authorization can be customized by modifying the classification check in `McpAuthServices.xml`. Currently set to require `AppSupport` classification.

### Permission System Integration

Future enhancements can add more granular permissions by creating MCP-specific permission entities in Moqui and checking them in the authorization service.

## Frontend Integration

Frontend clients should:

1. Store the API key received during login
2. Include the API key in all MCP requests
3. Handle 401/403 errors by redirecting to login
4. Refresh API keys as needed

## Security Considerations

1. **API Key Storage**: Store API keys securely on the client side
2. **HTTPS**: Always use HTTPS in production to protect API keys in transit
3. **Key Rotation**: Implement API key rotation policies as needed
4. **Audit Logging**: All MCP operations are logged with user context
5. **Rate Limiting**: Consider implementing rate limiting for MCP endpoints

## Migration Notes

Existing MCP clients will need to be updated to include API key authentication. The endpoints that previously allowed anonymous access now require authentication.

## Troubleshooting

### Common Issues

1. **"API key required"**: Ensure API key is included in request headers
2. **"Invalid API key"**: Verify the API key is correct and user account is active
3. **"User not authorized for classification"**: Ensure user has `AppSupport` classification
4. **"Authentication validation failed"**: Check Moqui logs for detailed error messages

### Debug Logging

Enable debug logging in `MoquiDevConf.xml`:
```xml
<logger name="McpAuthServices" level="DEBUG"/>
<logger name="McpServices" level="DEBUG"/>
```
