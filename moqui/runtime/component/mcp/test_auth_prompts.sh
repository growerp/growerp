#!/bin/bash

# Test MCP Authentication Prompts
# Tests the AI authentication prompt functionality

BASE_URL="http://localhost:8080"
USERNAME="test@example.com"
PASSWORD="qqqqqq9!"
CLASSIFICATION="AppSupport"

echo "=== GrowERP MCP Authentication Prompt Test ==="
echo ""

# Step 1: Test MCP endpoint without authentication - should get auth prompt
echo "Step 1: Testing get_companies tool without authentication (should get auth prompt)..."
echo "Making request to: ${BASE_URL}/rest/s1/mcp/protocol"

# First, ensure we logout any existing sessions
curl -s -X POST "${BASE_URL}/rest/s1/growerp/logout" > /dev/null

PROMPT_RESPONSE=$(curl -s -X POST "${BASE_URL}/rest/s1/mcp/protocol" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc": "2.0", "method": "tools/call", "params": {"name": "get_companies", "arguments": {"limit": 3}}, "id": 1}')

echo "Response: $PROMPT_RESPONSE"
echo ""

# Also test with explicit empty headers to ensure no cached auth
echo "Step 1b: Testing with explicit empty api_key header..."
EMPTY_KEY_RESPONSE=$(curl -s -X POST "${BASE_URL}/rest/s1/mcp/protocol" \
  -H "Content-Type: application/json" \
  -H "api_key: " \
  -d '{"jsonrpc": "2.0", "method": "tools/call", "params": {"name": "get_companies", "arguments": {"limit": 3}}, "id": 1}')

echo "Empty key response: $EMPTY_KEY_RESPONSE"
echo ""

# Check if response contains auth prompt
if echo "$PROMPT_RESPONSE" | grep -q "auth_prompt"; then
    echo "✅ Authentication prompt returned successfully!"
    echo "  - Contains auth_prompt type"
    
    # Extract prompt details
    if echo "$PROMPT_RESPONSE" | grep -q "growerp_login"; then
        echo "  - Contains growerp_login prompt"
    fi
    
    if echo "$PROMPT_RESPONSE" | grep -q "username"; then
        echo "  - Contains username field"
    fi
    
    if echo "$PROMPT_RESPONSE" | grep -q "password"; then
        echo "  - Contains password field"
    fi
    
    if echo "$PROMPT_RESPONSE" | grep -q "test@example.com"; then
        echo "  - Contains test credentials hint"
    fi
else
    echo "❌ Authentication prompt not found in response"
fi
echo ""

# Step 2: Test the auth/login endpoint with credentials
echo "Step 2: Testing auth/login endpoint with credentials..."

LOGIN_RESPONSE=$(curl -s -X POST "${BASE_URL}/rest/s1/mcp/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username": "'${USERNAME}'", "password": "'${PASSWORD}'", "classificationId": "'${CLASSIFICATION}'", "requestId": 2}')

echo "Login Response: $LOGIN_RESPONSE"
echo ""

# Extract API key from login response using jq for proper JSON parsing
API_KEY=$(echo "$LOGIN_RESPONSE" | jq -r '.apiKey')

if [ ! -z "$API_KEY" ]; then
    echo "✅ Login via auth/login endpoint successful!"
    echo "  API Key: ${API_KEY:0:16}..."
    
    # Step 3: Test MCP endpoint with the obtained API key
    echo ""
    echo "Step 3: Testing get_companies tool with API key from login..."
    echo "API Key: ${API_KEY:0:20}... (length: ${#API_KEY})"
    
    # Create clean JSON in a temporary file
    cat > /tmp/mcp_test.json << 'EOF'
{"jsonrpc": "2.0", "method": "tools/call", "params": {"name": "get_companies", "arguments": {"limit": 3}}, "id": 3}
EOF
    
    # Test with the API key from GrowERP login
    AUTHED_RESPONSE=$(curl -s -X POST "${BASE_URL}/rest/s1/mcp/protocol" \
      -H "Content-Type: application/json" \
      -H "api_key: ${API_KEY}" \
      -d @/tmp/mcp_test.json 2>&1)
    
    # Clean up temp file
    rm -f /tmp/mcp_test.json
    
    if echo "$AUTHED_RESPONSE" | grep -q '"content"'; then
        echo "✅ get_companies tool works with API key!"
        echo "  Response contains content data"
        # Show some of the response
        echo "$AUTHED_RESPONSE" | head -10
    else
        echo "❌ get_companies tool failed with API key"
        echo "  Response: $AUTHED_RESPONSE"
        
        # Let's also test the API key validation directly
        echo "  Testing API key validation directly..."
        VALIDATION_TEST=$(curl -s -X POST "${BASE_URL}/rest/s1/growerp/service/McpAuthServices/validate/McpApiKey" \
          -H "Content-Type: application/json" \
          -H "api_key: ${API_KEY}" \
          -d '{}')
        echo "  Validation test: $VALIDATION_TEST"
    fi
    
else
    echo "❌ Login failed or API key not found"
fi
echo ""

# Step 4: Test the MCP protocol with direct login method
echo "Step 4: Testing MCP protocol with auth/login method..."

LOGIN_VIA_PROTOCOL=$(curl -s -X POST "${BASE_URL}/rest/s1/mcp/protocol" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc": "2.0", "method": "auth/login", "params": {"username": "'${USERNAME}'", "password": "'${PASSWORD}'", "classificationId": "'${CLASSIFICATION}'"}, "id": 4}')

echo "Protocol Login Response: $LOGIN_VIA_PROTOCOL"
echo ""

if echo "$LOGIN_VIA_PROTOCOL" | grep -q '"auth_success"'; then
    echo "✅ Login via MCP protocol method successful!"
    
    # Extract API key from protocol response
    PROTOCOL_API_KEY=$(echo "$LOGIN_VIA_PROTOCOL" | grep -o '"apiKey" *: *"[^"]*' | cut -d'"' -f4)
    
    if [ ! -z "$PROTOCOL_API_KEY" ]; then
        echo "  API Key: ${PROTOCOL_API_KEY:0:16}..."
    fi
else
    echo "❌ Login via MCP protocol method failed"
fi
echo ""

# Step 5: Test auth prompt endpoint directly
echo "Step 5: Testing auth prompt endpoint..."

DIRECT_PROMPT=$(curl -s -X GET "${BASE_URL}/rest/s1/mcp/auth/prompt?requestId=5&reason=Testing")

echo "Direct Prompt Response: $DIRECT_PROMPT"
echo ""

if echo "$DIRECT_PROMPT" | grep -q "auth_prompt"; then
    echo "✅ Direct auth prompt endpoint works!"
else
    echo "❌ Direct auth prompt endpoint failed"
fi
echo ""

echo "=== Test Summary ==="
echo "This test demonstrates how AI can:"
echo "1. Receive authentication prompts when accessing protected MCP tools (get_companies)"
echo "2. Use the auth/login endpoint to authenticate with username/password"
echo "3. Use the obtained API key for subsequent MCP tool requests"
echo "4. Handle authentication via the MCP protocol directly"
echo ""
echo "The AI should look for 'auth_prompt' type in error responses and use the"
echo "provided prompt structure to collect user credentials."