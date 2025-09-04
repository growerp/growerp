#!/bin/bash

# Test script for MCP server protocol compliance

echo "Testing GrowERP MCP Server..."
echo "============================="

MCP_SERVER="groovy /home/hans/growerp/moqui/runtime/component/mcp/mcp-stdio-server-simple.groovy"

echo "1. Testing initialize..."
echo '{"jsonrpc": "2.0", "method": "initialize", "params": {"protocolVersion": "2024-11-05", "clientInfo": {"name": "test-client", "version": "1.0.0"}}, "id": 1}' | $MCP_SERVER 2>/dev/null
echo ""

echo "2. Testing tools/list..."
echo '{"jsonrpc": "2.0", "method": "tools/list", "params": {}, "id": 2}' | $MCP_SERVER 2>/dev/null  
echo ""

echo "3. Testing ping..."
echo '{"jsonrpc": "2.0", "method": "ping", "params": {}, "id": 3}' | $MCP_SERVER 2>/dev/null
echo ""

echo "4. Testing tools/call (ping_system)..."
echo '{"jsonrpc": "2.0", "method": "tools/call", "params": {"name": "ping_system", "arguments": {}}, "id": 4}' | $MCP_SERVER 2>/dev/null
echo ""

echo "5. Testing unknown method..."
echo '{"jsonrpc": "2.0", "method": "unknown", "params": {}, "id": 5}' | $MCP_SERVER 2>/dev/null
echo ""

echo "6. Testing invalid JSON..."
echo 'invalid json' | $MCP_SERVER 2>/dev/null
echo ""

echo "Testing complete!"
