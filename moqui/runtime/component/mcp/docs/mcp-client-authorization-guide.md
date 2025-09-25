# MCP Client Authorization Guide

This comprehensive guide covers how to configure MCP clients (Claude Desktop, Python clients, etc.) to authenticate with the GrowERP MCP Server's OAuth-enabled endpoints.

## 🔒 Overview

The GrowERP MCP Server is an **OAuth-enabled server** that supports multiple authentication methods for maximum compatibility with different MCP clients and integration scenarios.

### Supported Authentication Methods

1. **OAuth 2.0 Password Flow** - Full OAuth implementation with discovery endpoint
2. **API Key Authentication** - Simple token-based authentication 
3. **Manual Headers** - Direct header specification for custom integrations
4. **Combined Authentication** - Multiple methods in a single configuration

## 🚀 Quick Start

### Method 1: OAuth 2.0 (Recommended)

Create a YAML configuration file for OAuth authentication:

```yaml
# ~/.config/claude-desktop/mcp-config.yaml
mcpServers:
  growerp-system:
    command: "node"
    args: ["-e", "/* MCP client implementation */"]
    oauth:
      discovery_url: "http://localhost:8080/rest/s1/mcp/auth/discovery"
      client_id: "mcp-client"
      username: "admin"
      password: "ofbiz"
      grant_type: "password"
```

### Method 2: API Key (Simple)

For JSON-based configurations:

```json
{
  "mcpServers": {
    "growerp-system": {
      "command": "python",
      "args": ["-m", "mcp_client"],
      "env": {
        "MCP_SERVER_URL": "http://localhost:8080/rest/s1/mcp/protocol",
        "API_KEY": "demo-token-12345"
      }
    }
  }
}
```

## 📋 Detailed Configuration Options

### OAuth 2.0 Configuration

#### YAML Format (Preferred for OAuth)

```yaml
# mcp-config.yaml
mcpServers:
  growerp-system:
    command: "python"
    args: ["-m", "growerp_mcp_client"]
    oauth:
      discovery_url: "http://localhost:8080/rest/s1/mcp/auth/discovery"
      client_id: "mcp-client"
      username: "admin"          # Your GrowERP username
      password: "ofbiz"          # Your GrowERP password  
      grant_type: "password"
      scope: "mcp-access"        # Optional scope
      timeout: 30                # Optional timeout in seconds
    env:
      MCP_LOG_LEVEL: "INFO"
```

#### JSON Format (Alternative)

```json
{
  "mcpServers": {
    "growerp-system": {
      "command": "python",
      "args": ["-m", "growerp_mcp_client"],
      "oauth": {
        "discovery_url": "http://localhost:8080/rest/s1/mcp/auth/discovery",
        "client_id": "mcp-client",
        "username": "admin",
        "password": "ofbiz",
        "grant_type": "password"
      }
    }
  }
}
```

### API Key Configuration

#### Environment Variables

```json
{
  "mcpServers": {
    "growerp-system": {
      "command": "python",
      "args": ["-m", "mcp_client"],
      "env": {
        "MCP_SERVER_URL": "http://localhost:8080/rest/s1/mcp/protocol",
        "API_KEY": "demo-token-12345",
        "MCP_TIMEOUT": "30"
      }
    }
  }
}
```

#### Direct Configuration

```json
{
  "mcpServers": {
    "growerp-system": {
      "command": "python", 
      "args": ["-m", "mcp_client"],
      "config": {
        "serverUrl": "http://localhost:8080/rest/s1/mcp/protocol",
        "apiKey": "demo-token-12345",
        "headers": {
          "X-API-Key": "demo-token-12345",
          "Content-Type": "application/json"
        }
      }
    }
  }
}
```

### Manual Headers Configuration

For advanced custom integrations:

```json
{
  "mcpServers": {
    "growerp-system": {
      "command": "custom-mcp-client",
      "args": ["--server", "http://localhost:8080/rest/s1/mcp/protocol"],
      "headers": {
        "Authorization": "Bearer demo-token-12345",
        "X-API-Key": "demo-token-12345", 
        "X-Client-Version": "1.0.0",
        "Accept": "application/json",
        "Content-Type": "application/json"
      }
    }
  }
}
```

### Combined Authentication (Maximum Compatibility)

Support multiple authentication methods in a single configuration:

```json
{
  "mcpServers": {
    "growerp-system": {
      "command": "python",
      "args": ["-m", "universal_mcp_client"],
      "oauth": {
        "discovery_url": "http://localhost:8080/rest/s1/mcp/auth/discovery",
        "client_id": "mcp-client", 
        "username": "admin",
        "password": "ofbiz",
        "grant_type": "password"
      },
      "configFile": "./mcp-fallback-config.yaml",
      "headers": {
        "X-API-Key": "demo-token-12345",
        "X-Fallback-Auth": "enabled"
      },
      "env": {
        "MCP_SERVER_URL": "http://localhost:8080/rest/s1/mcp/protocol",
        "API_KEY": "demo-token-12345"
      }
    }
  }
}
```

## 🆕 OAuth 2.0 Server Implementation

The GrowERP MCP Server now supports **full OAuth 2.0 authentication** alongside API key authentication. This makes it compatible with more MCP clients and provides standard OAuth flows.

### OAuth 2.0 Endpoints

- **Discovery**: `http://localhost:8080/rest/s1/mcp/auth/discovery`
- **Token**: `http://localhost:8080/rest/s1/mcp/auth/token`  
- **User Info**: `http://localhost:8080/rest/s1/mcp/auth/userinfo`
- **JWKS**: `http://localhost:8080/rest/s1/mcp/auth/jwks`

### OAuth 2.0 Flow Testing

```bash
# 1. Discovery
curl -s http://localhost:8080/rest/s1/mcp/auth/discovery | jq .

# 2. Get Token
curl -s -X POST http://localhost:8080/rest/s1/mcp/auth/token \
  -H "Content-Type: application/json" \
  -d '{
    "grantType": "password",
    "username": "test@example.com",
    "password": "qqqqqq9!",
    "clientId": "mcp-client"
  }' | jq .

# 3. Use Token
curl -s -X POST http://localhost:8080/rest/s1/mcp/protocol \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/list","id":1}' | jq .
```

## 🔧 Client-Specific Configuration

### Claude Desktop Configuration

Claude Desktop supports both JSON and YAML configurations:

#### Option 1: settings.json (Main config)
```json
{
  "mcpServers": {
    "growerp-system": {
      "oauth": {
        "discovery_url": "http://localhost:8080/rest/s1/mcp/auth/discovery",
        "client_id": "mcp-client",
        "username": "admin", 
        "password": "ofbiz",
        "grant_type": "password"
      }
    }
  }
}
```

#### Option 2: External YAML file
```json
{
  "mcpServers": {
    "growerp-system": {
      "configFile": "./mcp-config.yaml"
    }
  }
}
```

### Python MCP Client

```python
# Example Python client configuration
import json
from mcp_client import MCPClient

config = {
    "server_url": "http://localhost:8080/rest/s1/mcp/protocol",
    "oauth": {
        "discovery_url": "http://localhost:8080/rest/s1/mcp/auth/discovery",
        "client_id": "mcp-client",
        "username": "admin",
        "password": "ofbiz", 
        "grant_type": "password"
    },
    "fallback_api_key": "demo-token-12345"
}

client = MCPClient(config)
```

### Node.js MCP Client

```javascript
// Example Node.js client configuration
const { MCPClient } = require('@modelcontextprotocol/client');

const config = {
  serverUrl: 'http://localhost:8080/rest/s1/mcp/protocol',
  oauth: {
    discoveryUrl: 'http://localhost:8080/rest/s1/mcp/auth/discovery',
    clientId: 'mcp-client',
    username: 'admin',
    password: 'ofbiz',
    grantType: 'password'
  },
  headers: {
    'X-API-Key': 'demo-token-12345'
  }
};

const client = new MCPClient(config);
```

## 🔍 OAuth Discovery Endpoint

The GrowERP MCP Server provides OAuth discovery at:

```
GET http://localhost:8080/rest/s1/mcp/auth/discovery
```

### Discovery Response

```json
{
  "issuer": "http://localhost:8080/rest/s1/mcp/auth",
  "authorization_endpoint": "http://localhost:8080/rest/s1/mcp/auth/authorize", 
  "token_endpoint": "http://localhost:8080/rest/s1/mcp/auth/token",
  "userinfo_endpoint": "http://localhost:8080/rest/s1/mcp/auth/userinfo",
  "jwks_uri": "http://localhost:8080/rest/s1/mcp/auth/jwks",
  "grant_types_supported": ["password", "client_credentials"],
  "response_types_supported": ["token"],
  "scopes_supported": ["mcp-access", "read", "write"],
  "token_endpoint_auth_methods_supported": ["client_secret_post", "client_secret_basic"]
}
```

## 🔑 Authentication Flow

### OAuth 2.0 Password Flow

1. **Discovery**: Client fetches OAuth configuration from discovery endpoint
2. **Token Request**: Client sends username/password to token endpoint  
3. **Token Response**: Server returns access token
4. **API Calls**: Client uses token for MCP protocol requests

### API Key Flow

1. **Token Generation**: Get API key from GrowERP admin or use demo token
2. **Header Setup**: Include API key in X-API-Key header
3. **Direct Access**: Make MCP protocol requests with API key

## 🛠️ Testing Authentication

### Test OAuth Configuration

```bash
#!/bin/bash
# test_oauth_config.sh

DISCOVERY_URL="http://localhost:8080/rest/s1/mcp/auth/discovery"
TOKEN_URL="http://localhost:8080/rest/s1/mcp/auth/token"

echo "🔍 Testing OAuth Discovery..."
curl -s "$DISCOVERY_URL" | jq .

echo -e "\n🔑 Testing Token Request..."
curl -s -X POST "$TOKEN_URL" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password&client_id=mcp-client&username=admin&password=ofbiz" | jq .
```

### Test API Key Configuration

```bash
#!/bin/bash
# test_api_key.sh

API_KEY="demo-token-12345"
MCP_URL="http://localhost:8080/rest/s1/mcp/protocol"

echo "🔑 Testing API Key Authentication..."
curl -s -X POST "$MCP_URL" \
  -H "X-API-Key: $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/list","id":1}' | jq .
```

### Complete Integration Test

```bash
#!/bin/bash
# test_complete_auth.sh

echo "🧪 Complete MCP Authentication Test"
echo "=================================="

# Test 1: OAuth Discovery
echo "1️⃣ OAuth Discovery Test..."
DISCOVERY=$(curl -s "http://localhost:8080/rest/s1/mcp/auth/discovery")
if echo "$DISCOVERY" | jq -e '.token_endpoint' >/dev/null; then
    echo "✅ OAuth discovery working"
else
    echo "❌ OAuth discovery failed"
fi

# Test 2: Token Request
echo -e "\n2️⃣ Token Request Test..."
TOKEN_RESPONSE=$(curl -s -X POST "http://localhost:8080/rest/s1/mcp/auth/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password&client_id=mcp-client&username=admin&password=ofbiz")

ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r '.access_token // empty')
if [ -n "$ACCESS_TOKEN" ]; then
    echo "✅ Token request successful"
else
    echo "❌ Token request failed"
fi

# Test 3: MCP Protocol with OAuth
echo -e "\n3️⃣ MCP Protocol with OAuth..."
if [ -n "$ACCESS_TOKEN" ]; then
    MCP_OAUTH=$(curl -s -X POST "http://localhost:8080/rest/s1/mcp/protocol" \
      -H "Authorization: Bearer $ACCESS_TOKEN" \
      -H "Content-Type: application/json" \
      -d '{"jsonrpc":"2.0","method":"tools/list","id":1}')
    
    if echo "$MCP_OAUTH" | jq -e '.result.tools' >/dev/null; then
        echo "✅ MCP OAuth protocol working"
    else
        echo "❌ MCP OAuth protocol failed"
    fi
fi

# Test 4: MCP Protocol with API Key
echo -e "\n4️⃣ MCP Protocol with API Key..."
MCP_API_KEY=$(curl -s -X POST "http://localhost:8080/rest/s1/mcp/protocol" \
  -H "X-API-Key: demo-token-12345" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/list","id":1}')

if echo "$MCP_API_KEY" | jq -e '.result.tools' >/dev/null; then
    echo "✅ MCP API Key protocol working"
else
    echo "❌ MCP API Key protocol failed"  
fi

echo -e "\n🎉 Authentication test complete!"
```

## 🚨 Troubleshooting

### Common Issues

#### 1. OAuth Discovery Not Found
```
Error: Discovery endpoint not responding
```
**Solution**: Ensure GrowERP backend is running on `http://localhost:8080`

#### 2. Invalid Credentials
```
Error: 401 Unauthorized - Invalid username or password
```
**Solution**: Verify username/password. Default is `admin`/`ofbiz`

#### 3. API Key Rejected
```
Error: 403 Forbidden - Invalid API key
```
**Solution**: Use valid API key like `demo-token-12345` or generate new one

#### 4. CORS Issues
```
Error: Access-Control-Allow-Origin header missing
```
**Solution**: Configure CORS in GrowERP or use server-side MCP client

### Debug Configuration

Enable detailed logging in your MCP client:

```json
{
  "mcpServers": {
    "growerp-system": {
      "oauth": { /* oauth config */ },
      "env": {
        "MCP_LOG_LEVEL": "DEBUG",
        "MCP_TRACE_REQUESTS": "true",
        "MCP_DEBUG_AUTH": "true"
      }
    }
  }
}
```

### Manual Testing

Test your configuration manually:

```bash
# Test OAuth flow manually
curl -X POST "http://localhost:8080/rest/s1/mcp/auth/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password&client_id=mcp-client&username=YOUR_USERNAME&password=YOUR_PASSWORD"

# Test MCP protocol with resulting token
curl -X POST "http://localhost:8080/rest/s1/mcp/protocol" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/list","id":1}'
```

## 📚 Related Documentation

- **[API Reference](api-reference.md)** - Complete tool and resource documentation
- **[Security Guide](security-guide.md)** - Production security recommendations  
- **[Quick Start](quick-start.md)** - Fast setup for testing
- **[Examples](examples.md)** - Code examples in multiple languages
- **[Troubleshooting](troubleshooting.md)** - Common issues and solutions

## 🔗 Configuration Examples Repository

Find complete working examples in the `examples/` directory:

- `examples/claude-desktop-config.json` - Claude Desktop configuration
- `examples/python-client-config.py` - Python client setup
- `examples/nodejs-client-config.js` - Node.js client setup  
- `examples/oauth-test-suite.sh` - Complete OAuth testing

## 📞 Support

For authentication issues:

1. **Check Prerequisites**: Ensure GrowERP backend is running
2. **Validate Credentials**: Test username/password manually
3. **Review Logs**: Enable debug logging in MCP client
4. **Test Endpoints**: Use cURL to verify OAuth/API endpoints
5. **File Issues**: Report bugs with configuration details

---

**Last Updated**: December 2024  
**Version**: 1.0 (OAuth-enabled Server)  
**Compatibility**: All MCP clients supporting OAuth 2.0 or API keys