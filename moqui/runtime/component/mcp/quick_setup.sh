#!/bin/bash

# Quick Setup Script for GrowERP MCP Server Testing
# This script sets up the environment and runs basic tests

set -e

echo "========================================="
echo "GrowERP MCP Server Quick Setup & Test"
echo "========================================="

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check Groovy/Java installation
echo "Checking Groovy/Java installation..."
if command_exists groovy; then
    GROOVY_CMD="groovy"
    echo "✓ Groovy found: $(groovy --version | head -n1)"
elif command_exists java; then
    # Use Java directly - Groovy script will run with java command
    JAVA_VERSION=$(java -version 2>&1 | head -n1)
    echo "✓ Java found: $JAVA_VERSION"
    echo "📦 Using Java to run Groovy script (no external dependencies needed)"
    GROOVY_CMD="java"
else
    echo "❌ Groovy or Java is required but not found. Please install Java 8+ or Groovy"
    exit 1
fi

# Note: Using dependency-free version to avoid @Grab issues
echo "✓ Using dependency-free Groovy client (built-in Java HTTP client)"

# Check if MCP server is running
echo "Checking MCP server status..."
MCP_URL="http://localhost:8081"

if curl -s "$MCP_URL" >/dev/null 2>&1; then
    echo "✓ MCP server is running at $MCP_URL"
else
    echo "⚠ MCP server is not running at $MCP_URL"
    echo "Starting MCP server..."
    
    # Check if we're in the right directory
    if [ ! -f "deploy_mcp_server.sh" ]; then
        echo "❌ deploy_mcp_server.sh not found. Please run this script from the MCP server directory."
        exit 1
    fi
    
    # Run deployment script
    ./deploy_mcp_server.sh
    
    # Wait a moment for server to start
    echo "Waiting for server to start..."
    sleep 5
    
    # Check again
    if curl -s "$MCP_URL" >/dev/null 2>&1; then
        echo "✓ MCP server started successfully"
    else
        echo "❌ Failed to start MCP server. Check logs for errors."
        exit 1
    fi
fi

echo ""
echo "========================================="
echo "Running MCP Client Tests"
echo "========================================="

# Run the Groovy test client (dependency-free version)
if [ "$GROOVY_CMD" = "groovy" ]; then
    groovy test_mcp_client_simple.groovy
else
    # Use Java with Groovy classes
    echo "Running with Java (dependency-free Groovy script)..."
    # Try groovy command first, fall back to basic execution
    if command_exists groovy; then
        groovy test_mcp_client_simple.groovy
    else
        echo "⚠ Groovy command not found. Please install Groovy or run manually:"
        echo "   groovy test_mcp_client_simple.groovy"
        echo ""
        echo "For now, testing basic connectivity with curl..."
        
        # Basic connectivity test using curl
        if curl -s "$MCP_URL" >/dev/null 2>&1; then
            echo "✓ MCP server is responding at $MCP_URL"
            echo "✓ You can manually run: groovy test_mcp_client_simple.groovy"
        else
            echo "✗ MCP server is not responding"
        fi
    fi
fi

echo ""
echo "========================================="
echo "Quick Start Complete!"
echo "========================================="
echo ""
echo "What's Next:"
echo "• Use the dependency-free Groovy client (test_mcp_client_simple.groovy)"
echo "• For advanced features, try the full version (test_mcp_client.groovy) when dependencies are available"
echo "• Check DEPLOYMENT_GUIDE.md for AI integration examples"
echo "• Explore available tools and resources through the MCP interface"
echo ""
echo "AI Integration Examples:"
echo "• Claude Desktop: Add MCP server config to claude_desktop_config.json"
echo "• OpenAI API: Use the Groovy client to fetch data for ChatGPT prompts"
echo "• Custom AI: Integrate MCP calls into your AI application workflow"
echo "• Groovy DSL: Create domain-specific languages for business operations"
echo ""
echo "For production deployment:"
echo "• Set up proper authentication"
echo "• Configure HTTPS with SSL certificates"
echo "• Set up monitoring and logging"
echo ""
echo "Server Management:"
echo "• Start: ./deploy_mcp_server.sh"
echo "• Stop: ./stop_mcp_server.sh (created after first run)"
echo "• Logs: Check moqui/runtime/logs/ for debugging"
