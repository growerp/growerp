#!/bin/bash

# Screen Infrastructure Test Runner for MCP
# This script runs comprehensive screen infrastructure tests

set -e

echo "🖥️  MCP Screen Infrastructure Test Runner"
echo "======================================"

# Check if MCP server is running
echo "🔍 Checking MCP server status..."
if ! curl -s -u "john.sales:opencode" "http://localhost:8080/mcp" > /dev/null; then
    echo "❌ MCP server is not running at http://localhost:8080/mcp"
    echo "Please start the server first:"
    echo "  cd moqui-mcp-2 && ../gradlew run --daemon > ../server.log 2>&1 &"
    exit 1
fi

echo "✅ MCP server is running"

# Set classpath
CLASSPATH="lib/*:build/libs/*:../framework/build/libs/*:../runtime/lib/*"

# Run screen infrastructure tests
echo ""
echo "🧪 Running Screen Infrastructure Tests..."
echo "======================================="

cd "$(dirname "$0")/.."

if groovy -cp "$CLASSPATH" screen/ScreenInfrastructureTest.groovy; then
    echo ""
    echo "✅ Screen infrastructure tests completed successfully"
else
    echo ""
    echo "❌ Screen infrastructure tests failed"
    exit 1
fi

echo ""
echo "🎉 All screen tests completed!"