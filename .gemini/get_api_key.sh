#!/bin/bash

# Script to get a fresh API key for GrowERP MCP server
# Usage: ./get_api_key.sh [username] [password] [classificationId]

USERNAME=${1:-"test@example.com"}
PASSWORD=${2:-"qqqqqq9!"}
CLASSIFICATION=${3:-"AppSupport"}

echo "🔑 Getting API key for user: $USERNAME"

RESPONSE=$(curl -s -X POST http://localhost:8080/rest/s1/mcp/auth/login \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"$USERNAME\",\"password\":\"$PASSWORD\",\"classificationId\":\"$CLASSIFICATION\"}")

if [ $? -eq 0 ]; then
    API_KEY=$(echo "$RESPONSE" | jq -r '.apiKey // empty')
    if [ -n "$API_KEY" ]; then
        echo "✅ API Key: $API_KEY"
        echo "📋 Add this to your settings.json:"
        echo "\"api_key\": \"$API_KEY\""
        
        # Optionally update settings.json automatically
        if [ "$4" = "--update" ]; then
            SETTINGS_FILE="/home/hans/growerp/.gemini/settings.json"
            if [ -f "$SETTINGS_FILE" ]; then
                # Create backup
                cp "$SETTINGS_FILE" "$SETTINGS_FILE.backup"
                
                # Update API key in settings.json
                jq --arg key "$API_KEY" '.mcpServers."growerp-system".headers.api_key = $key' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp" && mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
                echo "✅ Updated $SETTINGS_FILE with new API key"
            fi
        fi
    else
        echo "❌ Failed to extract API key from response:"
        echo "$RESPONSE" | jq .
    fi
else
    echo "❌ Failed to connect to server"
fi