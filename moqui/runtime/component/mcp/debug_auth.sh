#!/bin/bash

# Debug authentication in MCP
BASE_URL="http://localhost:8080"

echo "=== Debug MCP Authentication ==="
echo ""

# Test direct call to list#Tools service 
echo "Testing direct call to list#Tools service..."
TOOLS_RESPONSE=$(curl -s -X GET "${BASE_URL}/rest/s1/mcp/tools")
echo "Tools Response: $TOOLS_RESPONSE"
echo ""

# Test validation service directly
echo "Testing API key validation service..."
VALIDATE_RESPONSE=$(curl -s -X POST "${BASE_URL}/rest/s1/mcp/auth/prompt")
echo "Validation Response: $VALIDATE_RESPONSE"
echo ""

# Test with explicit empty api_key header
echo "Testing with empty api_key header..."
EMPTY_KEY_RESPONSE=$(curl -s -X POST "${BASE_URL}/rest/s1/mcp/protocol" \
  -H "Content-Type: application/json" \
  -H "api_key:" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/list",
    "id": 1
  }')
echo "Empty Key Response: $EMPTY_KEY_RESPONSE"
echo ""

# Test with invalid api_key header
echo "Testing with invalid api_key header..."
INVALID_KEY_RESPONSE=$(curl -s -X POST "${BASE_URL}/rest/s1/mcp/protocol" \
  -H "Content-Type: application/json" \
  -H "api_key: invalid_key_123" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/list",
    "id": 1
  }')
echo "Invalid Key Response: $INVALID_KEY_RESPONSE"
echo ""

echo "=== End Debug ==="
