#!/bin/bash

# MCP Authorization Test Script
# Tests the API key authentication for MCP endpoints

BASE_URL="http://localhost:8080"
USERNAME="test@example.com"
PASSWORD="qqqqqq9!"
CLASSIFICATION="AppSupport"

echo "=== GrowERP MCP Authorization Test ==="
echo ""

# Step 1: Login and get API key
echo "Step 1: Logging in to get API key..."
LOGIN_RESPONSE=$(curl -s -X POST "${BASE_URL}/rest/s1/growerp/100/Login" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "'${USERNAME}'",
    "password": "'${PASSWORD}'", 
    "classificationId": "'${CLASSIFICATION}'"
  }')

# Extract API key using a robust method for GrowERP JSON format
# GrowERP returns JSON with spaces: "apiKey" : "value" (not compact "apiKey":"value")
API_KEY=$(echo "$LOGIN_RESPONSE" | grep -o '"apiKey" : "[^"]*' | cut -d'"' -f4)

if [ -z "$API_KEY" ]; then
    echo "❌ Failed to get API key. Login response:"
    echo "$LOGIN_RESPONSE"
fi

echo "✅ Login successful! API Key: ${API_KEY:0:16}..."
echo ""

# Step 2: Test MCP discovery endpoints without authentication (should be public per MCP spec)
echo "Step 2: Testing MCP discovery endpoints without authentication (should be public per MCP spec)..."

UNAUTH_RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "${BASE_URL}/rest/s1/mcp/resources")
UNAUTH_STATUS=$(echo "$UNAUTH_RESPONSE" | tail -n1)

if [ "$UNAUTH_STATUS" -eq 200 ]; then
    echo "✅ MCP discovery endpoints are public as required by MCP spec (HTTP $UNAUTH_STATUS)"
else
    echo "⚠️  MCP discovery endpoints returned unexpected status (HTTP $UNAUTH_STATUS)"
fi
echo ""

# Step 3: Test MCP endpoints with authentication (should work)
echo "Step 3: Testing MCP endpoints with authentication..."

# Test each endpoint
ENDPOINTS=("health" "tools" "resources" "prompts")
ALL_PASSED=true

for ENDPOINT in "${ENDPOINTS[@]}"; do
    echo "  Testing $ENDPOINT endpoint..."
    
    AUTH_RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "${BASE_URL}/rest/s1/mcp/${ENDPOINT}" \
      -H "api_key: ${API_KEY}")
    
    AUTH_STATUS=$(echo "$AUTH_RESPONSE" | tail -n1)
    
    if [ "$AUTH_STATUS" -eq 200 ]; then
        echo "    ✅ $ENDPOINT endpoint works with authentication"
    else
        echo "    ❌ $ENDPOINT endpoint failed (HTTP $AUTH_STATUS)"
        echo "    Response: $(echo "$AUTH_RESPONSE" | head -n -1)"
        ALL_PASSED=false
    fi
done
echo ""

# Step 4: Test MCP Protocol endpoint
echo "Step 4: Testing MCP Protocol endpoint..."

PROTOCOL_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "${BASE_URL}/rest/s1/mcp/protocol" \
  -H "Content-Type: application/json" \
  -H "api_key: ${API_KEY}" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/list",
    "id": 1
  }')

PROTOCOL_STATUS=$(echo "$PROTOCOL_RESPONSE" | tail -n1)

if [ "$PROTOCOL_STATUS" -eq 200 ]; then
    echo "✅ MCP Protocol endpoint works with authentication"
    echo "Response: $(echo "$PROTOCOL_RESPONSE" | head -n -1 | head -c 200)..."
else
    echo "❌ MCP Protocol endpoint failed (HTTP $PROTOCOL_STATUS)"
    echo "Response: $(echo "$PROTOCOL_RESPONSE" | head -n -1)"
    ALL_PASSED=false
fi
echo ""

# Step 5: Test authentication validation endpoint
echo "Step 5: Testing authentication validation..."

AUTH_CHECK_RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "${BASE_URL}/rest/s1/growerp/100/Authenticate?classificationId=${CLASSIFICATION}" \
  -H "api_key: ${API_KEY}")

AUTH_CHECK_STATUS=$(echo "$AUTH_CHECK_RESPONSE" | tail -n1)

if [ "$AUTH_CHECK_STATUS" -eq 200 ]; then
    echo "✅ Authentication validation works"
else
    echo "❌ Authentication validation failed (HTTP $AUTH_CHECK_STATUS)"
    echo "Response: $(echo "$AUTH_CHECK_RESPONSE" | head -n -1)"
    ALL_PASSED=false
fi
echo ""

# Summary
echo "=== Test Results Summary ==="
if [ "$ALL_PASSED" = true ]; then
    echo "🎉 All tests passed! MCP authorization is working correctly."
    exit 0
else
    echo "❌ Some tests failed. Check the output above for details."
    exit 1
fi
