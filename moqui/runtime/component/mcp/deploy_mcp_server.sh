#!/bin/bash

# GrowERP MCP Server Deployment Script
set -e

echo "=========================================="
echo "GrowERP MCP Server Deployment"
echo "=========================================="

# Configuration
MOQUI_DIR="/home/hans/growerp/moqui"
MCP_PORT=${MCP_PORT:-8081}
MCP_HOST=${MCP_HOST:-"0.0.0.0"}
BACKEND_PORT=${BACKEND_PORT:-8080}

cd "$MOQUI_DIR"

# Function to check if a port is in use
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null ; then
        return 0  # Port is in use
    else
        return 1  # Port is free
    fi
}

# Function to wait for backend to be ready
wait_for_backend() {
    echo "Waiting for Moqui backend to be ready..."
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s "http://localhost:$BACKEND_PORT/status" >/dev/null 2>&1; then
            echo "✓ Backend is ready!"
            return 0
        fi
        echo "  Attempt $attempt/$max_attempts - Backend not ready yet..."
        sleep 2
        attempt=$((attempt + 1))
    done
    
    echo "✗ Backend failed to start within timeout"
    return 1
}

# Step 1: Check if backend is already running
if check_port $BACKEND_PORT; then
    echo "✓ Moqui backend already running on port $BACKEND_PORT"
else
    echo "Starting Moqui backend..."
    
    # Check if database is initialized
    if [ ! -d "runtime/db/h2" ]; then
        echo "Initializing database..."
        java -jar moqui.war load types=seed,seed-initial,install no-run-es
    fi
    
    # Start backend in background
    echo "Starting Moqui backend on port $BACKEND_PORT..."
    nohup java -jar moqui.war no-run-es > runtime/log/moqui-startup.log 2>&1 &
    echo $! > runtime/moqui.pid
    
    # Wait for backend to be ready
    if ! wait_for_backend; then
        echo "Failed to start backend. Check logs in runtime/log/"
        exit 1
    fi
fi

# Step 2: Create MCP server configuration
echo "Configuring MCP server..."

MCP_CONFIG='{
    "serverId": "main-mcp-server",
    "port": '$MCP_PORT',
    "host": "'$MCP_HOST'",
    "enabled": true,
    "description": "Main GrowERP MCP Server for AI Integration"
}'

# Try to create/update MCP server configuration
echo "Creating MCP server configuration..."
RESPONSE=$(curl -s -w "%{http_code}" -X POST "http://localhost:$BACKEND_PORT/rest/s1/mcp/servers" \
    -H "Content-Type: application/json" \
    -d "$MCP_CONFIG" || echo "000")

if [ "${RESPONSE: -3}" = "200" ] || [ "${RESPONSE: -3}" = "201" ]; then
    echo "✓ MCP server configuration created"
elif [ "${RESPONSE: -3}" = "409" ]; then
    echo "✓ MCP server configuration already exists"
else
    echo "Warning: Failed to create MCP server configuration (HTTP: ${RESPONSE: -3})"
    echo "Continuing with default configuration..."
fi

# Step 3: Start MCP server
echo "Starting MCP server on port $MCP_PORT..."

RESPONSE=$(curl -s -w "%{http_code}" -X POST "http://localhost:$BACKEND_PORT/rest/s1/mcp/servers/main-mcp-server/start" || echo "000")

if [ "${RESPONSE: -3}" = "200" ]; then
    echo "✓ MCP server started successfully"
else
    echo "Warning: Failed to start MCP server via API (HTTP: ${RESPONSE: -3})"
    echo "Trying direct startup..."
    
    # Alternative: Start MCP server directly (if API fails)
    # This would require implementing a direct startup method
fi

# Step 4: Verify MCP server is running
echo "Verifying MCP server..."
sleep 3

if check_port $MCP_PORT; then
    echo "✓ MCP server is running on port $MCP_PORT"
    
    # Test MCP server response
    echo "Testing MCP server connectivity..."
    MCP_RESPONSE=$(curl -s "http://localhost:$MCP_PORT/" -H "Accept: application/json" || echo "")
    
    if echo "$MCP_RESPONSE" | grep -q "growerp-mcp-server"; then
        echo "✓ MCP server responding correctly"
    else
        echo "⚠ MCP server may not be responding properly"
    fi
else
    echo "✗ MCP server failed to start on port $MCP_PORT"
    exit 1
fi

echo ""
echo "=========================================="
echo "✓ GrowERP MCP Server Deployment Complete!"
echo "=========================================="
echo ""
echo "Server Details:"
echo "  - Backend URL:    http://localhost:$BACKEND_PORT"
echo "  - MCP Server URL: http://localhost:$MCP_PORT"
echo "  - Host:           $MCP_HOST"
echo ""
echo "Test the server:"
echo "  curl http://localhost:$MCP_PORT/"
echo ""
echo "View logs:"
echo "  tail -f runtime/log/moqui.log"
echo ""
echo "Stop servers:"
echo "  ./stop_mcp_server.sh"
echo ""

# Create stop script
cat > stop_mcp_server.sh << 'EOF'
#!/bin/bash
echo "Stopping GrowERP MCP Server..."

# Stop MCP server via API
curl -s -X POST "http://localhost:8080/rest/s1/mcp/servers/main-mcp-server/stop" || true

# Stop Moqui backend if we started it
if [ -f runtime/moqui.pid ]; then
    PID=$(cat runtime/moqui.pid)
    if kill -0 $PID 2>/dev/null; then
        echo "Stopping Moqui backend (PID: $PID)..."
        kill $PID
        sleep 5
        if kill -0 $PID 2>/dev/null; then
            echo "Force killing backend..."
            kill -9 $PID
        fi
    fi
    rm -f runtime/moqui.pid
fi

echo "✓ Servers stopped"
EOF

chmod +x stop_mcp_server.sh

echo "=========================================="
