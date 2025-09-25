#!/bin/bash

# Test script for MCP server protocol compliance

echo "Testing GrowERP MCP Server..."
echo "============================="

BASE_URL="http://localhost:8080/rest/s1/mcp/protocol"

echo "1. Testing initialize..."
curl -s -X POST "$BASE_URL" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc": "2.0", "method": "initialize", "params": {"protocolVersion": "2024-11-05", "clientInfo": {"name": "test-client", "version": "1.0.0"}}, "id": 1}'
echo ""
echo ""

echo "2. Testing tools/list..."
curl -s -X POST "$BASE_URL" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc": "2.0", "method": "tools/list", "params": {}, "id": 2}'
echo ""
echo ""

echo "3. Testing ping..."
curl -s -X POST "$BASE_URL" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc": "2.0", "method": "ping", "params": {}, "id": 3}'
echo ""
echo ""

echo "4. Testing tools/call (ping_system)..."
curl -s -X POST "$BASE_URL" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc": "2.0", "method": "tools/call", "params": {"name": "ping_system", "arguments": {}}, "id": 4}'
echo ""
echo ""

echo "5. Testing unknown method..."
curl -s -X POST "$BASE_URL" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc": "2.0", "method": "unknown", "params": {}, "id": 5}'
echo ""
echo ""

echo "6. Testing invalid JSON..."
curl -s -X POST "$BASE_URL" \
  -H "Content-Type: application/json" \
  -d 'invalid json'
echo ""
echo ""

echo "Testing complete!"
