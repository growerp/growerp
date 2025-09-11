# GrowERP MCP Authentication Test Commands

This document provides complete curl commands for testing the MCP authentication system.

## 1. Test Authentication Prompt (No Auth)

```bash
curl -X POST http://localhost:8080/rest/s1/mcp/protocol \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "tools/call",
    "params": {
      "name": "get_companies",
      "arguments": {}
    }
  }' | jq .
```

Expected: Authentication prompt with login details.

## 2. Login and Get API Key

```bash
curl -s -X POST "http://localhost:8080/rest/s1/mcp/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username": "test@example.com", "password": "qqqqqq9!", "classificationId": "AppSupport", "requestId": 2}' | jq -r '.apiKey'
```

Expected: Success response with API key.

## 3. Use API Key for Tool Access

First, extract the API key from the login response:

```bash
API_KEY=$(curl -s -X POST http://localhost:8080/rest/s1/mcp/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 2,
    "method": "login",
    "params": {
      "username": "test@example.com",
      "password": "qqqqqq9!",
      "classificationId": "AppSupport"
    }
  }' | jq -r '.loginResponse.result.apiKey')

echo "API Key: $API_KEY"
```

Then use it to access protected tools:

```bash
curl -X POST http://localhost:8080/rest/s1/mcp/protocol \
  -H "Content-Type: application/json" \
  -H "api_key: $API_KEY" \
  -d '{
    "jsonrpc": "2.0",
    "id": 3,
    "method": "tools/call",
    "params": {
      "name": "get_companies",
      "arguments": {}
    }
  }' | jq .
```

Expected: List of companies without authentication prompt.

## 4. One-liner Test with Extracted API Key

```bash
API_KEY=$(curl -s -X POST http://localhost:8080/rest/s1/mcp/auth/login -H "Content-Type: application/json" -d '{"jsonrpc": "2.0", "id": 2, "method": "login", "params": {"username": "test@example.com", "password": "qqqqqq9!", "classificationId": "AppSupport"}}' | jq -r '.loginResponse.result.apiKey') && curl -X POST http://localhost:8080/rest/s1/mcp/protocol -H "Content-Type: application/json" -H "api_key: $API_KEY" -d '{"jsonrpc": "2.0", "id": 3, "method": "tools/call", "params": {"name": "get_companies", "arguments": {}}}' | jq .
```

## 5. Test Login via MCP Protocol

```bash
curl -X POST http://localhost:8080/rest/s1/mcp/protocol \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 4,
    "method": "auth/login",
    "params": {
      "username": "test@example.com",
      "password": "qqqqqq9!",
      "classificationId": "AppSupport"
    }
  }' | jq .
```

## 6. Test Invalid API Key

```bash
curl -X POST http://localhost:8080/rest/s1/mcp/protocol \
  -H "Content-Type: application/json" \
  -H "api_key: invalid-key-123" \
  -d '{
    "jsonrpc": "2.0",
    "id": 5,
    "method": "tools/call",
    "params": {
      "name": "get_companies",
      "arguments": {}
    }
  }' | jq .
```

Expected: Authentication prompt due to invalid key.

## 7. Test Direct Auth Prompt Endpoint

```bash
curl -X POST http://localhost:8080/rest/s1/mcp/auth/prompt \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": "5",
    "method": "prompt",
    "params": {
      "reason": "Testing direct prompt endpoint"
    }
  }' | jq .
```

## Notes

- All commands use `jq .` for pretty JSON formatting
- The API key has a length of 40 characters
- Authentication prompts include test credentials: `test@example.com` / `qqqqqq9!`
- The `api_key` header name is case-sensitive
- API keys are generated fresh with each login

## Troubleshooting

If you get connection errors, ensure:
1. Moqui is running: `cd /home/hans/growerp/moqui && java -jar moqui.war no-run-es`
2. The MCP component is properly deployed and loaded
3. jq is installed for JSON parsing: `sudo apt install jq`
